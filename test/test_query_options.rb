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

  def test_skip
    Event.destroy_all
    VCR.use_cassette('test_skip', :record => :new_episodes) do
      num_to_test = 10
      num_to_test.times do |i|
        Event.create(:name => "#{i}")
      end
      all_events = []
      count = 0
      begin
        results = Event.skip(count).limit(2).all
        all_events += results
        count += results.count
      end while not results.empty?
      assert_equal true, (all_events.count == num_to_test)

      found_names = []
      all_events.each do |event|
        assert_equal false, (found_names.include?(event.name))
        found_names.push(event.name)
      end
    end
    #Event.destroy_all
  end
  
end