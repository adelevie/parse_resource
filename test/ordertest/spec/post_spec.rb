require_relative "../models/post"

ParseResource::Base.load!(ENV['PARSE_APP_KEY'],ENV['PARSE_MASTER_KEY'])

describe Post do

  # Before each 'describe' group we create some test data
  before(:all) do

    # Remove all the data
    Post.destroy_all

    # Create some test data
    titles = 'a'..'z'
    titles.each { |title| Post.create(:title => title, :author => "John Doe") }    

    # Get all the posts and the ordered posts
    @posts = Post.all
    @ordered_posts = Post.order(:title)

  end 

  describe "the ordered_posts" do

    it "should contain the same number of posts than the full list of posts" do 
      @posts.length.should == @ordered_posts.length.should
    end  	

    it "should contain 26 posts" do
      @ordered_posts.length.should == 26
    end

    it "should have 'a' as the first post" do
      @ordered_posts.first.title.should == "a"      
    end

    it "should have 'z' as the last post" do
      @ordered_posts.last.title.should == "z"
    end

    it "should have a..z titles in order" do      
      titles = ('a'..'z').to_a
      @ordered_posts.each_with_index do |post,index|
        post.title.should == titles[index]
      end        
    end

    it "should have the same titles if 'order' request is repeated" do      

      3.times {
        ordered_posts_new = Post.order(:title)
        ordered_posts_new.each_with_index do |post,index|
          post.title.should == @ordered_posts[index].title
        end
      }
      
    end

  end

end
