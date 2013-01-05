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

  def test_fetching_closest_10
    Place.destroy_all
    [[34.09300844216167, -118.3780094460731],
     [34.09297074516132, -118.3779001235962],
     [34.09291733023489, -118.3780601208767],
     [34.09291733023489, -118.3780601208767],
     [34.10020829969745, -118.2852727109533 ],
     [33.81637559726026, -118.3783150233789 ],
     [36.11837535750446, -115.1759274967512],
     [48.0284736030277, 37.79059904775168 ],
     [48.02790593385819, 37.78864582772938 ],
     [48.02776282648577, 37.78850555419922 ],
     [48.02750452121758, 37.78846263885498 ]
    ].each do |location|
      place = Place.new
      place.location = ParseGeoPoint.new :latitude => location[0], :longitude => location[1]
      place.save
    end
    assert_equal Place.count, 11
    assert_equal Place.near(:location, [34.09300844216167, -118.3780094460731]).limit(10).all.count, 10
  end

  def test_fetching_closest_by_miles
    Place.destroy_all
    [[34.09300844216167, -118.3780094460731],
     [34.09297074516132, -118.3779001235962],
     [34.09291733023489, -118.3780601208767],
     [34.09291733023489, -118.3780601208767],
     [34.10020829969745, -118.2852727109533 ],
     [33.81637559726026, -118.3783150233789 ],
     [36.11837535750446, -115.1759274967512],
     [48.0284736030277, 37.79059904775168 ],
     [48.02790593385819, 37.78864582772938 ],
     [48.02776282648577, 37.78850555419922 ],
     [48.02750452121758, 37.78846263885498 ]
    ].each do |location|
      place = Place.new
      place.location = ParseGeoPoint.new :latitude => location[0], :longitude => location[1]
      place.save
    end
    assert_equal Place.count, 11
    within_10_miles = Place.near(:location, [34.09300844216167, -118.3780094460731], :maxDistanceInMiles => 10).all
    assert_equal within_10_miles.count, 5
    within_10_miles.map(&:location).each do |local|
      assert_equal local.longitude > -119 && local.longitude < -118, true
      assert_equal local.latitude > 34 && local.latitude < 35, true
    end
  end

  def test_fetching_closest_by_kilometers
    Place.destroy_all
    [[34.09300844216167, -118.3780094460731],
     [34.09297074516132, -118.3779001235962],
     [34.09291733023489, -118.3780601208767],
     [34.09291733023489, -118.3780601208767],
     [34.10020829969745, -118.2852727109533 ],
     [33.81637559726026, -118.3783150233789 ],
     [36.11837535750446, -115.1759274967512],
     [48.0284736030277, 37.79059904775168 ],
     [48.02790593385819, 37.78864582772938 ],
     [48.02776282648577, 37.78850555419922 ],
     [48.02750452121758, 37.78846263885498 ]
    ].each do |location|
      place = Place.new
      place.location = ParseGeoPoint.new :latitude => location[0], :longitude => location[1]
      place.save
    end
    assert_equal Place.count, 11
    within_10_kms = Place.near(:location, [34.09300844216167, -118.3780094460731], :maxDistanceInKilometers => 10).all
    assert_equal within_10_kms.count, 5
    within_10_kms.map(&:location).each do |local|
      assert_equal local.longitude > -119 && local.longitude < -118, true
      assert_equal local.latitude > 34 && local.latitude < 35, true
    end
  end

  def test_fetching_closest_by_radians
    Place.destroy_all
    [[34.09300844216167, -118.3780094460731],
     [34.09297074516132, -118.3779001235962],
     [34.09291733023489, -118.3780601208767],
     [34.09291733023489, -118.3780601208767],
     [34.10020829969745, -118.2852727109533 ],
     [33.81637559726026, -118.3783150233789 ],
     [36.11837535750446, -115.1759274967512],
     [48.0284736030277, 37.79059904775168 ],
     [48.02790593385819, 37.78864582772938 ],
     [48.02776282648577, 37.78850555419922 ],
     [48.02750452121758, 37.78846263885498 ]
    ].each do |location|
      place = Place.new
      place.location = ParseGeoPoint.new :latitude => location[0], :longitude => location[1]
      place.save
    end
    assert_equal Place.count, 11
    within_10_radians = Place.near(:location, [34.09300844216167, -118.3780094460731], :maxDistanceInRadians => 10/3959).all
    assert_equal within_10_radians.count, 1
    within_10_radians.map(&:location).each do |local|
      assert_equal local.longitude > -119 && local.longitude < -118, true
      assert_equal local.latitude > 34 && local.latitude < 35, true
    end
  end

  def test_fetching_cloest_within_box
    Place.destroy_all
    [[34.09300844216167, -118.3780094460731],
     [34.09297074516132, -118.3779001235962],
     [34.09291733023489, -118.3780601208767],
     [34.09291733023489, -118.3780601208767],
     [34.10020829969745, -118.2852727109533 ],
     [33.81637559726026, -118.3783150233789 ],
     [36.11837535750446, -115.1759274967512],
     [48.0284736030277, 37.79059904775168 ],
     [48.02790593385819, 37.78864582772938 ],
     [48.02776282648577, 37.78850555419922 ],
     [48.02750452121758, 37.78846263885498 ]
    ].each do |location|
      place = Place.new
      place.location = ParseGeoPoint.new :latitude => location[0], :longitude => location[1]
      place.save
    end
    assert_equal Place.count, 11
    within_box = Place.within_box(:location, [33.81637559726026, -118.3783150233789], [34.09300844216167, -118.3780094460731]).all
    assert_equal within_box.count, 4
  end

end
