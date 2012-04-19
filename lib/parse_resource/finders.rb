module ParseResource
	module Finders
# Find a ParseResource::Base object by ID
    #
    # @param [String] id the ID of the Parse object you want to find.
    # @return [ParseResource] an object that subclasses ParseResource.
    def find(id)
			raise RecordNotFound if id.blank?
      where(:objectId => id).first
    end

    # Find a ParseResource::Base object by chaining #where method calls.
    #
    def where(*args)
      Query.new(self).where(*args)
    end
    
    # Include the attributes of a parent ojbect in the results
    # Similar to ActiveRecord eager loading
    #
    def include_object(parent)
      Query.new(self).include_object(parent)
    end

    # Add this at the end of a method chain to get the count of objects, instead of an Array of objects
    def count
      #https://www.parse.com/docs/rest#queries-counting
      Query.new(self).count(1)
    end

    # Find all ParseResource::Base objects for that model.
    #
    # @return [Array] an `Array` of objects that subclass `ParseResource`.
    def all
      Query.new(self).all
    end

    # Find the first object. Fairly random, not based on any specific condition.
    #
    def first
      Query.new(self).limit(1).first
    end

    # Limits the number of objects returned
    #
    def limit(n)
      Query.new(self).limit(n)
    end
    
    def order(attribute)
      Query.new(self).order(attribute)
    end

	end
end