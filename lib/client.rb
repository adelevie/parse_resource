require 'parse-ruby-client'

module ParseResource
  
  class Client
		def initialize(data)
			@@client = Parse.init(data)
    end
  end

  def self.init(data = {:application_id => ENV["PARSE_APPLICATION_ID"], :api_key => ENV["PARSE_REST_API_KEY"]})
    @@client = Client.new(data)
  end
  

  def self.client
  	Parse.client
  end


end