require 'helper'
require 'parse_resource'

class TestQuery < Test::Unit::TestCase

  def test_respond_to
    q = Query.new(self).where(:foo => "bar")
    assert_equal q.respond_to?(:length), true
    assert_equal q.respond_to?(:[]), true
    assert_equal q.respond_to?(:map), true
  end

end
