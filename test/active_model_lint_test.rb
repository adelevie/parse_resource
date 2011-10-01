require 'helper'
require 'parse_resource'

path = "parse_resource.yml"
settings = YAML.load(ERB.new(File.new(path).read).result)['test']

ParseResource.load!(settings['app_id'], settings['master_key'])

class Post < ParseResource
  fields :title, :body, :author
  validates_presence_of :title
end
class ActiveModelLintTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  def setup
    @model = Post.new
  end
end
