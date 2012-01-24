require 'parse_resource'

class Post < ParseResource::Base
  fields :title, :author, :body

  validates_presence_of :title
end