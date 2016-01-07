module ParseResource
  # config/initializers/parsed_resource.rb (for instance)
  #
  # ```ruby
  # ParsedResource.configure do |config|
  #   config.app_id = 'consumer_token'
  #   config.master_key = 'consumer_secret'
  # end
  # ```
  # elsewhere
  #
  # ```ruby
  # client = ParsedResource::Client.connect '/users'
  # client.get
  # ```
  class << self
    def configure
      yield Client
      true
    end
  end

end

require 'parse_resource/client'
require 'parse_resource/base'
require 'parse_resource/query_methods'
require 'parse_resource/query'
require 'parse_resource/parse_role'
require 'parse_resource/parse_user'
require 'parse_resource/parse_user_validator'
require 'parse_resource/parse_error'

require 'kaminari_extension'
