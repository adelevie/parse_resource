require 'helper'
require 'parse_resource'

path = "parse_resource.yml"
settings = YAML.load(ERB.new(File.new(path).read).result)['test']

ParseResource::Base.load!(settings['app_id'], settings['master_key'])

class Post < ParseResource::Base
  belongs_to :author
  fields :title, :body
  validates_presence_of :title
end

class Author < ParseResource::Base
  has_many :posts
  field :name
end

class TestAssociations < Test::Unit::TestCase

  def test_responds_to_has_many
    Author.destroy_all
    author = Author.create("alan")
    assert_equal true, author.respond_to?(:posts)
    Author.destroy_all
  end

  def test_has_many_returns_an_array
    Author.destroy_all
    author = Author.create("alex")
    assert_equal true, author.posts.is_a?(Array)
    Author.destroy_all
  end
  
  def test_relational_query
    Author.destroy_all
    Post.destroy_all
    a = Author.create(:name => "JK Rowling")
    p = Post.create(:title => "hello")
    p.author = a
    p.save
    post = Post.include_object(:author).where(:title => "hello").first
    puts "-----"
    puts post.author.id
    puts "-----"
    assert_equal Post, post.class
    assert_equal true, post.author.is_a?(Author)
    Author.destroy_all
    Post.destroy_all
  end
  
  def test_has_many_parent_getter
    Author.destroy_all
    Post.destroy_all
    a = Author.create(:name => "RL Stine")
    p = Post.create(:title => "Goosebumps")
    p.author = a
    p.save
    assert_equal a.posts.class, Array
    Author.destroy_all
    Post.destroy_all
  end
  
  def test_has_many_child_getter
    Author.destroy_all
    Post.destroy_all
    a = Author.create(:name => "JK Rowling")
    p = Post.create(:title => "hello")
    p.author = a
    p.save
    assert_equal p.author.id, a.id
    Author.destroy_all
    Post.destroy_all
  end
  
  def test_belongs_to_setter
    Author.destroy_all
    Post.destroy_all
    
    a = Author.create(:name => "Walter Kirn")
    p = Post.create(:title => "Up in the Air")
    p.author = a
    
    assert_equal a.id, p.author.id
    
    Author.destroy_all
    Post.destroy_all
  end
  
  def test_has_many_setter
    Author.destroy_all
    Post.destroy_all
    author = Author.create(:name => "R.L. Stine")
    post = Post.create(:title => "Goosebumps")
    author.posts << post
    assert_equal true, (author.posts.length > 0)
    assert_equal Post, author.posts[0].class
    Author.destroy_all
    Post.destroy_all
  end

end