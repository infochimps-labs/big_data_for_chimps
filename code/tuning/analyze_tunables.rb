#!/usr/bin/env ruby
require 'yaml'
require 'gorillib/model'
require 'gorillib/hash/mash'
require 'multi_json'
require 'gorillib/builder'
require 'gorillib/model/serialization'

class Gorillib::Model::Field
  field :units,     :symbol
  field :hadoop_1,  :string
  field :min,       Whatever
  field :max,       Whatever
  field :recommend, Whatever
end

module Units
  extend self
  KB = KiB   = 2**10
  MB = MiB   = 2**20
  GB = GiB   = 2**30
  TB = TiB   = 2**40

  def quantified_bytes(val)
    return val.to_int if val.respond_to?(:to_int)
    case val
    when /\A(\d+)[kK]\z/ then Integer($1) * KiB
    when /\A(\d+)[mM]\z/ then Integer($1) * MiB
    when /\A(\d+)[gG]\z/ then Integer($1) * GiB
    when /\A(\d+)[tT]\z/ then Integer($1) * TiB
    when /\A(\d+)\z/     then Integer($1)
    else val
    end
  end
end

class Tunable
  include Gorillib::Builder

  def self.derived(name, type=Whatever, opts={}, &block)
    field(name, type, opts.merge(default: block))
  end
end

class Component < Tunable
  field :cluster,      :string
  field :facet,        :string
  field :facet_index,  :integer
  field :node_name,    :string
  field :public_ip,    :string
  field :private_ip,   :string
end

class RackTopology < Tunable
  field :fake_topology,   :boolean
  field :fake_rack_size,  :integer
end

class Cluster < Tunable
  attr_accessor :owner
  field :namenodes,     Array, of: Component
  field :secondarynns,  Array, of: Component
  field :jobtrackers,   Array, of: Component
  field :datanodes,     Array, of: Component
  field :tasktrackers,  Array, of: Component
  field :topology,      RackTopology

  def components() [namenodes, secondarynns, jobtrackers, datanodes, tasktrackers].flatten ; end

  def machines
    components.map{|comp| comp.attributes.slice(:node_name) }.uniq
  end
  def machine_count() machines.length ; end

  def machine
    owner
  end

  # derived :machine_count, :integer, doc: "number of machines in cluster" do machines.length ; end
  # derived :mappers_mem     do machine_count * machine.mappers_mem  ; end
  # derived :reducers_mem    do machine_count * machine.reducers_mem ; end
  # derived :dfs_cap_gb      do machine_count * machine.dfs_cap_gb   ; end
  # derived :disk_cap_gb     do machine_count * machine.disk_cap_gb  ; end
  # derived :dfs_block_count do (1024 * dfs_cap_gb) / fs_block_mb     ; end
end

class HadoopDaemon < Tunable
  include Gorillib::Model
  field :dash_port,     :integer
  field :jmx_dash_port, :integer
  field :run_state,     :boolean
  field :java_heap_size_max, :string

  def receive_java_heap_size_max(val) super(Units.quantified_bytes(val)) ; end
end

class NamenodeDaemon  < HadoopDaemon
  field :ipc_port,     :integer
end
class SecondarynnDaemon < HadoopDaemon
  field :ipc_port,     :integer
end
class JobtrackerDaemon < HadoopDaemon
  field :ipc_port,     :integer
end
class DatanodeDaemon < HadoopDaemon
  field :ipc_port,     :integer
  field :xcvr_port,     :integer
end
class TasktrackerDaemon < HadoopDaemon
end

class Daemons < Tunable
  field :namenode,    NamenodeDaemon
  field :secondarynn, SecondarynnDaemon
  field :jobtracker,  JobtrackerDaemon
  field :datanode,    DatanodeDaemon
  field :tasktracker, TasktrackerDaemon
end

