
___________________________________________________________________________

## From Originals:

### MySQL Cookbook

* Writing Pig Programs
  - intro		Checking for Errors
  - gotchas		Handling Special Characters and NULL Values in Statements
* Selecting Data from Tables
  - select		Specifying Which Rows to Select
  - select		Specifying Which Columns to Select
  - select		Giving Better Names to Query Result Columns
  - select		WHERE Clauses and Column Aliases
  - distinct		Removing Duplicate Rows
  - transform		Working with NULL Values
  - select		Writing Comparisons Involving NULL in Programs
* Transforming Data
  - transform		Combining Columns to Construct Composite Values
  - sorting		Sorting a Result Set
  - union		Selecting Data from More Than One Table
  - sorting		Selecting Rows from the Beginning or End of a Result Set
  - sorting		Selecting Rows from the Middle of a Result Set
  - ?global val		Calculating LIMIT Values from Expressions
* Table Management
  - self-join		Cloning a Table
  - store		Saving a Query Result in a Table
  - Adv.pig		Checking or Changing a Table’s Storage Engine (-> loadfuncs)
  - cogroup2		Generating Unique Table Names (-> table name conventions)
* Working with Strings
  - String Properties
  - gotchas		Choosing a String Data Type (-> munging-- get itmthe hell into utf-8)
  - group	aswego	Converting the Lettercase of a String
  - select	aswego	Controlling Case Sensitivity in String Comparisons and Regular Expressions
  - select	aswego	Pattern Matching with SQL Patterns; Searching for Substrings (just use regexp)
  - select		Pattern Matching with Regular Expressions
  - transform		Breaking Apart or Combining Strings
* Working with Dates and Times
  - transform	srybob	use udfs from recent pig and piggybank. Fr anything fancy use ruby
* Sorting Query Results
  - sorting		Using ORDER BY to Sort Query Results
  - sorting	nocando	Using Expressions for Sorting
  - sorting	aswego	Displaying One Set of Values While Sorting by Another
  - sorting	aswego	Controlling Case Sensitivity of String Sorts
  - evtlof		Sorting Hostnames in Domain Order
  - evtlog		Sorting Dotted-Quad IP Values in Numeric Order
  - sorting		Floating Values to the Head or Tail of the Sort Order (case statement)
* Generating Summaries
  - groupagg		Summarizing with COUNT()
  - groupagg		Summarizing with MIN(), MAX(), SUM() and AVG()
  - groupagg	nested	Using DISTINCT to Eliminate Duplicates
  - sorting		Finding Values Associated with Minimum and Maximum Values (including ties; for column or in group. Make sure to use a HashMap join)
  - grpapp	maybe	Controlling String Case Sensitivity for MIN() and MAX()
  - ??   		Dividing a Summary into Subgroups
  - groupagg	srybob	Summaries and NULL Values
  - group		Selecting Only Groups with Certain Characteristics
  - distinct		Using Counts to Determine Whether Values Are Unique
  - group	aswego	Grouping by Expression Results
  - group	histog	Categorizing Noncategorical Data
  - group	aswego	Controlling Summary Display Order
  - sorting		Finding Smallest or Largest Summary Values
  - group	grpall	Working with Per-Group and Overall Summary Values
* Generating and Using Sequences
  - stats	genrte	Creating a Sequence Column and Generating Sequence Values
  - stats	genrte	Extending the Range of a Sequence Column
  - sorting	rank	Ensuring That Rows Are Renumbered in a Particular Order
  - sorting	aswego	Starting a Sequence at a Particular Value
  - sorting	numlns	Sequencing an Unsequenced Table (or use udf)
  - todo		Using Sequence Generators as Counters
  - stats	genrte	Generating Repeating Sequences
  - sorting	rank	Numbering Query Output Rows Sequentially
* Using Multiple Tables
  - group2	semijn	Finding Rows in One Table That Match Rows in Another
  - group2	aswego	Finding Rows with No Match in Another Table
  - join	selfjn	Comparing a Table to Itself
  - group2	notjoin	Producing Master-Detail Lists and Summaries (num players who hit over 300 for each team-year, total salary, rank of salary in team, rank of ops in team) (caution against A joon B on Y group by Y)
  - join	Mnymny	Enumerating a Many-to-Many Relationship
  - sorting		Finding Rows Containing Per-Group Minimum or Maximum
