module ParseResource
	module Client
    # Creates a RESTful resource
    # sends requests to [base_uri]/[classname]
    #
    def resource
      if model_name == "User" #https://parse.com/docs/rest#users-signup
        base_uri = "https://api.parse.com/1/users"
      else
        base_uri = "https://api.parse.com/1/classes/#{model_name}"
      end

      #refactor to settings['app_id'] etc
      app_id     = settings['app_id']
      master_key = settings['master_key']
      RestClient::Resource.new(base_uri, app_id, master_key)
    end

        # Create a ParseResource::Base object.
    #
    # @param [Hash] attributes a `Hash` of attributes
    # @return [ParseResource] an object that subclasses `ParseResource`. Or returns `false` if object fails to save.
    def create(attributes = {})
      attributes = HashWithIndifferentAccess.new(attributes)
      new(attributes).save
    end

    def destroy_all
      all.each do |object|
        object.destroy
      end
    end


	end
end