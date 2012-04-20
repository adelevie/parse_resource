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
require "parse_resource/associations"
require "parse_resource/finders"
require "parse_resource/default_attributes"
require "parse_resource/dynamic_methods"
require "parse_resource/client"

module ParseResource
  

  class Base
    # ParseResource::Base provides an easy way to use Ruby to interace with a Parse.com backend
    # Usage:
    #  class Post < ParseResource::Base
    #    fields :title, :author, :body
    #  end
    
    extend Associations
    extend Finders
    extend Client
    include DefaultAttributes
    include DynamicMethods

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
    
    #def self.belongs_to(parent)
    #  field(parent)
    #end
  

    def to_pointer
      klass_name = self.class.model_name
      klass_name = "_User" if klass_name == "User"
      {"__type" => "Pointer", "className" => klass_name, "objectId" => self.id}
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

    # def self.has_many

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

  end
end