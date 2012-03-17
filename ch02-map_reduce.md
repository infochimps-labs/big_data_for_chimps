# Chapter 2: Map / Reduce


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

Instead of being clever, you can instead be simple [4]. 

The bargain that Map/Reduce proposes is that you agree to only write programs that fit this Haiku:

  data flutters by
  elephants make sturdy piles
  insight rustles forth

More prosaically, 

1. *label*      -- turn each input record one-by-one into a reducible record with a label attached
2. *group/sort* -- hadoop groups those records uniquely under each label, in a sorted order
3. *process*    -- for each group, process its reducible records in order, emitting anything you want.

The trick lies in the second step: 

__________________________________________________________________________

[1] "Linear" means that increasing your cluster size by a factor of `S` increases the rate of progress by a factor of `S` and thus solves problems in `1/S` the amount of time. 

[2] Even if you did find yourself on a supercomputer, Einsten and the speed of light take all the fun out of it. Light travels about a foot per nanosecond, and on a very fast CPU each instruction takes about half a nanosecond, so it's impossible to talk to a machine more than a hands-breadth away. Even with all that clever hardware you must always be thinking about locality, which is a Hard Problem. The Chimpanzee Way says "Do not solve Hard Problems. Turn a Hard Problem into a Simple Problem and solve that instead"

[3] http://en.wikipedia.org/wiki/K_computer

[4] "Simple beats clever" is a general pattern in scalable systems.

[5] you may be saying to yourself, "Self, I seem to recall my teacher writing on the chalkboard that sorting records takes more than linear time -- in fact, I recall it is `O(N log N)`". This is true. But in practice you typically buy more computers in proportion to the size of data, so the amount of data you have on each computer remains about the same. This means that the sort stage takes the same amount of time as long as your data is reasonably well-behaved. In fact, because disk speeds are so slow compared to RAM, and because the merge sort algorithm is very elegant, it takes longer to read or process the data than to sort it.
    
    