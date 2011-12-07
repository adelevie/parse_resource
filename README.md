ParseResource
=============

ParseResource makes it easy to interact with Parse.com's REST API. It adheres to the ActiveRecord pattern. ParceResource is fully ActiveModel compliant, meaning you can use validations and Rails forms.

Ruby/Rails developers should feel right at home.

Features
---------------
*   ActiveRecord-like API, almost no learning curve
*   Validations
*   Rails forms and scaffolds **just work**

Use cases
-------------
*   Build a custom admin dashboard for your Parse.com data
*   Use the same database for your web and native apps
*   Pre-collect data for use in iOS and Android apps

To-do
--------------
*   User authentication
*   Better documentation
*   Associations
*   Callbacks
*   Push notifications
*   Better type-casting

User authentication is my top priority feature. Several people have specifically requested it, and Parse just began exposing [`User` objects in the REST API](https://www.parse.com/docs/rest#users).

Let me know of any other features you want.


Words of caution
---------------

ParseResource is brand new. Test coverage is decent.

This is my first gem. Be afraid.

Installation
------------

Include in your `Gemfile`:

```ruby
gem "parse_resource", "~> 1.5.11"
```

Or just gem install:

```ruby
gem install parse_resource
```

Create an account at Parse.com. Then create an application and copy the `app_id` and `master_key` into a file called `parse_resource.yml`. If you're using a Rails app, place this file in the `config` folder.

```yml
development:
  app_id: 1234567890
  master_key: abcdefgh

test:
  app_id: 1234567890
  master_key: abcdefgh

production:
  app_id: 1234567890
  master_key: abcdefgh
```

You can create separate Parse databases if you want. If not, include the same info for each environment.

In a non-Rails app, include this somewhere (preferable in an initializer):


```ruby
ParseResource.load!("your_app_id", "your_master_key")
```


Usage
-----

Create a model:

```ruby
class Post < ParseResource::Base
  fields :title, :author, :body

  validates_presence_of :title
end
```

If you are using version `1.5.11` or earlier, subclass to just `ParseResource`.

Creating, updating, and deleting:

```ruby
p = Post.new
 => #<Post:0xab74864 @attributes={}, @unsaved_attributes={}> 
p.valid?
 => false 
p.errors
 => #<ActiveModel::Errors:0xab71998 @base=#<Post:0xab74864 @attributes={}, @unsaved_attributes={}, @validation_context=nil, @errors=#<ActiveModel::Errors:0xab71998 ...>>, @messages={:title=>["can't be blank"]}> 
p.title = "Introducing ParseResource"
 => "Introducing ParseResource" 
p.valid?
 => true 
p.author = "Alan deLevie"
 => "Alan deLevie" 
p.body = "Ipso Lorem"
 => "Ipso Lorem" 
p.save
 => #<Post:0xab74864 @attributes={:title=>"Introducing ParseResource", :author=>"Alan deLevie", :body=>"Ipso Lorem", :createdAt=>"2011-09-19T01:32:04.973Z", :objectId=>"QARfXUILgY"}, @unsaved_attributes={}, @validation_context=nil, @errors=#<ActiveModel::Errors:0xab71998 @base=#<Post:0xab74864 ...>, @messages={}>> 
p.id
 => "QARfXUILgY" 
p.updated_at
 => nil 
p.created_at
 => "2011-09-19T01:32:04.973Z" 
p.title = "[Update] Introducing ParseResource"
 => "[Update] Introducing ParseResource" 
p.save
 => #<Post:0xab74864 @attributes={:title=>"[Update] Introducing ParseResource", :author=>"Alan deLevie", :body=>"Ipso Lorem", :createdAt=>"2011-09-19T01:32:04.973Z", :objectId=>"QARfXUILgY", :updatedAt=>"2011-09-19T01:32:37.930Z", "title"=>"[Update] Introducing ParseResource"}, @unsaved_attributes={}, @validation_context=nil, @errors=#<ActiveModel::Errors:0xab71998 @base=#<Post:0xab74864 ...>, @messages={}>> 
p.updated_at
 => "2011-09-19T01:32:37.930Z" 
p.destroy
 => nil 
p.title
 => nil 
```

Finding:

```ruby
a = Post.create(:title => "foo", :author => "bar", :body => "ipso")
 => #<Post:0xa6eee34 @attributes={:title=>"foo", :author=>"bar", :body=>"ipso", :createdAt=>"2011-09-19T01:36:42.833Z", :objectId=>"dPjKwaqQUv"}, @unsaved_attributes={}, @validation_context=nil, @errors=#<ActiveModel::Errors:0xa6ee54c @base=#<Post:0xa6eee34 ...>, @messages={}>> 
b = Post.create(:title => "a newer post", :author => "bar", :body => "some newer content")
 => #<Post:0xa6b5e68 @attributes={:title=>"a newer post", :author=>"bar", :body=>"some newer content", :createdAt=>"2011-09-19T01:37:16.805Z", :objectId=>"ZripqKvunV"}, @unsaved_attributes={}, @validation_context=nil, @errors=#<ActiveModel::Errors:0xa6b5710 @base=#<Post:0xa6b5e68 ...>, @messages={}>> 
posts = Post.where(:author => "bar")
 => [#<Post:0xa67b830 @attributes={:body=>"ipso", :author=>"bar", :title=>"foo", :updatedAt=>"2011-09-19T01:36:42.834Z", :createdAt=>"2011-09-19T01:36:42.834Z", :objectId=>"dPjKwaqQUv"}, @unsaved_attributes={:body=>"ipso", :author=>"bar", :title=>"foo", :updatedAt=>"2011-09-19T01:36:42.834Z", :createdAt=>"2011-09-19T01:36:42.834Z", :objectId=>"dPjKwaqQUv"}>, #<Post:0xa67b088 @attributes={:body=>"some newer content", :author=>"bar", :title=>"a newer post", :updatedAt=>"2011-09-19T01:37:16.805Z", :createdAt=>"2011-09-19T01:37:16.805Z", :objectId=>"ZripqKvunV"}, @unsaved_attributes={:body=>"some newer content", :author=>"bar", :title=>"a newer post", :updatedAt=>"2011-09-19T01:37:16.805Z", :createdAt=>"2011-09-19T01:37:16.805Z", :objectId=>"ZripqKvunV"}>] 
p = Post.first
 => #<Post:0xa640dd4 @attributes={:body=>"ipso", :author=>"bar", :title=>"foo", :updatedAt=>"2011-09-19T01:36:42.834Z", :createdAt=>"2011-09-19T01:36:42.834Z", :objectId=>"dPjKwaqQUv"}, @unsaved_attributes={:body=>"ipso", :author=>"bar", :title=>"foo", :updatedAt=>"2011-09-19T01:36:42.834Z", :createdAt=>"2011-09-19T01:36:42.834Z", :objectId=>"dPjKwaqQUv"}> 
posts = Post.all
 => [#<Post:0xa6236a8 @attributes={:body=>"ipso", :author=>"bar", :title=>"foo", :updatedAt=>"2011-09-19T01:36:42.834Z", :createdAt=>"2011-09-19T01:36:42.834Z", :objectId=>"dPjKwaqQUv"}, @unsaved_attributes={:body=>"ipso", :author=>"bar", :title=>"foo", :updatedAt=>"2011-09-19T01:36:42.834Z", :createdAt=>"2011-09-19T01:36:42.834Z", :objectId=>"dPjKwaqQUv"}>, #<Post:0xa6226cc @attributes={:body=>"some newer content", :author=>"bar", :title=>"a newer post", :updatedAt=>"2011-09-19T01:37:16.805Z", :createdAt=>"2011-09-19T01:37:16.805Z", :objectId=>"ZripqKvunV"}, @unsaved_attributes={:body=>"some newer content", :author=>"bar", :title=>"a newer post", :updatedAt=>"2011-09-19T01:37:16.805Z", :createdAt=>"2011-09-19T01:37:16.805Z", :objectId=>"ZripqKvunV"}>]
id = "DjiH4Qffke"
p = Post.find(id)
 => #<Post:0xa50f028 @unsaved_attributes={}, @attributes={"title"=>"fvvV", "updatedAt"=>"2011-09-22T21:36:13.044Z", "createdAt"=>"2011-09-22T21:36:13.044Z", "objectId"=>"DjiH4Qffke"}> 
```


Contributing to ParseResource
-----------------------------

*   Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
*   Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
*   Fork the project
*   Start a feature/bugfix branch
*   Commit and push until you are happy with your contribution
*   Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
*   Create `parse_resource.yml` in the root of the gem folder. Using the same format as `parse_resource.yml` in the instructions (except only creating a `test` environment, add your own API keys.
*   Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
---------

Copyright (c) 2011 Alan deLevie. See LICENSE.txt for
further details.