Values
  - group	winloss	Computing Team Standings
  - Join		Using a Join to Fill or Identify Holes in a List
  - group2	over	Calculating Successive-Row Differences
  - group2	over	Finding Cumulative Sums and Running Averages
  - join	left	Identifying and Removing Mismatched or Unattached Rows
* Statistical Techniques Introduction
  - group		Calculating Descriptive Statistics
  - group		Per-Group Descriptive Statistics
  - stats	genrte	Generating Frequency Distributions
  - stats	agg2	Counting Missing Values (COUNT - COUNT_STAR)
  - group		(the "has never played for NYA" example)
  - stats	maybe	Calculating Linear Regressions or Correlation Coefficients
  - stats	genrte	Generating Random Numbers
  - sorting	shuffle	Randomizing a Set of Rows (rand, or join on ints, or consistent
  - select	sample	Selecting Random Items from a Set of Rows (and much more in stats)
  - sorting	rank	Assigning Ranks
* Handling Duplicates Introduction
  - distinct		Counting and Identifying Duplicates
  - distinct		Eliminating Duplicates from a Table
  - distinct	aswego	Eliminating Duplicates from a Self-Join Result
* Using Stored Routines, Triggers, and Events (-> UDF)


### SQL Cookbook

* Selecting
  - select	filter	Retrieving a Subset of Rows from a Table
  - select	filter	Finding Rows That Satisfy Multiple Conditions
  - select	project	Retrieving a Subset of Columns from a Table
  - select	project	Providing Meaningful Names for Columns
  - transform		Concatenating Column Values
  - select		Using Conditional Logic in a SELECT Statement
  - select	limit	Limiting the Number of Rows Returned
  - select	sample	Returning n Random Records from a Table
  - select	sample	Returning fractional sample of random records
  - select	filter	Finding Null Values
  - transform	ternary	Transforming Nulls into Real Values
  - select		Searching for Patterns
* Sorting Query Results
  - sorting		Returning Query Results in a Specified Order
  - sorting	aswego	Sorting by Multiple Fields; Sorting by an Expression Sorting on a Data Dependent Key (eg by era-zscore if pitcher, by ops-zscore if batter) - just generate a synthetic colimn and the project it out
  - sorting	aswego	Dealing with Nulls When Sorting (make an is_foo_null column and order by is_foo_null, foo)
* Working with Multiple Tables
  - union		Stacking One Rowset Atop Another
  - join		Combining Related Rows by Foreign Key (The solution is an example of a join, or more accurately an equi-join, which is a type of inner join. A join is an operation that combines rows from two tables into one. An equi-join is one in which the join condition is based on an equality condition (e.g., where one department number equals another). An inner join is the original type of join; each row returned contains data from each table.)
  - join	intsct	Finding Rows in Common Between Two Tables
  - setops	diffnce	Retrieving Values from One Table That Do Not Exist in Another (set difference; players in batting but not pitching -- or in one but not other (symmetric difference)
  - join	antijn	Retrieving Rows from One Table That Do Not Correspond to Rows in Another (non-allstars: can do this with an outer join, because cross product won't screw you up)
  - join	multi	Adding Joins to a Query Without Interfering with Other Joins (join bats on allstars inner and hof outer)
  - group2	seteql	Determining Whether Two Tables Have the Same Data (is symmetric difference empty)  -
  - join	note	Performing Outer Joins When Using Aggregates (join a b and c, but many-to-many is causing trouble. Remember, a join is just a cogroup and flatten (with its implicit cross).
  - omit		Using NULLs in Operations and Comparisons
* Working with Strings
  - flatten		Walking a String
  - transform	aswego	Embedding Quotes Within String Literals
  - transform	gsub	Replacing and Removing from a String
  - select	regex	Determining Whether a String Is Alphanumeric
  - transform	aswego	Converting a Number to its String Representation (and Back)
  - group	ownsake	Creating a Delimited List Within a Field from Table Rows (denormalizing multiple values into one field)
  - group		Converting Delimited Data into a Tuple or Bag (remember flatten tuple = columns, flatten bag = rows)
  - eventlog		Parsing an IP Address or Hostname (and while we're at it, reverse dot the hostname)
* Working with Numbers
  - groupagg		Computing an Average; Finding the Min/Max Value in a Group; Summing the Values in a Group; Counting Rows in a Group
  - groupagg	byall	Finding the Min/Max Value in a Column; Summing or Averaging the Values in a Column; Counting Rows in a Table
  - groupagg	bykey	stdev using datafu udf
  - groupagg		Counting Distinct Values in a Group (nested distinct)
  - distinct		Counting Distinct Values in a Column (DISTINCT)
  - group2	over	Generating a Running Total (over and stitch)
  - sorting?		Calculating a Mode (histogram and max)
  - stats		Calculating a Median (stats chapter)
  - stats	ntiles	Find Outliers Using the 1.5-Inter-Quartile-Range Rule
  - group2	global	Determining the Percentage of a Total (use "scalar projection", or cheat.
  - groupagg	aswego	Aggregating Nullable Columns (NULL values don't get counted in an average. To have them be counted, ternary into a zero)
  - stats	advagg	Computing Averages Without High and Low Values (Trimmed Mean by rejecting max and min values)
  - transform	aswego	Converting Alphanumeric Strings into Numbers (cast with (int))
  - group		Counting Items in a Bag (use datafu.CountEach)
  - transform		(make the games data into normal form by taking the players tuple, transposing it to positions)
* Date Arithmetic
  - transform	aswego	Date Arithmetic (just point to)
  - eventlog		Filling in Missing Dates (apply fill gaps pattern)
  - eventlog		Identifying Overlapping Date Ranges
  - join	fill	Filling in Missing Values in a Range of Values
  - stat	genrte	Generating Consecutive Numeric Values
* Advanced Searching
  - sorting	topk	Selecting the Top n Records (order limit)
  - sorting	topk	Finding Records with the Highest and Lowest Values (even when there are ties -- use Over with
  - group2	over	Investigating Future Rows,Shifting Row Values
  - sorting		Ranking Results (note rank on its own sequentially numbers 1,2,3,4,5,6; on a column, itdoesnt use all integers: nondense is 1,2,2,4,5,5 dense is 1,2,2,3,4,4
  - sorting	rank	Ranking Records within a group (order in nested; stitch and over)
  - sorting?	over	(placing next or prev value with tuple, or running diff)
* Reporting and Warehousing
  - cube	rollup	Calculating Simple Subtotals
  - cube	cube	Calculating Subtotals for All Possible Expression Combinations
  - cube	aswego	Dealing with null Values in a CUBE
  - transform	xplode	(Expanding Ranges into Fixed Intervals)
  - join	direct	(is qualified: join on team)
* Odds ‘n’ Ends
  - stats?		Transposing a Result Set
  - transform		Parsing Serialized Data into Rows
  - groupagg		Calculating Percent Relative to Total
  - group2		Testing for Existence of a Value Within a Group
  - group2		Answering Questions Involving Negation (player info for player who have not played for the yankees; cant do join(filter teamyear!=NYA). Need to do antijoin of(filter == nya) or use the summing trick! Generate is_inthere and then do max or sum. Quoting Rozenshtein’s book: "To find out “who does not,” first find out “who does” and then get rid of them." (Is there an "IN"? And which is best?) (a stupid plan: cogroup(filter bags for nya, filter rows for bag isEmpty))

  - group		Questions Involving “at Most”: Eg select players who played for at most two different teams.
  - distinct		(select at most N seasons for a player, drop rest)
  - group2		(questions involving all: all players who played against every team during years they played. Use count(distinct teams) might work except that teams might vary over years. For example, if you are asked to find people who eat all vegetables, you are essentially looking for people for whom there is no vegetable that they do not eat. This type of problem statement is typically categorized as relational division. With questions regarding “any,” it is crucial you pay close attention to how the question is phrased. Consider the difference between these two requirements: “a student who takes any class” and “a plane faster than any train.” The former implies, “find a student who takes at least one class,” while the latter implies “find a plane that is faster than all trains.”
