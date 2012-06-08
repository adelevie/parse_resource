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
            
      self.attributes.merge!(attributes)
      self.attributes unless self.attributes.empty?
      create_setters_and_getters!
    end

    # Explicitly adds a field to the model.
    #
    # @param [Symbol] name the name of the field, eg `:author`.
    # @param [Boolean] val the return value of the field. Only use this within the class.
    def self.field(name, val=nil)
      class_eval do
        define_method(name) do
          @attributes[name] ? @attributes[name] : @unsaved_attributes[name]
        end
        define_method("#{name}=") do |val|
          val = val.to_pointer if val.respond_to?(:to_pointer)
          
          @attributes[name] = val
          @unsaved_attributes[name] = val
          
          val
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
      {"__type" => "Pointer", "className" => klass_name, "objectId" => self.id}
    end

    # Creates setter methods for model fields
    def create_setters!(k,v)
      self.class.send(:define_method, "#{k}=") do |val|
        val = val.to_pointer if val.respond_to?(:to_pointer)

        @attributes[k.to_s] = val
        @unsaved_attributes[k.to_s] = val
        
        val
      end
    end

    def self.method_missing(name, *args)
      name = name.to_s
      if name.start_with?("find_by_")
        attribute   = name.gsub(/^find_by_/,"")
        finder_name = "find_all_by_#{attribute}"

        define_singleton_method(finder_name) do |target_value|
          where({attribute.to_sym => target_value}).first
        end

        send(finder_name, args[0])

      elsif name.start_with?("find_all_by_")
        attribute   = name.gsub(/^find_all_by_/,"")
        finder_name = "find_all_by_#{attribute}"

        define_singleton_method(finder_name) do |target_value|
          where({attribute.to_sym => target_value}).all
        end

        send(finder_name, args[0])
      else
        super(name.to_sym, *args)
      end
    end

    # Creates getter methods for model fields
    def create_getters!(k,v)
      self.class.send(:define_method, "#{k}") do
                
        case @attributes[k]
        when Hash
          
          klass_name = @attributes[k]["className"]
          klass_name = "User" if klass_name == "_User"
          
          case @attributes[k]["__type"]
          when "Pointer"
            result = klass_name.constantize.find(@attributes[k]["objectId"])
          when "Object"
            result = klass_name.constantize.new(@attributes[k], false)
          end #todo: support Dates and other types https://www.parse.com/docs/rest#objects-types
          
        else
          result =  @attributes[k]
        end
        
        result
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

    # Creates a RESTful resource
    # sends requests to [base_uri]/[classname]
    #
    def self.resource
      if @@settings.nil?
        path = "config/parse_resource.yml"
        environment = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : ENV["RACK_ENV"]
        @@settings = YAML.load(ERB.new(File.new(path).read).result)[environment]
      end

      if model_name == "User" #https://parse.com/docs/rest#users-signup
        base_uri = "https://api.parse.com/1/users"
      else
        base_uri = "https://api.parse.com/1/classes/#{model_name}"
      end

      #refactor to settings['app_id'] etc
      app_id     = @@settings['app_id']
      master_key = @@settings['master_key']
      RestClient::Resource.new(base_uri, app_id, master_key)
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
    
    def self.order(attribute)
      Query.new(self).order(attribute)
    end

    # Create a ParseResource::Base object.
    #
    # @param [Hash] attributes a `Hash` of attributes
    # @return [ParseResource] an object that subclasses `ParseResource`. Or returns `false` if object fails to save.
    def self.create(attributes = {})
      attributes = HashWithIndifferentAccess.new(attributes)
      new(attributes).save
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

    def create
      opts = {:content_type => "application/json"}
      attrs = @unsaved_attributes.to_json
      result = self.resource.post(attrs, opts) do |resp, req, res, &block|
        
        case resp.code 
        when 400
          
          # https://www.parse.com/docs/ios/api/Classes/PFConstants.html
          error_response = JSON.parse(resp)
          pe = ParseError.new(error_response["code"]).to_array
          self.errors.add(pe[0], pe[1])
        
        else
          @attributes.merge!(JSON.parse(resp))
          @attributes.merge!(@unsaved_attributes)
          attributes = HashWithIndifferentAccess.new(attributes)
          @unsaved_attributes = {}
          create_setters_and_getters!
        end
        
        self
      end
    
      result
    end

    def save
      if valid?
        run_callbacks :save do
          new? ? create : update
        end
      else
        false
      end
      rescue false
    end

    def update(attributes = {})
      
      attributes = HashWithIndifferentAccess.new(attributes)
        
      @unsaved_attributes.merge!(attributes)

      put_attrs = @unsaved_attributes
      put_attrs.delete('objectId')
      put_attrs.delete('createdAt')
      put_attrs.delete('updatedAt')
      put_attrs = put_attrs.to_json
      
      opts = {:content_type => "application/json"}
      result = self.instance_resource.put(put_attrs, opts) do |resp, req, res, &block|

        case resp.code
        when 400
          
          # https://www.parse.com/docs/ios/api/Classes/PFConstants.html
          error_response = JSON.parse(resp)
          pe = ParseError.new(error_response["code"], error_response["error"]).to_array
          self.errors.add(pe[0], pe[1])
          
        else

          @attributes.merge!(JSON.parse(resp))
          @attributes.merge!(@unsaved_attributes)
          @unsaved_attributes = {}
          create_setters_and_getters!

          self
        end
        
        result
      end
     
    end

    def update_attributes(attributes = {})
      self.update(attributes)
    end

    def destroy
      self.instance_resource.delete
      @attributes = {}
      @unsaved_attributes = {}
      nil
    end

    # provides access to @attributes for getting and setting
    def attributes
      @attributes ||= self.class.class_attributes
      @attributes
    end

    def attributes=(n)
      @attributes = n
      @attributes
    end

    # aliasing for idiomatic Ruby
    def id; self.objectId rescue nil; end

    def created_at; self.createdAt; end

    def updated_at; self.updatedAt rescue nil; end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
    end

  end
end
