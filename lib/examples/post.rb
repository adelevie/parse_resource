require 'parse_resource'

class Post < ParseResource
  fields :title, :body, :author

  validates_presence_of :title
end
