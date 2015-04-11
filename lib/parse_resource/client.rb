module ParseResource
  class Client
    BASE_URI = 'https://api.parse.com/1'

    class << self
      attr_accessor :app_id, :master_key

      def connect(api_endpoint)
        if app_id.blank? || master_key.blank?
          raise "No API credentials. Create an initializer first."
        end
        RestClient::Resource.new(BASE_URI + api_endpoint, app_id, master_key)
      end
    end

  end
end
