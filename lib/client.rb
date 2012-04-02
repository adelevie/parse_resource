require 'parse-ruby-client'

module ParseResource
  
  class Client
	def initialize
		@@client = Parse.init
    end
  end


end