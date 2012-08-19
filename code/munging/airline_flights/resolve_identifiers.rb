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

  def conflicting_attribute!(attr, this_val, that_val)
    case attr
    when :name, :city          then return :pass
    when :latitude, :longitude then return true ############## if (this_val - that_val).abs < 0.03
    end
    super
  end

  def ids
    [:icao, :iata, :faa].hashify{|attr| public_send(attr) }.compact
  end

  def adopt_opinions(that)
    self.opinions = that.opinions + self.opinions
    self.opinions.uniq!
  end
  
end

class RawAirportIdentifier < Airport
  include RawAirport
  def to_airport
    self
  end
  def receive_name(val)
    super.tap{|val| val.gsub!(/\s*\[(military|private)\]/, '')}
  end

  def self.load_airports(filename)
    Tsv.new(filename).map do |vals|
      # next unless EXEMPLARS.include?(vals[1]) || (vals[0][0] == 'K' && EXEMPLARS.include?(vals[0][1..3]))
      self.new({icao: vals[0], iata: vals[1], faa: vals[2], name: vals[3], city: vals[4]}.compact_blank)
    end.compact
  end
end

class Airport

  class IdReconciler
    include Gorillib::Model
    include Gorillib::Model::LoadFromCsv
    include Gorillib::Model::Reconcilable
    self.csv_options = { col_sep: "\t", num_fields: 4..6 }

    field :opinions, Array, default: Array.new

    def ids
      val = opinions.flat_map{|op| op.ids.to_a }
      # p val
      # p val.uniq.compact
      val.uniq.compact
    end
    def icao() ids.assoc(:icao) ;  end
    def iata() ids.assoc(:iata) ;  end
    def faa()  ids.assoc(:faa) ;  end

    def self.load
      RawDataexpoAirport.load_airports(:dataexpo_raw_airports) do |airport|
        register(:dataexpo, airport)
      end
      RawOpenflightAirport.load_airports(:openflights_raw_airports) do |airport|
        register(:openflights, airport)
      end
      RawAirportIdentifier.load_airports(:wikipedia_icao).each do |airport|
        register(:wp_icao, airport)
      end
      RawAirportIdentifier.load_airports(:wikipedia_iata).each do |airport|
        register(:wp_iata, airport)
      end

      # # recs = EXEMPLARS.map{|ex| ID_MAP[:iata][ex] }.uniq
      recs = ID_MAP.map{|attr, hsh| hsh.sort.map(&:last) }.flatten.uniq
      # recs = ID_MAP[:icao].select{|id,obj| id =~ /^K/ }.sort.map(&:last)
      cons = recs.map{|rec| rec.reconcile }
      chars = []
      cons.each do |consensus|
        lint = consensus.lint
        next unless lint.present?
        if lint[:funny]
          chars << lint[:funny].map(&:last).to_s.chars.to_a
        end
        puts "%-79s\t%s" % [lint, consensus.to_s[0..100]]
      end
      puts chars.flatten.uniq.sort.join
    end

    def reconcile
      res = Airport.new
      clean = opinions.all?{|op| res.adopt(op) }
      if clean
        # puts "ok   \t#{res.inspect}"
      else
        puts "confl\t#{res.inspect}"
        puts "     \t#{self.inspect}"
      end
      res
    end

    def adopt_opinions(vals, _)
      self.opinions = vals + self.opinions
      self.opinions.uniq!
    end

    def inspect
      str = "#<#{self.class.name} #{ids}"
      opinions.each{|op| str << "\n\t  #{op._origin}\t#{op.inspect}" }
      str << ">"
    end

    def self.dump_ids(ids)
      "%s\t%s\t%s" % [icao, iata, faa]
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
      reconciler = self.new(opinions: [obj])
      # get the existing objects
      existing   = ids.map{|attr, id| ID_MAP[attr][id] }.compact.uniq
      # reconcile them
      existing.each{|that| reconciler.adopt(that) }

      # save the reconciler under each of the ids.
      reconciler.ids.each{|attr, id| ID_MAP[attr][id] = reconciler }
      # dump_info("1 #{origin}", ids, reconciler, existing)
    end
  end

end
