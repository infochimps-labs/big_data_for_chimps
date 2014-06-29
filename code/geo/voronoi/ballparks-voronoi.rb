#!/usr/bin/env ruby
require 'gorillib'
require 'gorillib/data_munging'
require 'configliere'
require 'gorillib/pathname'
require_relative('../../models/baseball')

module Sports
  module Baseball
    Park.class_eval do
      include Gorillib::Model::LoadFromTsv
    end
  end
end

# ruby -rwebrick -e'WEBrick::HTTPServer.new(:Port => 8000, :DocumentRoot => Dir.pwd).start' &

park_deduper = {}

Sports::Baseball::Park.load_tsv(
    '~/ics/book/big_data_for_chimps/data/sports/baseball/baseball_databank/parks/parkinfo.tsv',
    null_vals: ['NULL', ''].to_set ) do |park|
  next if (park.lng.blank? || park.lat.blank?)
  next if park.country_id != 'US' || %w{HI PR AK}.include?(park.state_id)

  park_deduper[ [park.lng, park.lat] ] = park;
end
parks = park_deduper.values

dump_fields = [:park_id, :park_name, :beg_date, :end_date, :is_active, :n_games, :lng, :lat, :city, :state_id, :country_id]
File.open("ballparks.tsv", "w") do |parks_csv|
  parks_csv << dump_fields.join("\t") << "\n"
  parks.each do |park|
    parks_csv << park.attributes.values_at(*dump_fields).join("\t") << "\n"
  end
end



# require 'ruby_vor'
# rv_points = points.map{|park_id, park_name, lng, lat, city, state, ctry| RubyVor::Point.new(10*lng, 10*lat) }
# comp = RubyVor::VDDT::Computation.from_points(rv_points)
# puts "The nearest-neighbor graph:"
# p comp.nn_graph
# # puts "\nThe minimum-spanning tree:"
# # p comp.minimum_spanning_tree
# # Voronoi diagram and the triangulation
# RubyVor::Visualizer.make_svg(comp, :name => 'dia.svg', :voronoi_diagram => true)
