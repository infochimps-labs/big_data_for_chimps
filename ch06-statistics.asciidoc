# Chapter 6: Statistics


Describe long-tail and normal distribution

Build intuition about long-tail

Log counts and combinators (see blekko posts)



### Median

Naïve: 
* do a total sort.
* Pull out the %iles

Compare :
Count bins (histogram)
For 100 M rows -- What about when there are 10,000 values? 1m values? 1B possible values?

#### Approximate methods

We can also just approximate. 

Reservoir sampling. 

If you know distribution, can do a good job.
I know that cities of the world lie between 1 and 8 billion. If I want to know median within .1% (one part in 1000), 

    X_n / X_n-1 = 1.001 or log(xn) - log(xn1) = -3

## Sampling



### random numbers + Hadoop considered harmful.

Don't generate a random number as a sampling or sort key in a map job. The problem is that map tasks  can be restarted - because of speculative execution, a failed machine, etc. -- and with random records, each of those runs will dispatch differently. It also makes life hard in general when your jobs aren't predictable run-to-run. You want to make friends with a couple records early in the so urge, and keep track of its passage though the full data flow. Similarly to the best practice of using intrinsic vs synthetic keys, it's always better to use intrinsic metadata --  truth should flow from the edge inward. 

