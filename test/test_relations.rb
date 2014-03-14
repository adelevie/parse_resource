require 'helper'
require 'parse_resource'

ParseResource::Base.load!(ENV["PARSE_RESOURCE_APPLICATION_ID"], ENV["PARSE_RESOURCE_MASTER_KEY"])

class Tip < ParseResource::Base
  field :title
  has_many :categories
end

class Category < ParseResource::Base
  field :name
  belongs_to :tip
end


class TestParseResource < Test::Unit::TestCase

  def setup
    Tip.destroy_all
    Category.destroy_all
  end

  def teardown
    Tip.destroy_all
    Category.destroy_all
  end

  def test_create_nested_relation
    tip = Tip.create(:title => "Oakley sunglasses")
    assert_equal tip.categories.count, 0
    tip.categories.create(:name => "Eyewear")
    tip.save
    assert_equal tip.categories.count, 1
    tip.reload
    assert_equal tip.categories.count, 1
  end

  def test_create_two_nested_relations
    tip = Tip.create(:title => "Oakley sunglasses")
    assert_equal tip.categories.count, 0
    tip.categories.create(:name => "Eyewear")
    tip.save
    assert_equal tip.categories.count, 1
    tip.categories.create(:name => "Sunglasses")
    tip.save
    assert_equal tip.categories.count, 2
    tip.reload
    assert_equal tip.categories.count, 2
  end

  def test_create_nested_relation_then_save_then_remove
    tip = Tip.create(:title => "Oakley sunglasses")
    assert_equal tip.categories.count, 0
    category = Category.create(:name => "Eyewear")
    tip.categories << category
    assert_equal tip.categories.count, 1
    tip.save
    assert_equal tip.categories.count, 1
    tip.categories.delete(category)
    assert_equal tip.categories.count, 0
    tip.save
    assert_equal tip.categories.count, 0
    tip.reload
    assert_equal tip.categories.count, 0
  end

  def test_has_one_relations
    cat = Category.create(:name => "Sports Apparel")
    assert_equal cat.name, "Sports Apparel"

    tip = Tip.create(:title => "Nike Zoom II cleats")
    assert_equal tip.title, "Nike Zoom II cleats"
    assert_equal tip.categories.count, 0

    tip.categories << cat
    assert_equal tip.categories.count, 1
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat.attributes), true
    #assert_equal tip.categories[0].attributes, cat.attributes

    tip.save
    assert_equal tip.categories.count, 1
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat.attributes), true
    #assert_equal tip.categories[0].attributes, cat.attributes

    tip = Tip.find(tip.id)
    assert_equal tip.title, "Nike Zoom II cleats"
    assert_equal tip.categories.count, 1
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat.attributes), true

    tip.reload
    assert_equal tip.categories.count, 1
  end

  def test_has_two_relations
    cat1 = Category.create(:name => "Footwear")
    assert_equal cat1.name, "Footwear"

    cat2 = Category.create(:name => "Sports Apparel")
    assert_equal cat2.name, "Sports Apparel"

    tip = Tip.create(:title => "Puma running shoes")
    assert_equal tip.title, "Puma running shoes"
    assert_equal tip.categories.count, 0

    tip.categories << cat1
    assert_equal tip.categories.count, 1
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat1.attributes), true

    tip.categories << cat2
    assert_equal tip.categories.count, 2
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat2.attributes), true

    tip.save
    assert_equal tip.categories.count, 2
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat1.attributes), true
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat2.attributes), true

    tip = Tip.find(tip.id)
    assert_equal tip.title, "Puma running shoes"
    assert_equal tip.categories.count, 2
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat1.attributes), true
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat2.attributes), true

    tip.reload
    assert_equal tip.categories.count, 2
  end

  def test_has_three_relations
    cat1 = Category.create(:name => "Sports Apparel")
    assert_equal cat1.name, "Sports Apparel"

    cat2 = Category.create(:name => "Footwear")
    assert_equal cat2.name, "Footwear"

    cat3 = Category.create(:name => "Running shoes")
    assert_equal cat3.name, "Running shoes"

    tip = Tip.create(:title => "Puma running shoes")
    assert_equal tip.title, "Puma running shoes"
    assert_equal tip.categories.count, 0

    tip.categories << cat1
    assert_equal tip.categories.count, 1
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat1.attributes), true

    tip.categories << cat2
    assert_equal tip.categories.count, 2
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat2.attributes), true

    tip.categories << cat3
    assert_equal tip.categories.count, 3
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat3.attributes), true

    tip.save
    assert_equal tip.categories.count, 3
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat1.attributes), true
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat2.attributes), true
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat3.attributes), true

    tip = Tip.find(tip.id)
    assert_equal tip.title, "Puma running shoes"
    assert_equal tip.categories.count, 3
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat1.attributes), true
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat2.attributes), true
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat3.attributes), true

    tip.reload
    assert_equal tip.categories.count, 3
  end

  def test_save_then_remove_a_relation
    cat1 = Category.create(:name => "Sports Apparel")
    assert_equal cat1.name, "Sports Apparel"

    tip = Tip.create(:title => "Nike Zoom II cleats")
    assert_equal tip.title, "Nike Zoom II cleats"
    assert_equal tip.categories.count, 0

    tip.categories << cat1
    assert_equal tip.categories.count, 1
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat1.attributes), true

    tip.save
    assert_equal tip.categories.count, 1
    assert_equal item_with_value_exists_in_array?(tip.categories, "attributes", cat1.attributes), true

    tip.categories.pop
    assert_equal tip.categories.count, 0

    tip.save
    assert_equal tip.categories.count, 0

    tip = Tip.find(tip.id)
    assert_equal tip.title, "Nike Zoom II cleats"
    assert_equal tip.categories.count, 0

    tip.reload
    assert_equal tip.categories.count, 0
  end

  def test_add_remove_then_save_a_relation
    cat1 = Category.create(:name => "Sports Apparel")
    tip = Tip.create(:title => "Nike Zoom II cleats")
    assert_equal tip.categories.count, 0
    tip.categories << cat1
    assert_equal tip.categories.count, 1
    tip.categories.delete cat1
    assert_equal tip.categories.count, 0
    tip.save
    assert_equal tip.categories.count, 0
    tip = Tip.find(tip.id)
    assert_equal tip.categories.count, 0
    tip.reload
    assert_equal tip.categories.count, 0
  end

  def test_add_batch_of_relations
    cat1 = Category.create(:name => "Sports Apparel")
    cat2 = Category.create(:name => "Footwear")
    tip = Tip.create(:title => "Nike Zoom II cleats")
    assert_equal tip.categories.count, 0
    tip.categories << cat1
    tip.categories << cat2
    assert_equal tip.categories.count, 2
    tip.save
    assert_equal tip.categories.count, 2
    tip = Tip.find(tip.id)
    assert_equal tip.categories.count, 2
    tip.reload
    assert_equal tip.categories.count, 2
  end

  def test_add_relation_using_array_push_method
    cat1 = Category.create(:name => "Sports Apparel")
    tip = Tip.create(:title => "Nike Zoom II cleats")
    assert_equal tip.categories.count, 0
    tip.categories.push cat1
    assert_equal tip.categories.count, 1
    assert_equal tip.categories[0].attributes, cat1.attributes
    tip.save
    assert_equal tip.categories.count, 1
    tip = Tip.find(tip.id)
    assert_equal tip.categories.count, 1
    tip.reload
    assert_equal tip.categories.count, 1
  end

  #def test_should_not_be_able_to_add_object_of_wrong_type
  #  tip1 = Tip.create(:title => "Prada Handbag")
  #  tip2 = Tip.create(:title => "Nike Zoom II cleats")
  #  assert_equal tip1.categories.count, 0
  #  assert_raise Exception do
  #    tip1.categories.push tip2
  #  end
  #  assert_equal tip1.categories.count, 0
  #end


end