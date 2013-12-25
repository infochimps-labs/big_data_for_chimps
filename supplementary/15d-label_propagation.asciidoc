=== Label Propagation


Label propagation is an elegantly direct way to make this natural structure express itself.

It's fairly similar to pagerank: 

// Think about a teenager choosing a college.
// Some may have already chosen -- their mind is made up.
// Others have no opinion, but receive lots of lobbying from family and classmates

Some pages have been expressly geolocated: they have "ground truth". That will be used to seed the location inferences, and to judge our progress.
Most other pages will have a distribution of locations.

At each mapper step, a page emits its propagatable locations to every page it links to; it also sends its metadata to itself.

The reducer combines all the inbound evidence to form a new inferred location distribution, along with a number summarizing how much the inferred location changed compared to the previous estimate.

==== Consensus locations

The reducer must turn the "votes" into a consistent geolocation;
Good taste will guide of our approach, but there's no one "right" way to do this.
we've taken care to decouple that method from the overall code --

* Locations with more confidence should outweigh locations with less confidence
* If

This page has many dilute votes around DC, and a strong number of votes for Boston:

                                                                                     x
       x    x                                                                      x
    xx xx x     x                                     x                     xx   x
    Washington, DC                  New York          Boston
    
 Here I've spread out the DC ones and added to Boston:

           
                                                              x                    
                                                              x                    x      
                                                              x                    x    x
    xx  x   x     x   xx   xx                       x                  xxx  x x
    Washington, DC                  New York          Boston

So, where "is" that page? 
* DC, because it has more weight in its vicinity
* New York, because it has the highest peak
* Boston, because it has the 
* 

* Single Peak
* 1, 2 or 3 peaks, as warranted
* "Drain" local area 
* Clustering
* Alpha shapes
* All of it (above certain threshold

what do we pass along

* One location ('{∂: x, y}')
* One peak ('{∂: x, y, r}')
* Several locations: ('<{∂: x, y}, {∂: x, y}, {∂: x, y}>')
* Several peaks
* Full distribution

compare:

* US
* New York City
* Manhattan
* Texas
* "Midwest"
* The Dodgers (Brooklyn/Los Angeles)
* Abraham Lincoln (Illinois and Washington DC)
* Superbowl

==== Alpha Shapes

* Reducer goes on tags

=== a random note to self


Italian Restaurant Rte 1 in Hollywood


