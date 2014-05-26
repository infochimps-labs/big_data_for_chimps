

### Eliminating Records

* Selecting Records Based on a Condition (~1.2 Retrieving a Subset of Rows from a Table, 1.8 Using Conditional Logic in a SELECT Statement)
  - Selecting Records that Satisfy Multiple Conditions (~1.3)
  - Selecting Records that Match a Regular Expression (~1.13 Searching for Patterns)

* Projecting Chosen Columns from a Table (~1.4 Retrieving a Subset of Columns from a Table, ~1.5 Providing Meaningful Names for Columns, ~1.6)



* Selecting a Fixed Limit of Records (~1.9 Limiting the Number of Rows Returned)

* Selecting a Random Sample of Records (~1.10 Returning n Random Records from a Table)

### Transforming Records

* Working with Null Values
  - ~1.11 Finding Null Values
  - ~1.12 Transforming Nulls into Real Values

* Working with Strings
  - ~1.7 Concatenating Column Values

### Tables

* ~3.1 Stacking One Rowset Atop Another


### Join

3.2 Combining Related Rows
3.3 Finding Rows in Common Between Two Tables
3.4 Retrieving Values from One Table That Do Not Exist in Another
3.5 Retrieving Rows from One Table That Do Not Correspond to Rows in Another
3.6 Adding Joins to a Query Without Interfering with Other Joins
3.7 Determining Whether Two Tables Have the Same Data

  - Dealing with Nulls in Joins and Groups (~3.12 Using NULLs in Operations and Comparisons)

  - not: ~3.8 Identifying and Avoiding Cartesian Products
  - not: ~3.9 Performing Joins When Using Aggregates
  - not: ~3.10 Performing Outer Joins When Using Aggregates
3.11 Returning Missing Data from Multiple Tables


### Ordering Records

* Sorting All Records in Total Order (~2.1 Returning Query Results in a Specified Order)
  - (~2.2 Sorting by Multiple Fields)
  - Dealing with Nulls When Sorting (~2.5)
  - not: ~2.3 Sorting by Substrings
  - not: ~2.4 Sorting Mixed Alphanumeric Data
  - not: ~2.6 Sorting on a Data Dependent Key
* Sorting Records within a Group





