require_relative('../rake_helper')

Pathname.register_paths(
  data:          '~/ics/book/big_data_for_chimps/data',
  iso_code_data: [:data, 'iso_codes'],
  )

Pathname.register_paths(
  geo_data:                  [:data, 'geo'],
  geo_work:                  [:work, 'geo'],
  geo_code:                  File.dirname(__FILE__),
  #
  iso_3166:                  [:geo_data, 'iso_codes', "iso_3166.tsv"   ],
  geonames_countries:        [:geo_data, 'geonames',  "geonames_countries.json"   ],
  #
  countries:                 [:geo_work, "countries.tsv"   ],
  )

chain :geo do
  code_files = FileList[Pathname.of(:geo_code, '*.rb').to_s]
  chain(:countries) do

    # desc 'load the ISO 3166 countries'
    # task(:countries_iso_3166, after: [code_files, :force]) do |dest|
    #   require_relative('./iso_codes')
    #   p Wukong::Data::CountryCode.for_any_name('Bolivia')
    # end

    desc 'load the Geonames countries'
    task(:geonames_countries
      # , after: [code_files, :force]
      ) do |dest|
      require_relative('./geo_json')
      Wukong::Data::GeonamesGeoJson.load(:geonames_countries)
    end

  end
end

task :default => [
  # 'geo:countries',
  'geo:countries:geonames_countries'
]
