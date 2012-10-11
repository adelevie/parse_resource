require 'helper'
require 'parse_resource'

path = "parse_resource.yml"
settings = YAML.load(ERB.new(File.new(path).read).result)['test']

ParseResource::Base.load!(settings['app_id'], settings['master_key'])

class Post < ParseResource::Base
  fields :title, :body, :author
  validates_presence_of :title
end

class Author < ParseResource::Base
  has_many :posts
  field :name
end

class TestParseResource < Test::Unit::TestCase

  def setup
    Post.destroy_all
    Author.destroy_all
  end

  def teardown
    Post.destroy_all
    Author.destroy_all
  end

  def test_initialize_without_args
    assert Post.new.is_a?(Post)
  end

  def test_count
    Author.destroy_all
    p1 = Author.create(:name => "bar")
    p2 = Author.create(:name => "jab")
    assert_equal Author.count, 2
    assert_equal Author.where(:name => "jab").count, 1
    p1.destroy
    p2.destroy
    assert_equal Author.count, 0
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

	def test_find_should_throw_an_exception_if_object_is_nil
		assert_raise RecordNotFound do
			Post.find("")
		end
	end

  def test_first
    Post.create(:title => "firsttt")
    p = Post.first
    assert p.is_a?(Post)
  end

  def test_find_by
    p1    = Post.create(:title => "Welcome111")
    where = Post.where(:title => "Welcome111").first
    find  = Post.find_by_title("Welcome111")
    assert_equal where.id, find.id
  end

  def test_find_all_by
    p1    = Post.create(:title => "Welcome111")
    where = Post.where(:title => "Welcome111").all
    find  = Post.find_all_by_title("Welcome111")
    assert_equal where.first.id, find.first.id 
    assert_equal find.class, Array
  end

  def test_where
    p1 = Post.create(:title => "Welcome111")
    p2 = Post.where(:title => "Welcome111").first
    assert_equal p2.id, p1.id
  end

  def test_destroy_all
    p = Post.create(:title => "arbitrary")
    Post.destroy_all
    assert_equal Post.count, 0
  end

  def test_chained_wheres
    Post.destroy_all
    p1 = Post.create(:title => "chained_wheres", :body => "testing")
    p2 = Post.create(:title => "chained_wheres", :body => "testing_2")
    query = Post.where(:title => "chained_wheres").where(:body => "testing")
    p3 = query.first
    
    assert_equal p3.id, p1.id
  end

  def test_limit
    15.times do |i|
      Post.create(:title => "foo_"+i.to_s)
    end
    posts = Post.limit(5).all
    assert_equal posts.length, 5
  end

  #def test_skip
  #  15.times do |i|
  #    Post.create(:title => "skip", :author => i)
  #  end
  #  post = Post.where(:title => "skip").skip(14).first
  #  assert_equal post.author, 15
  #end

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
    @post.save
    assert @post.attributes['objectId']
    assert @post.attributes['updatedAt']
    assert @post.attributes['createdAt']
  end

  def test_each
    Post.destroy_all
    4.times do |i|
      #Post.create(:title => "each", :author => i.to_s)
      Post.create(:title => "each")
    end
    posts = Post.where(:title => "each")
    posts.each do |p|
      assert_equal p.title, "each"
    end
  end

  def test_map
    Post.destroy_all
    4.times do |i|
      Post.create(:title => "map")
    end
    posts = Post.where(:title => "map")
    assert_equal posts.map {|p| p}.class, Array
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
    assert_equal p.title, nil
    assert_equal 0, Post.where(:title => "hello1234567890abc!", :objectId => id).length
  end

  def test_validation
    p = Post.new
    assert !p.valid?
    p.title = "foo"
    assert p.valid?
  end

  def test_to_pointer

  end

  def test_to_date_object
    date = DateTime.strptime("Thu, 11 Oct 2012 10:20:40 -0700", '%a, %d %b %Y %H:%M:%S %z')
    assert_equal {"__type"=>"Date", "iso"=>"2012-10-11T10:20:40-07:00"}, Post.to_date_object(date)
  end

end
