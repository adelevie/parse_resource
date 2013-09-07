require 'helper'
require 'parse_resource'

ParseResource::Base.load!(ENV["PARSE_RESOURCE_APPLICATION_ID"], ENV["PARSE_RESOURCE_MASTER_KEY"])

class Role < ParseRole
end

class TestParseRole < Test::Unit::TestCase
  
  def test_role_creation
    VCR.use_cassette('test_role_creation', :record => :new_episodes) do
      Role.destroy_all
      role = Role.create(:name => "VIP", :ACL => {:read => true, :write => true})
      assert_equal "VIP", role.name
      assert role.is_a?(Role)
      assert role.id
      assert role.created_at
    end
  end
  
  def test_role_retrieval
    VCR.use_cassette('test_role_retrieval', :record => :new_episodes) do
      Role.destroy_all
      role_name = "VIP"
      new_role = Role.create(:name => role_name, :ACL => {:read => true, :write => true})
      found_role = Role.where(:name => role_name).first
      assert_equal role_name, found_role.name
      assert_equal new_role.id, found_role.id
    end
  end

  def test_adding_user_to_role
    VCR.use_cassette('test_role_add_user', :record => :new_episodes) do
      User.destroy_all
      Role.destroy_all
      role_name = "VIP"
      role = Role.create(:name => role_name, :ACL => {:read => true, :write => true})
      user = User.create(:username => "alan", :password => "12345")
      role.add_user(user)
      assert role.users.all.map(&:id).include? user.id
    end
  end
  
  def test_removing_user_from_role
    VCR.use_cassette('test_role_remove_user', :record => :new_episodes) do
      User.destroy_all
      Role.destroy_all
      role_name = "VIP"
      role = Role.create(:name => role_name, :ACL => {:read => true, :write => true})
      user = User.create(:username => "alan", :password => "12345")
      role.add_user(user)
      role.remove_user(user)
      assert role.users.all.empty? == true
      assert !role.users.all.map(&:id).include?(user.id)
    end
  end
end