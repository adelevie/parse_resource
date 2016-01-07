require 'parse_resource/parse_user_validator'

module ParseResource
  class User < ParseResource::Base
    fields :username, :password

    validates :username, presence: true # , parse_user: true
    validates :password, presence: { unless: :persisted? }

    def self.authenticate(username, password)
      resource = Client.connect '/login'

      begin
        resp = resource.get(:params => {:username => username, :password => password})
        user = model_name.to_s.constantize.new(JSON.parse(resp), false)

        user
      rescue => e
        puts "An error occurred while authenticating: #{e.message}"
        false
      end
    end

    def self.authenticate_with_facebook(user_id, access_token, expires)
      resource = Client.connect '/users'

      begin
        resp = resource.post(
                {
                  "authData" => {
                    "facebook" => {
                      "id" => user_id,
                      "access_token" => access_token,
                      "expiration_date" => Time.now + expires.to_i
                    }
                  }
                }.to_json,
                content_type: 'application/json', accept: :json)
        user = model_name.to_s.constantize.new(JSON.parse(resp), false)
        user
      rescue => e
        puts "An error occurred while authenticating with FB: #{e.message}"
        false
      end
    end

    def self.reset_password(email)
      resource = Client.connect('/requestPasswordReset')

      begin
        resp = resource.post({:email => email}.to_json, :content_type => 'application/json')
        true
      rescue => e
        puts "An error occurred while reseting password: #{e.message}"
        false
      end
    end

  end
end