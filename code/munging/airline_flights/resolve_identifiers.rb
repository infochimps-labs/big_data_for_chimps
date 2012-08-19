require_relative './models'
require 'gorillib/model/reconcilable'
require 'gorillib/array/hashify'

class Tsv
  attr_reader :filename

  def initialize(filename)
    @filename = Pathname.of(filename)
  end

  def file
    @file ||= File.open(filename)
  end
  def file? ; !! @file ; end

  def each
    file.each do |line|
      yield line.chomp.split("\t")
    end
    nil
  end

  def map
    acc = []
    each{|line| acc << yield(line) }
    acc
  end
end

class Airport
  include Gorillib::Model::Reconcilable
  include Gorillib::Model::LoadFromCsv

  attr_accessor :_origin # source of the record

  # def conflicting_attribute!(attr, *args)
  #   return if []
  #   super
  # end

  def ids
    [:icao, :iata, :faa].hashify{|attr| public_send(attr) }.compact
  end

  def self.load_identifier_file(origin, filename)
    Tsv.new(filename).map do |vals|
      next unless EXEMPLARS.include?(vals[1]) || (vals[0][0] == 'K' && EXEMPLARS.include?(vals[0][1..3]))
      self.new({icao: vals[0], iata: vals[1], faa: vals[2], name: vals[3], city: vals[4]}.compact_blank)
    end.compact
  end

  def self.load_dataexpo(filename)
    RawDataexpoAirport.load_csv(filename) do |raw_airport|
      yield raw_airport.to_airport
    end
  end
  
  def self.load_openflights(filename)
    RawOpenflightAirport.load_csv(filename) do |raw_airport|
      yield raw_airport.to_airport
    end
  end
end

class Airport

  class IdReconciler
    include Gorillib::Model
    include Gorillib::Model::LoadFromCsv
    include Gorillib::Model::Reconcilable
    self.csv_options = { col_sep: "\t", num_fields: 4..6 }

    def initialize(*opinions)
      @opinions = Set.new(opinions)
    end

    def ids
      opinions.inject({}){|acc,el| acc.merge!(el.ids) }
    end
    def icao() ids[:icao] ;  end
    def iata() ids[:iata] ;  end
    def faa()  ids[:faa] ;  end

    def self.load
      Airport.load_dataexpo(:dataexpo_raw_airports) do |airport|
        register(:dataexpo, airport)
      end
      Airport.load_openflights(:openflights_raw_airports) do |airport|
        register(:openflights, airport)
      end
      
      airports_icao = Airport.load_identifier_file(:wikipedia_icao)
      airports_iata = Airport.load_identifier_file(:wikipedia_iata)

      airports_icao.each do |airport|
        register(:wp_icao, airport)
      end
      airports_iata.each do |airport|
        register(:wp_iata, airport)
      end

      EXEMPLARS.each do |ex|
        rec = ID_MAP[:iata][ex]
        p rec
        rec.opinions.each{|op| puts "%s\t%s" % [op._origin, op] }
      end
    end


    def reconcile_opinions(that_val)
      self.opinions += that_val
    end
    
    def to_inspectable
      { ids: ids }.merge(super)
    end

    # def adopt_attribute(attr, val)
    #   p ['adopt', self, attr, val]
    # end

    def self.dump_ids(ids)
      "%s\t%s\t%s" % [ids[:icao], ids[:iata], ids[:faa]]
    end
    def self.dump_mapping
      [:icao, :iata, :faa].map do |attr|
        "%-50s" % ID_MAP[attr].to_a.sort.map{|id, val| "#{id}:#{val.icao||'    '}|#{val.iata||'   '}|#{val.faa||'   '}"}.join(";")
      end
    end

    def self.dump_info(kind, ids, reconciler, existing, *args)
      ex_str = [existing.map{|el| dump_ids(el.ids) }, "\t\t","\t\t","\t\t"].flatten[0..2]
      puts [kind, dump_ids(ids), dump_ids(reconciler.ids), ex_str, *args, dump_mapping.join("//") ].flatten.join("\t| ")
    end

    ID_MAP = { icao: {}, iata: {}, faa: {} }
    # given a set of id keys:
    # * find any reconcilers existing for those keys
    # *
    #
    # Suppose our dataset has 3 identifiers, which look like
    #
    #     a    S
    #          S    88
    #     a    Z
    #     b
    #          Q
    #     b    Q    77
    #
    def self.register(origin, obj)
      obj._origin = origin
      ids = obj.ids
      reconciler = self.new(obj)
      # get the existing objects
      existing   = ids.map{|attr, id| ID_MAP[attr][id] }.compact.uniq
      # reconcile them
      existing.each{|that| reconciler.adopt(that) }

      # save the reconciler under each of the ids.
      ids.each{|attr, id| ID_MAP[attr][id] = reconciler }
      # dump_info("1 #{origin}", ids, reconciler, existing)
    end
  end

end
