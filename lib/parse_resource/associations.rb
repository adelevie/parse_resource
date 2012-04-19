module ParseResource
  module Associations
    def belongs_to(parent)
      field(parent)
    end
    
    def has_many(children)
      parent_klass_name = model_name
      lowercase_parent_klass_name = parent_klass_name.downcase
      parent_klass = model_name.constantize
      child_klass_name = children.to_s.singularize.camelize
      child_klass = child_klass_name.constantize
      
      if parent_klass_name == "User"
        parent_klass_name = "_User"
      end
      
      @@parent_klass_name = parent_klass_name
      
      send(:define_method, children) do
        @@parent_id = self.id
        @@parent_instance = self

        parent_klass_name = @@parent_klass_name.downcase unless @@parent_klass_name == "User"
        parent_klass_name = "_User" if @@parent_klass_name == "User"
        
        query = child_klass.where(parent_klass_name.to_sym => @@parent_instance.to_pointer)
        singleton = query.all
        
        class << singleton
          def <<(child)
            parent_klass_name = @@parent_klass_name.downcase unless @@parent_klass_name == "User"
            parent_klass_name = @@parent_klass_name if @@parent_klass_name == "User"
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
  end
end