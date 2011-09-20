require 'helper'
require 'parse_resource'

class Post < ParseResource
  fields :title, :body, :author
  validates_presence_of :title
end

class Tweet < ParseResource
end

class TestParseResource < Test::Unit::TestCase

  def test_initialize_without_args
    assert Post.new.is_a?(Post)
    assert Tweet.new.is_a?(Tweet)
  end

  def test_initialize_with_args
    p = Post.new(:title => "title1", :body => "ipso")
    t = Tweet.new(:user => "aplusk")
    assert_equal p.title, "title1"
    assert_equal p.body, "ipso"
    assert_equal t.user, "aplusk"
  end

  def test_validation
    p = Post.new
    assert !p.valid?
    p.title = "foo"
    assert p.valid?
  end
end
