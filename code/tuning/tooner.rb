
module Tooner
  class TuneSet
    include Gorillib::Model
    class_attribute :derivables ; self.derivables = {}

    def self.derived(name, *args, &block)
      derivable = ->() do
        write_attribute(name, instance_eval(&block))
      end
      self.derivables = self.derivables.merge(name => derivable)
      field(*args)
    end

    def self.estimate(name, *args)
      field(name, *args)
    end
  end

  class Filesystem < TuneSet
  end
  class S3fs < Filesystem
  end
  class Hdfs < Filesystem
  end
  class Process < TuneSet
    field   :mem_mb
  end

  class JvmProcess < TuneSet
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

  class Hadoop < TuneSet
    tunable :nn_thread_count, :integer, units: :thread, default: 10, min: 10 do
      ref "Hadoop Operations p 96"
      recommend{ Math.log(machine_count.to_f) * 20 }
    end


    tunable :file_buffer_bytes, default: 4096, recommend: 65536, hadoop_1: 'io.file.buffer.size'

    tunable :fs_block_mb, :integer, units: mb, default: 64, min: 32 do
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

    tunable :balancer_thru_frac
    tunable :balancer_thru,    hadoop_1: 'dfs.balance.bandwidthPerSec'

    derived :mapper_spills       do mapper.out_mb / mapper_sortbuf_data_mem end
    derived :midflight_runtime   do mapper.out_mb  * mapper.compress_frac * network.thru ; end
    derived :mapper_runtime      do mapper.in_mb   * mapper.thru  ; end
    derived :reducer_runtime     do reducer.in_mb  * reducer.thru ; end
    derived :commit_disk_runtime do reducer.out_mb * disk_write.thru ; end
    derived :commit_disk_runtime do reducer.out_mb * network.thru * 2 ; end

    derived :balancer_thru do balancer_thru_frac * network.thru ;  end

    constraint("Machine has sufficient ram") do
      daemons_mem + mappers_mem + reducers_mem < machine_mem_mb
    end

    constraint("Short map tasks are wasteful"){ mapper.completion_time > 60  }
    constraint("Long map tasks are risky"    ){ mapper.completion_time < 900 }
    constraint("Small blocks stress namenode")
    constraint("Large blocks might be wasteful")

    constraint("File buffer size must be a multiple of the system page size")

    constraint("Balancing should not be slow"){           balancer_thru_frac >= 0.05 }
    constraint("Balancing should not compete with work"){ balancer_thru_frac <= 0.1 }

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
