## Parallelized Operations

### Operations That Eliminate Data

* Filtering
  - select	filter	Select a Subset of Records from a Table Using FILTER
  - select	filter	Select a Subset of Records from a Table Using Map/Reduce
  - select	aswego	Specifying Which Records to Select; Finding Records That Satisfy Multiple Conditions
  - select	aswego	Pattern Matching in Strings with Regular Expressions (don't Pattern Matching with SQL Patterns or Searching for Substrings -- just use regexp)
  - select	aswego	Controlling Case Sensitivity in String Comparisons and Regular Expressions (`ff = FILTER fr BY EqualsIgnoreCase(franch_id, 'bOs'); DUMP ff;`)
  - select	aswego	Writing Comparisons Involving NULL
  - select	aswego	Finding Null Values
  - select	vals	(small set of values -- eg FILTER a BY i IN (1,22,333,4444,55555); also, `CASE X WHEN val1 ... WHEN val2 ... ELSE .. END` and `CASE WHEN cond .. WHEN cond .. ELSE .. END`)
* Projecting
  - select	project	Project a Only Chosen Columns from a Table Using FOREACH (Map/Reduce is trivial, should we include it?)
  - select	aswego	Renaming Columns from a Table
* Limit
  - select	limit	Select a Fixed Number of Records With LIMIT (Map/Reduce is painful, should we include it?)
  - select	nocando	Select Rows using a Limit and Offset
  - select	cylater	(Top-K, minimum and maximum values, etc under sorting)
* Sample
  - select	sample	Select a Random Fraction of Records with SAMPLE
* Other
  - select	bloom	Rejecting Records Early with a Bloom Filter (Bloom filters are a common way to select a limited set of records before moving data for a join or other heavyweight operation. Pig includes two UDFs: BuildBloom to build a bloom filter and Bloom to use the bloom filter in a filter statement. At present, users will need to explicitly call both UDFs to get the full benefit of bloom filter. In the future, we will include them in the optimizer so that large join queries can use bloom filter automatically. https://issues.apache.org/jira/browse/PIG-2328)

#### Transforming Records

  - transform	intro	Transform Records Individually using `FOREACH`
  - transform	intro	A nested `FOREACH` Allows Intermediate Expressions
  - transform	genrte	Generating Data
  - transform	udf	(Something) Applying a User-Defined Function
  - transform	gsub	Transforming Strings with Regular Expressions
  - transform		Working with NULL Values; Transforming Nulls into Real Values

  - transform	aswego	Converting a Number to its String Representation (and Back) (cast with (int))
  - transform	aswego	Date Arithmetic (just point to)
  - transform	aswego	Embedding Quotes Within String Literals
  - transform	aswego	Handling Special Characters and NULL Values in Statements
  - transform	aswego	Converting the Lettercase of a String
  - transform	useudf	Converting an inline JSON string to string (using a UDF)

  - transform		Assigning a Unique Identifier to Each Record (`-tagPath` / `tagFile`. I guess admit to the $.. syntax here? But don't get into the habit of using $0 and friends regularly. It's a sloppy habit and disrespectful to your teammates. Call forward to RANK, and to Over.)
  - transform		Assigning a Unique Identifier to Each Record using Map/Reduce
  - transform		Breaking Apart or Combining Strings
  - transform		Parsing Serialized Data into Records
  - transform		Combining Columns to Construct Composite Values
  - transform		Concatenating Column Values
  - group		Converting Delimited Data into a Tuple or Bag (remember flatten tuple = columns, flatten bag = rows)

### Operations that Expand the number of Rows or Columns

  - xplode	maybe	(Expanding Ranges into Fixed Intervals)
  - xplode		Exploding a String into its Characters
  - flatten		Flattening a Tuple Creates New Columns
  - flatten		Flattening a Bag Creates New Records (make the games data into normal form by taking the players tuple, transposing it to positions)
  - xplode	later	Other Similar Patterns
  - xplode	later	Transposing Columns into Records (in stats, but call ahead to it)

### Operations that Break One Table into Many

  - split		Splitting into Multiple Data Flows using `SPLIT`
  - split		Splitting into files by key by using a Pig Storefunc UDF
  - split		Splitting a Table into Uniform Chunks

### Operations that Treat the Union of Several Tables as One

  - union		Load Multiple Files as One Table
  - union		Treat Several Tables as a Single Table
  - union		Stacking One Rowset Atop Another
  - union		Clean Up Many Small Files by Merging into Fewer Files

## Structural Operations

* Grouping (denormalizing into a delimited list; how group works in map/reduce))
* Aggregation (Summary Statistics on group and table; summaries & nulls; testing existence & summing trick)
* Histogram (histogram; binning; re-injecting global values)
* Structural Operations on Groups (Distinct, Order; Windowed Over/Stitch; CountEach)
* cogroup 1 (howto cogroup)
* join (direct; outer; filling gaps; many-to-many; self-join; anti-join)
* cogroup2 (semi-join, multi-join, master-detail; z-score)
* set operations (union, distinct union, intersection, difference, symmetric difference, equality, partition)
* unique and duplicate records (eliminate duplicate records from {group or table}; full records with {unique or duplicated} value; arbitrary record for each distinct value; cardinality ie count of distict values)
* sorting (table; group; floating to top; case sensitivity)
* top-k (table; group; records with topmost value; running min/max; mode)
* ranking (table; group; records with topmost value in-group)
* shuffling
* won-loss revord; all qns; at-most qns; negation questions;
* group/decorate/flatten; group/flatten/flatten; cube & rollup

### Grouping Records

* Group
  - group	Group Records by value (Teams a player player for by year)
  - group		Creating a Delimited List Within a Field from Table Rows (denormalizing multiple values into one field)
  - group	aswego	Grouping by Expression Results
  - Move content from cogrpup at bottom describing how group works up here

### Summarizing Groups with Aggregate Functions

* Calculating Summary Statistics on Groups
  - groupagg		Summarizing with COUNT(), MIN(), MAX(), SUM(), AVG() and STDEV() (Computing an Average; Finding the Min/Max Value in a Group; Summing the Values in a Group; Counting Records in a Group)
  - groupagg		nested FOREACH (obp, slg, ops from counting stats)
  - groupagg		average weight and height by year
  - group2		Testing for Existence of a Value Within a Group (summing trick)
  - group		Selecting Only Groups with Certain Characteristics
  - groupagg	srybob	Summaries and NULL Values
  - groupagg	aswego	Aggregating Nullable Columns (NULL values don't get counted in an average. To have them be counted, ternary into a zero)

* Calculating Full-Table Summary Statistics
  - groupagg		Calculating Full-Table Summary Statistics (Computing an Average; Finding the Min/Max Value in a table; Summing the Values in a Table; Counting Records in a Table)
  - groupagg	grpall	Working with Per-Group and Overall Summary Values
  - groupagg		Calculating Descriptive Statistics
  (group & summarize number (H by season) and string (names))

* Histogram
  - groupagg	histog	Distribution of Values Using a Histogram
  - Histogram:
    - Games
    - binned games
    - multiple fields, (?reinject global totals)
  - groupagg	histog	Categorizing Noncategorical Data
  - groupagg	histog	Place Values into Categorical Bins
  - groupagg	histog	Re-injecting global totals
  - groupagg		Calculating Percent Relative to Total
  - group2	global	Determining the Percentage of a Total (use "scalar projection", or cheat.)
  - histogram	macros	(making a snippet a macro. Maybe in histogram? or summary stats?)

* Over/Stitch
  - inner-bag operations -- distinct teams in order by year(?)
  - summing trick: win-loss record; HoF standards test: 1pt batting over .300, 1-10 pts for each 0.025 pts of SLG above .300; 1-10 pts for each 0.010 of OBP over 0.300; 1-5 pts for each 200 walks over 300; 1 pt for each 200 HR. (And about a dozen more)
  - groupagg		Finding the Multiplicity of Each Item in a Bag (use datafu.CountEach)
  - group2	over	Calculating Successive-Record Differences
  - group2	over	Generating a Running Total (over and stitch)
  - group2	over	Finding Cumulative Sums and Running Averages
  - group2	over	Investigating Future Records, Shifting Record Values with Over(lag)

* QUESTION does cogroup go here, or below join, or with group?
* QUESTION does description of how cogroup works go here, or below, or with group?
* QUESTION do sorting and distincting in-group go here

### Join Matching Records Between Tables

* Direct Join:
  - join		Direct Join: Extend Records with Uniquely Matching Records from Another Table
  - join		Direct join on foreign key -- ages for each player season
  - join		Combining Related Records by Foreign Key (The solution is an example of a join, or more accurately an equi-join, which is a type of inner join. A join is an operation that combines rows from two tables into one. An equi-join is one in which the join condition is based on an equality condition (e.g., where one department number equals another). An inner join is the original type of join; each row returned contains data from each table.)
  - join		vertical partitioned (Wikipedia articles and metadata; just call this out as an example)
  - join	direct	(is qualified: join on team)
  - join	equijn	Note: You Can do any Join as Long as It's an Equi-join
* Outer Join
  - join		Join Against Another Table Without Discarding Non-Matches
  - join	left	Identifying and Removing Mismatched or Unattached Records
* Sparse Join
  - join		Matching Records
* Fill Gaps
  - join		filling holes in a list -- histogram of career hits
  - join		Fill in Holes in a List with a Join on an integer table
  - join		Using a Join to Identify or Fill Holes in a List
  - join	fill	Filling in Missing Values in a Range of Values
* Many-to-Many
  - join		many-to-many join --  ballparks a player has played in
  - join		Enumerating a Many-to-Many Relationship
  - join	Mnymny	Enumerating a Many-to-Many Relationship
* Self-Join
  - join		self join -- teammates -- team-year pla-plb (see below for just in-year teammates -- we can do the group-flatten-flatten trick because team subsumes player-a)
  - join		Join a table with itself (self-join)
  - join	selfjn	Comparing a Table to Itself
* Anti-Join
  - join	antijn	Retrieving Records from One Table That Do Not Correspond to Records in Another (non-allstars: can do this with an outer join, because cross product won't screw you up)
  - join	antijn	Finding Records with No Match in Another Table

### Restructuring Tables

* Semi-Join
  - group2	semijn	Finding Records in One Table That Match Records in Another
  - group2	intsct	Finding Records in Common Between Two Tables
  - cogroup		Find rows with a match in another table (semi-join)

* Set operations summary
  - group2	setops	Determining Whether Two Tables Have the Same Data (is symmetric difference empty)  -
  - group2	setops	Retrieving Values from One Table That Do Not Exist in Another (set difference; players in batting but not pitching -- or in one but not other (symmetric difference)
  - group2	setops	Group Elements From Multiple Tables On A Common Attribute (COGROUP)
  - group2	setops	GROUP/COGROUP To Restructure Tables
  - group2	setops	Partition a Set into Subsets: SPLIT, but keep in mind that the SPLIT operation doesn't short-circuit.
  - group2	setops	Union of Sets UNION-then-DISTINCT, or COGROUP (note that it doesn't dedupe, doesn't order, and doesn't check for same schema. career stats tables; do it with cogroup, not union-distinct)
  - group2	setops	Prepare a Distinct Set from a Collection of Records: DISTINCT
  - group2	setops	Intersect: semi-join (allstars)
  - group2	setops	Difference (in a but not in b): cogroup keep only empty (non-allstars)
  - group2	setops	Symmetric difference: in A or B but not in A intersect B -- do this with aggregation: count 0 or 1 and only keep 1
  - group2	setops	Equality (use symmetric difference): result should be empty
  - group2	setops	http://datafu.incubator.apache.org/docs/datafu/guide/set-operations.html and http://www.cs.tufts.edu/comp/150CPA/notes/Advanced_Pig.pdf

### Operations Involving Distinct, Duplicated or Unique Values

  - distinct		Counting and Identifying Duplicates // Using Counts to Determine Whether Values Are Unique
  - distinct		Eliminating Duplicates from a Table // Removing Duplicate Records (DISTINCT A; can't use this to find records according to a duplicated value though)
  - groupagg	nested	Using DISTINCT to Eliminate Duplicates

  - distinct	group	Eliminating Duplicates from a Group
  - groupagg		Counting Distinct Values in a Group (nested distinct)
  - distinct		Eliminating rows that have a duplicated value

  - distinct		Counting Distinct Values in a Column Exactly with GROUP BY ALL .. DISTINCT (Any time you see "GROUP BY ALL", your data-science spideysense should alert you to trouble. ...)
  - distinct		Cardinality (Count of Distinct Values) for a Column (for table and for group; exact and call forward to approximate)

  - distinct		Identifying unique records for a key
  - distinct		Identifying duplicated records for a key

  - distinct		(select at most N seasons for a player, drop rest)
  - distinct		keep one record from many distinct'ed by a field

### Sorting Operations

* Order a table
  - sorting		Sorting a Result Set
  - sorting		Using ORDER BY to Sort Query Results
  - sorting		Returning Query Results in a Specified Order

  - sorting		Floating Values to the Head or Tail of the Sort Order (extra sort column, comes first, with the overrides)
  - sorting	aswego	Controlling Case Sensitivity of String Sorts
  - sorting	aswego	Dealing with Nulls When Sorting (make an is_foo_null column and order by is_foo_null, foo)
  - sorting	aswego	Displaying One Set of Values While Sorting by Another
  - sorting	aswego	Sorting by Multiple Fields; Sorting by an Expression Sorting on a Data Dependent Key (eg by era-zscore if pitcher, by ops-zscore if batter) - just generate a synthetic colimn and the project it out
  - sorting	nocando	Using Expressions for Sorting
  - Sorting (ORDER BY, RANK) places all records in total order
  - Sorting Records by Key

* Selecting records based on Order
  - Season leaders
  - sorting		Selecting Records from the Beginning or End of a Result Set
  - sorting		Selecting Records from the Middle of a Result Set
  - sorting		Finding Smallest or Largest Summary Values
  - sorting	maybe	Controlling String Case Sensitivity for MIN() and MAX()
  - sorting		Finding Values Associated with Minimum and Maximum Values (including ties; for column or in group. Make sure to use a HashMap join)
  - sorting	top	Calculating a Mode (histogram and max)
  - sorting	over	(placing next or prev value with tuple, or running diff)
  - Finding Records Associated with Maximum Values
  - Select the Top K Records According to a Field Using ORDER..LIMIT
  - sorting	topk	Finding Records with the Highest and Lowest Values (even when there are ties -- use Over with
  - sorting	topk	Selecting the Top n Records (order limit)
  - Select Rows with the Top-K Values for a Field (move?)
  - Top K Within a Group
  - sorting		Finding Records Containing Per-Group Minimum or Maximum

* Ranking table, dimension and group
  - sorting		Ranking Results (note rank on its own sequentially numbers 1,2,3,4,5,6; on a column, itdoesnt use all integers: nondense is 1,2,2,4,5,5 dense is 1,2,2,3,4,4
  - sorting	rank	Assigning Ranks
  - sorting	rank	Ensuring That Records Are Renumbered in a Particular Order
  - sorting	rank	Numbering Records Sequentially
  - sorting	rank	Ranking Records within a group using Stitch/Over (order in nested; stitch and over)

* Shuffling Records
  - sorting	shuffle	Randomizing a Set of Records (rand, or join on ints, or consistent
  - Shuffle a Table into Random Order

### Advanced Operations

* Advanced Aggregations
  - group2	notjoin	Producing Master-Detail Lists and Summaries (for each player-year, the num players on their team who hit over 300; fraction of total team salary; rank of salary in team and league, rank of ops in team) (caution against A joon B on Y group by Y)
  - join	multi	Adding Joins to a Query Without Interfering with Other Joins (join bats on allstars inner and hof outer)
  - join	note	Performing Outer Joins When Using Aggregates (join a b and c, but many-to-many is causing trouble. Remember, a join is just a cogroup and flatten (with its implicit cross).

* Group/ Regroup
  - Group flatten regroup
    - each player/year, the rank of ops in mlb, league, division, team
    - exercise: for the top-k, instead do it for division then roll upwards...
  - Generate a won-loss record
  - Ungrouping operations (FOREACH..FLATTEN) expand record

  - group2		Questions Involving “at Most”: Eg select players who played for at most two different teams.
  - group2	winloss	Computing Team Standings

  - group2		Generating Unique Table Names (-> table name conventions)
  - group2		(questions involving all: all players who played against every team during years they played. Use count(distinct teams) might work except that teams might vary over years. For example, if you are asked to find people who eat all vegetables, you are essentially looking for people for whom there is no vegetable that they do not eat. This type of problem statement is typically categorized as relational division. With questions regarding “any,” it is crucial you pay close attention to how the question is phrased. Consider the difference between these two requirements: “a student who takes any class” and “a plane faster than any train.” The former implies, “find a student who takes at least one class,” while the latter implies “find a plane that is faster than all trains.”
  - group2		Answering Questions Involving Negation (player info for player who have not played for the yankees; cant do join(filter teamyear!=NYA). Need to do antijoin of(filter == nya) or use the summing trick! Generate is_inthere and then do max or sum. Quoting Rozenshtein’s book: "To find out “who does not,” first find out “who does” and then get rid of them." (Is there an "IN"? And which is best?) (a stupid plan: cogroup(filter bags for nya, filter rows for bag isEmpty))

* Cube and Rollup
  - cube	aswego	Dealing with null Values in a CUBE
  - cube	cube	Calculating Subtotals for All Possible Expression Combinations
  - cube	rollup	Calculating Simple Subtotals

* Group-decorate;
  - find OPSz for players (z-score not OPS+) then regroup on player ID. (Avg on season is a group on year of just OPS. join player stats on year is cogroup of both avg and player stats. Group on player id is a group and flatten. Instead, group decorate flatten on full player stats is already subsumed into cost, and player id is too. The exception (and this is likely one) is if the join table is small enough to do a HashMap join; in that case it's a reduce of just the full OPS list, map-only HashMap join, final group. In next chapter, will be one where join totally loses.)
  - Group-decorate-flatten-flatten:
    - group by team, flatten by year?
    - note that violating third normal form (no functional dependency on non-key, eg div lg team in a player year row -- the div & lg are fixed
  - Rollup Summary Statistics at Multiple Levels
    - Show m/r job doing both summaries at same time, and using summaries directly.
    - Introduce notion of holistic?
    - (but not cube)

### More

* SQL-hive-pig cheatsheet

___________________________________________________________________________

  - adv.pig	udfs	(When do UDFs, compare JRuby UDF to Java UDF to Stream, and cite difference in $AWS cluster time and $ programmer salary to wait the extra time.
  - stats		Counting Distinct Values in a Column Approximately
  - adv.pig		Storing and Loading to/from a Database
  - adv.pig	sparse	‘merge-sparse’. This is useful for cases when both joined tables are pre-sorted and indexed, and the right-hand table has few ( < 1% of its total) matching keys. http://pig.apache.org/docs/r0.12.0/perf.html#merge-sparse-joins
  - stats	genrte	Generating Consecutive Numeric Values
  - store		Saving a Query Result in a Table
  - todo		Using Sequence Generators as Counters
  - stats		Calculating a Median (stats chapter)
  - stats	advagg	Computing Averages Without High and Low Values (Trimmed Mean by rejecting max and min values)
  - stats	agg2	Counting Missing Values (COUNT - COUNT_STAR)
  - stats	genrte	Creating a Sequence Column and Generating Sequence Values
  - stats	genrte	Extending the Range of a Sequence Column
  - stats	genrte	Generating Frequency Distributions
  - stats	genrte	Generating Random Numbers
  - stats	genrte	Generating Repeating Sequences
  - stats	maybe	Calculating Linear Regressions or Correlation Coefficients
  - stats	advagg	Transposing Columns into Records
  - stats	assego	Calculating the Standard Deviation (with summarizer)

  - stats	ntiles	Find Outliers Using the 1.5-Inter-Quartile-Range Rule
  - stats?		Transposing a Result Set
  - eventlog		Fill in Missing Dates (apply fill gaps pattern)
  - stats	sample	Sample a Fixed Number of Records with Reservoir Sampling
  - select	sample	Selecting Random Items from a Set of Records (and much more in stats) (`DEFINE rand RANDOM('12345'); ... FOREACH foo GENERATE rand();`, but that is same random number for each mapper!! Can you do this for SAMPLE?)
  - eventlog		Identifying Overlapping Date Ranges
  - eventlog		Parsing an IP Address or Hostname (and while we're at it, reverse dot the hostname)
  - eventlog		Sorting Dotted-Quad IP Values in Numeric Order
  - eventlog		Sorting Hostnames in Domain Order
  - munging		Choose a String Data Type (-> munging-- get it the hell into utf-8)

  - intro	pigslow	(Really hammer the point that Pig is in practice faster -- reading small files / local mode for tiny jobs, combining splits, writing combiners; ...
  - intro	usage	(mention that 'SET' on its own dumps the config)
