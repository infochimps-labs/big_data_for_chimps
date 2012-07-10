module Gorillib::Model
  def table_attributes()
    Hash[self.class.table_fields.map do |fn|
        val = self.public_send(fn) rescue '(err)'
        val = self.class.table_fixup[fn].call(val) if self.class.table_fixup[fn] && val.present? && (val != '(err)')
        [fn, val]
      end]
  end
  module ClassMethods
    def table_fields() field_names ; end
    def table_fixup()  Hash.new ; end
  end
end

Formatador.class_eval do
  def self.models_table(models)
    exemplar = models.first
    display_compact_table(models.map{|obj| obj.table_attributes }, exemplar.class.table_fields){0}
  end
end
