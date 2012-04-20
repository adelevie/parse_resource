module ParseResource
	module DynamicMethods
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

    # Creates setter methods for model fields
    def create_setters!(k,v)
      self.class.send(:define_method, "#{k}=") do |val|
        val = val.to_pointer if val.respond_to?(:to_pointer)

        @attributes[k.to_s] = val
        @unsaved_attributes[k.to_s] = val
        
        val
      end
    end

    def create_setters_and_getters!
      @attributes.each_pair do |k,v|
        create_setters!(k,v)
        create_getters!(k,v)
      end
    end
	end
end