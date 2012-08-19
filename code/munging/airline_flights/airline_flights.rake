require_relative('../../rake_helper')
require_relative('airport')
require 'pry'

Pathname.register_paths(
  af_data:                  [:data, 'airline_flights'],
  af_work:                  [:work, 'airline_flights'],
  #
  openflights_raw_airports: [:af_data, "openflights_airports-raw#{Settings[:mini_slug]}.csv"   ],
  dataexpo_raw_airports:    [:af_data, "dataexpo_airports-raw#{Settings[:mini_slug]}.csv"      ],
  wikipedia_icao:           [:af_data, "wikipedia_icao.tsv" ],
  wikipedia_iata:           [:af_data, "wikipedia_iata.tsv" ],
  #
  openflights_parsed:       [:af_work, "openflights_airports-parsed#{Settings[:mini_slug]}.tsv"],
  dataexpo_parsed:          [:af_work, "dataexpo_airports-parsed#{Settings[:mini_slug]}.tsv"   ],
  airport_identifiers:      [:af_work, "airport_identifiers.tsv"   ],
  )

chain :airline_flights do
  chain(:parse) do
    # desc 'parse the dataexpo airports'
    # create_file :dataexpo_parsed do |dest|
    #   RawDataexpoAirport.load_csv(:dataexpo_raw_airports) do |raw_airport|
    #     dest << raw_airport.to_airport.to_tsv << "\n"
    #   end
    # end
    #
    # desc 'parse the openflights airports'
    # create_file :openflights_parsed do |dest|
    #   RawOpenflightAirport.load_csv(:openflights_raw_airports) do |raw_airport|
    #     dest << raw_airport.to_airport.to_tsv << "\n"
    #   end
    # end

    desc 'run the identifier resolver'
    file_task(:airport_identifiers,
      # after: [:dataexpo_parsed, :openflights_parsed]
      ) do |dest|
      require_relative 'resolve_identifiers'
      Airport::IdReconciler.load
    end
  end
end

# task :default => 'airline_flights'

task :default => 'airline_flights:parse:airport_identifiers'
