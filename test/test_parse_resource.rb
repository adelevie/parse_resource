require 'helper'
require 'parse_resource'

ParseResource::Base.load!(ENV["PARSE_RESOURCE_APPLICATION_ID"], ENV["PARSE_RESOURCE_MASTER_KEY"])

class Post < ParseResource::Base
  fields :title, :body, :author
  validates_presence_of :title
end

class Author < ParseResource::Base
  field :name
end

class Spoon < ParseResource::Base
  fields :width, :length
end

class Fork < ParseResource::Base
  fields :points
end

class Knife < ParseResource::Base
  fields :is_shiny
end

class Straw < ParseResource::Base
  fields :title, :body
end

class TestParseResource < Test::Unit::TestCase

  #def setup
  #  Post.destroy_all
  #  Author.destroy_all
  #  Spoon.destroy_all
  #  Fork.destroy_all
  #  Straw.destroy_all
  #end

  #def teardown
  #  Post.destroy_all
  #  Author.destroy_all
  #  Spoon.destroy_all
  #  Fork.destroy_all
  #  Straw.destroy_all
  #end

  def test_initialize_without_args
    assert Post.new.is_a?(Post)
  end

  def test_count
    VCR.use_cassette('test_count', :record => :new_episodes) do
      Author.destroy_all
      p1 = Author.create(:name => "bar")
      p2 = Author.create(:name => "jab")
      assert_equal Author.count, 2
      assert_equal Author.where(:name => "jab").count, 1
      p1.destroy
      p2.destroy
      assert_equal Author.count, 0
    end
  end

  def test_initialize_with_args
    @spoon = Spoon.new(:length => "title1", :width => "ipso")
    assert @spoon.is_a?(Spoon)
    assert_equal @spoon.length, "title1"
    assert_equal @spoon.width, "ipso"
  end

  def test_create
    VCR.use_cassette('test_create', :record => :new_episodes) do
      s = Spoon.create(:length => "1234567890created!")
      assert s.is_a?(Spoon)
      assert s.id
      assert s.created_at
    end
  end

  def test_find
    VCR.use_cassette('test_find', :record => :new_episodes) do
      p1 = Spoon.create(:length => "Welcome")
      p2 = Spoon.find(p1.id)
      assert_equal p2.id, p2.id
    end
  end

	def test_find_should_throw_an_exception_if_object_is_nil
    VCR.use_cassette('test_find_should_throw_an_exception_if_object_is_nil', :record => :new_episodes) do
  		assert_raise RecordNotFound do
  			Post.find("")
  		end
    end
	end

  def test_first
    VCR.use_cassette('test_first', :record => :new_episodes) do
      f = Fork.create(:points => "firsttt")
      p = Fork.first
      assert p.is_a?(Fork)
      assert f.id, p.id
      assert f.points, p.points
    end
  end

  def test_find_by
    VCR.use_cassette('test_find_by', :record => :new_episodes) do
      p1    = Post.create(:title => "Welcome111")
      where = Post.where(:title => "Welcome111").first
      find  = Post.find_by_title("Welcome111")
      assert_equal where.id, find.id
    end
  end

  def test_find_all_by
    VCR.use_cassette('test_find_all_by', :record => :new_episodes) do
      p1    = Post.create(:title => "Welcome111")
      where = Post.where(:title => "Welcome111").all
      find  = Post.find_all_by_title("Welcome111")
      assert_equal where.first.id, find.first.id 
      assert_equal find.class, Array
    end
  end

  def test_where
    VCR.use_cassette('test_where', :record => :new_episodes) do
      p1 = Post.create(:title => "Welcome111")
      p2 = Post.where(:title => "Welcome111").first
      assert_equal p2.title, p1.title
    end
  end

  def test_destroy_all
    VCR.use_cassette('test_destroy_all', :record => :new_episodes) do
      p = Knife.create(:is_shiny => "arbitrary")
      Knife.destroy_all
      assert_equal Knife.count, 0
    end
  end

  def test_chained_wheres
    VCR.use_cassette('test_chained_wheres', :record => :new_episodes) do
      p1 = Straw.create(:title => "chained_wheres", :body => "testing")
      p2 = Straw.create(:title => "chained_wheres", :body => "testing_2")
      query = Straw.where(:title => "chained_wheres").where(:body => "testing")
      p3 = query.first
      
      assert_equal p3.id, p1.id
    end
  end

  def test_limit
    VCR.use_cassette('test_limit', :record => :new_episodes) do
      15.times do |i|
        Post.create(:title => "foo_"+i.to_s)
      end
      posts = Post.limit(5).all
      assert_equal posts.length, 5
    end
  end

  #def test_skip
  #  15.times do |i|
  #    Post.create(:title => "skip", :author => i)
  #  end
  #  post = Post.where(:title => "skip").skip(14).first
  #  assert_equal post.author, 15
  #end

  def test_all
    VCR.use_cassette('test_all', :record => :new_episodes) do
      Post.create(:title => "11222")
      Post.create(:title => "112ssd22")
      posts = Post.all
      assert posts.is_a?(Array)
      assert posts[0].is_a?(Post)
    end
  end

  def test_attribute_getters
    VCR.use_cassette('test_attribute_getters', :record => :new_episodes) do
      @post = Post.create(:title => "title1")
      assert_equal @post.attributes['title'], "title1"
      assert_equal @post.attributes['title'], @post.title
    end
  end

  def test_attribute_setters
    VCR.use_cassette('test_attribute_setters', :record => :new_episodes) do
      @post = Post.create(:title => "1")
      @post.body = "newerbody"
      assert_equal @post.body, "newerbody"
    end
  end

  def test_save
    VCR.use_cassette('test_save', :record => :new_episodes) do
      @post = Post.create(:title => "testing save")
      @post.save
      assert @post.attributes['objectId']
      assert @post.attributes['updatedAt']
      assert @post.attributes['createdAt']
    end
  end

  def test_each
    VCR.use_cassette('test_each', :record => :new_episodes) do
      #Post.destroy_all
      4.times do |i|
        #Post.create(:title => "each", :author => i.to_s)
        Post.create(:title => "each")
      end
      posts = Post.where(:title => "each")
      posts.each do |p|
        assert_equal p.title, "each"
      end
    end
  end

  def test_map
    VCR.use_cassette('test_map', :record => :new_episodes) do
      #Post.destroy_all
      4.times do |i|
        Post.create(:title => "map")
      end
      posts = Post.where(:title => "map")
      assert_equal posts.map {|p| p}.class, Array
    end
  end

  def test_id
    VCR.use_cassette('test_id', :record => :new_episodes) do
      @post = Post.create(:title => "testing id")
      assert @post.respond_to?(:id)
      assert @post.id
      assert @post.attributes['objectId'] = @post.id
    end
  end

  def test_created_at
    VCR.use_cassette('test_created_at', :record => :new_episodes) do
      @post = Post.create(:title => "testing created_at")
      assert @post.respond_to?(:created_at)
      assert @post.created_at
      assert @post.attributes['createdAt']
    end
  end

  def test_updated_at
    VCR.use_cassette('test_updated_at', :record => :new_episodes) do
      @post = Post.create(:title => "testing updated_at")
      @post.title = "something else"
      @post.save
      assert @post.updated_at
    end
  end

  def test_update
    VCR.use_cassette('test_update', :record => :new_episodes) do
      @post = Post.create(:title => "stale title")
      updated_once = @post.updated_at
      @post.update(:title => "updated title")
      assert_equal @post.title, "updated title"
      @post.title = "updated from setter"
      assert_equal @post.title, "updated from setter"
      assert_not_equal @post.updated_at, updated_once
    end
  end

  def test_destroy
    VCR.use_cassette('test_destroy', :record => :new_episodes) do
      p = Post.create(:title => "hello1234567890abc!")
      id = p.id
      p.destroy
      assert_equal p.title, nil
      assert_equal 0, Post.where(:title => "hello1234567890abc!", :objectId => id).length
    end
  end

  def test_validation
    p = Post.new
    assert !p.valid?
    p.title = "foo"
    assert p.valid?
  end

end
