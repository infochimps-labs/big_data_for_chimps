=== Tuning Storm+Trident

* Ensure each stage is always ready to accept records;
* Deliver each processed record promptly to its destination

==== Outline

The first step in tuning a flow is to identify your principal goal: latency, throughput, memory or cost. 
Tuning for cost means balancing the throughput (records/hour per machine) and cost of infrastructure  (amortized $/hour per machine). Once you've chosen the hardware to provision, tuning for cost is equivalent to tuning for throughput, so we'll just discuss latency and throughput as goals. (I'm also going to concentrate on typical latency/throughput, and not on say variance or 99th percentile figures)

Next, identify your dataflow's principal limit, the constraining resource that most tightly bounds the performance of its slowest stage. A dataflow can't pass through more records per second than the cumulative output of its most constricted stage, and it can't deliver records in less end-to-end time than the stage with the longest delay.

The principal limit may be:

* _IO volume_:  there's a hardware limit to the number of bytes per second that a machine's disks or network connection can sustain. Event log processing often involves large amounts of data requiring only parsing or other trivial transformations before storage -- throughput of such dataflows are IO bound.
* _CPU_: a CPU-bound flow spends more time in calculations to process a record 
* _concurrency_: network requests to an external resource often require almost no CPU and minimal volume. If your principal goal is throughput, the flow is only bound by how many network requests you can make in parallel.
* _remote rate limit bound_: alternatively, you may be calling an external resource that imposes a maximum throughput out of your control. A legacy datastore might only be able to serve a certain volume of requests before its performance degrades, or terms-of-service restrictions from a third-party web API (Google's Geolocation API.)
* _memory_: large windowed joins or memory-intensive analytics algorithms may require so much RAM it defines the machine characteristics

Tunables:

* Topology; Little's Law
  - skew
* System: machines; workers/machine, machine sizing; (zookeeper, kafka sizing)
* Throttling: batch size; kafka-partitions; max pending; trident batch delay; spout delay; timeout
* Congestion: number of ackers; queue sizing (exec send, exec recv, transfer); `zmq.threads`
* Memory: Max heap (Xmx), new gen/survivor size; (queue sizes)
* Ulimit, other ntwk sysctls for concurrency and ntwk; Netty vs ZMQ transport; drpc.worker.threads; 
* Other important settings: preferIPv4; `transactional.zookeeper.root` (parent name for transactional state ledger in Zookeeper); `` (java options passed to _your_ worker function), `topology.worker.shared.thread.pool.size` 
* Don't touch: `zmq.hwm` (unless you are seeing unreliable network trnsport under bursty load), disruptor wait strategy, worker receive buffer size

==== Initial tuning

CPU-bound flow

Construct a topology with parallelism one, set max-pending to one, and time the flow through each stage.
Increase the parallelism of CPU-bound stages to nearly saturate the CPU. 
Set the trident batch delay to be comfortably larger than how long a batch takes -- that is, there should be a short additional delay after each batch completes 
Adjust batch sizes to 

* `each()` functions should not care about batch size. 
* `partitionAggregate`
* `partitionPersist` and `partitionQuery

==== Topology

Time each stage independently
The stages upstream of your principal bottleneck should always have records ready to process. The stages downstream should always have capacity to accept and promptly deliver processed records.

==== Provisioning

Use one worker per topology per machine: storm passes tuples directly from sending executor to receiving executor if they're within the same worker. Also set number of ackers equal to number of workers -- the default of one per topology never makes sense (future versions of Storm will fix this).

If you're CPU-bound, set one executor per core for the bounding stage (or one less than cores at large core count). Don't adjust the parallelism without reason -- even a shuffle implies network transfer. Shuffles don't impart any load-balancing.

Match your spout parallelism to its downstream flow. Use the same number of kafka partitions as kafka spouts (or a small multiple). If there are more spouts than kafka machines*kpartitions, the extra spouts will sit idle.

For map states or persistentAggregates -- things where results are accumulated into memory structures -- allocate one stage per worker. Cache efficiency and batch request overhead typically improve with large record set sizes.

In a concurrency bound problem, use very high parallelism 
If possible,  use a QueryFunction to combine multiple queries into a batch request.

===== Little's Law


    Throughput (recs/s) = Capacity / Latency

If all records must pass through a stage that handles 10 records per second, then the flow cannot possibly proceed faster than 10 records per second, and it cannot have latency smaller than 100ms (1/10)

==== Important equations and constants

* Initial records per batch = fetch bytes / avg record size
* Max network throughput


==== Size

Records per batch
If you are using the Kafka spout, this is controlled by max fetch bytes

account for fanout

The executor send buffer shouldn't be outrageously smaller than the record count per batch

JVM Heap size and new gen size. 
* Given the cardinal rule of stream processing (accept records and get rid of them quickly), Trident will be happiest with a large New Gen space. 
* Switch on GC logging
    * The survivor spaces should not overflow after new-gen gcs
    * very few objects promoted to old-gen
    * new gen size must be less than one-half the full heap size
* Your goal: no more than one new-gen GC per 5 seconds, with less than 0.1s pause times; no more than one old-gen GC per 5 minutes, and no full (stop-the-world) GCs seen even under heavy use
* You cannot arbitrarily turn up the heap sizes
    * Heap size larger than about 12-16 GB becomes fairly dangerous. Try as you might, a stop-the-world GC may some dday be necesary -- and the amount of time to sweep that full amount of memory must be less than the relevant timeouts

==== Tempo and Throttling

Max-pending (`TOPOLOGY_MAX_SPOUT_PENDING`) sets the number of tuple trees live in the system at any one time.

Trident-batch-delay (`topology.trident.batch.emit.interval.millis`) sets the maximum pace at which the trident Master Batch Coordinator will issue new seed tuples. It's a cap, not an add-on: if t-b-d is 500ms and the most recent batch was released 486ms, the spout coordinator will wait 14ms before dispensing a new seed tuple. If the next pending entry isn't cleared for 523ms, it will be dispensed immediately. If it took 1400ms, it will also be released immediately -- but no make-up tuples are issued.

Trident-batch-delay is principally useful to prevent congestion, especially around startup. As opposed to a traditional Storm spout, a Trident spout will likely dispatch hundreds of records with each batch. If max-pending is 20, and the spout releases 500 records per batch, the spout will try to cram 10,000 records into its send queue.
