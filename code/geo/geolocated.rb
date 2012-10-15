require 'gorillib/numeric/clamp'

Numeric.class_eval do
  def to_radians() self.to_f * Math::PI / 180.0 ; end
  def to_degrees() self.to_f * 180.0 / Math::PI ; end
end

module Wukong
  #
  # reference: [Bing Maps Tile System](http://msdn.microsoft.com/en-us/library/bb259689.aspx)
  #
  module Geolocated
    module_function # call methods as eg Wukong::Geolocated.tile_xy_to_quadkey or, if included in class, on self as private methods

    # field :longitude,  type: Float,   description: "Longitude (X) of a point, in decimal degrees"
    # field :latitude,   type: Float,   description: "Latitude (Y) of a point, in decimal degrees"
    # field :zoom_level, type: Integer, description: "Zoom level of tile to fetch. An integer between 0 (world) and 16 or so"
    # field :quadkey,    type: String,  description: "Quadkey of tile, eg 002313012"
    # field :tile_x,     type: Integer, description: "Tile X index, an integer between 0 and 2^zoom_level - 1"
    # field :tile_y,     type: Integer, description: "Tile Y index, an integer between 0 and 2^zoom_level - 1"

    module ByCoordinates
      extend Gorillib::Concern
      included do |klass|
        warn "You must define methods `longitude` and `latitude`" unless klass.method_defined?(:longitude) && klass.method_defined?(:latitude)
      end

      def quadkey(zl) ; tile_xy_to_quadkey(tile_x, tile_y) ; end
      def tile_x(zl)  ; lng_lat_zl_to_tile_xy(latitude, longitude, zl)  ; end

    end

    # TODO: remove unless defined?
    unless defined?(EARTH_RADIUS)
      EARTH_RADIUS      =  6371000 # meters
      MIN_LONGITUDE     = -180
      MAX_LONGITUDE     =  180
      MIN_LATITUDE      = -85.05112878
      MAX_LATITUDE      =  85.05112878
      ALLOWED_LONGITUDE = (MIN_LONGITUDE..MAX_LONGITUDE)
      ALLOWED_LATITUDE  = (MIN_LATITUDE..MAX_LATITUDE)
      TILE_PIXEL_SIZE   =  256
    end

    # Width or height in number of tiles
    def map_tile_size(zl)
      1 << zl
    end

    # Convert longitude in degrees to _floating-point_ tile x,y coordinates at given zoom level
    def lng_zl_to_tile_xf(longitude, zl)
      raise ArgumentError, "longitude must be within bounds ((#{longitude}) vs #{ALLOWED_LONGITUDE})" unless (ALLOWED_LONGITUDE.include?(longitude))
      xx = (longitude.to_f + 180.0) / 360.0
      (map_tile_size(zl) * xx)
    end

    # Convert latitude in degrees to _floating-point_ tile x,y coordinates at given zoom level
    def lat_zl_to_tile_yf(latitude, zl)
      raise ArgumentError, "latitude must be within bounds ((#{latitude}) vs #{ALLOWED_LATITUDE})" unless (ALLOWED_LATITUDE.include?(latitude))
      sin_lat = Math.sin(latitude.to_radians)
      yy = Math.log((1 + sin_lat) / (1 - sin_lat)) / (4 * Math::PI)
      (map_tile_size(zl) * (0.5 - yy))
    end

    # Convert latitude in degrees to integer tile x,y coordinates at given zoom level
    def lng_lat_zl_to_tile_xy(longitude, latitude, zl)
      [lng_zl_to_tile_xf(longitude, zl).floor, lat_zl_to_tile_yf(latitude, zl).floor]
    end

    # Convert from tile_x, tile_y, zoom level to longitude and latitude in
    # degrees (slight loss of precision).
    #
    # Tile coordinates may be floats or integer; they must lie within map range.
    def tile_xy_zl_to_lng_lat(tile_x, tile_y, zl)
      tile_size = map_tile_size(zl)
      raise ArgumentError, "tile index must be within bounds ((#{tile_x},#{tile_y}) vs #{tile_size})" unless ((0..(tile_size-1)).include?(tile_x)) && ((0..(tile_size-1)).include?(tile_x))
      xx =       (tile_x.to_f / tile_size)
      yy = 0.5 - (tile_y.to_f / tile_size)
      lng = 360.0 * xx - 180.0
      lat = 90 - 360 * Math.atan(Math.exp(-yy * 2 * Math::PI)) / Math::PI
      [lng, lat]
    end

    # Convert from tile x,y into a quadkey at a specified zoom level
    def tile_xy_to_quadkey(tile_x, tile_y, zl)
      quadkey = ""
      for i in zl.downto(1)
        digit    = 0
        mask     = 1 << (i - 1)
        digit   += 1 unless (tile_x & mask) == 0
        digit   += 2 unless (tile_y & mask) == 0
        quadkey += digit.to_s
      end
      return quadkey
    end

    # Convert a quadkey into tile x,y coordinates and level
    def quadkey_to_tile_xy(quadkey)
      tile_x = tile_y = 0
      zl = quadkey.to_s.length
      for i in zl.downto(1)
        mask = 1 << (i - 1)
        char = quadkey[zl - i]
        case char
        when "0" then next
        when "1" then tile_x |= mask ; next
        when "2" then tile_y |= mask ; next
        when "3" then tile_x |= mask ; tile_y |= mask ; next
        else
          raise "Quadkey must be a string containing only the characters 0, 1, 2 or 3!"
        end
      end
      [tile_x, tile_y, zl]
    end

    # Convert a lat/lng and zoom level into a quadkey
    def lng_lat_zl_to_quadkey(longitude, latitude, zl)
      pixel_x, pixel_y = lng_lat_to_pixel_xy(longitude, latitude, zl)
      tile_x,  tile_y  = pixel_xy_to_tile_xy(pixel_x, pixel_y)
      tile_xy_to_quadkey(tile_x, tile_y, zl)
    end

    # Convert a quadkey into a bounding box using adjacent tile
    def quadkey_to_bbox(quadkey)
      tile_x,   tile_y, zl = quadkey_to_tile_xy(quadkey)
      pixel_x0, pixel_y0      = tile_xy_to_pixel_xy(tile_x, tile_y)
      top_lat,  top_lng       = pixel_xy_to_lng_lat(pixel_x0, pixel_y0, zl)

      pixel_x1, pixel_y1      = tile_xy_to_pixel_xy(tile_x + 1, tile_y + 1)
      btm_lat, btm_lng  = pixel_xy_to_lng_lat(pixel_x1, pixel_y1, zl)
      [top_lat, top_lng, btm_lat, btm_lng]
    end

    # Retuns the smallest quadkey containing both of corners of the given bounding box
    def quadkey_containing_bbox(lat_1, lng_1, lat_2, lng_2)
      tile_1 = lng_lat_zl_to_quadkey(lat_1, lng_1, 23)
      tile_2 = lng_lat_zl_to_quadkey(lat_2, lng_2, 23)
      containing_key = ""
      tile_1.chars.zip(tile_2.chars).each do |pair|
        break unless pair.first == pair.last
        containing_key += pair.first
      end
      containing_key
    end

    # Returns a bounding box containing the circle created by the lat/lng and radius
    def lng_lat_rad_to_bbox(longitude, latitude, radius)
      north_lat, north_lng = point_north(longitude, latitude, radius)
      east_lat,  east_lng  = point_east(longitude, latitude, radius)
      south_lat, south_lng = point_north(longitude, latitude, -radius)
      west_lat,  west_lng  = point_east(longitude, latitude, -radius)
      [north_lat, west_lng, south_lat, east_lng]
    end

    # Returns the centroid of a bounding box
    #
    # @param [Array<Float, Float>] top_left  Longitude, Latitude of top left point
    # @param [Array<Float, Float>] btm_right Longitude, Latitude of bottom right point
    #
    # @return [Array<Float, Float>] Longitude, Latitude of centroid
    def bbox_centroid(top_left, btm_right)
      lng1, lat1 = top_left
      lng2, lat2 = btm_right
      haversine_midpoint(lng_1, lat_1, lng_2, lat_2)
    end

    # Return the haversine distance in meters between two points
    def haversine_distance(lng_1, lat_1, lng_2, lat_2)
      delta_lng = (lng_2 - lng_1).abs.to_radians
      delta_lat = (lat_2 - lat_1).abs.to_radians
      lat_1_rad = lat_1.to_radians
      lat_2_rad = lat_2.to_radians

      a = (Math.sin(delta_lat / 2.0))**2 + Math.cos(lat_1_rad) * Math.cos(lat_2_rad) * (Math.sin(delta_lng / 2.0))**2
      c = 2.0 * Math.atan2(Math.sqrt(a), Math.sqrt(1.0 - a))
      c * EARTH_RADIUS
    end

    # Return the haversine midpoint in meters between two points
    def haversine_midpoint(lng_1, lat_1, lng_2, lat_2)
      bearing_x = Math.cos(lat_2.to_radians) * Math.cos((lng_2 - lng_1).to_radians)
      bearing_y = Math.cos(lat_2.to_radians) * Math.sin((lng_2 - lng_1).to_radians)
      mid_lat   = Math.atan2((Math.sin(lat_1.to_radians) + Math.sin(lat_2.to_radians)), (Math.sqrt((Math.cos(lat_1.to_radians) + bearing_x)**2 + bearing_y**2)))
      mid_lng   = lng_1.to_radians + Math.atan2(bearing_y, (Math.cos(lat_1.to_radians) + bearing_x))
      [mid_lng.to_degrees, mid_lat.to_degrees]
    end

    # From a given point, calculate the point directly north a specified distance
    def point_north(longitude, latitude, distance)
      north_lat = (latitude.to_radians + (distance.to_f / EARTH_RADIUS)).to_degrees
      [longitude, north_lat]
    end

    # From a given point, calculate the change in degrees directly east a given distance
    def point_east(longitude, latitude, distance)
      radius = EARTH_RADIUS * Math.sin(((Math::PI / 2.0) - latitude.to_radians.abs))
      east_lng = (longitude.to_radians + (distance.to_f / radius)).to_degrees
      [east_lng, latitude]
    end

    #
    # Pixel coordinates
    #
    # Use with a standard (256x256 pixel) grid-based tileserver
    #

    # Width or height of grid bitmap in pixels at given zoom level
    def map_pixel_size(zl)
      TILE_PIXEL_SIZE * map_tile_size(zl)
    end

    # Return pixel resolution in meters per pixel at a specified latitude and zoom level
    def pixel_resolution(latitude, zl)
      lat = latitude.clamp(MIN_LATITUDE, MAX_LATITUDE)
      Math.cos(lat.to_radians) * 2 * Math::PI * EARTH_RADIUS / map_pixel_size(zl).to_f
    end

    # Map scale at a specified latitude, zoom level, & screen resolution in dpi
    def map_scale_for_dpi(latitude, zl, screen_dpi)
      pixel_resolution(latitude, zl) * screen_dpi / 0.0254
    end

    # Convert from x,y pixel pair into tile x,y coordinates
    def pixel_xy_to_tile_xy(pixel_x, pixel_y)
      [pixel_x / TILE_PIXEL_SIZE, pixel_y / TILE_PIXEL_SIZE]
    end

    # Convert from x,y tile pair into pixel x,y coordinates (top left corner)
    def tile_xy_to_pixel_xy(tile_x, tile_y)
      [tile_x * TILE_PIXEL_SIZE, tile_y * TILE_PIXEL_SIZE]
    end

    def pixel_xy_zl_to_lng_lat(pixel_x, pixel_y, zl)
      tile_xy_zl_to_lng_lat(pixel_x.to_f / TILE_PIXEL_SIZE, pixel_y.to_f / TILE_PIXEL_SIZE, zl)
    end

    def lng_lat_zl_to_pixel_xy(lng, lat, zl)
      pixel_x = lng_zl_to_tile_xf(lng, zl)
      pixel_y = lat_zl_to_tile_yf(lat, zl)
      [(pixel_x * TILE_PIXEL_SIZE + 0.5).floor, (pixel_y * TILE_PIXEL_SIZE + 0.5).floor]
    end

  end
end
