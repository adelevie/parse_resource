require 'helper'
require 'parse_resource'

path = "parse_resource.yml"
settings = YAML.load(ERB.new(File.new(path).read).result)['test']

ParseResource.load!(settings['app_id'], settings['master_key'])

class Post < ParseResource
  fields :title, :author, :body
end
