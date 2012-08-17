# -*- coding: utf-8 -*-
require File.expand_path('~/ics/book/big_data_for_chimps/code/munging/airline_flights/airline_flights')

### @export "airport_model"
class Airport
  include Gorillib::Model

  field :airport_ofid, String, doc: "Unique OpenFlights identifier for this airport."
  field :faa,          String, doc: "3-letter FAA code, or blank if not assigned."
  field :iata,         String, doc: "For all other airports, 3-letter IATA code, or blank if not assigned."
  field :icao,         String, doc: "4-letter ICAO code; Blank if not assigned."
  field :utc_offset,   Float,  doc: "Hours offset from UTC. Fractional hours are expressed as decimals, eg. India is 5.5."
  field :dst_rule,     String, doc: "Daylight savings time rule. One of E (Europe), A (US/Canada), S (South America), O (Australia), Z (New Zealand), N (None) or U (Unknown). See the readme for more."
  field :latitude,     Float,  doc: "Decimal degrees, usually to six significant digits. Negative is South, positive is North."
  field :longitude,    Float,  doc: "Decimal degrees, usually to six significant digits. Negative is West,  positive is East."
  field :altitude,     String, doc: "In feet."
  field :country,      String, doc: "Country or territory where airport is located."
  field :state,        String, doc: "State in which the airport is located"
  field :city,         String, doc: "Main city served by airport. May be spelled differently from Name."
  field :name,         String, doc: "Name of airport. May or may not contain the City name."

end
### @export "nil"
class Airport

  EXEMPLARS = %w[
    ANC ATL AUS BDL BNA BOI BOS BWI CLE CLT
    CMH DCA DEN DFW DTW EWR FLL HNL IAD IAH
    IND JAX JFK LAS LAX LGA MCI MCO MDW MIA
    MSP MSY OAK ORD PDX PHL PHX PIT PVD RDU
    SAN SEA SFO SJC SJU SLC SMF STL TPA YYZ ]

  def iata_icao
    [iata, icao].join('-')
  end

  def utc_time_for(tm)
    utc_time  = tm.get_utc + utc_offset
    utc_time += (60*60) if TimezoneFixup.dst?(tm)
    utc_time
  end
end
### @export "nil"

#
# As of January 2012, the OpenFlights Airports Database contains 6977 airports
# [spanning the globe](http://openflights.org/demo/openflights-apdb-2048.png).
# If you enjoy this data, please consider [visiting their page and
# donating](http://openflights.org/data.html)
#
# > Note: Rules for daylight savings time change from year to year and from
# > country to country. The current data is an approximation for 2009, built on
# > a country level. Most airports in DST-less regions in countries that
# > generally observe DST (eg. AL, HI in the USA, NT, QL in Australia, parts of
# > Canada) are marked incorrectly.
#
# Sample entries
#
#     507,"Heathrow","London","United Kingdom","LHR","EGLL",51.4775,-0.461389,83,0,"E"
#     26,"Kugaaruk","Pelly Bay","Canada","YBB","CYBB",68.534444,-89.808056,56,-6,"A"
#     3127,"Pokhara","Pokhara","Nepal","PKR","VNPK",28.200881,83.982056,2712,5.75,"N"
#

### @export "raw_openflight_airport"

