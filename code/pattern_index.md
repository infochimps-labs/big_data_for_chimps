      	Sec	 	Keyword  	Title                                                                                               		Sample Code	Prose	Integrated	Q Approved
    5 	~  	0																
    5 	0  	0	intro		Introduction                                                                                        	
    5 	a  	1	filter   	Selecting Records That Satisfy a Condition                                                          		Y          	Y    	Y
    5 	a  	2	filter   	- Selecting Records that Satisfy Multiple Conditions                                                		Y          	Y    	Y
    5 	a  	5	filter   	- Selecting Records that Match a Regular Expression                                                 		Y          	Y    	Y
    5 	a  	4	filter   	- Controlling Case Sensitivity and Other Regular Expression Modifiers                               		Y          	Y    	Y
    5 	a  	3	filter   	- Selecting or Rejecting Records with a Null Value                                                  		Y          	Y    	Y
    5 	a  	6	filter   	- Selecting Records Against a Fixed List of Lookup Values                                           		Y          	Y    	Y
    5 	b  	4	sample   	Selecting a Random Sample of Records                                                                		Y          	Y    	Y
    5 	c  	1	project  	Projecting Chosen Columns from a Table by Name                                                      		Y          	Y    	Y
    5 	c  	2	project  	- Using a FOREACH to select, rename and reorder fields                                              		Y          	Y    	Y
    5 	d  	1	limit    	Selecting a Fixed Limit of Records                                                                  		Y          	Y    	Y
    5 	f  	1	foreach  	Transforming Records Individually                                                                   		Y          	Y    	Y
    5 	f  	2	foreach  	- A Nested FOREACH Allows Intermediate Expressions                                                  		           	Y
    5 	f  	3	foreach  	Transforming Records with an External UDF                                                           		           	Y
    5 	g  	1	generate 	Assign an Increasing ID to Each Record in a Collection of Files                                     		Y
    5 	g  	2	generate 	Generating a Sequence Using an Integer Table                                                        		           	Y
    5 	g  	3	generate	Generating Data by Distributing Assignments As Input                                                	
    5 	h  	1	expand   	Expanding One Value Into a Tuple or Bag                                                             		x          	Y
    5 	h  	2	expand   	- Splitting a String into its Characters                                                            		           	Y
    5 	h  	2	expand   	- Tokenizing a String into Words                                                                    		           	Y
    5 	h  	2	expand   	- Generate a Record for Each Word in a Text Field                                                   		           	Y
    5 	h  	3	expand   	Splitting a Delimited String into a Collection of Values                                            		Y          	Y
    5 	h  	4	expand   	Flattening a Bag Generates Many Records                                                             		Y          	Y
    5 	h  	4	expand   	Flattening a Tuple Generates Many Columns                                                           		Y          	Y
    5 	m  	 	split    	Directing Data Conditionally into Multiple Data Flow                                                		           	Y
    5 	m  	 	split    	Partitioning Data into Multiple Tables By Key                                                       		           	Y
    5 	m  	 	split    	Partitioning Data into Uniform Chunks                                                               		           	Y
    5 	n  	 	union    	Cleaning Up Many Small Files by Merging into Fewer Files                                            		Y          	Y
    5 	n  	 	union    	Treating the Union of Several Tables as a Single Table                                              		           	Y
    5 	n  	 	union    	Loading Multiple Files as a Single Table                                                            		Y          	Y
                                            
    6 	0  	0	intro		Introduction                                                                                        	
    6 	a  	1	group    	Grouping Records into a Bag by Key                                                                  		Y          	Y    	Y
    6 	a  	4	group    	Representing a Collection of Values with a Delimited String                                         		Y          	Y    	Y
    6 	a  	4	group    	Representing a Complex Data Structure with a Delimited String                                       		Y          	Y    	Y
    6 	a  	5	group    	Representing a Complex Data Structure with a JSON-encoded String                                    		x          	Y    	Y
    6 	b  	1	groupagg 	Summarizing Aggregate Statistics of a Group                                                         		Y          	x
    6 	b  	2	groupagg 	- Average of all non-Null values                                                                    		Y          	x
    6 	b  	2	groupagg 	- Count of Distinct Values                                                                          		Y          	x
    6 	b  	2	groupagg 	- Count of non-Null values                                                                          		Y          	x
    6 	b  	2	groupagg 	- Median (50th Percentile Value) of a Bag                                                           		Y          	x
    6 	b  	2	groupagg 	- Minimum / Maximum non-Null value                                                                  		Y          	x
    6 	b  	2	groupagg 	- Size of Bag (Count of all values, Null or not)                                                    		Y          	x
    6 	b  	2	groupagg 	- Standard Deviation of all non-Null Values                                                         		Y          	x
    6 	b  	2	groupagg 	- Sum of non-Null values                                                                            		Y          	x
    6 	c  	3	groupagg 	Summarizing Aggregate Statistics of a Table                                                         		Y          	x
    6 	c  	4	groupagg 	Completely Summarizing the Values of a Field                                                        		Y          	x
    6 	c  	5	groupagg 	- Completely Summarizing the Values of a String Field                                               		Y          	x
    6 	c  	5	groupagg 	- Finding the Size of a String in Bytes or in Characters                                            		Y          	x
    6 	c  	 	groupagg 	- Completely Summarizing the Values of a Numeric Field                                              		Y          	x
    6 	c  	4	hist     	- Calculating Quantiles                                                                             		Y
    6 	h  	1	hist     	Calculating the Distribution of Values with a Histogram                                             		Y          	Y
    6 	h  	2	hist     	Binning Data for a Histogram                                                                        		           	Y
    6 	h  	3	hist     	Calculating a Relative Distribution Histogram                                                       		Y          	Y
    6 	h  	4	hist     	Re-injecting Global Values                                                                          		           	Y
    6 	h  	5	hist		Calculating a Histogram Within a Group                                                              	
    6 	i  	3	sumtrick 	Testing for Existence of a Value Within a Group: the Summing Trick                                  		Y          	x
    6 	i  	2	sumtrick 	Summarizing for Multiple Subsets Simultaneously                                                     		Y
    6 	i  	1	cogroup  	Putting Individual Records in Context using the Group/Decorate/Flatten Pattern                      		x
    6 	j  	1	join     	Joining Records in a Table with Corresponding Records in Another Table (Inner Join)                 		x          	Y
    6 	j  	2	join     	- Joining Records in a Table with Directly Matching Records from Another Table (Direct Inner Join)  		x          	Y
    6 	j  	2	join     	- Disambiguating Field Names With `::`                                                              		x          	Y
    6 	j  	5	join     	Joining Records Without Discarding Non-Matches (Outer Join)                                         		           	Y
    6 	j  	4	join		Joining a Table with Itself (self-join)                                                             	
    6 	j  	3	join     	Enumerating a Many-to-Many Relationship                                                             		x          	x
    6 	j  	5	join     	Joining on an Integer Table to Fill Holes in a List                                                 		Y          	x
    6 	j  	6	join		Selecting Records With No Match in Another Table (anti-join)                                        	
    6 	k  	2	cogroup  	Detecting Outliers                                                                                  		x
    6 	k  	1	join		Selecting Records Having a Match in Another Table (semi-join)                                       	
    6 	k  	4	join		- Dealing with Nulls When Grouping or Joining                                                       	
    6 	o  	1	sort     	Sorting All Records in Total Order                                                                  		Y          	Y
    6 	o  	2	sort     	- Cannot Use an Expression in an ORDER BY statement                                                 		Y          	x
    6 	o  	2	sort     	- Sorting by Multiple Fields                                                                        		Y          	x
    6 	o  	2	sort     	- Floating Values to the Head or Tail of the Sort Order                                             		Y          	x
    6 	o  	2	sort     	- Case-insensitive Sorting                                                                          		Y          	x
    6 	o  	2	sort     	- Dealing with Nulls When Sorting                                                                   		Y          	x
    6 	o  	3	sort     	Sorting Records within a Group                                                                      		Y
    6 	p  	1	sort     	Shuffle all Records in a Table                                                                      		Y
    6 	p  	4	sort     	- Shuffle all Records in a Table Consistently                                                       		Y
    6 	r  	1	rank     	Numbering Records in Rank Order                                                                     		           	x
    6 	r  	2	rank		- Handling Ties when Ranking Records                                                                	
    6 	r  	5	rank     	- Selecting Rows from the Middle of a Result Set                                                    		           	Y
    6 	r  	5	rank     	- Painfully Paginating Through a Result Set                                                         		           	Y
    6 	t  	1	topk     	Selecting Records Having the Top K Values in a Table                                                		x          	Y
    6 	t  	2	topk     	Selecting Records Having the Top K Values in a Group                                                		x          	Y
    6 	t  	3	topk		Selecting Records Associated with Maximum Values                                                    	
    6 	u  	1	distinct 	Eliminating Duplicate Records from a Table                                                          		           	Y
    6 	u  	2	distinct 	Counting and Identifying Duplicates                                                                 		           	Y
    6 	u  	3	distinct 	Selecting Records with Unique (or with Duplicate) Values for a Key                                  		x          	x
    6 	v  	1	setops   	Set Operations                                                                                      		Y          	Y
    6 	v  	2	setops   	- Distinct Union                                                                                    		Y          	Y
    6 	v  	2	setops   	- Set Difference                                                                                    		Y          	Y
    6 	v  	2	setops   	- Set Equality                                                                                      		Y          	Y
    6 	v  	2	setops   	- Set Intersection                                                                                  		Y          	Y
    6 	v  	2	setops   	- Symmetric Set Difference                                                                          		Y          	Y
    6 	x  	1	cogroup  	Co-Grouping Records Across Tables by Common Key                                                     		           	Y
    6 	x  	1	cogroup  	Computing a Win-Expectancy Table                                                                    		Y          	x
    6 	x  	1	cogroup  	Computing a Won-Loss Record                                                                         		x          	Y
    6 	x  	1	cogroup  	Performing a Join-and-Aggregate with COGROUP                                                        		           	Y
    6 	x  	2	cogroup		- Dealing with Nulls in COGROUP operations (outer-join equivalent)                                  	
    6 	x  	3	join		- Why Flatten Can Be Dangerous                                                                      	
    6 	x  	 	groupover	Generating Cumulative Sums and Running Averages                                                     		x
    6 	y  	 	rollup		Cube                                                                                                	
    6 	y  	 	rollup		Rollup                                                                                              	
    6 	~  	0																
    7 	f  	2	foreach		(Below are things to opportunistically cover if natural opportunity presents -- not frontline material)	
    7 	f  	2	foreach		- Concatenating Several Values into a Single String                                                 	
    7 	f  	2	foreach		- Converting the Lettercase of a String                                                             	
    7 	f  	2	foreach		- Extracting Characters from a String by Offset                                                     	
    7 	f  	2	foreach		- Handling Special Characters in Strings                                                            	
    7 	f  	2	foreach		- Transforming Nulls into Real Values                                                               	
    7 	f  	2	foreach		- Working with Null Values                                                                          	
    7 	f  	2	foreach		- Formatting a String According to a Template                                                       	
    7 	f  	2	foreach		- Replacing Sections of a String using a Regular Expression                                         	
                                            
    7 	a  	3	group		- Nested GROUP BY                                                                                   	
    7 	h  	2	hist		- Mode (Most Frequent Value) of a Bag                                                               	
    7 	x  	4	cogroup		Producing Master-Detail Lists and Summaries                                                         	
    7 	h  	5	expand		Transposing Records into Attribute-Value Pairs                                                      	
    7 	h  	5	expand		Histogram on Multiple Fields Simultaneously



==== Nested GROUP BY


==== Selecting Rows from the Middle of a Result Set




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
