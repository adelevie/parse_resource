require 'helper'
require 'parse_resource'

ParseResource::Base.load!(ENV["PARSE_RESOURCE_APPLICATION_ID"], ENV["PARSE_RESOURCE_MASTER_KEY"])


class Installation < ParseResource::Base
end

class TestParseUser < Test::Unit::TestCase
  #def setup
  #  User.destroy_all
  #end

  #def teardown
  #  User.destroy_all
  #end

  def test_creation
    Installation.destroy_all
    i = Installation.create(:deviceType => "ios",
                            :deviceToken => "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                            :channels => [""])
    assert_not_nil(i.id)
    assert i.errors.empty?
  end

  def test_creation_validation_check
    Installation.destroy_all
    # missing deviceType
    i = Installation.create(:deviceToken => "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                            :channels => [""])
    assert_equal false, i.errors.empty?
    assert_equal false, i.errors["400"].empty?
    parse_error_response = i.errors["400"][0]
    assert_equal 135, parse_error_response["code"] # deviceType must be specified in this operation
  end

end
