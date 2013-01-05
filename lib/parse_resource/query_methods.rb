#require 'parse_resource'
require 'parse_resource/query'

module ParseResource

	module QueryMethods

		module ClassMethods
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

	    # Skip the number of objects
	    #
	    def skip(n)
	      Query.new(self).skip(n)
	    end
	    
	    def order(attr)
	      Query.new(self).order(attr)
      end

      def near(near, geo_point, options={})
        Query.new(self).near(near, geo_point, options)
      end

      def within_box(near, geo_point_south, geo_point_north)
        Query.new(self).within_box(near, geo_point_south, geo_point_north)
      end
		end

		def self.included(base)
			base.extend(ClassMethods)
		end
	end
end