
There are six and a half shapes of record-oriented datasets:

* Tables,
* Structured objects, 
* Sparse tables,
* Adjacency List Graphs, 
* Edge list / Tuple piles,
* Data frame / tensor
* Blobs

If the details of storing an object or a table as tuples poke though to the programmer, it is a moral failure and everyone who brought this about should feel shame.

Graphs: row key as node id; node metadata as out-of-band cells; into edges as column titles; edge metadata as cell values.