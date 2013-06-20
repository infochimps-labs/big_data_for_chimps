=== Three legs of the big data stack

A full big data application platform has three pieces: Batch processing for results that require the full dataset; Streaming Analytics to process results as they are created;
Scalable datastore for processing as records are consumed.

 (almost uniformly using Hadoop or equivalent); a Scalable datastore (HBase/Cassandra-like and/or Mongo/ElasticSearch/Couchbase-like); and Stream Analytics (Storm+Trident).



=== Storm



==== Reliability

Storm provides "at least once" processing of data. 

Storm uses an incredibly elegant strategy to track the successful completion in whole of a tuple tree.
The acker task tracks a check 
(TODO: verify -- attempt id combines the tuple's id (`messageId`) and task id)
For each tuple tree. Each execute attempt id is XORed onto the checksum on execute and again on completion.

The XOR function is commutative: `A ^ B == B ^ A`, and the XOR of a number with itself is zero. So if the acker got the events `A_beg, B_beg, A_end, C_beg, C_end, B_end`, the resulting checksum would be `A ^ B ^ A ^ C ^ C ^ B`, which is the same as `A ^ A ^ B ^ B ^ C ^ C` -- which collapses to zero. Without proving the second point, 

* If the tuple tree is processed successfully, each attempt id will appear twice and so the sum must be zero if successful
* If the tuple tree is not -- if some one or more tuples are incorrectly acked -- it is exceedingly unlikely the the checksum will be zero.

This lets Storm process millions of tuples in very little memory or processor.



=== Trident

* Website request vs customer info
* Tweet vs followers
* Activity content vs geo context
* Trade request - risk analysis - hedge - verification
* Document security - patterns of access

=== Locality Models
* RPC - RPC
* Client-server data store
* Streaming Analytics
* Fabric (VCD)
* Batch

* Latency
* Throughput
* Tempo -- how often does data change?
* Size -- how large is record?
* Access control -- security; API rate limits
* Data model -- your web log hit (with path, response time, HTTP status code, etc) is my sales lead.

=== Lambda Architecture

* _Fast data_: recorded live, updates allowed with partial locality or denormalized data
* _Slow data_: gold data, using global data, full answer.



=== Example lambda architecture: online pagerank

* Start with stable pagerank.
* When a new node is discovered, just "borrow" a notional pagerank allocation from its neighbors
* Don't worry about any beyond immediate locality
* Later, batch job re-settles the graph.
* Pagerank calculation is idempotent: within reason, any perturbed input will settle out.
* 

=== locality in stream

* GroupBy / Partitioned aggregates
* DRPC
* Denormalized remote data request
* Hash join -- hold a cached version of table and decorate

==== Why can you get away with 

Storm/Trident has buffering and throttling mechanisms built in

Hadoop is designed to drive all system resources to their full limit until the fundamental limiting resource is encountered. 





a