class Machine < Tunable
  field :ipaddress,                  :string,  units: '',             hadoop_1: ''
  field :fqdn,                       :string,  units: '',             hadoop_1: ''
  field :private_ips, :array, of: :string
  field :public_ips,                 :array, of: :string

  field :home_dir,                   :string,                         hadoop_1: ''
  field :conf_dir,                   :string,                         hadoop_1: ''
  field :log_dir,                    :string,                         hadoop_1: ''
  field :pid_dir,                    :string,                         hadoop_1: ''

  field :ram,                        :integer, units: 'byte'
  field :cores,                      :integer, units: 'byte'

  # field :mem_mb,                   :integer, doc: "total ram on machine",                 units: :mb
  # field :cores,                    :integer, doc: "number of cores on the machine",       units: :core
  # field :v_disk,                   :float,   doc: "measured throughput of disk, MB/s",    units: :mb_per_s
  # field :v_ntwk,                   :float,   doc: "measured throughput of network, MB/s", units: :mb_per_s
  # field :data_vol_count,           :integer
  # field :data_vol
  # field :root_vol
end

class Dfs < Tunable
  field :s3_block_size,              :integer, units: 'byte',         hadoop_1: ''
  field :hdfs_block_size,            :integer, units: 'byte',         hadoop_1: ''
  field :dfs_replication,            :integer,                        hadoop_1: ''
  field :file_buffer_size,           :integer, units: 'byte',         hadoop_1: ''
end

class Phase < Tunable
  derived :in_mb,                    :integer
  field :expansion_frac,             :float,   units: 'frac', default: 1.25, doc: "Leaves room for mapper tasks whose output is larger than their input"
  derived :out_mb,                   :float   do (in_mb   * expansion) end
  derived :out_recs,                 :float   do (in_recs * expansion) end
  #
  field :thru,                       :float,  units: :mb_per_s, doc: "throughput, MB/s"

  field :compress_frac,              :float, units: :mult, default: 0.3
  #
  derived                            :runtime,      :float, units: :second
end

class Mapred < Tunable
  # Mapper tuning
  field :io_sort_mb,                 :integer, units: 'megabyte',     hadoop_1: 'io.sort.mb'
  field :io_sort_record_frac,        :float,   units: 'frac',         hadoop_1: 'io.sort.record.percent', default: 0.15
  field :io_sort_spill_frac,         :float,   units: 'frac',         hadoop_1: 'io.sort.spill.percent',  default: 0.80
  field :min_split_size,             :integer, units: 'byte',         hadoop_1: 'mapred.min.split.size',  default: (100 * Units::MiB)

  field :mapper_sortbuf_acct_mem,    :integer
  field :mapper_sortbuf_data_mem,    :integer
  field :mapper_sortbuf_acct_frac,   :integer do
    mapper_sortbuf_acct_mem / mapper_sortbuf_total_mem
  end

  # Reducer tuning
  field :io_sort_factor,             :integer, units: '',             hadoop_1: 'io.sort.factor'
  field :shuffle_heap_frac,          :float,   units: '',             hadoop_1: 'mapred.job.shuffle.input.buffer.percent'
  field :shuffle_merge_frac,         :float,   units: '',             hadoop_1: 'mapred.job.shuffle.merge.percent', default: 0.66
  field :reduce_heap_frac,           :float,   units: '',             hadoop_1: 'mapred.job.reduce.input.buffer.percent'
  field :reducer_parallel_copies,    :integer, units: '',             hadoop_1: 'mapred.reduce.parallel.copies'

  # Child jobs
  field :max_map_tasks,              :integer,                        hadoop_1: 'mapred.tasktracker.map.tasks.maximum'
  field :max_reduce_tasks,           :integer,                        hadoop_1: 'mapred.tasktracker.reduce.tasks.maximum'
  field :map_heap_mb,                :integer, units: 'megabyte'
  field :reduce_heap_mb,             :integer, units: 'megabyte'
  field :java_child_ulimit,          :integer, units: 'byte',         hadoop_1: 'mapred.child.ulimit'
  field :java_child_opts,            :string,                         hadoop_1: 'mapred.child.java.opts'
  field :java_map_opts,              :string,                         hadoop_1: 'mapred.map.child.java.opts'
  field :java_reduce_opts,           :string,                         hadoop_1: 'mapred.reduce.child.java.opts'

  # Compression
  field :compress_mapout_codec,      :string,                         hadoop_1: 'mapred.output.compress.codec'
  field :compress_output_codec,      :string,                         hadoop_1: 'mapred.map.output.compression.codec'
  field :codecs,                     :array, of: :string,             hadoop_1: 'io.compression.codecs'

  # Scheduling
  field :map_speculative_exec,       :boolean, units: '',             hadoop_1: 'mapred.map.tasks.speculative.execution'
  field :reduce_speculative_exec,    :boolean, units: '',             hadoop_1: 'mapred.reduce.tasks.speculative.execution<'
  field :slowstart_frac,             :float,   units: 'frac',         hadoop_1: 'mapred.reduce.slowstart.completed.maps'
  field :task_scheduler,             :string,  units: '',             hadoop_1: 'mapred.jobtracker.taskScheduler'

  # Ergonomics
  field :trash_interval,             :integer, units: 'minute',       hadoop_1: 'fs.trash.interval'
  field :dashboard_is_admin,         :boolean, units: '',             hadoop_1: 'webinterface.private.actions'
  field :balancer_max_bandwidth,     :integer, units: 'byte_per_sec', hadoop_1: 'dfs.balance.bandwidthPerSec'
