require_relative('../../rake_helper')
require_relative('./models')

Pathname.register_paths(
  af_data:                  [:data, 'airline_flights'],
  af_work:                  [:work, 'airline_flights'],
  af_code:                  File.dirname(__FILE__),
  #
  openflights_raw_airports: [:af_data, "openflights_airports-raw#{Settings[:mini_slug]}.csv"   ],
  dataexpo_raw_airports:    [:af_data, "dataexpo_airports-raw#{Settings[:mini_slug]}.csv"      ],
  wikipedia_icao:           [:af_data, "wikipedia_icao.tsv" ],
  wikipedia_iata:           [:af_data, "wikipedia_iata.tsv" ],
  wikipedia_us_abroad:      [:af_data, "wikipedia_us_abroad.tsv" ],
  #
  openflights_parsed:       [:af_work, "openflights_airports-parsed#{Settings[:mini_slug]}.tsv"],
  dataexpo_parsed:          [:af_work, "dataexpo_airports-parsed#{Settings[:mini_slug]}.tsv"   ],
  airport_identifiers:      [:af_work, "airport_identifiers.tsv"   ],
  airport_identifiers_mini: [:af_work, "airport_identifiers-sample.tsv"   ],
  )

chain :airline_flights do
  code_files = FileList[Pathname.of(:af_code, '*airport*.rb').to_s]
  chain(:parse) do
    desc 'parse the dataexpo airports'
    create_file :dataexpo_parsed, after: code_files do |dest|
      RawDataexpoAirport.load_airports(:dataexpo_raw_airports) do |airport|
        dest << airport.to_tsv << "\n"
      end
    end

    desc 'parse the openflights airports'
    create_file :openflights_parsed, after: code_files do |dest|
      RawOpenflightAirport.load_airports(:openflights_raw_airports) do |airport|
        dest << airport.to_tsv << "\n"
      end
    end

    task :reconcile_airports => [:dataexpo_parsed, :openflights_parsed] do
      require_relative 'reconcile_airports'
      Airport::IdReconciler.load_all
    end

    desc 'run the identifier reconciler'
    create_file(:airport_identifiers, after: code_files, invoke: 'airline_flights:parse:reconcile_airports') do |dest|
      Airport::IdReconciler.airports.each do |airport|
        dest << airport.to_tsv << "\n"
        puts airport if airport.faa_controlled? && (airport.icao !~ /^K/) && (airport.faa.blank?)
      end
    end

    desc 'run the identifier reconciler'
    create_file(:airport_identifiers_mini, after: code_files, invoke: 'airline_flights:parse:reconcile_airports') do |dest|
      Airport::IdReconciler.exemplars.each do |airport|
        dest << airport.to_tsv << "\n"
      end
    end

  end
end

# task :default => 'airline_flights'

task :default => [
  # 'airline_flights:parse:dataexpo_parsed',
  # 'airline_flights:parse:openflights_parsed',
  'airline_flights:parse:airport_identifiers',
  # 'airline_flights:parse:airport_identifiers_mini'
]
