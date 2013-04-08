if defined?(Kaminari)
  module KaminariExtension
    module ParseBaseExt
      extend ActiveSupport::Concern
      include Kaminari::ConfigurationMethods

      module ClassMethods
        def page(num)
          Query.new(self).page(num)
        end
      end
    end

    module QueryExt
      extend ActiveSupport::Concern
      include Kaminari::PageScopeMethods

      included do
        alias :offset :skip
      end

      def limit_value
        criteria[:limit]
      end

      def offset_value
        criteria[:skip]
      end

      def total_count
        count
      end

      def max_per_page
        @klass.max_per_page
      end

      def page(num)
        limit(@klass.default_per_page).skip(@klass.default_per_page * ([num.to_i, 1].max - 1))
        self
      end

      def per(num)
        if (n = num.to_i) <= 0
          self
        elsif max_per_page && max_per_page < n
          new_offset_value = offset_value / limit_value * max_per_page
          limit(max_per_page).offset(new_offset_value)
        else
          new_offset_value = offset_value / limit_value * n
          limit(n).offset(new_offset_value)
        end
        self
      end
    end
  end

  ParseResource::Base.send :include, KaminariExtension::ParseBaseExt
  Query.send               :include, KaminariExtension::QueryExt
end
