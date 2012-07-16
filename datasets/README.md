
* Yahoo Stocks
* Wikipedia Pageviews
* Weather Daily + Weather Stations
* Airline Flights and Delays

* Wikipedia Corpus
* Word Frequency BNC

* Wikipedia Page Graph

* Material Safety Data Sheets
* Crunchbase
* US Census ACS 2009

* UFO Sightings
* Geonames
* Foursquare Venues
* Natural Earth boundaries
* US Census Boundaries
* Zillow Neighborhoods
* Open Street Map

* Twitter
  - strong links
  - trust rank
  - influence metrics
  
* Retrosheet
* MLB Gameday

* IP to Geo

* [Google Books Ngrams](http://aws.amazon.com/datasets/8172056142375670)
  - 2_000 GB 
  - graph, linguistics 

* Common Crawl web corpus 
  - 60_000 GB 
  - text

* [Apache Software Foundation Public Mail Archives](http://aws.amazon.com/datasets/7791434387204566)
  - 200 GB
  - corpus 
  - A collection of all publicly available mail archives from the Apache55 Software Foundation (ASF)

* Marvel Universe Social Graph 
  - 1 GB
  - graph
  - Social collaboration network of the Marvel comic book universe based on co-appearances.

* Daily Global Weather Measurements, 1929-2009 (NCDC, GSOD)
  - 20 GB
  - geo, stats


* Wikipedia Page Traffic Statistic V3 
  - 
  - a 150 GB sample of the data used to power trendingtopics.org. It includes a full 3 months of hourly page traffic statistics from Wikipedia (1/1/2011-3/31/2011).

* Twilio/Wigle.net Street Vector Data Set --  -- geo -- Twilio/Wigle.net database of mapped US street names and address ranges.

* 2008 TIGER/Line Shapefiles -- 125 GB -- geo -- This data set is a complete set of Census 2000 and Current shapefiles for American states, counties, subdivisions, districts, places, and areas. The data is available as shapefiles suitable for use in GIS, along with their associated metadata. The official source of this data is the US Census Bureau, Geography Division.

### Amazon Co-Purchasing Data

* http://snap.stanford.edu/data/amazon0312.html


### Patents

* [Google Patent Collection](http://www.google.com/googlebooks/uspto-patents.html)


### Other

* [Book Crossing](http://www.informatik.uni-freiburg.de/~cziegler/BX/) Collected by Cai-Nicolas Ziegler in a 4-week crawl (August / September 2004) from the Book-Crossing community with kind permission from Ron Hornbaker, CTO of Humankind Systems. Contains 278,858 users (anonymized but with demographic information) providing 1,149,780 ratings (explicit / implicit) about 271,379 books. Freely available for research use when acknowledged with the following reference (further details on the dataset are given in this publication): Improving Recommendation Lists Through Topic Diversification, Cai-Nicolas Ziegler, Sean M. McNee, Joseph A. Konstan, Georg Lausen; Proceedings of the 14th International World Wide Web Conference (WWW '05), May 10-14, 2005, Chiba, Japan. To appear. As a courtesy, if you use the data, I would appreciate knowing your name, what research group you are in, and the publications that may result.	


Format

The Book-Crossing dataset comprises 3 tables.
BX-Users
Contains the users. Note that user IDs (`User-ID`) have been anonymized and map to integers. Demographic data is provided (`Location`, `Age`) if available. Otherwise, these fields contain NULL-values.

BX-Books
Books are identified by their respective ISBN. Invalid ISBNs have already been removed from the dataset. Moreover, some content-based information is given (`Book-Title`, `Book-Author`, `Year-Of-Publication`, `Publisher`), obtained from Amazon Web Services. Note that in case of several authors, only the first is provided. URLs linking to cover images are also given, appearing in three different flavours (`Image-URL-S`, `Image-URL-M`, `Image-URL-L`), i.e., small, medium, large. These URLs point to the Amazon web site.

BX-Book-Ratings
Contains the book rating information. Ratings (`Book-Rating`) are either explicit, expressed on a scale from 1-10 (higher values denoting higher appreciation), or implicit, expressed by 0.

* [Westbury Usenet Archive](http://www.psych.ualberta.ca/~westburylab/downloads/usenetcorpus.download.html) -- USENET corpus (2005-2010) [BETA VERSION] This corpus is a collection of public USENET postings. This corpus was collected between Oct 2005 and Jan 2011, and covers 47860 English language, non-binary-file news groups. Despite our best effots, this corpus includes a very small number of non-English words, non-words, and spelling errors. The corpus is untagged, raw text. It may be neccessary to process the corpus further to put the corpus in a format that suits your needs.


* [Million Song Dataset](http://labrosa.ee.columbia.edu/millionsong/) -- The Million Song Dataset is a freely-available collection of audio features and metadata for a million contemporary popular music tracks.

Its purposes are:

To encourage research on algorithms that scale to commercial sizes
To provide a reference dataset for evaluating research
As a shortcut alternative to creating a large dataset with APIs (e.g. The Echo Nest's)
To help new researchers get started in the MIR field
The core of the dataset is the feature analysis and metadata for one million songs, provided by The Echo Nest. The dataset does not include any audio, only the derived features. Note, however, that sample audio can be fetched from services like 7digital, using code we provide.

The Million Song Dataset is also a cluster of complementary datasets contributed by the community:

SecondHandSongs dataset -> cover songs
musiXmatch dataset -> lyrics
Last.fm dataset -> song-level tags and similarity
Taste Profile subset -> user data

### Google / Stanford Crosswiki 

[wikipedia_words](http://www-nlp.stanford.edu/pubs/crosswikis-data.tar.bz2/)


This data set accompanies

   Valentin I. Spitkovsky and Angel X. Chang. 2012.
   A Cross-Lingual Dictionary for English Wikipedia Concepts.
   In Proceedings of the Eighth International
     Conference on Language Resources and Evaluation (LREC 2012).

Please cite the appropriate publication if you use this data.  (See
  http://nlp.stanford.edu/publications.shtml for .bib entries.)


There are six line-based (and two other) text files, each of them
lexicographically sorted, encoded with UTF-8, and compressed using
bzip2 (-9).  One way to view the data without fully expanding it
first is with the bzcat command, e.g.,

  bzcat dictionary.bz2 | grep ... | less


Note that raw data were gathered from heterogeneous sources, at
different points in time, and are thus sometimes contradictory.
We made a best effort at reconciling the information, but likely
also introduced some bugs of our own, so be prepared to write
fault-tolerant code...  keep in mind that even tiny error rates
translate into millions of exceptions, over billions of datums.


### Reference Energy Disaggregation Dataset (REDD)

[Reference Energy Disaggregation Data Set](http://redd.csail.mit.edu/)

Initial REDD Release, Version 1.0

This is the home page for the REDD data set. Below you can download an initial version of the data set, containing several weeks of power data for 6 different homes, and high-frequency current/voltage data for the main power supply of two of these homes. The data itself and the hardware used to collect it are described more thoroughly in the Readme below and in the paper:

J. Zico Kolter and Matthew J. Johnson. REDD: A public data set for energy disaggregation research. In proceedings of the SustKDD workshop on Data Mining Applications in Sustainability, 2011. [pdf]

Those wishing to use the dataset in academic work should cite this paper as the reference. Although the data set is freely available, for the time being we still ask those interested in the downloading the data to email us (kolter@csail.mit.edu) to receive the username/password to download the data. See the readme.txt file for a full description of the different downloads and their formats

### Access Logs from the Internet Traffic Archive

[Internet Traffic Archive](http://ita.ee.lbl.gov/html/traces.html)

* [star wars kid access logs](http://waxy.org/2008/05/star_wars_kid_the_data_dump/) from waxy.org


### Metaindexes


http://www.kdnuggets.com/datasets/
http://thedatahub.org/

### Not using


* [Crunchbase](http://crunchbase.com)
* [World Bank](http://data.worldbank.org)

* [US Legislative CoSponsorship](http://jhfowler.ucsd.edu/cosponsorship.htm)
* [VoteView](http://voteview.org/downloads.asp) DW-NOMINATE Rank Orderings all Houses and Senates

* [Record of American Democracy](http://road.hmdc.harvard.edu/pages/road-documentation) -- The Record Of American Democracy (ROAD) data includes election returns, socioeconomic summaries, and demographic measures of the American public at unusually low levels of geographic aggregation. The NSF-supported ROAD project covers every state in the country from 1984 through 1990 (including some off-year elections). One collection of data sets includes every election at and above State House, along with party registration and other variables, in each state for the roughly 170,000 precincts nationwide (about 60 times the number of counties). Another collection has added to these (roughly 30-40) political variables an additional 3,725 variables merged from the 1990 U.S. Census for 47,327 aggregate units (about 15 times the number of counties) about the size one or more cities or towns. These units completely tile the U.S. landmass. The collection also includes geographic boundary files so users can easily draw maps with these data.



* [Human Mortality DB](http://www.mortality.org/) The Human Mortality Database (HMD) was created to provide detailed mortality and population data to researchers, students, journalists, policy analysts, and others interested in the history of human longevity. The project began as an outgrowth of earlier projects in the Department of Demography at the University of California, Berkeley, USA, and at the Max Planck Institute for Demographic Research in Rostock, Germany (see history). It is the work of two teams of researchers in the USA and Germany (see research teams), with the help of financial backers and scientific collaborators from around the world (see acknowledgements).

* [FCC Antenna locations](http://transition.fcc.gov/mb/databases/cdbs/)

* [Pew Research Datasets](http://pewinternet.org/Static-Pages/Data-Tools/Download-Data/Data-Sets.aspx)

* [Facebook 100](http://masonporter.blogspot.com/2011/02/facebook100-data-set.html) -- http://archive.org/details/oxford-2005-facebook-matrix

* [Youtube Related Videos](http://netsg.cs.sfu.ca/youtubedata/)

