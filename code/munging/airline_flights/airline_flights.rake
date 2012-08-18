require 'configliere' ; Settings.use :commandline
require File.expand_path('~/ics/book/big_data_for_chimps/code/munging/airline_flights/airline_flights')
require File.expand_path('~/ics/book/big_data_for_chimps/code/munging/airline_flights/airport')

Settings.define :mini, type: :boolean, default: true, description: "use sample data or full data?"
Settings.resolve!

mini_slug = Settings.mini ? "-sample" : ""
Pathname.register_paths(raw_openflights_airports: [:data, 'airline_flights', "openflights_airports-raw#{mini_slug}.csv"])
Pathname.register_paths(raw_dataexpo_airports:    [:data, 'airline_flights', "dataexpo_airports-raw#{mini_slug}.csv"])

namespace :airports do

  namespace :parse do

    desc 'dump the openflights airports'
    task :openflights do
      RawOpenflightAirport.load_csv(:raw_openflights_airports) do |raw_airport|
        puts raw_airport.to_airport.to_tsv
      end
    end

    desc 'dump the dataexpo airports'
    task :dataexpo do
      RawDataexpoAirport.load_csv(:raw_dataexpo_airports) do |raw_airport|
        puts raw_airport.to_airport.to_tsv
      end
    end

  end

  task :parse => ['parse:dataexpo', 'parse:openflights']
end

# RawDataexpoAirport.load_csv(Pathname.path_to(:data, 'airline_flights', 'dataexpo_airports-raw-sample.csv')) do |raw_airport|
#   airport = Airport.receive(raw_airport.airport_attrs)
#   puts airport.to_tsv
# end

# RawOpenflightAirport.load_csv(Pathname.path_to(:data, 'airline_flights', 'openflights_airports-raw-sample.csv')) do |raw_airport|
#   puts raw_airport.to_airport.to_tsv
# end