#
class RawOpenflightAirport
  include Gorillib::Model
  include Gorillib::Model::LoadFromCsv

  BLANKISH_STRINGS = ["", nil, "NULL", '\\N', "NONE", "NA", "Null", "..."]
  OK_CHARS_RE      = /[^a-zA-Z0-9\ \/\.\,\-\(\)\']/

  field :airport_ofid, String, doc: "Unique OpenFlights identifier for this airport."
  field :name,       String, doc: "Name of airport. May or may not contain the City name."
  field :city,       String, blankish: BLANKISH_STRINGS, doc: "Main city served by airport. May be spelled differently from Name."
  field :country,    String, doc: "Country or territory where airport is located."
  field :iata,       String, blankish: BLANKISH_STRINGS, doc: "3-letter FAA code, for airports located in the USA. For all other airports, 3-letter IATA code, or blank if not assigned."
  field :icao,       String, blankish: BLANKISH_STRINGS, doc: "4-letter ICAO code; Blank if not assigned."
  field :latitude,   Float,  doc: "Decimal degrees, usually to six significant digits. Negative is South, positive is North."
  field :longitude,  Float,  doc: "Decimal degrees, usually to six significant digits. Negative is West,  positive is East."
  field :altitude,   String, doc: "In feet."
  field :utc_offset, Float,  doc: "Hours offset from UTC. Fractional hours are expressed as decimals, eg. India is 5.5."
  field :dst_rule,   String, doc: "Daylight savings time rule. One of E (Europe), A (US/Canada), S (South America), O (Australia), Z (New Zealand), N (None) or U (Unknown). See the readme for more."

  def iata_icao
    [iata, icao].join('-')
  end

  def receive_city(val)
    super.tap{|val| if val then val.strip! ; val.gsub!(/\\+/, '') ; end }
  end

  def receive_country(val)
    super.tap{|val| val.gsub!(/United States/, 'USA') if val }
  end

  def receive_name(val)
    super.tap do |val|
      if val
        val.strip!
        val.gsub!(/\\+/, '')
        val.gsub!(/ Airport$/, '')
        val.gsub!(/\b(Int\'l|International)\b/, 'Intl')
        val.gsub!(/\b(Intercontinental)\b/, 'Intcntl')
        val.gsub!(/\b(Airpt)\b/, 'Airport')
        val.gsub!(/ Airport$/, '')
      end
    end
  end

  def to_airport
    attrs = self.compact_attributes
    # add in an identifiable copy of our values, for comparison
    attrs.keys.each{|attr| attrs[:"of_#{attr}"] = attrs[attr] }
    Airport.receive(attrs)
  end
end

### @export "raw_dataexpo_airport"
class RawDataexpoAirport
  include Gorillib::Model
  include Gorillib::Model::LoadFromCsv
  self.csv_options = self.csv_options.merge(pop_headers: true)

  field :iata,         String, doc: "the international airport abbreviation code"
  field :name,         String, doc: "Airport name"
  field :city,         String, blankish: ["NA"], doc: "city in which the airport is located"
  field :state,        String, blankish: ["NA"], doc: "state in which the airport is located"
  field :country,      String, doc: "country in which airport is located"
  field :latitude,     Float,  doc: "latitude of the airport"
  field :longitude,    Float,  doc: "longitude of the airport"

  def icao
    @icao ||= Airport.fixup(iata)
  end

  def iata_icao
    [iata, icao].join('-')
  end

  def receive_city(val)
    super.tap{|val| val.strip! if val }
  end

  def receive_name(val)
    super.tap do |val|
      if val
        val.gsub!(/\b(Int\'l|International)\b/, 'Intl')
        val.gsub!(/\b(Intercontinental)\b/, 'Intcntl')
        val.gsub!(/\b(Airpt)\b/, 'Airport')
        val.gsub!(/ Airport$/, '')
        val.strip!
      end
    end
  end

  def airport_attrs
    attrs = self.compact_attributes
    # attrs[:icao] = "K#{iata}"
    # add in an identifiable copy of our values, for comparison
    attrs.keys.each{|attr| attrs[:"de_#{attr}"] = attrs[attr] }
    attrs
  end

  def to_airport
    Airport.receive(airport_attrs)
  end
end
### @export "nil"


RawDataexpoAirport.load_csv(Pathname.path_to(:data, 'airline_flights', 'dataexpo_airports-raw-sample.csv')) do |raw_airport|
  airport = Airport.receive(raw_airport.airport_attrs)
  puts airport.to_tsv
end
