#!/usr/bin/env ruby
require 'swineherd/resource'

SCHEMES = [:file, :hdfs, :s3n, :s3hdfs]

module SimpleUnits
  extend self

  KILOBYTE = 1024             unless defined?(KILOBYTE)
  MEGABYTE = 1024 * KILOBYTE  unless defined?(MEGABYTE)
  GIGABYTE = 1024 * MEGABYTE  unless defined?(GIGABYTE)
  TERABYTE = 1024 * GIGABYTE  unless defined?(TERABYTE)

  def to_kilobytes(size)   size and size.to_f / KILOBYTE ; end
  def to_megabytes(size)   size and size.to_f / MEGABYTE ; end
  def to_gigabytes(size)   size and size.to_f / GIGABYTE ; end
  def to_terabytes(size)   size and size.to_f / TERABYTE ; end
  #
  def from_kilobytes(size) size and size.to_f * KILOBYTE ; end
  def from_megabytes(size) size and size.to_f * MEGABYTE ; end
  def from_gigabytes(size) size and size.to_f * GIGABYTE ; end
  def from_terabytes(size) size and size.to_f * TERABYTE ; end
  #
  module HasBytes
    def kb()     SimpleUnits.to_kilobytes(bytes) ; end
    def mb()     SimpleUnits.to_megabytes(bytes) ; end
    def gb()     SimpleUnits.to_gigabytes(bytes) ; end
  end

  MINUTE  = 60                  unless defined?(MINUTE)
  HOUR    = 60       * MINUTE   unless defined?(HOUR)
  DAY     = 24       * HOUR     unless defined?(DAY)
  MONTH   = 29.53059 * DAY      unless defined?(MONTH)
  YEAR    = 365.25   * DAY      unless defined?(YEAR)

  def to_minutes(tm)   tm and tm.to_f / MINUTE ; end
  def to_hours(tm)     tm and tm.to_f / HOUR   ; end
  def to_days(tm)      tm and tm.to_f / DAY    ; end
  def to_years(tm)     tm and tm.to_f / YEAR   ; end
  #
  def from_minutes(tm) tm and tm.to_f * MINUTE ; end
  def from_hours(tm)   tm and tm.to_f * HOUR   ; end
  def from_days(tm)    tm and tm.to_f * DAY    ; end
  def from_years(tm)   tm and tm.to_f * YEAR   ; end
  #
  module HasDuration
    def sec()                            duration  ; end
    def min()     SimpleUnits.to_minutes(duration) ; end
    def hr()      SimpleUnits.to_hours(  duration) ; end
  end

end

class Asset
  include Gorillib::Model
  include SimpleUnits
  include SimpleUnits::HasBytes

  field :name,        Symbol
  field :doc,         String
  field :bytes,       Integer
end

class FileAsset < Asset
  field :path,        Pathname
  field :host,        String
  field :scheme,      Symbol

end

class AssetCollection < Gorillib::ModelCollection
end

class Executor
  include Gorillib::Model

  field :name,          Symbol,  doc: "label for this executor",             position: 0
  #
  field :machine_cost,  Float,   doc: "machine cost per hour",               position: 1
  field :ram,           Float,   doc: "memory, in megabytes, per node",      position: 2
  field :cpus,          Integer, doc: "number of CPUs",                      position: 3
  field :cores,         Integer, doc: "total number of cores",               position: 4
  field :core_speed,    Integer, doc: "nominal speed of each core",          position: 5
  field :network,       Integer, doc: "nominal network speed in megabits/s", position: 6
  field :disk_size,     Integer, doc: "size of disk in megabytes"
  #
  field :machine_count, Integer, doc: "number of machines", default: 1

  def cost_per_hr
    machine_count * machine_cost
  end
  def cost_per_sec()   machine_count * cost_per_hr / SimpleUnits::HOUR   ; end
  def cost_per_min()   cost_per_sec / SimpleUnits::MINUTE ; end
  def cost_per_day()   cost_per_sec / SimpleUnits::DAY    ; end
  def cost_per_month() cost_per_sec / SimpleUnits::MONTH  ; end

  def self.amortized_cost(sale_price, depreciation_years)
    hrs = SimpleUnits.to_hours(SimpleUnits.from_years(depreciation_years.to_f))
    sale_price.to_f / hrs
  end


  class_attribute :examples ; self.examples ||= Hash.new

  examples[:laptop]    = new(:laptop,    amortized_cost(2500, 3), (8*1024), 1, 4, network: 100, disk_size: 500*1024)
  examples[:m1_large]  = new(:m1_large,  0.32, (7.5*1024), 2, 2, 2,   network: 100, disk_size:  850*1024)
  examples[:c1_xlarge] = new(:c1_xlarge, 0.66, (7.0*1024), 4, 8, 2.5, network: 100, disk_size: 1690*1024)

  def self.examples_table
    Formatador.display_compact_table(Executor.examples.values.map{|obj| obj.attributes }, Executor.field_names){0}
  end
end


class RunStats
  include Gorillib::Model
  include SimpleUnits
  include SimpleUnits::HasDuration

  field :input,    Asset,    doc: "asset consumed by this run"
  field :product,  Asset,    doc: "asset produced by this run"
  field :executor, Executor, doc: "context that executed this run: runner, machines, etc."
  #
  field :beg_time, Time,   doc: "Start time"
  field :end_time, Time,   doc: "End time"

  def run(runnable)
    self.beg_time = Time.now
    yield
    self.end_time = Time.now
  end

  def duration
    return nil unless beg_time.present? && end_time.present?
    (end_time - beg_time).to_f
  end

  # @return true if the run is complete
  def reportable?
    !!duration
  end

  def asset(asset_name)
    raise ArgumentError, "asset name must be :input or :output" unless [:input, :output].include?(asset_name)
    read_attribute(asset_name)
  end

  #
  # Derived metrics
  #

  def gb(asset_name)
    asset(asset_name).gb
  end

  def gb_per_min(asset_name) reportable? and gb(asset_name) / min ; end
  def min_per_gb(asset_name) reportable? and 1.0 / gb_per_min(asset_name)     ; end

  def cost
    return unless reportable?
    executor.cost_per_hr * hr
  end
  def cost_per_gb(asset_name)
    reportable? and cost / gb(asset_name)
  end
end

# [:one_gb].map do |asset|
#   asset.copy_to :hdfs_src,   :exists => :ignore
#   asset.copy_to :s3n_src,    :exists => :ignore
#   asset.copy_to :s3hdfs_src, :exists => :ignore
# end
#
# [:one_gb].map do |asset|
#   time_transfer_of :local_src, :local_dest
#   time_transfer_of :local_src, :other_vol_dest
#   time_transfer_of :local_src, :remote_file_dest
#   time_transfer_of :local_src, :hdfs_dest
#   time_transfer_of :local_src, :s3n_dest
#   time_transfer_of :local_src, :s3hdfs_dest
#   #
#   time_transfer_of :hdfs_src,  :local_dest
#   time_transfer_of :hdfs_src,  :hdfs_dest
#   time_transfer_of :hdfs_src,  :s3n_dest
#   time_transfer_of :hdfs_src,  :s3hdfs_dest
#   #
#   time_transfer_of :s3n_src,   :local_dest
#   time_transfer_of :s3n_src,   :hdfs_dest
#   time_transfer_of :s3n_src,   :s3n_dest
#   time_transfer_of :s3n_src,   :s3hdfs_dest
#
# end
