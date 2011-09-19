class ParseResource
  # ParseResource provides an easy way to use Ruby to interace with a Parse.com backend
  # Usage:
  #  class Post < ParseResource
  #    fields :title, :author, :body
  #  end

  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::AttributeMethods
  extend ActiveModel::Naming

  # instantiation!
  # p = Post.new(:title => "cool story")
  def initialize(attributes = {})
    if new?
      @unsaved_attributes = attributes.symbolize_keys!
    else
      @unsaved_attributes = HashWithIndifferentAccess.new
    end
    self.attributes = {}
    self.attributes.merge!(attributes)
    self.attributes.symbolize_keys! unless self.attributes.empty?
    #@field_message = "set in #initialize"
    create_setters!
  end

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

  def self.fields(*args)
    args.each {|f| field(f)}
  end

  def self.add_field(fieldname, val=nil)
    class_attributes.merge!({fieldname.to_sym => nil})
  end

  # a sprinkle of metaprogramming
  # p = Post.new(:some_attr => "some value")
  # p.some_attr = "new value"
  def create_setters!
    @attributes.each_pair do |k,v|
      self.class.send(:define_method, "#{k}=") do |val|
        @attributes[k.to_sym] = val
        @unsaved_attributes[k.to_sym] = val
        val
      end
    end
  end

  class << self
    def load!(path="config/parse_resource.yml")
      environment = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : ENV["RACK_ENV"]
      @settings = YAML.load(ERB.new(File.new(path).read).result)[environment]
    end

    # creates a RESTful resource
    # sends requests to [base_uri]/[classname]
    def resource
      if @settings.nil?
        path = "config/parse_resource.yml"
        environment = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : ENV["RACK_ENV"]
        @settings = YAML.load(ERB.new(File.new(path).read).result)[environment]
      end
      base_uri   = "https://api.parse.com/1/classes/#{model_name}"
      app_id     = @settings['app_id']
      master_key = @settings['master_key']
      RestClient::Resource.new(base_uri, app_id, master_key)
    end

    # finders
    # Post.find("abcdf")
    def find(id)
      where(:objectId => id).first
    end

    # Post.where(:author => "Alan", :title => "Ipso Lorem")
    def where(parameters)
      resp = resource.get(:params => {:where => parameters.to_json})
      results = JSON.parse(resp)['results']
      results.map {|r| model_name.constantize.new(r.symbolize_keys!)}
    end

    # Post.all
    def all
      resp = resource.get
      results = JSON.parse(resp)['results']
      results.map {|r| model_name.constantize.new(r.symbolize_keys!)}
    end

    # Post.create(:title => "new post")
    def create(attributes = {})
      new(attributes).save
    end

    # Post.first
    def first
      all.first
    end

    def class_attributes
      @class_attributes ||= {}
    end

  end

  def persisted?
    !self.id.nil?
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
    @attributes.merge!(JSON.parse(resp).symbolize_keys!)
    @attributes.merge!(@unsaved_attributes)
    @unsaved_attributes = HashWithIndifferentAccess.new
    create_setters!
    self
  end

  def save
    if valid?
      new? ? create : update
    else
      false
    end
    rescue false
  end

  def update(attributes = HashWithIndifferentAccess.new)
    @unsaved_attributes.merge!(attributes)

    put_attrs = @unsaved_attributes
    put_attrs.delete('objectId')
    put_attrs.delete('createdAt')
    put_attrs.delete('updatedAt')
    put_attrs = put_attrs.to_json

    resp = self.instance_resource.put(put_attrs, :content_type => "application/json")

    @attributes.merge!(JSON.parse(resp).symbolize_keys!)
    @attributes.merge!(@unsaved_attributes)
    @unsaved_attributes = HashWithIndifferentAccess.new
    create_setters!

    self
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
    @attributes.symbolize_keys!
  end

  def attributes=(n)
    @attributes = n
    @attributes.symbolize_keys!
  end

  # aliasing for idiomatic Ruby
  def id; self.objectId rescue nil; end

  def created_at; self.createdAt; end

  def updated_at; self.updatedAt rescue nil; end

  # another sprinkle of metaprogramming
  # p = Post.new(:some_attr => "some value")
  # p.some_attr #=> "some value"
  def method_missing(meth, *args, &block)
    if self.attributes.has_key?(meth.to_sym)
      self.attributes[meth.to_sym]
    else
      super
    end
  end
end
