require 'helper'
require 'parse_resource'

path = "parse_resource.yml"
settings = YAML.load(ERB.new(File.new(path).read).result)['test']

ParseResource::Base.load!(settings['app_id'], settings['master_key'])

class Event < ParseResource::Base
  field :name
end

class TestQueryOptions < Test::Unit::TestCase
  
  def setup
    Event.destroy_all
  end
  
  def teardown
    Event.destroy_all
  end
  
  def test_order
    e1 = Event.create(:name => "1st")
    sleep 1
    e2 = Event.create(:name => "2nd")
    events = Event.order("created_at").all
    puts events[0].created_at
    puts events[1].created_at
    assert_equal true, (events[0].created_at < events[1].created_at)
    Event.destroy_all
  end

  def test_skip
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
    Event.destroy_all
  end
  
end