require 'helper'
require 'parse_resource'

ParseResource::Base.load!(ENV["PARSE_RESOURCE_APPLICATION_ID"], ENV["PARSE_RESOURCE_MASTER_KEY"])

class Place < ParseResource::Base
  fields :name, :location
end

class TestParseResource < Test::Unit::TestCase

  def test_saving_geopoint_with_coords
    Place.destroy_all
    place = Place.new
    place.name = "Office"
    place.location = ParseGeoPoint.new
    place.location.latitude = 34.09300844216167
    place.location.longitude = -118.3780094460731
    place.save
    assert_equal Place.count, 1
  end

  def test_saving_geo_point_with_quick_init
    Place.destroy_all
    place = Place.new
    place.location = ParseGeoPoint.new :latitude => 34.09300844216167, :longitude => -118.3780094460731
    place.save
    assert_equal Place.count, 1
  end

  def test_fetching_geopoint_field
    Place.destroy_all
    place = Place.new
    place.location = ParseGeoPoint.new :latitude => 34.09300844216167, :longitude => -118.3780094460731
    place.save
    assert_equal Place.count, 1

    server_place = Place.find(place.objectId)
    assert_equal server_place.location.latitude, 34.09300844216167
    assert_equal server_place.location.longitude, -118.3780094460731
  end

end
