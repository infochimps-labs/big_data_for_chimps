# Chapter 8: Advanced Pig

## Advanced Join Fu

Pig has three special-purpose join strategies: the "map-side" (aka 'fragment replicate') join 

The map-side join have strong restrictions on the properties 

A dataflow designed to take advantage of them 
can produce order-of-magnitude scalability improvements.

They're also a great illustration of three key scalability patterns.
Once you have a clear picture of how these joins work,
you can be confident you understand the map/reduce paradigm deeply.

### Map-side Join

A map-side (aka 'fragment replicate') join

#### How a map-side join works

(explanation) 

#### Example: map-side join of wikipedia page metadata with wikipedia pageview stats

### Merge Join

#### How a merge join works

(explanation) 

Quoting Pig docs:

> "You will also see better performance if the data in the left table is partitioned evenly across part files (no significant skew and each part file contains at least one full block of data)."

#### Example: merge join of user graph with page rank iteration

### Skew Join

(explanation of when needed)

#### How a skew join works

(explanation how)

#### Example: ? counting triangles in wikipedia page graph ? OR ? Pageview counts ?


## Efficiency and Scalability


### Do's and Don'ts

The Pig Documentation has a comprehensive section on [Performance and Efficiency in Pig](http://pig.apache.org/docs/r0.9.2/perf.html). We won't try to improve on it, but here are some highlights:

* As early as possible, reduce the size of your data:
  - LIMIT
  - Use a FOREACH to reject unnecessary columns
  - FILTER

* Filter out `Null`s before a join
  in a join, all the records rendezvous at the reducer
  if you reject nulls at the map side, you will reduce network load

### Join Optimizations

> "Make sure the table with the largest number of tuples per key is the last table in your query. 
>  In some of our tests we saw 10x performance improvement as the result of this optimization.
>
>      small = load 'small_file' as (t, u, v);
>      large = load 'large_file' as (x, y, z);
>       C = join small by t, large by x;

(explain why)

(come up with a clever mnemonic that doesn't involve sex, or get permission to use the mnemonic that does.)

### Magic Combiners


### Turn off Optimizations

After you've been using Pig for a while, you might enjoy learning about all those wonderful optimizations, but it's rarely necessary to think about them.

In rare cases, 
you may suspect that the optimizer is working against you 
or affecting results.

To turn off an optimization

      TODO: instructions

### Exercises

1. Quoting Pig docs:
  > "You will also see better performance if the data in the left table is partitioned evenly across part files (no significant skew and each part file contains at least one full block of data)."

  Why is this?
  
2. Each of the following snippets goes against the Pig documentation's recommendations in one clear way. 
  - Rewrite it according to best practices
  - compare the run time of your improved script against the bad version shown here.
  
  things like this from http://pig.apache.org/docs/r0.9.2/perf.html --

  a. (fails to use a map-side join)
  
  b. (join large on small, when it should join small on large)
  
  c. (many `FOREACH`es instead of one expanded-form `FOREACH`)
  
  d. (expensive operation before `LIMIT`)

For each use weather data on weather stations.


## Pig and HBase

TBD

## Pig and JSON

TBD
__________________________________________________________________________

