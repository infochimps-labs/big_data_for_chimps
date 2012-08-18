require 'configliere' ; Settings.use :commandline
require 'gorillib/model'
require 'gorillib/factories'
require 'gorillib/model/serialization'
require 'gorillib/model/serialization/csv'
require 'gorillib/type/extended'
require 'gorillib/hash/slice'
require 'gorillib/pathname'

Settings.define :mini, type: :boolean, default: true, description: "use sample data or full data?"
Settings.resolve!
mini_slug = Settings.mini ? "-sample" : ""

Pathname.register_paths(
  book_root: '~/ics/book/big_data_for_chimps/',
  code: [:book_root, 'code'],
  data: [:book_root, 'data'],
  work: [:book_root, 'tmp'],
  #
  af_data:                  [:data, 'airline_flights'],
  af_work:                  [:work, 'airline_flights'],
  openflights_raw_airports: [:af_data, "openflights_airports-raw#{mini_slug}.csv"   ],
  dataexpo_raw_airports:    [:af_data, "dataexpo_airports-raw#{mini_slug}.csv"      ],
  openflights_parsed:       [:af_work, "openflights_airports-parsed#{mini_slug}.tsv"],
  dataexpo_parsed:          [:af_work, "dataexpo_airports-parsed#{mini_slug}.tsv"   ],
  )

def create_file(token, options={})
  target     = Pathname.path_to(token)
  target_dir = File.dirname(target.to_s)
  directory(target_dir)
  file target => target_dir  do
    File.open(target, 'wb') do |target_file|
      yield target_file
    end
  end
  task(options[:part_of] => token) if options[:part_of]
  task(token => target)
end

require File.expand_path('~/ics/book/big_data_for_chimps/code/munging/airline_flights/airport')

namespace :airports do
  namespace :parse do

    desc 'dump the dataexpo airports'
    create_file :dataexpo_parsed, part_of: :dataexpo do |parsed_file|
      RawDataexpoAirport.load_csv(:dataexpo_raw_airports) do |raw_airport|
        parsed_file << raw_airport.to_airport.to_tsv << "\n"
      end
    end

    desc 'dump the openflights airports'
    create_file :openflights_parsed, part_of: :openflights do |parsed_file|
      RawOpenflightAirport.load_csv(:openflights_raw_airports) do |raw_airport|
        parsed_file << raw_airport.to_airport.to_tsv << "\n"
      end
    end

  end

  task :parse => ['parse:dataexpo', 'parse:openflights']
end
