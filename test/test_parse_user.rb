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
  
  def test_login
    user = "fake_person"
    pass = "fake_pass"
    u1 = User.create(:username => user, :password => pass)
    u2 = User.login(user, pass)
    assert_equal u1.id, u2.id
    u3 = User.login("wrong_username", "wrong_pass")
    assert_equal u3, false
  end
  
end