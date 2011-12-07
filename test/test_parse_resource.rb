require 'helper'
require 'parse_resource'

path = "parse_resource.yml"
settings = YAML.load(ERB.new(File.new(path).read).result)['test']

ParseResource.load!(settings['app_id'], settings['master_key'])

class Post < ParseResource::Base
  fields :title, :body, :author
  validates_presence_of :title
end

class TestParseResource < Test::Unit::TestCase

  def test_initialize_without_args
    assert Post.new.is_a?(Post)
  end

  def test_initialize_with_args
    @post = Post.new(:title => "title1", :body => "ipso")
    assert @post.is_a?(Post)
    assert_equal @post.title, "title1"
    assert_equal @post.body, "ipso"
  end

  def test_create
    p = Post.create(:title => "1234567890created!")
    assert p.is_a?(Post)
    @find_id = p.id
    assert p.id
    assert p.created_at
  end

  def test_find
    p1 = Post.create(:title => "Welcome")
    p2 = Post.find(p1.id)
    assert_equal p2.id, p2.id
  end

  def test_first
    p = Post.first
    assert p.is_a?(Post)
  end

  def test_where
    p1 = Post.create(:title => "Welcome111")
    p2 = Post.where(:title => "Welcome111").first
    assert_equal p2.id, p1.id
  end

  def test_all
    Post.create(:title => "11222")
    Post.create(:title => "112ssd22")
    posts = Post.all
    assert posts.is_a?(Array)
    assert posts[0].is_a?(Post)
  end

  def test_attribute_getters
    @post = Post.create(:title => "title1")
    assert_equal @post.attributes['title'], "title1"
    assert_equal @post.attributes['title'], @post.title
  end

  def test_attribute_setters
    @post = Post.create(:title => "1")
    @post.body = "newerbody"
    assert_equal @post.body, "newerbody"
  end

  def test_save
    @post = Post.create(:title => "testing save")
    assert @post.save
    assert @post.attributes['objectId']
    assert @post.attributes['updatedAt']
    assert @post.attributes['createdAt']
  end

  def test_id
    @post = Post.create(:title => "testing id")
    assert @post.respond_to?(:id)
    assert @post.id
    assert @post.attributes['objectId'] = @post.id
  end

  def test_created_at
    @post = Post.create(:title => "testing created_at")
    assert @post.respond_to?(:created_at)
    assert @post.created_at
    assert @post.attributes['createdAt']
  end

  def test_updated_at
    @post = Post.create(:title => "testing updated_at")
    @post.title = "something else"
    @post.save
    assert @post.updated_at
  end

  def test_update
    @post = Post.create(:title => "stale title")
    updated_once = @post.updated_at
    @post.update(:title => "updated title")
    assert_equal @post.title, "updated title"
    @post.title = "updated from setter"
    assert_equal @post.title, "updated from setter"
    assert_not_equal @post.updated_at, updated_once
  end

  def test_destroy
    p = Post.create(:title => "hello1234567890abc!")
    id = p.id
    p.destroy
    assert_equal 0, Post.where(:title => "hello1234567890abc!", :objectId => id).length
  end

  def test_validation
    p = Post.new
    assert !p.valid?
    p.title = "foo"
    assert p.valid?
  end
end
