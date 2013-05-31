require 'helper'
require 'parse_resource'

ParseResource::Base.load!(ENV["PARSE_RESOURCE_APPLICATION_ID"], ENV["PARSE_RESOURCE_MASTER_KEY"])

module Nesty
  class Nest < ParseResource::Base
    parse_model_name "Nest"
    field number: Integer
    field date: Date
    field words: String 
    field :whatever 
  end 
end

class TestParseResourceExtensions < Test::Unit::TestCase

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

  def test_setting_attribute_value_integer_as_integer
    nest = Nesty::Nest.new
    nest.number = 1337
    assert_equal nest.number, 1337
  end

  def test_setting_attribute_value_integer_as_string
    nest = Nesty::Nest.new
    nest.number = "1337"
    assert_equal nest.number, 1337
  end

  def test_setting_attribute_value_string_as_integer
    nest = Nesty::Nest.new
    nest.words = 1337
    assert_equal nest.words, "1337"
  end

  def test_setting_attribute_without_coersion
    nest = Nesty::Nest.new
    nest.whatever = 1337
    assert_equal nest.whatever, 1337
    nest.whatever = "meh"
    assert_equal nest.whatever, "meh"
  end


end
