# Chapter 3: Why Hadoop Works

* Locality of reference and the speed of light
* Disk is the new tape -- Random access on bulk storage is very slow
* Fun -- Resilient distributed frameworks have traditionally been very conceptually complex, where by complex I mean "MPI is a soul-sucking hellscape"

## Locality of Reference

Ever since there were        [] [] [] [] 
                             [] [] [] [] eight computers and a network, 
programmers have wished that eight computers solved problems 
            twice as fast as [] [] [] [] four computers. That's linear scaling [1], and it's pretty awesome any time you can achieve it.

The problem comes when the computer
                  [] [] [] [] [] [] [] over here needs to talk to the computer
     over here -> [] [] [] [] [] [] [] 
  and this one -> [] [] [] [] [] [] [] 
       needs to talk to this one ^ 
and so forth. 

If you've ever had lunch with a very large troop of chimpanzees, hollering across the room to pass the bananas over here, and pardon me may I borrow your anthill-poking twig, and my aren't these tasty grubs, you can imagine how hard it is to get any work done. 

You can try to make it efficient for any computer to talk to any other computer. But it requires top-of-the-line  hardware, and clever engineers to build it, and a high priesthood to maintain it, and this attracts project managers, which means meetings, and soon everything is quite expensive, so expensive that only nation states and huge institutions can afford to do so. This of course means you can only use these expensive supercomputer for Big Important Problems -- so unless you take drastic actions, like joining the NSA or going to grad school, you can't get to play on them. [2]

Instead of being clever, be simple [4]. 

The bargain that Map/Reduce proposes is that you agree to only write programs that fit this Haiku:

      data flutters by
          elephants make sturdy piles
        insight rustles forth

More prosaically, 

1. *label*      -- turn each input record one-by-one into a reducible record with a label attached
2. *group/sort* -- hadoop groups those records uniquely under each label, in a sorted order
3. *process*    -- for each group, process its reducible records in order, emitting anything you want.

The trick lies in the 'group/sort' step. The only locality available is to assign the same label to each set of objects that you'd like to party together


If you agree to that contract, Hadoop not only makes the locality problem go away but alsp makes a whole lot of other hassles disappear. You get to write simple, focused code snippets and let Hadoop manage all the complexity.

The machines in stage 1 ('label') are allowed no locality. They see each record exactly once, but with no promises as to order, and no promises as to which one sees which record. We've 'moved the compute to the data', allowing each process to work quietly on the data in its work space.

As each pile of output products starts to accumulate, we can begin to group them. Every group is assigned to its own reducer (it's important to be fair that no one is over-worked.) When a pile reaches a convenient size, it is shipped to the appropriate reducer while the mapper keeps working. Once the map finishes, we organize those piles for its reducer to process, each in proper order.

If you notice, the only time data moves from one machine to another is when the intermediate piles of data get shipped. Instead of monkeys flinging poo, we now have a dignified elephant parade conducted in concert with the efforts of our diligent workers.

    
## Disk is the new tape

Doug Cutting's example comparing speed of searching by index vs. searching by full table scan 

For each of 

* Local Disk
* EBS
* SSD
* S3
* MySQL (local)
* MySQL (network)
* HBase (network)
* in-memory
* Redis (local)
*  Redis (network)

Compare throughput of:

* random readss    
* streaming reads  
* random writes 
* streaming writes



## Hadoop is Secretly Fun

Walk into any good Hot Rod shop and you'll see a sign reading "Fast, Good or Cheap, choose any two". Hadoop is the first distributed computing framework that can claim "Simple, Resilient, Scalable, choose all three".

The key, is that simplicity + decoupling + embracing constraint 
unlocks significant power.

Heaven knows Hadoop has its flaws, and its codebase is long and hairy, but its core is 

* speculative execution
* compressed data transport
* memory management of buffers
* selective application of combiners
* fault-tolerance and retry
* distributed counters
* logging
* serialization


### Economics:

Say you want to store a billion objects, each 10kb in size. At commodity cloud storage prices in 2012, this will cost roughly [^1]

* $250,000 a month to store in RAM
* $ 25,000 a month to store it in a database with a 1:10 ram-to-storage ratio
* $  1,500 a month to store it flat on disk

CPU


A 30-machine cluster with 240 CPU cores, 2000 GB total RAM and 50 TB of raw disk [^1]:

* purchase: (-> find out purchase price)
* cloud: about $60/hr; $10,000 to run for 8 hours a day every work day.


By contrast, it costs [^1]

* $  1,600 a month to hire an intern for 25 hours a week
* $ 10,000 a month to hire an experienced data scientist, if you can find one

In a database world, the dominant cost of an engineering project is infrastructure. In a hadoop world, the dominant cost is engineers.



[^1] I admit these are not apples-to-apples comparisons. But the differences are orders of magnitude: subtly isn't called for




## Notes
__________________________________________________________________________

[1] "Linear" means that increasing your cluster size by a factor of `S` increases the rate of progress by a factor of `S` and thus solves problems in `1/S` the amount of time. 

[2] Even if you did find yourself on a supercomputer, Einsten and the speed of light take all the fun out of it. Light travels about a foot per nanosecond, and on a very fast CPU each instruction takes about half a nanosecond, so it's impossible to talk to a machine more than a hands-breadth away. Even with all that clever hardware you must always be thinking about locality, which is a Hard Problem. The Chimpanzee Way says "Do not solve Hard Problems. Turn a Hard Problem into a Simple Problem and solve that instead"

[3] http://en.wikipedia.org/wiki/K_computer

[4] over and over in scalable systems you'll find the result of Simplicity, Decoupling and Embracing Constraint is great power.

[5] you may be saying to yourself, "Self, I seem to recall my teacher writing on the chalkboard that sorting records takes more than linear time -- in fact, I recall it is `O(N log N)`". This is true. But in practice you typically buy more computers in proportion to the size of data, so the amount of data you have on each computer remains about the same. This means that the sort stage takes the same amount of time as long as your data is reasonably well-behaved. In fact, because disk speeds are so slow compared to RAM, and because the merge sort algorithm is very elegant, it takes longer to read or process the data than to sort it.
