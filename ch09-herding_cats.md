# Chapter 9: Herding `cat`s

## Moving things to and fro


To put something on the HDFS directly from a pipe:

    hdp-mkdir infochimps.com
    curl 'http://infochimps.com' | hdp-put - infochimps.com/index.html




## Stupid Hadoop Tricks


### Mappers that process filenames, not file contents

You can output anything you want in your mappers. 

Every once in a while, you need to do something where getting the content onto the HDFS is almost more work than it's worth. For instance, say you had to process a whole bunch of files located in no convenient place or organization

* pull in all the files
* transfer the files to the HDFS
* start the job to process them
* transfer them back off

or: 

* send, as the mapper input, the files to fetch
* each mapper fetches the page contents and emits them 

Be careful: hadoop has no rate limiting. It will quite happily obliterate any system you point it at, for whom there's no apparent difference between Hadoop and a concentrated Distributed Denial of Service attack.

__________________________________________________________________________

### Benign DDOS

Speaking of which... So you have an API. And you think it's working well, and in fact you think it's working really well. Want to simulate a 200x load spike? Replay a week's worth of request logs at your server, accelerated to all show up in an hour. Each mapper reads a section of the logs, and makes the corresponding request (setting its browser string and referer URL accordingly). It emits the response duration, HTTP status code, and content size. There are [dedicated tools to do this kind of HTTP benchmarking](https://github.com/wg/wrk), but they typically make the same request over and over. Replaying a real load at higher speed means that your caching strategy is properly exercised.

__________________________________________________________________________