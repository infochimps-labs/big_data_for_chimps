
===== Pattern in Use

* _Where You'll Use It_  -- 
* _Standard Snippet_	 -- 
* _Hello, SQL Users_     -- 
* _Important to Know_	 -- 
* _Output Count_	 -- As many records as the cardinality of its key, i.e. the number of distinct values. Data size should decrease greatly.
* _Records_		 -- 
* _Data Flow_		 -- Pipelinable: it's composed onto the end of the preceding map or reduce, and if it stands alone becomes a map-only job.
* _Exercises for You_    -- 
* _See Also_             -- 


// footnote:[Just as the truly wise physicist knows that the best way to use a barometer to measure the height of the building is to approach the building manager and say "You can have this nifty barometer if you tell me how high your building is"] https://en.wikipedia.org/wiki/Barometer_question


For many of these It's quite difficult to attach _business_ context, because the answer is "everywhere" -- the point of the patterns is that they crop up across all data explorations. So in those cases, I've tried to put in hooks to enough other programming contexts that 
 Q and I both have the feeling that we should ask our tech reviewers to help with examples of business context.

I see where that's needed for strategic things, and so I tried to frame the "What baseball players have had the greatest careers" as a search for outliers:

Here, it's baseball players, but similar questions will apply when examining agents posing security threats, factors causing manufacturing defects, cell strains with a significantly positive response, and many other topics of importance."


But the content in the chapters we're assembling now cover tactical patterns, where this is harder to do -- and I'm not sure the reader will be expecting it. When we demonstrate Concatenating Several Values into a Single String or Testing for Absence of a Value Within a Group or Set Operations on Full Tables, the answer to "what are other applications of this technique" is "most of them, if that's what you're trying to do".

As you know, I have a habit of inflating problems to grandest scale, so I might be overestimating what you're suggesting we change. But it's exceptionally hard to come up with a natural examples for things like "Testing for Absence of a Value Within a Group" or "Set Operations on Full Tables", while keeping focus on the analytic pattern and not on the data or domain specifics of the problem. And the baseball data is one of the very few that let us exhibit the full range of patterns.

I've just added this section to the first analytic patterns chapter

Throughout the book, when we touch on _strategic_ techniques -- how to assemble the patterns you're about to see into an explanation that tells a coherent story -- we endeavor to not only choose an interesting and realistic problem from some domain, but also to indicate how the strategic approach would extend to other domains, especially ones with an obvious business focus.

This part of the book, however, will focus on tactical patterns, which are exactly those tools that don't adhere to any particular domain. Think of them as the screwdriver, torque wrench, lathe and so forth of your toolkit. Now, if this book were called "Big Mechanics for Chimps", we introduce those tools by repairing and rebuilding a Volkswagen Beetle engine, or by building another lathe from scratch. But those lessons carry over to anywhere machine tools apply: air conditioner repair, fixing your kid's bike, building a rocket ship to Mars. Similarly, to meet our standard of interesting and realistic demonstrations, we need some domain to explore. And to keep focus on the patterns and not on specifics of the data model or domain, it's best to choose one and stick with it. So we will center these next few chapters on what Nate Silver calls "the perfect data set": the sea of numbers surrounding the sport of baseball. The members of the Retrosheet and Baseball Databank projects have provided an extraordinary resource: comprehensive statistics from the birth of the game in the late 1800s until the present day, freely available and redistributable. There is an overview of the stats we'll use in (REF sidebar), and further information in the "Overview of Datasets" appendix (REF). Even if you're not a baseball fan, we've endeavored to choose recognizably interesting questions and to minimize the number of concepts you'll need to learn. We expect you'll learn a lot about data pipelines here.

This means, however, that you may find yourself looking at a pattern and saying "geez, I don't see how this would apply to my work in quantitative finance". It might be the case that it doesn't apply; a practicing air conditioner repair person will generally not have use for a lathe. In many other cases it does apply, but you won't see how until some late night when your back's against the wall and you remember that one section in that covered "Splitting a Table into Uniform Chunks" and an hour later you tweet "No doubt about it, I sure am glad I purchased 'Big Data for Chimps'". Our belief and our goal is that it's most commonly the second scenario.

### Grouping

Cleveland Spiders

* **Grouping Records into a Bag by Key**
  - FOREACH with GROUP BY lets you summarize and
* **How a group works**
* **Representing a Collection of Values with a Delimited String**
  - **Representing a Complex Data Structure with a Delimited String**
  - **Representing a Complex Data Structure with a JSON-encoded String**

### Group and Aggregate

* **Aggregate -- Generate career stats**
* **Summarize; complete summarize**
* **Macro for completely summarizing**

* **Group and Aggregate**
* **Summarizing Tables and Groups**
  - **Aggregate Statistics of a Full Table**
  - **Aggregate Statistics of a Group**
  - **Calculating Quantiles**

* **Completely Summarizing a Field**
  - **Completely Summarizing the Values of a String Field**
  - **Completely Summarizing the Values of a Numeric Field**
  - **Pig Macros**

