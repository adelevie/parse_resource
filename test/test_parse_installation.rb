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
    # TODO: actually check for the parse error code 135, once ParseError is
    # fixed to actually represent parse error codes.
  end

end
