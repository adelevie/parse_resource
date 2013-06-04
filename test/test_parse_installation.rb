require 'helper'
require 'parse_resource'

ParseResource::Base.load!(ENV["PARSE_RESOURCE_APPLICATION_ID"], ENV["PARSE_RESOURCE_MASTER_KEY"])


class Installation < ParseResource::Base
  field :deviceType
  field :deviceToken
  field :channels
end

class TestParseUser < Test::Unit::TestCase
  #def setup
  #  User.destroy_all
  #end

  #def teardown
  #  User.destroy_all
  #end

  def test_installation_creation
    VCR.use_cassette('test_installation_creation', :record => :new_episodes) do
      Installation.destroy_all
      i = Installation.create(:deviceType => "ios",
                              :deviceToken => "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                              :channels => [""])
      assert_not_nil(i.id)
      assert i.errors.empty?
    end
  end

  def test_installation_creation_validation_check
    VCR.use_cassette('test_installation_creation_validation_check', :record => :new_episodes) do
      Installation.destroy_all
      # missing deviceType
      i = Installation.create(:deviceToken => "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                              :channels => [""])
      assert_equal false, i.errors.empty?
      assert_equal "135".to_sym, i.errors.first.first # deviceType must be specified in this operation
    end
  end

end
