require "rubygems"
require "bundler/setup"
require "active_model"
require "erb"
require "rest-client"
require "json"
require "active_support/hash_with_indifferent_access"
require "parse_resource/query"
require "parse_resource/query_methods"
require "parse_resource/parse_error"
require "parse_resource/parse_exceptions"
require "parse_resource/types/parse_geopoint"

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

    #settings 
    @@settings ||= nil
    # mapping between the parse models and your models.
    @@parse_models ||= {}
    # inverse mapping to make things quick to go the other way.
    @@inverse_parse_models ||= {}


    # Instantiates a ParseResource::Base object
    #
    # @params [Hash], [Boolean] a `Hash` of attributes and a `Boolean` that should be false only if the object already exists
    # @return [ParseResource::Base] an object that subclasses `Parseresource::Base`
    def initialize(attributes = {}, new=true)     
      if new
        @unsaved_attributes = attributes.stringify_keys.slice(* self.class.accepted_fields)
        @unsaved_attributes = coerce_attributes(@unsaved_attributes)
      else
        @unsaved_attributes = {}
      end

      @attributes = {}
      self.error_instances = []

      self.attributes.merge!(attributes)
      self.attributes unless self.attributes.empty?
      create_setters_and_getters!
    end

    # Explicitly adds a field to the model.
    #
    # @param [Symbol] name the name of the field, eg `:author`.
    # @param [Boolean] val the return value of the field. Only use this within the class.
    def self.field(name_or_hash, val=nil)
      if name_or_hash.class == Hash
        fname = name_or_hash.keys.first
        klass = name_or_hash.values.first
        self.add_to_map(fname.to_s, klass)
      else
        fname = name_or_hash
        klass = nil
      end

      self.add_accepted_field(fname.to_s)

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

    def self.accepted_fields
      @_fields || []
    end

    def self.add_accepted_field(field)
      @_fields ||= []
      @_fields << field
    end

    def self.add_to_map(key, value)
      @_map ||= {}
      @_map[key] = value
    end

    def self.field_map
      @_map || {}
    end

    def self.field_map_keys
      ( @_map || {} ).keys
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
      klass_name = "_Installation" if klass_name == "Installation"
      {"__type" => "Pointer", "className" => klass_name.to_s, "objectId" => self.id}
    end

    def self.to_date_object(date)
      date = date.to_time if date.respond_to?(:to_time)
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

    # Explicitly set Parse.com API keys.
    #
    # @param [String] app_id the Application ID of your Parse database
    # @param [String] master_key the Master Key of your Parse database
    def self.load!(app_id, master_key)
      @@settings = {"app_id" => app_id, "master_key" => master_key}
    end

    def self.settings
      load_settings
    end

    def self.parse_model_name(klass_name)
      @parse_class ||= klass_name
      @@parse_models[klass_name] = self.name
      @@inverse_parse_models[self.name] = klass_name
    end

    def self.parse_models
      @@parse_models
    end

    def self.inverse_parse_models
      @@inverse_parse_models
    end

    def self.model_name_for_parse_class(parse_class)
      @@parse_models[parse_class.to_s]
    end

    def self.parse_class_name_for_model(model_name)
      @@inverse_parse_models[model_name.to_s]
    end

    # Gets the current class's model name for the URI
    def self.model_name_uri
      if self.model_name == "User"
        "users"
      elsif self.model_name == "Installation"
        "installations"
      else
        parse_class_name = ParseResource::Base.parse_class_name_for_model(self.model_name)
        "classes/#{parse_class_name || self.model_name}"
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

    def self.parse_class
      @parse_class || self.name
    end

    def parse_class
      self.class.parse_class
    end

    def self.to_s
      if self.respond_to? "objectId"
        self.objectId
      else
        super
      end
    end

    def self.parse(id)
      self.find(id)
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
    # Set slice_size to send larger batches. Defaults to 20 to prevent timeouts.
    # Parse doesn't support batches of over 20.
    #
    def self.batch_save(save_objects, slice_size = 20, method = nil)
      return true if save_objects.blank?
      load_settings

      base_uri = "https://api.parse.com/1/batch"
      app_id     = @@settings['app_id']
      master_key = @@settings['master_key']

      res = RestClient::Resource.new(base_uri, app_id, master_key)

      # Batch saves seem to fail if they're too big. We'll slice it up into multiple posts if they are.
      save_objects.each_slice(slice_size) do |objects|
        # attributes_for_saving
        batch_json = { "requests" => [] }

        objects.each do |item|
          method ||= (item.new?) ? "POST" : "PUT"
          object_path = "/1/#{item.class.model_name_uri}"
          object_path = "#{object_path}/#{item.id}" if item.id
          json = {
            "method" => method,
            "path" => object_path
          }
          json["body"] = item.attributes_for_saving unless method == "DELETE"
          batch_json["requests"] << json
        end
        res.post(batch_json.to_json, :content_type => "application/json") do |resp, req, res, &block|
          response = JSON.parse(resp) rescue nil
          if resp.code == 400
            puts resp
            return false
          end
          if response && response.is_a?(Array) && response.length == objects.length
            merge_all_attributes(objects, response) unless method == "DELETE"
          end
        end
      end
      true
    end

    def self.merge_all_attributes(objects, response)
      i = 0
      objects.each do |item|
        item.merge_attributes(response[i]["success"]) if response[i] && response[i]["success"]
        i += 1
      end
      nil
    end

    def self.save_all(objects)
      batch_save(objects)
    end

    def self.destroy_all(objects=nil)
      objects ||= self.all
      batch_save(objects, 20, "DELETE")
    end

    def self.delete_all(o)
      raise StandardError.new("Parse Resource: delete_all doesn't exist. Did you mean destroy_all?")
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


    include ParseResource::QueryMethods


    def self.chunk(attribute)
      Query.new(self).chunk(attribute)
    end

    # Create a ParseResource::Base object.
    #
    # @param [Hash] attributes a `Hash` of attributes
    # @return [ParseResource] an object that subclasses `ParseResource`. Or returns `false` if object fails to save.
    def self.create(attributes = {})
      attributes = HashWithIndifferentAccess.new(attributes)
      obj = new(attributes)
      obj.save
      obj
    end

    # Replaced with a batch destroy_all method.
    # def self.destroy_all(all)
    #   all.each do |object|
    #     object.destroy
    #   end
    # end

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
        elsif v.is_a?(Date) || v.is_a?(Time) || v.is_a?(DateTime)
          new_hash[k] = self.class.to_date_object(v)
        else
          new_hash[k] = v
        end
      end
      new_hash
    end

    def save
      if valid?
        if new?
          return create
        else
          return update
        end
      else
        false
      end
      rescue false
    end

    def create
      run_callbacks :update do
        run_callbacks :save do

          attrs = attributes_for_saving.to_json
          opts = {:content_type => "application/json"}
          result = self.resource.post(attrs, opts) do |resp, req, res, &block|
            return post_result(resp, req, res, &block)
          end
        end
      end
    end

    def update(attributes = {})
      if attributes
        attributes = attributes.stringify_keys.slice(* self.class.accepted_fields)
        attributes = self.coerce_attributes(attributes)
      end

      run_callbacks :update do
        run_callbacks :save do
          @unsaved_attributes.merge!(attributes)
          put_attrs = attributes_for_saving.to_json

          opts = {:content_type => "application/json"}
          result = self.instance_resource.put(put_attrs, opts) do |resp, req, res, &block|
            return post_result(resp, req, res, &block)
          end
        end
      end
    end

    # Merges in the return value of a save and resets the unsaved_attributes
    def merge_attributes(results)
      @attributes.merge!(results)
      @attributes.merge!(@unsaved_attributes)
      @unsaved_attributes = {}
      create_setters_and_getters!
      @attributes
    end

    def post_result(resp, req, res, &block)
      if resp.code.to_s == "200" || resp.code.to_s == "201"
        merge_attributes(JSON.parse(resp))
        return true
      else
        error_response = JSON.parse(resp)
        if error_response["error"]
          pe = ParseError.new(error_response["code"], error_response["error"])
        else
          pe = ParseError.new(resp.code.to_s)
        end
        # try to add error to model.
        if pe.code == 111
          phrase = pe.msg.split("key ")
          key = phrase[1].split(",").first if phrase.count > 1
          self.errors.add(key.to_sym, pe.msg) if key
          #self.errors.add(key.underscore, pe.msg) if key
        end
        self.errors.add(pe.code.to_s.to_sym, pe.msg)
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

    def coerce_attributes(attributes)
      attributes.keys.each do |key|
        attributes[key] = coerce_attribute(key, attributes[key])
      end
      attributes
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

    def dirty?
      @unsaved_attributes.length > 0
    end

    def clean?
      !dirty?
    end

    # provides access to @attributes for getting and setting
    def attributes
      @attributes ||= self.class.class_attributes
      @attributes
    end

    def attributes=(value)
      if value.is_a?(Hash) && value.present?
        value.each do |k, v|
          send "#{k}=", v
        end
      end
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
          # if we are using a mapped class then we need to find that class here
          # and call its find method
          name = ParseResource::Base.model_name_for_parse_class(klass_name) || klass_name
          result = name.constantize.find(attrs[k]["objectId"])
        when "Object"
          result = klass_name.constantize.new(attrs[k], false)
        when "Date"
          result = DateTime.parse(attrs[k]["iso"]).to_time_in_current_zone
        when "File"
          result = attrs[k]["url"]
        when "GeoPoint"
          result = ParseGeoPoint.new(attrs[k])
        end #todo: support other types https://www.parse.com/docs/rest#objects-types
      else
        result =  attrs["#{k}"]
      end
      result
    end

    def set_attribute(k, v)
      if v.is_a?(Date) || v.is_a?(Time) || v.is_a?(DateTime)
        v = self.class.to_date_object(v)
      elsif v.respond_to?(:to_pointer)
        v = v.to_pointer
        # if we have a mapped class then we need to change back to the parse 
        # class here.
        klass_name = ParseResource::Base.parse_class_name_for_model(v['className'])
        v['className'] = klass_name unless klass_name.nil?
      end
      @unsaved_attributes[k.to_s] = v unless v == @attributes[k.to_s] # || @unsaved_attributes[k.to_s]
      @attributes[k.to_s] = v
      v
    end

    def coerce_attribute(key, value)
      klass = self.class.field_map[key]

      if klass.nil? || value.class == klass
        value
      else
        if(Kernel.respond_to?(klass.name))
          Kernel.send(klass.name, value)
        elsif klass.respond_to?(:parse)
          klass.parse(value)
        else
          value
        end
      end
    end


    # aliasing for idiomatic Ruby
    def id; get_attribute("objectId") rescue nil; end
    def objectId; get_attribute("objectId") rescue nil; end

    def created_at; get_attribute("createdAt"); end

    def updated_at; get_attribute("updatedAt"); rescue nil; end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
    end

  end
end
