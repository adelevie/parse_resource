module KaminariExtension
  module ParseBaseExt
    extend ActiveSupport::Concern
    include Kaminari::ConfigurationMethods

    module ClassMethods
      def page(num)
        Query.new(self).limit(default_per_page).skip(default_per_page * ([num.to_i, 1].max - 1))
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
  end
end

if defined?(Kaminari)
  ParseResource::Base.send :include, KaminariExtension::ParseBaseExt
  Query.send               :include, KaminariExtension::QueryExt
end