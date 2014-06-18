
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
	-- ==== Selecting or Rejecting Records with a Null Value
	-- ==== Use a HashMap (Replicated) Join when Joining Small-ish to Large-ish
	-- ==== Dealing with Nulls When Grouping or Joining
	-- === Why Flatten Can Be Dangerous
	-- === Producing Master-Detail Lists and Summaries
	-- ==== Dealing with Nulls (outer-join equivalent)
	-- === Performing a Join-and-Aggregate with COGROUP
	-- === Cube
	-- === Rollup
	-- ==== Painfully Paginating Through a Result Set
	-- ==== Eliminating rows that have a duplicated value
