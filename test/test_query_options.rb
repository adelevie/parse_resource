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

	def test_skip
		10.times do |i|
			Event.create(:name => i.to_s)
		end
		Event.skip(5).order("created_at").all.map(&:name) == ["5","6","7","8","9","10"]
	end
  
  def test_order
    e1 = Event.create(:name => "1st")
    e2 = Event.create(:name => "2nd")
    events = Event.order("created_at").all
    puts events[0].name
    puts events[1].name
    assert_equal true, (events[0].created_at < events[1].created_at)
    Event.destroy_all
  end
  
end
