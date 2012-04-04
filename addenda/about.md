## What this book covers

* Detailed example programs applying Hadoop to interesting problems in context
* Advice and best practices for efficient software development
* How to think at scale -- equipping you with a deep understanding of how to break a problem into efficient data transformations, and of how data must flow through the cluster to effect those transformations.

All of the examples use real data, and describe patterns found in many problem domains:

* Statistical Summaries
* Identify patterns and groups in the data
* Searching, filtering and herding records in bulk
* Advanced queries against spatial or time-series data sets.

Feel free to hop around among chapters; the application chapters don't have large dependencies on earlier chapters. 

Most of the chapters have exercises included. If you're a beginning user, I highly recommend you work out at least one exercise from each chapter. Let me put that more strongly: if you're a beginning user, you should not *read* this book -- you should have it open next to you while you *write* whatever code each chapter inspires you to produce. The book's website has sample solutions, and data sets to compare against your output.

## Who this book is for

You should be familiar with at least one programming language, but it doesn't have to be Ruby. Ruby is a very readable language, and the code samples provided should correspond cleanly to languages like Python or Scala.

All of the code in this book will run unmodified on your laptop computer and on an industrial-strength Hadoop cluster (though you will want to use a reduced data set for the laptop). You don't *need* to have an existing Hadoop installation, but you won't really be learning unless you spend some time on a real environment. The book gives straightforward instructions for creating a Hadoop cluster on the Amazon EC2 cloud.

## Who this book is not for

This is not "Hadoop the Definitive Guide" (that's been written, and well); this is more like "Hadoop: a Highly Opinionated Guide".  The only coverage of how to use the bare Hadoop API is to say "In most cases, don't". We recommend storing your data in one of several highly space-inefficient formats and in many other ways willingly trade a small performance hit for a large increase in programmer joy. The book has a relentless emphasis on writing *scalable* code, but no content on writing *performant* code beyond the advice that the best path to a 2x speedup is to launch twice as many machines.

There is some content on machine learning with Hadoop, on provisioning and deploying hadoop, and on a few important settings. But it does not cover advanced algorithms, operations or tuning in any real depth.

## How this book is being written

I plan to push chapters to the publicly-viewable ['Hadoop for Chimps' git repo](http://github.com/infochimps-labs/big_data_for_chimps) as they are written, and to post them periodically to the [the Infochimps blog](http://blog.infochimps.com) after minor cleanup.

We really mean it about the github thing -- please [comment](https://github.com/blog/622-inline-commit-notes) on the text, [file issues](http://github.com/infochimps-labs/big_data_for_chimps/issues) and send pull requests. 

However! We might not use your feedback, no matter how dazzlingly cogent it is. Also, we are soliciting comments from readers -- but we are not seeking out content from collaborators. Do not run off and craft a dazzlingly lucid explanation of some topic, far excelling whatever hackish tripe I would have coughed out, and then expect us to include it[^1]. I have strong opinions about what the book should cover and a fixed budget of pages; and while I am trying my hand at author, I have no interest in being an editor. Don't prepare original content unless you get in touch first.

__________________________________________________________________________

[^1] Do craft dazzlingly lucid explanations, though! Always! And tell us about it -- we won't use it for the book, but we'd probably enjoy linking to it.


## Questions

* "Big Data for Chimps" or "Hadoop for Chimps"?
* Can we get a Chimpanzee for the cover animal?