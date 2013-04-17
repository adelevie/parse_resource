require 'helper'
require 'parse_resource'

ParseResource::Base.load!(ENV["PARSE_RESOURCE_APPLICATION_ID"], ENV["PARSE_RESOURCE_MASTER_KEY"])


class Event < ParseResource::Base
  field :name
end

class TestQueryOptions < Test::Unit::TestCase
  
  #def setup
  #  Event.destroy_all
  #end
  
  #def teardown
  #  Event.destroy_all
  #end
  
end