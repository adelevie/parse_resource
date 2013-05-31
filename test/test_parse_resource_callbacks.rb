require 'helper'
require 'parse_resource'

ParseResource::Base.load!(ENV["PARSE_RESOURCE_APPLICATION_ID"], ENV["PARSE_RESOURCE_MASTER_KEY"])


class CallerOne < ParseResource::Base
  field number: Integer
  def save_callback
    throw :save
  end
  def update_callback
    throw :update
  end
end

class CallerTwo < ParseResource::Base
  field number: Integer
  def save_callback
    throw :save
  end
  def update_callback
    throw :update
  end
end 

class CallerThree < ParseResource::Base
  field number: Integer
  def save_callback
    throw :save
  end
  def update_callback
    throw :update
  end
end  

class TestParseResourceCallbacks < Test::Unit::TestCase
  def test_that_update_calls_the_before_update_callback
    VCR.use_cassette('test_that_update_calls_the_before_update_callback', :record => :new_episodes) do
      CallerOne.destroy_all
      caller = CallerOne.create
      CallerOne.before_update :update_callback
      assert_throws(:update) { caller.update_attributes(number: 1) }
    end
  end

  def test_that_save_calls_the_before_save_callback
    VCR.use_cassette('test_that_save_calls_the_before_save_callback', :record => :new_episodes) do
      CallerTwo.destroy_all
      caller = CallerTwo.new
      CallerTwo.before_save :save_callback
      assert_throws(:save) { caller.save }
    end
  end

  def test_that_update_calls_the_before_save_callback
    VCR.use_cassette('test_that_update_calls_the_before_save_callback', :record => :new_episodes) do
      CallerThree.destroy_all
      caller = CallerThree.create
      CallerThree.before_save :save_callback
      assert_throws(:save) { caller.update_attributes(number: 1) }
    end
  end
end
