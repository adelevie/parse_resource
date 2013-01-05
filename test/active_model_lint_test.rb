require 'helper'
require 'parse_resource'

ParseResource::Base.load!(ENV["PARSE_RESOURCE_APPLICATION_ID"], ENV["PARSE_RESOURCE_MASTER_KEY"])

class Bowl < ParseResource
  fields :title, :body, :author
  validates_presence_of :title
end
class ActiveModelLintTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  def setup
    @model = Bowl.new
  end
end
