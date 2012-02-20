require 'helper'
require 'parse_resource'

path = "parse_resource.yml"
settings = YAML.load(ERB.new(File.new(path).read).result)['test']

ParseResource::Base.load!(settings['app_id'], settings['master_key'])

class Post < ParseResource::Base
  belongs_to :author
  fields :title, :body
end

class Author < ParseResource::Base
  has_many :posts
  field :name
end

class TestAssociations < Test::Unit::TestCase
  
  def setup
    Post.destroy_all
    Author.destroy_all
  end
  
  
  def teardown
    Post.destroy_all
    Author.destroy_all
  end

  def test_responds_to_has_many
    #author = Author.create(:name => "alan")
    author = Author.new
    assert_equal true, author.respond_to?(:posts)
  end

  def test_has_many_returns_an_array
    author = Author.create(:name => "alex")
    assert_equal true, author.posts.is_a?(Array)
  end
  
  def test_relational_query
    a = Author.create(:name => "JK Rowling_relational_query")
    p = Post.create(:title => "test relational query")
    p.author = a#.to_pointer
    p.save
    post = Post.include_object(:author).where(:title => "test relational query").first
    assert_equal Post, post.class
    assert_equal "Object", post.attributes['author']['__type']
    assert_equal "Author", post.attributes['author']['className']
    assert_equal a.id, post.attributes['author']['objectId']
    assert_equal a.name, post.attributes['author']['name']
  end
  
  def test_to_pointer_duck_typing
    a = Author.create(:name => "Duck")
    p = Post.create(:title => "Typing")
    p.author = a
    p.save
		require 'ruby-debug/debugger'
    assert_equal p.author.name, a.name
    assert_equal a.posts.class, Array
    assert_equal a.posts.length, 1
    assert_equal a.posts[0].class, Post
    assert_equal a.posts[0].id, p.id
  end
  
  def test_has_many_parent_getter
    a = Author.create(:name => "RL Stine")
    p = Post.create(:title => "Goosebumps_has_many_parent_getter")
    p.author = a#.to_pointer
    p.save
    assert_equal Array, a.posts.class
		require 'ruby-debug/debugger'
    assert_equal Post, a.posts.first.class
    assert_equal p.title, a.posts.first.title
  end
  
  def test_has_many_child_getter
    a = Author.create(:name => "JK Rowling_child_getter")
    p = Post.create(:title => "test has_many child getter")
    p.author = a.to_pointer
    p.save
    assert_equal p.author.id, a.id
  end
  
  def test_belongs_to_setter  
    Author.destroy_all
    Post.destroy_all  
    aa = Author.create(:name => "Shmalter Kirn")
    pp = Post.create(:title => "Shmup in the Air")
    pp.author = aa#.to_pointer
    pp.save
    assert aa.id
    assert_equal aa.id, pp.author.id
  end
  
  def test_has_many_setter
    author = Author.create(:name => "R.L. Stine")
    post = Post.create(:title => "Goosebumps_has_many_setter")
    author.posts << post
    assert_equal true, (author.posts.length > 0)
    assert_equal Post, author.posts[0].class
  end

end