end

class MidflightPhase < Phase
  field :compress_codec,          :string,                            hadoop_1: 'mapred.map.output.compression.codec'
  field :compress_on,             :boolean,                           hadoop_1: 'mapred.compress.map.output'
end

class ReducerPhase < Phase
  derived(:in_mb,                    :integer){   mapper.out_mb   * cluster.mapper_tasks / cluster.reducer_tasks }
  derived(:in_recs, :integer){ mapper.out_recs * cluster.mapper_tasks / cluster.reducer_tasks }
  #
  field :heap_mem_mb,                :integer
  field :sort_pt1_mem_frac,          :float,                          hadoop_1: 'mapred.job.shuffle.input.buffer.percent'
  field :sort_pt1_spill_segs,        :integer,                        hadoop_1: 'mapred.inmem.merge.threshold', default: 1000, recommend: 0
  field :sort_pt1_wtf_frac,          :float,                          hadoop_1: 'mapred.job.shuffle.merge.percent'
  field :sort_pt2_mem_frac,          :float,                          hadoop_1: 'mapred.job.reduce.input.buffer.percent', default: 0.0
  #
  field :sort_pt1_seg_count,         :integer,                        hadoop_1: 'io.sort.factor'
  field :sort_pt1_parl,              :integer,                        hadoop_1: 'mapred.reduce.parallel.copies'
  #
  derived :sort_pt1_mem_mb,          :integer do
    sort_pt1_mem_frac * [2048, heap_mem_mb].min
  end
  #
end

class OutputPhase < Phase
  field :compress_codec,  :string,                                    hadoop_1: 'mapred.output.compression.codec'
  field :compress_type,   :string,                                    hadoop_1: 'mapred.output.compression.type'
  field :compress_on,     :boolean,                                   hadoop_1: 'mapred.output.compress'
end

class HadoopConfig < Tunable

  member :cluster, Cluster
  field :machine, Machine
  field :daemons, Daemons

  field :dfs,     Dfs
  field :mapred,  Mapred

  def daemon_ram
    daemons.map{|dm| tunables[dm][:java_heap_size_max] }
  end

  def mapper_total_ram()
  end

  # derived :daemons_mem     do dn_mem_mb + tt_mem_mb            ; end
  # derived :mappers_mem     do mapred.max_map_tasks    * mapred.map_heap_mb    ; end
  # derived :reducers_mem    do mapred.max_reduce_tasks * mapred.reduce_heap_mb   ; end
  #
  # derived :disk_cap_gb     do data_vol_count * data_vol.cap_gb ; end
  # derived :dfs_cap_gb      do disk_cap_gb / fs_replication     ; end

  def receive_cluster(*args, &block)
    super.tap{|val| if val.is_a?(Cluster) then val.owner = self ; end }
  end
end

tunables = YAML.load(File.read('/foo/hadoop-tunables.yaml'))
config = HadoopConfig.receive(tunables)

puts MultiJson.dump(config.to_wire, pretty: true)
puts config.cluster.owner
