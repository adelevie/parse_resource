require 'helper'
require 'parse_resource'

path = "parse_resource.yml"
settings = YAML.load(ERB.new(File.new(path).read).result)['test']

ParseResource::Base.load!(settings['app_id'], settings['master_key'])

class User < ParseUser
end

class TestParseUser < Test::Unit::TestCase
  def setup
    User.destroy_all
  end
  
  def teardown
    User.destroy_all
  end
  
  def test_user_should_not_save_without_username_and_password
    u = User.new
    assert_equal u.valid?, false
    u.username = "fakename"
    assert_equal u.valid?, false
    u.password = "fakepass"
    assert_equal u.valid?, true
    assert_not_equal u.save, false
    assert_equal u.id.class, String
  end
  
  def test_username_should_be_unique
    User.destroy_all
    u = User.create(:username => "alan", :password => "12345")
    u2 = User.new(:username => "alan", :password => "56789")
    u2.save
    assert_equal u2.errors.count, 1
    assert_equal nil, u2.id
  end
  
  def test_authenticate
    user = "fake_person"
    pass = "fake_pass"
    u1 = User.create(:username => user, :password => pass)
    u2 = User.authenticate(user, pass)
    assert_equal u1.id, u2.id
    u3 = User.authenticate("wrong_username", "wrong_pass")
    assert_equal u3, false
  end
  
end