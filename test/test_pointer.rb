require 'helper'
require 'parse_resource'

path = "parse_resource.yml"
settings = YAML.load(ERB.new(File.new(path).read).result)['test']

ParseResource::Base.load!(settings['app_id'], settings['master_key'])

class Kid < ParseResource::Base
  field :parentId1
end

class Carer < ParseResource::Base
	field :name
end

class TestPointer < Test::Unit::TestCase
	def test_pointer_type
		carer = Carer.new(:name => "Carer1")
		carer.save

		kid = Kid.new
    kid.parentId1 = {"__type"=>"Pointer","className"=>"Carer","objectId"=>carer.objectId}
		kid.save
		assert kid.id, "Unable to save"
	end
end
