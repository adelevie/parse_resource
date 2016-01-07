module ParseResource
  class RelationArray < Array
    attr_accessor :class_name

    # Initializes an array with `items`
    # RelationArray can only contain objects of `class_name`
    def initialize(items, class_name)
      super(items)
      self.class_name = class_name
    end

    # Pushes an object to the array
    # If a hash of attributes is passed it first creates a record
    def << (object)
      if object.is_a? Hash
        create(object)
        return self
      end

      raise Exception.new("This relation only stores objects of type #{klass}") unless object.is_a? klass

      super
    end

    def push(object)
      self << object
    end

    # Creates a new record from passed attributes and add it to the collection
    # It will create a post request to Parse and try to store the record
    def create(attributes_hash)
      object = klass.create(attributes_hash)
      self.push object
    end

    def delete(object)
      if object.is_a? Hash
        object_id = object["objectId"]
      elsif object.is_a? String
        object_id = object
      else
        object_id = object.id
      end

      self.each { |item| super(item) if item.id == object_id }
    end

    def contains?(object)
      any? {|item| item.attributes == object.attributes }
    end

    def find(id)
      detect { |item| item.id == id }
    end

    private

    def klass
      class_name.to_s.constantize
    end
  end
end