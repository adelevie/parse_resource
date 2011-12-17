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
end