
* Memory (RAM)     is cruelly limited in size 
* Storage (Disk)   is infinite in size 

* Memory is infinitely fast.
* Streaming data from disk is the limiting factor in speed if you're doing things right...
* ... unless Processing (CPU) is the limiting factor in speed
* Streaming data across the network is ever-so-slightly faster than streaming from disk
* Reading data in pieces from disk is infinitely slow
* Reading data in pieces from across the network is even slower


Here are prices in 

To store 10 Billion records with an average size of 1 kB costs

* $200,000 /month to store it all on ram ($1315/mo for 150 68.4 GB machines)
* $ 20,000 /month to have it 10% backed by ram ($1315/mo for 15 68.4 GB machines)
* $  1,000 /month to store it on disk (EBS volumes)



* $  1,600 /month salary of a part-time intern
* $  5,500 /month salary of a full-time junior engineer 
* $ 10,000 /month salary of a full-time senior engineer 

For a 10-hour working day, 

* $ 270 for a 30-machine cluster having a total of 1TB ram, 120 cores
* $ 180 for an intern         to operate it
* $ 300 for a junior engineer to operate it
* $ 600 for a senior engineer to operate it


### Steps

    (read and label the data)
    (send the data across the network)
    (sort each batch)
    (process the data in each batch and output it)
