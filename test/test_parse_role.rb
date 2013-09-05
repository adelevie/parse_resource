require 'helper'
require 'parse_resource'

ParseResource::Base.load!(ENV["PARSE_RESOURCE_APPLICATION_ID"], ENV["PARSE_RESOURCE_MASTER_KEY"])


class Role < ParseRole
end

class TestParseRole < Test::Unit::TestCase
  
  def test_role_creation
    VCR.use_cassette('test_role_creation', :record => :new_episodes) do
      # Role.destroy_all
      write_acl = Hash.new
      write_acl["*"] = {"write" => true, "read" => true}
      r = Role.create(:name => "VIP", :ACL => write_acl)
      assert_equal "VIP", r.name
    end
  end
  
  def test_role_retrieval
    VCR.use_cassette('test_role_retrieval', :record => :new_episodes) do
      # Role.destroy_all
      write_acl = {"*" => {"write" => true}}
      first_role_created = Role.create(:name => "VIP", :ACL => write_acl)
      second_role_created = Role.create(:name => "Senator", :ACL => write_acl)
      roles = Role.all
      # r = Role.find(:name => "VIP")
      assert_equal 2, roles.count
      # assert_equal "VIP", r.get_attribute("name")
    end
  end
  
end