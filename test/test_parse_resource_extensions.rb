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

class TypeCheck < ParseResource::Base
  field :number => Integer
end

module Jack
  class Black < ParseResource::Base
    parse_model_name "BlackJack"
    field :name 
  end
  class Parent < ParseResource::Base
    parse_model_name "RedJack"
    field :name 
    field :child, Jack::Black
  end
end

class TestParseResourceExtensions < Test::Unit::TestCase

  def test_model_mapping
    assert_equal Nesty::Nest.new.parse_class, "Nest"
  end

  def test_model_registration
    assert_equal ParseResource::Base.parse_models["Nest"], "Nesty::Nest"
    assert_equal ParseResource::Base.inverse_parse_models["Nesty::Nest"], "Nest"
  end

  def test_parse_class_name_lookup
    assert_equal Nesty::Nest.parse_class_name_for_model(Nesty::Nest), "Nest"
    assert_equal Jack::Black.parse_class_name_for_model(Jack::Black), "BlackJack"
  end

  def test_parse_class_name_lookup_with_string
    assert_equal Jack::Black.parse_class_name_for_model("Nesty::Nest"), "Nest"
    assert_equal Jack::Black.parse_class_name_for_model("Jack::Black"), "BlackJack"
  end

  def test_model_lookup
    assert_equal Nesty::Nest.model_name_for_parse_class("Nest"), "Nesty::Nest"
    assert_equal Jack::Black.model_name_for_parse_class("BlackJack"), "Jack::Black"
  end

  def test_setting_attribute_value_integer_as_integer
    nest = Nesty::Nest.new(number: 1337)
    assert_equal nest.number, 1337
  end

  def test_setting_attribute_value_integer_as_string
    nest = Nesty::Nest.new(number: "1337")
    assert_equal nest.number, 1337
  end

  def test_setting_attribute_value_string_as_integer
    nest = Nesty::Nest.new(words: 1337)
    assert_equal nest.words, "1337"
  end

  def test_setting_attribute_without_coersion
    nest = Nesty::Nest.new(whatever: 1337)
    assert_equal nest.whatever, 1337
    nest.whatever = "meh"
    assert_equal nest.whatever, "meh"
  end

  def test_nested_classes_using_mapped_names
    VCR.use_cassette('test_nested_classes_using_mapped_names', :record => :new_episodes) do
      Jack::Black.destroy_all
      Jack::Parent.destroy_all
      black = Jack::Black.create(name: "Child")
      parent = Jack::Parent.create(name: "parent")
      parent.child = black
      parent.save
      assert_not_equal parent.child, black
      assert_equal parent.child.id, black.id
    end
  end

  def test_nested_classes_update_using_mapped_names
    VCR.use_cassette('test_nested_classes_update_using_mapped_names', :record => :new_episodes) do
      Jack::Black.destroy_all
      Jack::Parent.destroy_all
      black = Jack::Black.create(name: "Child")
      parent = Jack::Parent.create(name: "parent")
      parent.update(child: black)
      assert_not_equal parent.child, black
      assert_equal parent.child.id, black.id
    end
  end

  def test_error_messages_includes_info_when_bad_type
      VCR.use_cassette('test_error_messages_includes_info_when_bad_type', :record => :new_episodes) do
      TypeCheck.destroy_all
      integer_number = TypeCheck.create(number: 1337)

      integer_number.number = "1337"

      assert integer_number.update== false
      assert integer_number.errors.first.include? :number
      assert integer_number.errors.first.include? "invalid type for key number, expected number, but got string"
    end
  end


end
