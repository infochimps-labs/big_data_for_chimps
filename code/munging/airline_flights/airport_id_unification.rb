class Airport

  # [Hash] all options passed to the field not recognized by one of its own current fields
  attr_reader :_extra_attributes

  # Airports whose IATA and FAA codes differ; all are in the US, so their ICAO is "K"+the FAA id
  FAA_ICAO_FIXUP = {
    "GRM" => "CKC", "CLD" => "CRQ", "SDX" => "SEZ", "AZA" => "IWA", "SCE" => "UNV", "BLD" => "BVU",
    "LKE" => "W55", "HSH" => "HND", "BKG" => "BBG", "UST" => "SGJ", "LYU" => "ELO", "WFK" => "FVE",
    "FRD" => "FHR", "ESD" => "ORS", "RKH" => "UZA", "NZC" => "VQQ", "SCF" => "SDL", "JCI" => "IXD",
    "AVW" => "AVQ", "UTM" => "UTA", "ONP" => "NOP", }

  def iata_to_faa
  end

  def lint
    errors = {}
    errors.merge(lint_differences)

    if (icao && iata && (icao =~ /^K.../))
      errors["ICAO != K+FAA yet ICAO is a K..."] = [icao, iata] if (icao != "K#{iata}") && (not IATA_ICAO_FIXUP.include?(iata))
    end

    errors[:spaces] ||= []
    errors[:funny]  ||= []
    attributes.each do |attr, val|
      next if val.blank?
      errors["#{attr} looks blankish"] = val if BLANKISH_STRINGS.include?(val)
      if (val.is_a?(String))
        errors[:spaces] << [attr, val] if  (val.strip != val)
        errors[:funny]  << [attr, val]  if val =~ OK_CHARS_RE
      end
    end
    errors.compact_blank!
  end

  [:iata, :icao, :latitude, :longitude, :country, :city, :name
  ].each do |attr|
    define_method("of_#{attr}"){ @_extra_attributes[:"of_#{attr}"] }
    define_method("de_#{attr}"){ @_extra_attributes[:"de_#{attr}"] }
  end

  def lint_differences
    errors = {}
    return errors unless de_name.present? && of_name.present?
    [
      [:iata, of_iata, de_iata], [:icao, of_icao, de_icao], [:country, of_country, de_country],
      [:city, of_city, de_city],
      [:name, of_name, de_name],
    ].each{|attr, of, de| next unless of && de ; errors[attr] = [of, de] if of != de }

    if (of_latitude && of_longitude && de_latitude && de_longitude)
      lat_diff = (of_latitude  - de_latitude ).abs
      lng_diff = (of_longitude - de_longitude).abs
      unless (lat_diff < 0.015) && (lng_diff < 0.015)
        msg = [of_latitude, de_latitude, of_longitude, de_longitude, lat_diff, lng_diff].map{|val| "%9.4f" % val }.join(" ")
        errors["distance"] = ([msg, of_city, de_city, of_name, de_name])
      end
    end

    errors
  end

  AIRPORTS      = Hash.new # unless defined?(AIRPORTS)
  def self.load(of_filename, de_filename)
    RawOpenflightAirport.load_csv(of_filename) do |raw_airport|
      airport = raw_airport.to_airport
      AIRPORTS[airport.iata_icao] = airport
    end
    RawDataexpoAirport.load_csv(de_filename) do |raw_airport|
      airport = (AIRPORTS[raw_airport.iata_icao] ||= self.new)
      if airport.de_name
        warn "duplicate data for #{[iata, de_iata, icao, de_icao]}: #{raw_airport.to_tsv} #{airport.to_tsv}"
      end
      airport.receive!(raw_airport.airport_attrs)
    end
    AIRPORTS
  end
end
