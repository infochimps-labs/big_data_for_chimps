require          'gorillib/data_munging'
require_relative '../geolocated'

describe Wukong::Geolocated do
  let(:aus_lng){   -97.759003 } # Austin, TX -- infochimps HQ
  let(:aus_lat){    30.273884 }
  let(:sat_lng){   -98.486123 } # San Antonio, TX
  let(:sat_lat){    29.42575  }
  let(:dpi){      72 }
  let(:aus_tile_x_8){   58.48248675555555 } # zoom level 8
  let(:aus_tile_y_8){  105.39405073699557 }
  let(:aus_tile_x_11){ 467 } # zoom level 11
  let(:aus_tile_y_11){ 843 }
  #
  let(:aus_tile_x_3){  1.82758 } # zoom level 3
  let(:aus_tile_y_3){  3.29356 }
  let(:aus_pixel_x_3){ 468     }
  let(:aus_pixel_y_3){ 843     }
  let(:aus_quadkey_3){ "023"   }
  let(:radius){      1_000_000 } # 1,000 km

  #
  # Tile coordinates
  #

  it "returns a map tile size given a zoom level" do
    Wukong::Geolocated.map_tile_size(3).should == 8
  end

  it "returns a tile_x, tile_y pair given a longitude, latitude and zoom level" do
    Wukong::Geolocated.lng_lat_zl_to_tile_xy(aus_lng, aus_lat,  8).should == [ 58, 105]
    Wukong::Geolocated.lng_lat_zl_to_tile_xy(aus_lng, aus_lat, 11).should == [467, 843]
  end

  it "returns a longitude, latitude pair given tile_x, tile_y and zoom level" do
    lng, lat = Wukong::Geolocated.tile_xy_zl_to_lng_lat(aus_tile_x_8, aus_tile_y_8, 8)
    lng.should be_within(0.0001).of(aus_lng)
    lat.should be_within(0.0001).of(aus_lat)
  end

  #
  # Pixel coordinates
  #

  it "returns a map pizel size given a zoom level" do
    Wukong::Geolocated.map_pixel_size(3).should == 2048
  end

  it "returns a pixel_x, pixel_y pair given a longitude, latitude and zoom level" do
    Wukong::Geolocated.lng_lat_zl_to_pixel_xy(aus_lng, aus_lat, 3).should == [468, 843]
  end

  it "returns a longitude, latitude pair given pixel_x, pixel_y and zoom level" do
    lng, lat = Wukong::Geolocated.pixel_xy_zl_to_lng_lat(aus_pixel_x_3, aus_pixel_y_3, 3)
    lat.round(4).should ==  30.2970
    lng.round(4).should == -97.7344
  end

  it "returns a tile x-y pair given a pixel x-y pair" do
    Wukong::Geolocated.pixel_xy_to_tile_xy(aus_pixel_x_3, aus_pixel_y_3).should == [1,3]
  end

  it "returns a pixel x-y pair given a float tile x-y pair" do
    Wukong::Geolocated.tile_xy_to_pixel_xy(aus_tile_x_3,      aus_tile_y_3     ).should == [467.86048, 843.15136]
  end

  it "returns a pixel x-y pair given an integer tile x-y pair" do
    Wukong::Geolocated.tile_xy_to_pixel_xy(aus_tile_x_3.to_i, aus_tile_y_3.to_i).should == [256, 768]
  end

  it "returns a quadkey given a tile x-y pair and a zoom level" do
    Wukong::Geolocated.tile_xy_to_quadkey(aus_tile_x_3, aus_tile_y_3, 3).should == "023"
  end

  it "returns tile x-y pair and a zoom level given a quadkey" do
    Wukong::Geolocated.quadkey_to_tile_xy(aus_quadkey_3).should == [1, 3, 3]
  end

  it "throws an error if a bad quadkey is given" do
    lambda { Wukong::Geolocated.quadkey_to_tile_xy("bad_key") }.should raise_error()
  end
  #
  # it "returns a quadkey given a latitude, longitude and zoom level" do
  #   Wukong::Geolocated.lng_lat_zoom_to_quadkey(aus_lng, aus_lat, zl_0).should == "023"
  # end
  #
  # it "returns a bounding box given a quadkey" do
  #   top_lat, top_lng, bottom_lat, bottom_lng = Wukong::Geolocated.quadkey_to_bbox(quadkey)
  #   top_lat.round(4).should    == 40.9799
  #   top_lng.round(4).should    == -135.0
  #   bottom_lat.round(4).should == 0.0
  #   bottom_lng.round(4).should == -90.0
  # end
  #
  # it "returns the smallest quadkey containing two lat-lng pairs" do
  #   Wukong::Geolocated.quadkey_containing_bbox(aus_lng, aus_lat, sat_lat, sat_lng).should == "023130"
  # end
  #
  # it "returns a bounding box given a lat/lng and radius" do
  #   aus_lng, aus_lat, sat_lat, sat_lng = Wukong::Geolocated.lng_lat_rad_to_bbox(aus_lng, aus_lat, radius)
  #   aus_lat.round(4).should == 39.2671
  #   aus_lng.round(4).should == -108.1723
  #   sat_lat.round(4).should == 21.2807
  #   sat_lng.round(4).should == -87.3457
  # end
  #
  # it "returns a centroid given a bounding box" do
  #   top_left     = [aus_lng, aus_lat]
  #   bottom_right = [sat_lng, sat_lat]
  #   mid_lng, mid_lat = Wukong::Geolocated.center_of_bbox(top_left, bottom_right)
  #   mid_lat.round(4).should == 29.8503
  #   mid_lng.round(4).should == -98.1241
  # end
  #
  # it "returns a pixel resolution given a latitude and zoom level" do
  #   Wukong::Geolocated.pixel_resolution(aus_lat, zl_0).round(4).should == 16880.4081
  # end
  #
  # it "returns a map scale given a latitude, zoom level and dpi" do
  #   Wukong::Geolocated.map_scale(aus_lat, zl_0, dpi).round(4).should == 47849975.8302
  # end
  #
  # it "calculates the haversine distance between two points" do
  #   Wukong::Geolocated.haversine_distance(aus_lng, aus_lat, sat_lat, sat_lng).round(4).should == 117522.1219
  # end
  #
  # it "calculates the haversine midpoint between two points" do
  #   lng, lat = Wukong::Geolocated.haversine_midpoint(aus_lng, aus_lat, sat_lat, sat_lng)
  #   lat.round(4).should == 29.8503
  #   lng.round(4).should == -98.1241
  # end
  #
  # it "calculates the point a given distance directly north from a lat/lng" do
  #   lng, lat = Wukong::Geolocated.point_north(aus_lng, aus_lat, 1000000)
  #   lat.round(4).should == 39.2671
  #   lng.round(4).should == -97.7590
  # end
  #
  # it "calculates the point a given distance directly east from a lat/lng" do
  #   lng, lat = Wukong::Geolocated.point_east(aus_lng, aus_lat, 1000000)
  #   lat.round(4).should == 30.2739
  #   lng.round(4).should == -87.3457
  # end

end
