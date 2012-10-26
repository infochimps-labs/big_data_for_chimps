



module Tooner

  class Param
    include Gorillib::Model
    field :hadoop_1_name, String
    field :hadoop_2_name, String
    field :value
  end

  class TuneSet
    include Gorillib::Model
    field :machine_count, Integer, doc: "number of machines in cluster",        units: :machine

    class Machine
      field :mem_mb,         Integer, doc: "total ram on machine",                 units: :mb
      field :cores,          Integer, doc: "number of cores on the machine",       units: :core
      field :v_disk,         Float,   doc: "measured throughput of disk, MB/s",    units: :mb_per_s
      field :v_ntwk,         Float,   doc: "measured throughput of network, MB/s", units: :mb_per_s
      #
      field :data_vol_count, Integer
      field :data_vol
      field :root_vol
      #
      derived :daemons_mem  do dn_mem_mb + tt_mem_mb            ; end
      derived :mappers_mem  do mapper_slots  * mapper_mem_mb    ; end
      derived :reducers_mem do reducer_slots * reducer_mem_mb   ; end

      derived :disk_cap_gb  do data_vol_count * data_vol.cap_gb ; end
      derived :dfs_cap_gb   do disk_cap_gb / fs_replication     ; end
    end

    class Cluster
      derived :mappers_mem      do machines_count * machine.mappers_mem  ; end
      derived :reducers_mem     do machines_count * machine.reducers_mem ; end
      derived :dfs_cap_gb       do machines_count * machine.dfs_cap_gb   ; end
      derived :disk_cap_gb      do machines_count * machine.disk_cap_gb  ; end
      derived :dfs_block_count  do (1024 * dfs_cap_gb) / fs_block_mb     ; end
    end

    class Filesystem
    end
    class S3fs < Filesystem
    end
    class Hdfs < Filesystem
    end

    class Process
      field   :mem_mb
    end

    class JvmProcess
      tunable :log_profiling, doc: 'true to record performance profiling information'
      tunable :log_gc,        doc: 'true to record garbage collection events'
      #
      estimate :overhead_mb
      tunable :max_newgen_mb
      tunable :max_heap_mb
      tunable :max_stack_mb
      derived :mem_mb do max_heap_mb + max_stack_mb + max_newgen_mb + overhead_mb ; end
      #
      derived :child_java_opts do
        opts = [ "-Xmx#{heap_mem_mb}", ]
        if task_profile then opts << " -Xprof -verbose:gc -Xloggc:/tmp/hdp-task-gc-@taskid@.log" ; end
        # -agentlib:hprof=cpu=samples,interval=1,file=<outputfilename>
        # if enable_jmx   then opts << "-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=#{node[:hadoop][:jmx_dash_addr]} -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false" ; end
      end
    end

    class Phase
      estimate :in_mb,        units: :mb
      estimate :in_recs,      units: :rec
      estimate :expansion,    units: :mult
      derived  :out_mb     do (in_mb   * expansion) end
      derived  :out_recs   do (in_recs * expansion) end
      #
      estimate :tp,           doc: "throughput, MB/s", units: :mb_per_s

      estimate :compression_frac, units: :mult, default: 0.3
      #
      derived  :runtime, units: :second
    end

    class MapperPhase < Phase
    end

    class MidflightPhase < Phase
    end

    class ReducerPhase < Phase
      derived(:in_mb){   mapper.out_mb   * mapper_tasks / reducer_tasks }
      derived(:in_recs){ mapper.out_recs * mapper_tasks / reducer_tasks }
      #
      tunable :heap_mem_mb
      tunable :sort_pt1_mem_frac,      hadoop_1: 'mapred.job.shuffle.input.buffer.percent'
      tunable :sort_pt1_spill_segs,    hadoop_1: 'mapred.inmem.merge.threshold', default: 1000, recommend: 0
      tunable :sort_pt1_wtf_frac,      hadoop_1: 'mapred.job.shuffle.merge.percent'
      tunable :sort_pt2_mem_frac,      hadoop_1: 'mapred.job.reduce.input.buffer.percent', default: 0.0
      #
      tunable :sort_pt1_seg_count,     hadoop_1: 'io.sort.factor'
      tunable :sort_pt1_parl,          hadoop_1: 'mapred.reduce.parallel.copies'
      #
      derived :sort_pt1_mem_mb do
        sort_pt1_mem_frac * [2048, heap_mem_mb].min
      end
      #
    end

    class CommitPhase < Phase
    end

    tunable :nn_thread_count, Integer, units: :thread, default: 10, min: 10 do
      ref "Hadoop Operations p 96"
      recommend{ Math.log(machine_count.to_f) * 20 }
    end

    tunable :mapper_min_split_mb, hadoop_1: 'mapred.min.split.size', cat: :mapper_mem
    #
    tunable :mapper_sortbuf_acct_mem,   cat: :mapper_mem
    tunable :mapper_sortbuf_data_mem,   cat: :mapper_mem
    tunable :mapper_sortbuf_total_mem,  hadoop_1: 'io.sort.mb', cat: :mapper_mem
    tunable :mapper_sortbuf_acct_frac,  hadoop_1: 'io.sort.record.percent', default: 0.05 do
      mapper_sortbuf_acct_mem / mapper_sortbuf_total_mem
    end
    tunable :mapper_sortbuf_spill_frac, hadoop_1: 'io.sort.spill.percent', default: 0.8
    #
    derived :mapper_overhead_mem, todo: true

    tunable :file_buffer_bytes, default: 4096, recommend: 65536, hadoop_1: 'io.file.buffer.size'

    tunable :fs_block_mb, Integer, units: mb, default: 64, min: 32 do
      ref "Hadoop Operations p 95"
      ref "Big Data for Chimps -- Tuning"
      cluster 128
    end

    tunable :reducer_launch_frac, hadoop_1: 'mapred.reduce.slowstart.completed.maps'
    tunable :mapper_speculative,  hadoop_1: 'mapred.map.tasks.speculative.execution'
    tunable :reducer_speculative, hadoop_1: 'mapred.reduce.tasks.speculative.execution'

    tunable :dn_heap_mem_mb
    tunable :tt_heap_mem_mb
    tunable :nn_heap_mem_mb
    tunable :jt_heap_mem_mb

    tunable :balancer_tp_frac
    tunable :balancer_tp,    hadoop_1: 'dfs.balance.bandwidthPerSec'

    derived :mapper_spills       do mapper.out_mb / mapper_sortbuf_data_mem end
    derived :midflight_runtime   do mapper.out_mb  * mapper.compression_frac * network.tp ; end
    derived :mapper_runtime      do mapper.in_mb   * mapper.tp  ; end
    derived :reducer_runtime     do reducer.in_mb  * reducer.tp ; end
    derived :commit_disk_runtime do reducer.out_mb * disk_write.tp ; end
    derived :commit_disk_runtime do reducer.out_mb * network.tp * 2 ; end

    derived :balancer_tp do balancer_tp_frac * network.tp ;  end

    constraint("Machine has sufficient ram") do
      daemons_mem + mappers_mem + reducers_mem < machine_mem_mb
    end

    constraint("Short map tasks are wasteful"){ mapper.completion_time > 60  }
    constraint("Long map tasks are risky"    ){ mapper.completion_time < 900 }
    constraint("Small blocks stress namenode")
    constraint("Large blocks might be wasteful")

    constraint("File buffer size must be a multiple of the system page size")

    constraint("Balancing should not be slow"){           balancer_tp_frac >= 0.05 }
    constraint("Balancing should not compete with work"){ balancer_tp_frac <= 0.1 }

    constraint("sufficient mapper heap"){  mapper_sort_buffer_mem + mapper_overhead_mem }
    constraint("only spill once"){ mapper_spills < mapper_sortbuf_spill_frac }

    constraint("replication allows data-local map tasks"){ fs_replication >= 2 }
    constraint("replication provides durability"){ fs_replication >= 3 }
    constraint("fast commit phase"){ fs_replication <= 3 }

    constraint("Jobtracker heap memory accommodates task count")
    constraint("Namenode heap memory accommodates block count")
    constraint("Namenode heap memory accommodates file count")

    confirmplz("DFS striped, and not stored on root")
    confirmplz("Mapred scratch files striped and not stored on root")
    confirmplz("Log files not stored on root")

  end
end
