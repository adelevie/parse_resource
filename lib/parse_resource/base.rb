require "rubygems"
require "bundler/setup"
require "active_model"
require "erb"
require "rest-client"
require "json"
require "active_support/hash_with_indifferent_access"
require "parse_resource/query"
require "parse_resource/parse_error"
require "parse_resource/parse_exceptions"

module ParseResource
  

  class Base
    # ParseResource::Base provides an easy way to use Ruby to interace with a Parse.com backend
    # Usage:
    #  class Post < ParseResource::Base
    #    fields :title, :author, :body
    #  end

    include ActiveModel::Validations
    include ActiveModel::Conversion
    include ActiveModel::AttributeMethods
    extend ActiveModel::Naming
    extend ActiveModel::Callbacks
    HashWithIndifferentAccess = ActiveSupport::HashWithIndifferentAccess

    attr_accessor :error_instances

    define_model_callbacks :save, :create, :update, :destroy
    
    # Instantiates a ParseResource::Base object
    #
    # @params [Hash], [Boolean] a `Hash` of attributes and a `Boolean` that should be false only if the object already exists
    # @return [ParseResource::Base] an object that subclasses `Parseresource::Base`
    def initialize(attributes = {}, new=true)
      #attributes = HashWithIndifferentAccess.new(attributes)

      if new
        @unsaved_attributes = attributes
      else
        @unsaved_attributes = {}
      end
      self.attributes = {}
      self.error_instances = []
            
      self.attributes.merge!(attributes)
      self.attributes unless self.attributes.empty?
      create_setters_and_getters!
    end

    # Explicitly adds a field to the model.
    #
    # @param [Symbol] name the name of the field, eg `:author`.
    # @param [Boolean] val the return value of the field. Only use this within the class.
    def self.field(fname, val=nil)
      class_eval do
        define_method(fname) do
          get_attribute("#{fname}")
        end
      end
      unless self.respond_to? "#{fname}="
        class_eval do
          define_method("#{fname}=") do |val|
            set_attribute("#{fname}", val)
            
            val
          end
        end
      end
    end

    # Add multiple fields in one line. Same as `#field`, but accepts multiple args.
    #
    # @param [Array] *args an array of `Symbol`s, `eg :author, :body, :title`.
    def self.fields(*args)
      args.each {|f| field(f)}
    end
    
    # Similar to its ActiveRecord counterpart.
    #
    # @param [Hash] options Added so that you can specify :class_name => '...'. It does nothing at all, but helps you write self-documenting code.
    def self.belongs_to(parent, options = {})
      field(parent)
    end
    
    def to_pointer
      klass_name = self.class.model_name
      klass_name = "_User" if klass_name == "User"
      {"__type" => "Pointer", "className" => klass_name.to_s, "objectId" => self.id}
    end

    def self.to_date_object(date)
      {"__type" => "Date", "iso" => date.iso8601} if date && (date.is_a?(Date) || date.is_a?(DateTime) || date.is_a?(Time))
    end

    # Creates setter methods for model fields
    def create_setters!(k,v)
      unless self.respond_to? "#{k}="
        self.class.send(:define_method, "#{k}=") do |val|
          set_attribute("#{k}", val)
          
          val
        end
      end
    end

    def self.method_missing(method_name, *args)
      method_name = method_name.to_s
      if method_name.start_with?("find_by_")
        attrib   = method_name.gsub(/^find_by_/,"")
        finder_name = "find_all_by_#{attrib}"

        define_singleton_method(finder_name) do |target_value|
          where({attrib.to_sym => target_value}).first
        end

        send(finder_name, args[0])

      elsif method_name.start_with?("find_all_by_")
        attrib   = method_name.gsub(/^find_all_by_/,"")
        finder_name = "find_all_by_#{attrib}"

        define_singleton_method(finder_name) do |target_value|
          where({attrib.to_sym => target_value}).all
        end

        send(finder_name, args[0])
      else
        super(method_name.to_sym, *args)
      end
    end

    # Creates getter methods for model fields
    def create_getters!(k,v)
      unless self.respond_to? "#{k}"
        self.class.send(:define_method, "#{k}") do
          get_attribute("#{k}")
        end
      end
    end

    def create_setters_and_getters!
      @attributes.each_pair do |k,v|
        create_setters!(k,v)
        create_getters!(k,v)
      end
    end
      
    def self.has_many(children, options = {})
      options.stringify_keys!
      
      parent_klass_name = model_name
      lowercase_parent_klass_name = parent_klass_name.downcase
      parent_klass = model_name.constantize
      child_klass_name = options['class_name'] || children.to_s.singularize.camelize
      child_klass = child_klass_name.constantize
      
      if parent_klass_name == "User"
        parent_klass_name = "_User"
      end
      
      @@parent_klass_name = parent_klass_name
      @@options ||= {}
      @@options[children] ||= {}
      @@options[children].merge!(options)
      
      send(:define_method, children) do
        @@parent_id = self.id
        @@parent_instance = self
        
        parent_klass_name = case
          when @@options[children]['inverse_of'] then @@options[children]['inverse_of'].downcase
          when @@parent_klass_name == "User" then "_User"
          else @@parent_klass_name.downcase
        end
        
        query = child_klass.where(parent_klass_name.to_sym => @@parent_instance.to_pointer)
        singleton = query.all
        
        class << singleton
          def <<(child)
            parent_klass_name = case
              when @@options[children]['inverse_of'] then @@options[children]['inverse_of'].downcase
              when @@parent_klass_name == "User" then @@parent_klass_name
              else @@parent_klass_name.downcase
            end
            if @@parent_instance.respond_to?(:to_pointer)
              child.send("#{parent_klass_name}=", @@parent_instance.to_pointer)
              child.save
            end
            super(child)
          end
        end
        
        singleton
      end
      
    end

    @@settings ||= nil

    # Explicitly set Parse.com API keys.
    #
    # @param [String] app_id the Application ID of your Parse database
    # @param [String] master_key the Master Key of your Parse database
    def self.load!(app_id, master_key)
      @@settings = {"app_id" => app_id, "master_key" => master_key}
    end

    def self.settings
      if @@settings.nil?
        path = "config/parse_resource.yml"
        #environment = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : ENV["RACK_ENV"]
        environment = ENV["RACK_ENV"]
        @@settings = YAML.load(ERB.new(File.new(path).read).result)[environment]
      end
      @@settings
    end
    
    # Gets the current class's model name for the URI
    def self.model_name_uri
      if self.model_name == "User"
        "users"
      else
        self.model_name
      end
    end
    
    # Gets the current class's Parse.com base_uri
    def self.model_base_uri
      "https://api.parse.com/1/#{model_name_uri}"
    end
    
    # Gets the current instance's parent class's Parse.com base_uri
    def model_base_uri
      self.class.send(:model_base_uri)
    end
    

    # Creates a RESTful resource
    # sends requests to [base_uri]/[classname]
    #
    def self.resource
      load_settings

      #refactor to settings['app_id'] etc
      app_id     = @@settings['app_id']
      master_key = @@settings['master_key']
      RestClient::Resource.new(self.model_base_uri, app_id, master_key)
    end
    
    # Batch requests
    # Sends multiple requests to /batch
    #
    def self.batch_save(objects)
      load_settings

      
      # attributes_for_saving
      batch_json = { "requests" => [] }
      
      objects.each do |item|
        method = (item.new?) ? "POST" : "PUT"
        batch_json["requests"] << {
          "method": method,
          "path": "/1/classes/#{item.class.model_name_uri}",
          "body": item.attributes_for_saving
        }
      end
      
      base_uri = "https://api.parse.com/1/batch"
      app_id     = @@settings['app_id']
      master_key = @@settings['master_key']
      
      opts = {:content_type => "application/json"}
      res = RestClient::Resource.new(base_uri, app_id, master_key)
      res.post(batch_json, opts) do |resp, req, res, &block|
        puts "Received response!"
        puts resp
      end
    end
    
    def self.load_settings
      @@settings ||= begin
        path = "config/parse_resource.yml"
        environment = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : ENV["RACK_ENV"]
        YAML.load(ERB.new(File.new(path).read).result)[environment]
      end
      @@settings
    end
    

    # Creates a RESTful resource for file uploads
    # sends requests to [base_uri]/files
    #
    def self.upload(file_instance, filename, options={})
      load_settings
      
      base_uri = "https://api.parse.com/1/files"
      
      #refactor to settings['app_id'] etc
      app_id     = @@settings['app_id']
      master_key = @@settings['master_key']

      options[:content_type] ||= 'image/jpg' # TODO: Guess mime type here.
      file_instance = File.new(file_instance, 'rb') if file_instance.is_a? String

      filename = filename.parameterize

      private_resource = RestClient::Resource.new "#{base_uri}/#{filename}", app_id, master_key
      private_resource.post(file_instance, options) do |resp, req, res, &block|
        return false if resp.code == 400
        return JSON.parse(resp) rescue {"code" => 0, "error" => "unknown error"}
      end
      false
    end

    # Find a ParseResource::Base object by ID
    #
    # @param [String] id the ID of the Parse object you want to find.
    # @return [ParseResource] an object that subclasses ParseResource.
    def self.find(id)
			raise RecordNotFound if id.blank?
      where(:objectId => id).first
    end

    # Find a ParseResource::Base object by chaining #where method calls.
    #
    def self.where(*args)
      Query.new(self).where(*args)
    end
    
    # Include the attributes of a parent ojbect in the results
    # Similar to ActiveRecord eager loading
    #
    def self.include_object(parent)
      Query.new(self).include_object(parent)
    end

    # Add this at the end of a method chain to get the count of objects, instead of an Array of objects
    def self.count
      #https://www.parse.com/docs/rest#queries-counting
      Query.new(self).count(1)
    end

    # Find all ParseResource::Base objects for that model.
    #
    # @return [Array] an `Array` of objects that subclass `ParseResource`.
    def self.all
      Query.new(self).all
    end

    # Find the first object. Fairly random, not based on any specific condition.
    #
    def self.first
      Query.new(self).limit(1).first
    end

    # Limits the number of objects returned
    #
    def self.limit(n)
      Query.new(self).limit(n)
    end

    # Skip the number of objects
    #
    def self.skip(n)
      Query.new(self).skip(n)
    end
    
    def self.order(attribute)
      Query.new(self).order(attribute)
    end

    # Create a ParseResource::Base object.
    #
    # @param [Hash] attributes a `Hash` of attributes
    # @return [ParseResource] an object that subclasses `ParseResource`. Or returns `false` if object fails to save.
    def self.create(attributes = {})
      attributes = HashWithIndifferentAccess.new(attributes)
      obj = new(attributes)
      obj.save
      obj # This won't return true/false it will return object or nil...
    end

    def self.destroy_all
      all.each do |object|
        object.destroy
      end
    end

    def self.class_attributes
      @class_attributes ||= {}
    end

    def persisted?
      if id
        true
      else
        false
      end
    end

    def new?
      !persisted?
    end

    # delegate from Class method
    def resource
      self.class.resource
    end

    # create RESTful resource for the specific Parse object
    # sends requests to [base_uri]/[classname]/[objectId]
    def instance_resource
      self.class.resource["#{self.id}"]
    end

    def pointerize(hash)
      new_hash = {}
      hash.each do |k, v|
        if v.respond_to?(:to_pointer)
          new_hash[k] = v.to_pointer
        else
          new_hash[k] = v
        end
      end
      new_hash
    end

    def save
      if valid?
        run_callbacks :save do
          if new?
            return create 
          else
            return update
          end
        end
      else
        false
      end
      rescue false
    end

    def create
      attrs = attributes_for_saving.to_json
      opts = {:content_type => "application/json"}
      result = self.resource.post(attrs, opts) do |resp, req, res, &block|
        return post_result(resp, req, res, &block)
      end
    end

    def update(attributes = {})
      
      attributes = HashWithIndifferentAccess.new(attributes)
        
      @unsaved_attributes.merge!(attributes)
      put_attrs = attributes_for_saving.to_json
      
      opts = {:content_type => "application/json"}
      result = self.instance_resource.put(put_attrs, opts) do |resp, req, res, &block|
        return post_result(resp, req, res, &block)
      end
    end
    
    def post_result(resp, req, res, &block)
      if resp.code.to_s == "200" || resp.code.to_s == "201"
        @attributes.merge!(JSON.parse(resp))
        @attributes.merge!(@unsaved_attributes)
        @unsaved_attributes = {}
        create_setters_and_getters!
        return true
      else
        error_response = JSON.parse(resp)
        if error_response["error"]
          pe = ParseError.new(error_response["code"], error_response["error"]).to_array
        else
          pe = ParseError.new(resp.code.to_s).to_array
        end
        self.errors.add(pe[0], pe[1])
        self.error_instances << pe     
        return false
      end      
    end
    
    def attributes_for_saving
      @unsaved_attributes = pointerize(@unsaved_attributes)
      put_attrs = @unsaved_attributes
      put_attrs.delete('objectId')
      put_attrs.delete('createdAt')
      put_attrs.delete('updatedAt')
      put_attrs
    end

    def update_attributes(attributes = {})
      self.update(attributes)
    end

    def destroy
      if self.instance_resource.delete
        @attributes = {}
        @unsaved_attributes = {}
        return true
      end
      false
    end

    def reload
      return false if new?
      
      fresh_object = self.class.find(id)
      @attributes.update(fresh_object.instance_variable_get('@attributes'))
      @unsaved_attributes = {}
      
      self
    end

    # provides access to @attributes for getting and setting
    def attributes
      @attributes ||= self.class.class_attributes
      @attributes
    end

    # AKN 2012-06-18: Shouldn't this also be setting @unsaved_attributes?
    def attributes=(n)
      @attributes = n
      @attributes
    end

    def get_attribute(k)
      attrs = @unsaved_attributes[k.to_s] ? @unsaved_attributes : @attributes
      case attrs[k]
      when Hash
        klass_name = attrs[k]["className"]
        klass_name = "User" if klass_name == "_User"
        case attrs[k]["__type"]
        when "Pointer"
          result = klass_name.constantize.find(attrs[k]["objectId"])
        when "Object"
          result = klass_name.constantize.new(attrs[k], false)
        when "Date"
          result = DateTime.parse(attrs[k]["iso"]).to_time_in_current_zone
        when "File"
          result = attrs[k]["url"]
        end #todo: support other types https://www.parse.com/docs/rest#objects-types
      else
        result =  attrs["#{k}"]
      end          
      result
    end

    def set_attribute(k, v)
      if v.is_a?(Date) || v.is_a?(Time) || v.is_a?(DateTime)
        v = {"__type" => "Date", "iso" => v.iso8601}
      elsif v.respond_to?(:to_pointer)
        v = v.to_pointer 
      end
      @unsaved_attributes[k.to_s] = v unless v == @attributes[k.to_s] # || @unsaved_attributes[k.to_s]
      @attributes[k.to_s] = v
      v
    end


    # aliasing for idiomatic Ruby
    def id; get_attribute("objectId") rescue nil; end
    def objectId; get_attribute("objectId") rescue nil; end

    def created_at; self.createdAt; end

    def updated_at; self.updatedAt rescue nil; end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
    end

  end
end