### Distributions

We calculate several distributions:

* weight, height **Calculating the Distribution of Numeric Values with a Histogram**
  - (filing people onto a schoolbus) **Interpreting Histograms and Quantiles**
* relative histogram: **Calculating a Relative Distribution Histogram**
  - **Re-injecting Global Values**: cheat-y or not.
* weight, height over time: **Counting Occurrences Within a Group**
* Other distributions
  - **Binning Data for a Histogram**
  - macro for histogram (?)
* birth/death month
  - be careful when torking with extremes: **Extreme Populations and Confounding Factors**

### Joins

* _direct join_:
  - Join vital stats on seasons to plot BMI vs SLG: **Joining Records in a Table with Corresponding Records in Another Table (Inner Join)**
  - Disambiguating Field Names With `::`
* _outer join_:* **Joining Records Without Discarding Non-Matches (Outer Join)**
  - ???
  - completing city names from geonames list
  - **Filling holes in the histogram list**
  - **Joining on an Integer Table to Fill Holes in a List**
* _many-to-many join_: all parks a player called home **Enumerating a Many-to-Many Relationship**
* _self-join_: All people a player ever called teammate **Joining a Table with Itself (self-join)**
  - exploding tuples count
* _anti-join_: **Selecting Records With No Match in Another Table (anti-join)**
* _semi-join_: **Selecting Records Having a Match in Another Table (semi-join)**

### Sorting, Maxima and Minima

* **Sorting All Records in Total Order**
  - **Sorting by Multiple Fields**
  - **Sorting on an Expression (You Can't)**
  - **Sorting Case-insensitive Strings**
  - **Dealing with Nulls When Sorting**
  - **Floating Values to the Top or Bottom of the Sort Order**
* **Sorting Records within a Group**
* **Shuffle all Records in a Table**
  - **Shuffle all Records in a Table Consistently**
* **Numbering Records in Rank Order**
  - **Handling Ties when Ranking Records**

* **Selecting Records Associated with Maximum Values**
  - **Selecting a Single Maximal Record Within a Group, Ignoring Ties**
* **Selecting Records Having the Top K Values in a Group (discarding ties)**
* **Selecting Records Having the Top K Values in a Table**

### Unique and Duplicate Values

* **Finding Duplicate and Unique Records**
  - **Eliminating Duplicate Records from a Table**
  - **Eliminating Duplicate Records from a Group**
  - **Selecting Records with Unique (or with Duplicate) Values for a Key**

### Set Operations

* **Set Operations on Full Tables**
  - **Distinct Union**
  - **Distinct Union (alternative method)**
  - **Set Intersection**
  - **Set Difference**
  - **Symmetric Set Difference: (A-B)+(B-A)**
  - **Set Equality**
* **Set Operations**
  - **Constructing a Sequence of Sets**
  - **Set operations within group**
  - **Exercises**

### Advanced Grouping Operations

* **Summarizing Multiple Subsets Simultaneously**

* **Testing for Absence of a Value Within a Group**
* **Detecting Outliers**

* **Co-Grouping Records Across Tables by Common Key**
* **Computing a Won-Loss Record**
* **Don't do this:**
* **Instead, use a COGROUP.**
* **Computing a Win-Expectancy Table**
  - **Run Expectancy**

* **Cumulative Sums and Other Iterative Functions on Groups**
  - **Generating a Running Total (Cumulative Sum / Cumulative Difference)**
  - **Generating a Running Product**
  - **Iterating Lead/Lag Values in an Ordered Bag**

* **Using Group/Decorate/Flatten to Bring Group Context to Individuals**


### Other

	-- ==== Mode (Most Frequent Value) of a Bag
	-- ==== Use a HashMap (Replicated) Join when Joining Small-ish to Large-ish
	-- ==== Dealing with Nulls When Grouping or Joining
	-- === Producing Master-Detail Lists and Summaries
	-- ==== Dealing with Nulls (outer-join equivalent)
	-- === Performing a Join-and-Aggregate with COGROUP
	-- === Cube
	-- === Rollup
	-- ==== Painfully Paginating Through a Result Set
	-- ==== Eliminating rows that have a duplicated value



=== In statistics Chapter

==== Cube and rollup
stats by team, division and league

cogroup events by team_id
... there's a way to do this in one less reduce in M/R -- can you in Pig?

=== in Time-series chapter

* Running total http://en.wikipedia.org/wiki/Prefix_sum
* prefix sum value; by combining list ranking, prefix sums, and Euler tours, many important problems on trees may be solved by efficient parallel algorithms.[3]
* Self join of table on its next row (eg timeseries at regular sample)

=== Don't know how to do these

* Computing Team Standings
* Producing Master-Detail Lists and Summaries
* Find Overlapping Rows
* Find Gaps in Time-Series
* Find Missing Rows in Series / Count all Values
* Calculating Differences Between Successive Rows
* Finding Cumulative Sums and Running Averages
