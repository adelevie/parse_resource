require "rubygems"
require "bundler/setup"
require "active_model"
require "erb"
require "rest-client"
require "json"
require "active_support/hash_with_indifferent_access"

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

  # define_model_callbacks :initialize, :find, :only => :after
  define_model_callbacks :save, :create, :update, :destroy


  # Instantiates a ParseResource::Base object
  #
  # @params [Hash], [Boolean] a `Hash` of attributes and a `Boolean` that should be false only if the object already exists
  # @return [ParseResource::Base] an object that subclasses `Parseresource::Base`
  def initialize(attributes = {}, new=true)
  attributes = HashWithIndifferentAccess.new(attributes)
  if new
    @unsaved_attributes = attributes
  else
    @unsaved_attributes = {}
  end
  self.attributes = {}
  self.attributes.merge!(attributes)
  self.attributes unless self.attributes.empty?
  create_setters!
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

  # Creates getter and setter methods for model fields
  # 
  def create_setters!
  @attributes.each_pair do |k,v|
    self.class.send(:define_method, "#{k}=") do |val|
      if k.is_a?(Symbol)
        k = k.to_s
      end
      @attributes[k.to_s] = val
      @unsaved_attributes[k.to_s] = val
      val
    end
    self.class.send(:define_method, "#{k}") do
      if k.is_a?(Symbol)
        k = k.to_s
      end

      @attributes[k.to_s]
    end
  end
  end

  class << self
  def has_one(child_name)
    class_eval do

      define_method("#{child_name}") do
        child_name
      end

      define_method("#{child_name}=") do |child_object|
        [child_object, child_name]
      end

    end
  end

  def belongs_to(name)
    class_eval do

      define_method("#{parent_name}") do
        name
      end

      define_method("#{parent_name}=") do |parent_object|
        [parent_name, parent_object]
      end

    end
  end


  @@settings ||= nil

  # Explicitly set Parse.com API keys.
  #
  # @param [String] app_id the Application ID of your Parse database
  # @param [String] master_key the Master Key of your Parse database
  def load!(app_id, master_key)
    @@settings = {"app_id" => app_id, "master_key" => master_key}
  end

  # Creates a RESTful resource
  # sends requests to [base_uri]/[classname]
  #
  def resource
    if @@settings.nil?
      path = "config/parse_resource.yml"
      environment = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : ENV["RACK_ENV"]
      @@settings = YAML.load(ERB.new(File.new(path).read).result)[environment]
    end
    base_uri   = "https://api.parse.com/1/classes/#{model_name}"
    app_id     = @@settings['app_id']
    master_key = @@settings['master_key']
    RestClient::Resource.new(base_uri, app_id, master_key)
  end

  # Find a ParseResource::Baseobject by ID
  #
  # @param [String] id the ID of the Parse object you want to find.
  # @return [ParseResource] an object that subclasses ParseResource.
  def find(id)
    where(:objectId => id).first
  end

  # Find a ParseResource::Baseobject by a `Hash` of conditions.
  #
  # @param [Hash] parameters a `Hash` of conditions.
  # @return [Array] an `Array` of objects that subclass `ParseResource`.
  def where(parameters)
    resp = resource.get(:params => {:where => parameters.to_json})
    results = JSON.parse(resp)['results']
    results.map {|r| model_name.constantize.new(r, false)}
  end

  # Find all ParseResource::Baseobjects for that model.
  #
  # @return [Array] an `Array` of objects that subclass `ParseResource`.
  def all
    resp = resource.get
    results = JSON.parse(resp)['results']
    results.map {|r| model_name.constantize.new(r, false)}
  end

  # Create a ParseResource::Baseobject.
  #
  # @param [Hash] attributes a `Hash` of attributes
  # @return [ParseResource] an object that subclasses `ParseResource`. Or returns `false` if object fails to save.
  def create(attributes = {})
    attributes = HashWithIndifferentAccess.new(attributes)
    new(attributes).save
  end

  # Find the first object. Fairly random, not based on any specific condition.
  #
  def first
    all.first
  end

  def class_attributes
    @class_attributes ||= {}
  end

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
  resp = self.resource.post(@unsaved_attributes.to_json, :content_type => "application/json")
  @attributes.merge!(JSON.parse(resp))
  @attributes.merge!(@unsaved_attributes)
  attributes = HashWithIndifferentAccess.new(attributes)
  @unsaved_attributes = {}
  create_setters!
  self
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

  resp = self.instance_resource.put(put_attrs, :content_type => "application/json")

  @attributes.merge!(JSON.parse(resp))
  @attributes.merge!(@unsaved_attributes)
  @unsaved_attributes = {}
  create_setters!

  self
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

  end
end
