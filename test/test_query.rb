require 'helper'
require 'parse_resource'

class TestQuery < Test::Unit::TestCase

  def test_respond_to
    q = Query.new(self).where(:foo => "bar")
    assert_equal q.respond_to?(:length), true
    assert_equal q.respond_to?(:[]), true
    assert_equal q.respond_to?(:map), true
  end

  def test_order_criteria
    q = Query.new(self).order("created_at DESC")
    assert_equal "-created_at", q.criteria[:order]

    q = Query.new(self).order("created_at")
    assert_equal "created_at", q.criteria[:order]
  end

end