1	1	1	Retrieving All Rows and Columns from a Table
1	2	2	Retrieving a Subset of Rows from a Table
1	3	2	Finding Rows That Satisfy Multiple Conditions
1	4	3	Retrieving a Subset of Columns from a Table
1	5	3	Providing Meaningful Names for Columns
1	6	4	Referencing an Aliased Column in the WHERE Clause
1	7	5	Concatenating Column Values
1	8	7	Using Conditional Logic in a SELECT Statement
1	9	8	Limiting the Number of Rows Returned
1	10	9	Returning n Random Records from a Table
1	11	11	Finding Null Values
1	12	11	Transforming Nulls into Real Values
1	13	12	Searching for Patterns
2	1	14	Returning Query Results in a Specified Order
2	2	15	Sorting by Multiple Fields
2	3	16	Sorting by Substrings
2	4	17	Sorting Mixed Alphanumeric Data
2	5	20	Dealing with Nulls When Sorting
2	6	26	Sorting on a Data Dependent Key
3	1	28	Stacking One Rowset Atop Another
3	2	30	Combining Related Rows
3	3	31	Finding Rows in Common Between Two Tables
3	4	33	Retrieving Values from One Table That Do Not Exist in Another
3	5	38	Retrieving Rows from One Table That Do Not Correspond to Rows in Another
3	6	40	Adding Joins to a Query Without Interfering with Other Joins
3	7	42	Determining Whether Two Tables Have the Same Data
3	8	49	Identifying and Avoiding Cartesian Products
3	9	50	Performing Joins When Using Aggregates
3	10	55	Performing Outer Joins When Using Aggregates
3	11	58	Returning Missing Data from Multiple Tables
3	12	62	Using NULLs in Operations and Comparisons
4	1	64	Inserting a New Record
4	2	64	Inserting Default Values
4	3	66	Overriding a Default Value with NULL
4	4	66	Copying Rows from One Table into Another
4	5	67	Copying a Table Definition
4	6	68	Inserting into Multiple Tables at Once
4	7	70	Blocking Inserts to Certain Columns
4	8	71	Modifying Records in a Table
4	9	72	Updating When Corresponding Rows Exist
4	10	73	Updating with Values from Another Table
4	11	77	Merging Records
4	12	78	Deleting All Records from a Table
4	13	79	Deleting Specific Records
4	14	79	Deleting a Single Record
4	15	80	Deleting Referential Integrity Violations
4	16	80	Deleting Duplicate Records
4	17	82	Deleting Records Referenced from Another Table
5	1	84	Listing Tables in a Schema
5	2	85	Listing a Table’s Columns
5	3	86	Listing Indexed Columns for a Table
5	4	88	Listing Constraints on a Table
5	5	89	Listing Foreign Keys Without Corresponding Indexes
5	6	93	Using SQL to Generate SQL
5	7	95	Describing the Data Dictionary Views in an Oracle Database
6	1	97	Walking a String
6	2	100	Embedding Quotes Within String Literals
6	3	101	Counting the Occurrences of a Character in a String
6	4	102	Removing Unwanted Characters from a String
6	5	103	Separating Numeric and Character Data
6	6	107	Determining Whether a String Is Alphanumeric
6	7	112	Extracting Initials from a Name
6	8	116	Ordering by Parts of a String
6	9	117	Ordering by a Number in a String
6	10	123	Creating a Delimited List from Table Rows
6	11	129	Converting Delimited Data into a Multi-Valued IN-List
6	12	135	Alphabetizing a String
6	13	141	Identifying Strings That Can Be Treated As Numbers
6	14	147	Extracting the nth Delimited Substring
6	15	154	Parsing an IP Address
7	1	157	Computing an Average
7	2	159	Finding the Min/Max Value in a Column
7	3	161	Summing the Values in a Column
7	4	162	Counting Rows in a Table
7	5	165	Counting Values in a Column
7	6	165	Generating a Running Total
7	7	168	Generating a Running Product
7	8	171	Calculating a Running Difference
7	9	172	Calculating a Mode
7	10	175	Calculating a Median
7	11	179	Determining the Percentage of a Total
7	12	182	Aggregating Nullable Columns
7	13	183	Computing Averages Without High and Low Values
7	14	185	Converting Alphanumeric Strings into Numbers
7	15	187	Changing Values in a Running Total
8	1	190	Adding and Subtracting Days, Months, and Years
8	2	193	Determining the Number of Days Between Two Dates
8	3	195	Determining the Number of Business Days Between Two Dates
8	4	200	Determining the Number of Months or Years Between Two Dates
8	5	202	Determining the Number of Seconds, Minutes, or Hours Between Two Dates
8	6	204	Counting the Occurrences of Weekdays in a Year
8	7	216	Determining the Date Difference Between the Current Record and the Next Record
9	1	222	Determining If a Year Is a Leap Year
9	2	229	Determining the Number of Days in a Year
9	3	232	Extracting Units of Time from a Date
9	4	235	Determining the First and Last Day of a Month
9	5	237	Determining All Dates for a Particular Weekday Throughout a Year
9	6	244	Determining the Date of the First and Last Occurrence of a Specific Weekday in a Month
9	7	251	Creating a Calendar
9	8	270	Listing Quarter Start and End Dates for the Year
9	9	275	Determining Quarter Start and End Dates for a Given Quarter
9	10	282	Filling in Missing Dates
9	11	291	Searching on Specific Units of Time
9	12	292	Comparing Records Using Specific Parts of a Date
9	13	295	Identifying Overlapping Date Ranges
10	1	301	Locating a Range of Consecutive Values
10	2	306	Finding Differences Between Rows in the Same Group or Partition
10	3	315	Locating the Beginning and End of a Range of Consecutive Values
10	4	320	Filling in Missing Values in a Range of Values
10	5	324	Generating Consecutive Numeric Values
11	1	328	Paginating Through a Result Set
11	2	331	Skipping n Rows from a Table
11	3	334	Incorporating OR Logic When Using Outer Joins
11	4	337	Determining Which Rows Are Reciprocals
11	5	338	Selecting the Top n Records
11	6	340	Finding Records with the Highest and Lowest Values
11	7	342	Investigating Future Rows
11	8	345	Shifting Row Values
11	9	348	Ranking Results
11	10	350	Suppressing Duplicates
11	11	352	Finding Knight Values
11	12	359	Generating Simple Forecasts
12	1	368	Pivoting a Result Set into One Row
12	2	370	Pivoting a Result Set into Multiple Rows
12	3	378	Reverse Pivoting a Result Set
12	4	380	Reverse Pivoting a Result Set into One Column
12	5	383	Suppressing Repeating Values from a Result Set
12	6	387	Pivoting a Result Set to Facilitate Inter-Row Calculations
12	7	388	Creating Buckets of Data, of a Fixed Size
12	8	392	Creating a Predefined Number of Buckets
12	9	397	Creating Horizontal Histograms
12	10	399	Creating Vertical Histograms
12	11	403	Returning Non-GROUP BY Columns
12	12	408	Calculating Simple Subtotals
12	13	412	Calculating Subtotals for All Possible Expression Combinations
12	14	421	Identifying Rows That Are Not Subtotals
12	15	423	Using Case Expressions to Flag Rows
12	16	425	Creating a Sparse Matrix
12	17	426	Grouping Rows by Units of Time
12	18	430	Performing Aggregations over Different Groups/Partitions Simultaneously
12	19	432	Performing Aggregations over a Moving Range of Values
12	20	439	Pivoting a Result Set with Subtotals
13	1	445	Expressing a Parent-Child Relationship
13	2	448	Expressing a Child-Parent-Grandparent Relationship
13	3	454	Creating a Hierarchical View of a Table
13	4	462	Finding All Child Rows for a Given Parent Row
13	5	466	Determining Which Rows Are Leaf, Branch, or Root Nodes
14	1	474	Creating Cross-Tab Reports Using SQL Server’s PIVOT Operator
14	2	476	Unpivoting a Cross-Tab Report Using SQL Server’s UNPIVOT Operator
14	3	478	Transposing a Result Set Using Oracle’s MODEL Clause
14	4	482	Extracting Elements of a String from Unfixed Locations
14	5	485	Finding the Number of Days in a Year (an Alternate Solution for Oracle)
14	6	486	Searching for Mixed Alphanumeric Strings
14	7	489	Converting Whole Numbers to Binary Using Oracle
14	8	492	Pivoting a Ranked Result Set
14	9	496	Adding a Column Header into a Double Pivoted Result Set
14	10	507	Converting a Scalar Subquery to a Composite Subquery in Oracle
14	11	509	Parsing Serialized Data into Rows
14	12	513	Calculating Percent Relative to Total
14	13	515	Creating CSV Output from Oracle
14	14	520	Finding Text Not Matching a Pattern (Oracle)
14	15	523	Transforming Data with an Inline View
14	16	524	Testing for Existence of a Value Within a Group
