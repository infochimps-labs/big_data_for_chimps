#!/usr/bin/env ruby

require_relative '../rake_helper'
require          'faraday'

Pathname.register_paths(
  images:     [:root, 'images'],
  )

Settings.define :server,     default: 'http://b.tile.stamen.com/toner-lite', description: "Map tile server; anything X/Y/Z.png-addressable works, eg http://b.tile.openstreetmap.org"
Settings.define :zoom_level, type: Integer, description: "Zoom level of tile to fetch. An integer between 0 (world) and 16 or so"

Settings.define :quadkey,    type: String,  description: "Quadkey of tile, eg 002313012."
Settings.define :tile_x,     type: Integer, description: "Tile X index, an integer between 0 and 2^zoom_level - 1"
Settings.define :tile_y,     type: Integer, description: "Tile Y index, an integer between 0 and 2^zoom_level - 1"
Settings.define :longitude,  type: Float,   description: "Longitude (X) of a point on the tile in decimal degrees"
Settings.define :latitude,   type: Float,   description: "Latitude (Y) of a point on the tile in decimal degrees"
