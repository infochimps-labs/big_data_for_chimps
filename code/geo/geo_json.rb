# -*- coding: utf-8 -*-

require 'gorillib/model/serialization/json'
require 'multi_json'

# {"type":"Feature",
#  "id":"3cc54602f2d69c1111dc35f0aaa92240",
#  "geometry":{"type":"Point","coordinates":[42.5,11.5]},
#  "properties":{
#    "geonameid":"223816","country_code":"DJ","admin1_code":"00",
#    "feature_code":"PCLI","feature_class":"A",
#    "asciiname":"Republic of Djibouti","name":"Republic of Djibouti","alternatenames":"Cîbûtî,...",
#    "modification_date":"2011-07-09",
#    "timezone":"Africa/Djibouti","gtopo30":"668","population":"740528"}}


# {"type":"Feature","id":"5b66ac7270763facfe1e9ab9c1bf99f8",
# "geometry":{"type":"Point","coordinates":[-98.5,39.76]},
# "properties":{
# "modification_date":"2011-04-27","_type":"geo/geonames_country",
# "asciiname":"United States","name":"United States","gtopo30":"537","geonameid":"6252001",
# "feature_code":"PCLI","country_code":"US","feature_class":"A",
# "alternatenames":"...","admin1_code":"00","population":"310232863"}}

module Geo


  class Place
    include Gorillib::Model

    field :geonames_id,       String
    field :name,              String
    field :ascii_name,        String
    #
    field :country_id,        String
    field :admin1_id,         String
    field :feature_cat,       String
    field :feature_subcat,    String
    #
    field :timezone,          String
    #
    field :elevation,         Float
    field :longitude,         Float
    field :latitude,          Float
    #
    field :population,        Integer
    field :alternate_names,   String

    def coordinates
      { longitude: longitude, latitude: latitude, elevation: elevation }.compact
    end
  end
  class Country < Place
  end

  class GeonamesPlace
    include Gorillib::Model
    class_attribute :place_klass ; self.place_klass = ::Geo::Place

    field :name,              String
    field :asciiname,         String
    field :geonameid,         String
    field :country_code,      String
    field :admin1_code,       String, blankish: [0, "0", "00", nil, ""]
    field :feature_code,      String
    field :feature_class,     String
    #
    field :modification_date, String
    field :timezone,          String
    #
    field :gtopo30,           Float,   blankish: ["-9999", -9999, nil, ""], doc: "Elevation "
    field :longitude,         Float
    field :latitude,          Float
    #
    field :population,        Integer, blankish: [0, "0", nil, ""]
    field :alternatenames,    String

    def to_place
      attrs = {
        name:            name,
        country_id:      country_code.downcase,
        admin1_id:       admin1_code,
        feature_cat:     feature_class,
        feature_subcat:  feature_code,
        ascii_name:      asciiname,
        # alternate_names: alternatenames,
        updated_at:      modification_date,
        timezone:        timezone,
        elevation:       gtopo30,
        longitude:       longitude,
        latitude:        latitude,
        population:      population,
        geonames_id:     geonameid,
      }
      place_klass.receive(attrs)
    end
  end

  class GeonamesCountry < GeonamesPlace
    self.place_klass = Geo::Country

  end
end

module Wukong
  module Data
    class GeoJson           ; include Gorillib::Model ; end
    class GeoJson::Geometry ; include Gorillib::Model ; end

    class GeoJson
      include Gorillib::Model::LoadFromJson
      include Gorillib::Model::Indexable
      field :type,       String
      field :id,         String
      field :geometry,   GeoJson::Geometry
      field :properties, GenericModel

      def self.load(*args)
        load_json(*args) do |val|
          p val.properties
          p val.properties.to_place
        end
      end

    end

    class GeoJson::Geometry
      field :type,        String
      field :coordinates, Array

      def point?
        type == 'Point'
      end

      def longitude
        return nil if coordinates.blank?
        raise "Longitude only available for Point objects" unless point?
        coordinates[0]
      end
      def latitude
        return nil if coordinates.blank?
        raise "Latitude only available for Point objects" unless point?
        coordinates[1]
      end
    end

    class GeonamesGeoJson < GeoJson
      def receive_properties(hsh)
        p geometry
        if hsh.respond_to?(:merge)
          super(hsh.merge(geo_json_id: id, longitude: geometry.longitude, latitude: geometry.latitude))
        else
          super
        end
      end
    end
  end
end
