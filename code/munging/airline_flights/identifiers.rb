require_relative './models'

class Airport
  class WpAirportId
    field :icao,         String
    field :iata,         String
    field :faa,          String
    field :name,         String
    field :location,     String
    field :notes,        String
  end

  class IdReconciler
    include Gorillib::Model
    include Gorillib::Model::LoadFromCsv

    self.csv_options = { col_sep: "\t", num_fields: 4..6 }

    field :openflights, Airport
    field :dataexpo,    Airport
    field :wp_icao,     Airport
    field :wp_iata,     Airport

    def accept_attribute(attr, val)
      if attribute_set?(attr)
        warn "Duplicate values for #{attr}: have #{self.read_attribute(attr)}, skipping #{val}"
        return(val)
      end
      write_attribute(attr, val)
    end

    ID_MAP = { icao: {}, iata: {}, faa: {} }
    # given a set of id keys:
    # * find any reconcilers existing for those keys
    # *
    #
    # Suppose our dataset has 3 identifiers, which look like
    #
    #     a
    #          Q
    #     b    S
    #          S    88
    #     a    Q    77
    #
    def self.register(obj)
      [:icao, :iata, :faa].each do |id_attr|
        id = obj.read_attribute(id_attr) or next
        # ID_MAP[attr][id] ||= self.new
      end
    end
  end

  module Reconcile

    def self.load(dirname)
      load_csv(File.join(dirname, 'wikipedia_icao.tsv')) do |id_mapping|
        [:icao, :iata, :faa ].each do |attr|
          val = id_mapping.read_attribute(attr) or next
          next if (val == '.') || (val == '_')
          if that = ID_MAPPINGS[attr][val]
            lint = that.disagreements(id_mapping)
            puts [attr, val, "%-25s" % lint.inspect, id_mapping, that, "%-60s" % id_mapping.name, "%-25s" % that.name].join("\t") if lint.present?
          else
            ID_MAPPINGS[attr][val] = id_mapping
          end
        end
        # [:icao, :iata, :faa ].each do |attr|
        #   val = id_mapping.read_attribute(attr)
        #   ID_MAPPINGS[attr][val] = id_mapping
        # end
      end
      load_csv(File.join(dirname, 'wikipedia_iata.tsv')) do |id_mapping|
        # if not ID_MAPPINGS[:icao].has_key?(id_mapping.icao)
        #   puts [:badicao, "%-25s" % "", id_mapping, " "*24, "%-60s" % id_mapping.name].join("\t")
        # end
        [:icao, :iata, :faa ].each do |attr|
          val = id_mapping.read_attribute(attr) or next
          next if (val == '.') || (val == '_')
          if that = ID_MAPPINGS[attr][val]
            lint = that.disagreements(id_mapping)
            puts [attr, val, "%-25s" % lint.inspect, id_mapping, that, "%-60s" % id_mapping.name, "%-25s" % that.name].join("\t") if lint.present?
          else
            ID_MAPPINGS[attr][val] = id_mapping
          end
        end
      end

    # def adopt_field(that, attr)
    #   this_val = self.read_attribute(attr)
    #   that_val = that.read_attribute(attr)
    #   if name =~ /Bogus|Austin/i
    #     puts [attr, this_val, that_val, attribute_set?(attr), that.attribute_set?(attr), to_tsv, that.to_tsv].join("\t")
    #   end
    #   if    this_val && that_val
    #     if (this_val != that_val) then warn [attr, this_val, that_val, name].join("\t") ; end
    #   elsif that_val
    #     write_attribute(that_val)
    #   end
    # end

    def to_s
      attributes.values[0..2].join("\t")
    end

    def disagreements(that)
      errors = {}
      [:icao, :iata, :faa ].each do |attr|
        this_val = self.read_attribute(attr) or next
        that_val = that.read_attribute(attr) or next
        next if that_val == '.' || that_val == '_'
        errors[attr] = [this_val, that_val] if this_val != that_val
      end
      errors
    end

  end
end
