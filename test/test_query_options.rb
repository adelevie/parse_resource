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
  
  def test_order_descending
    e1 = Event.create(:name => "1st")
    e2 = Event.create(:name => "2nd")
    events = Event.order("name desc").all
    Event.destroy_all
    assert_equal true, (events[0].name == "2nd")
  end

  def test_order_ascending
    e1 = Event.create(:name => "1st")
    e2 = Event.create(:name => "2nd")
    events = Event.order("name asc").all
    Event.destroy_all
    assert_equal true, (events[0].name == "1st")
  end

  def test_order_no_field
    e1 = Event.create(:name => "1st")
    e2 = Event.create(:name => "2nd")
    events = Event.order("desc").all
    Event.destroy_all
    puts events[0].name
    puts events[1].name
    assert_equal true, (events[0].name == "1st")
  end

  def test_skip
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