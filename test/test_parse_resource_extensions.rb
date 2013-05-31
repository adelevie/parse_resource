require 'helper'
require 'parse_resource'

ParseResource::Base.load!(ENV["PARSE_RESOURCE_APPLICATION_ID"], ENV["PARSE_RESOURCE_MASTER_KEY"])

module Nesty
  class Nest < ParseResource::Base
    parse_model_name "Nest"
    field number: Integer
    field date: Date
    field :words 
    end 
  end

class TestParseResource < Test::Unit::TestCase

  def test_initialize_without_args
    assert Post.new.is_a?(Post)
  end

  def test_model_mapping
    assert_equal Nesty::Nest.new.parse_class, "Nest"
  end

  def test_model_registration
    assert ParseResource::Base.parse_models.include? "Nest" => "Nesty::Nest"
    assert ParseResource::Base.inverse_parse_models.include? "Nesty::Nest" => "Nest"
  end

  def test_attribute_type_definition

  end
end
