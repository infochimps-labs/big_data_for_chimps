


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

Picture lunchtime for a very large troop of chimpanzees, hollering across the room to pass the bananas over here, and pardon me may I borrow your anthill-poking twig, and my aren't these tasty grubs, and now imagine trying to get any work done. It's a very hard problem. 

You can design very clever hardware that allows any computer can talk to any other computer. It requires expensive hardware, and clever engineering, and a high priesthood to maintain it, which attracts project managers, which means meetings. Everything is so expensive that only nation states can compete to build the biggest supercomputers, and so you can only use it for Big Important Problems and so unless you go to grad school or join the NSA or take other unreasonable steps you can't get to play on big iron. [2]

Instead of being clever, you can instead be simple [4]. 






__________________________________________________________________________

[1] "Linear" means that increasing your cluster size by a factor of `N` increases the rate of progress by a factor of `N` and thus solves problems in `1/N` the amount of time. 


[2] Even if you did find yourself on a supercomputer, Einsten and the speed of light take all the fun out of it. Light travels about a foot per nanosecond, and on a very fast CPU each instruction takes about half a nanosecond, so it's impossible to talk to a machine more than a hands-breadth away. Even with all that clever hardware, you have to always be thinking about locality and that means you have to write really clever programs.

[3] http://en.wikipedia.org/wiki/K_computer

[4] "Simple beats clever" is a general pattern in scalable systems.