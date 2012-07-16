module Gorillib::Model

  Field.class_eval do
    field :value_for_table, Whatever, doc: "proc to execute to get table-displayable value"
  end

  def table_attributes()
    Hash[self.class.table_fields.map do |fn, fixup|
        fixup = ->(val){ val } if fixup == true
        if fixup.arity == 0
          val = instance_exec(&fixup)
        else
          begin
            val = self.public_send(fn)
            val = fixup.call(val) unless val.nil?
          rescue StandardError => err ; val = '(err)' ; end
        end
        [fn, val]
      end]
  end
  module ClassMethods
    def table_fields() Hash[field_names.map{|x| [x, true]}] ; end
    def table_fixup()  Hash.new ; end
  end
end

Formatador.class_eval do
  def self.models_table(models)
    exemplar = models.first
    display_compact_table(models.map{|obj| obj.table_attributes }, exemplar.class.table_fields.keys){0}
  end
end
