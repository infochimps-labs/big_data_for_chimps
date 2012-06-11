# Common Crawl

http://aws.amazon.com/datasets/41740 

s3://aws-publicdatasets/common-crawl/crawl-002

A corpus of web crawl data composed of 5 billion web pages. This data set is freely available on Amazon S3 and formatted in the ARC (.arc) file format.

Details
* Size:	 60 TB
* Source:	 Common Crawl Foundation -­ http://commoncrawl.org
* Created On:	February 15, 2012 2:23 AM GMT
* Last Updated:	February 15, 2012 2:23 AM GMT
* Available at: s3://aws-publicdatasets/common-crawl/crawl-002/

A corpus of web crawl data composed of 5 billion web pages. This data set is freely available on Amazon S3 and formatted in the ARC (.arc) file format.

Common Crawl is a non-profit organization that builds and maintains an open repository of web crawl data for the purpose of driving innovation in research, education and technology. This data set contains web crawl data from 5 billion web pages and is released under the Common Crawl Terms of Use.

The ARC (.arc) file format used by Common Crawl was developed by the Internet Archive to store their archived crawl data. It is essentially a multi-part gzip file, with each entry in the master gzip (ARC) file being an independent gzip stream in itself. You can use a tool like zcat to spill the contents of an ARC file to stdout. For more information see the Internet Archive's [Arc File Format description](http://www.archive.org/web/researcher/ArcFileFormat.php).

Common Crawl provides the glue code required to launch Hadoop jobs on Amazon Elastic MapReduce that can run against the crawl corpus residing here in the Amazon Public Data Sets. By utilizing Amazon Elastic MapReduce to access the S3 resident data, end users can bypass costly network transfer costs.

To learn more about Amazon Elastic MapReduce please see the product detail page.

Common Crawl's Hadoop classes and other code can be found in its [GitHub repository](https://github.com/commoncrawl/commoncrawl).

A tutorial for analyzing Common Crawl's dataset with Amazon Elastic MapReduce called MapReduce for the Masses: [Zero to Hadoop in Five Minutes with Common Crawl](http://www.commoncrawl.org/mapreduce-for-the-masses/) may be found on the Common Crawl blog.


