
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Transforming Data
--

-- Foreach: transforming fields and naming them
-- Note that the IF eliminates both 0 and NULL
SELECT
  playerID, yearID, teamIDs, G, PA, H, HR,
  IF(AB>0,  (H / AB), 0)                         AS BAVG,
  IF(PA>0,  (H + 2B + 2 * 3B + 3 * HR), 0)       AS TB,
  IF(AB>0, ((H + 2B + 2 * 3B + 3 * HR) / AB), 0) AS SLG,
  IF(PA>0, ((H + BB + IFNULL(HBP,0))   / PA), 0) AS OBP
  FROM bat_season bat
  ;

-- Fancy Foreach: find OBP and SLG, then find OPS
-- Pretend we had assembled above into the table
SELECT
  playerID, yearID, teamIDs, G, PA, H, HR, BAVG, SLG, OBP, SLG,
  (SLG + OBP)     AS OPS,
  ((TB - H) / AB) AS ISO
  FROM bat_season bat
  ;

-- Binning records:
SELECT 100*CEIL(H / 100) AS H_bin, COUNT(*), nameCommon
  FROM bat_career bat
  GROUP BY H_bin
  ;

-- Generating Pairs
-- is there a way to do the SQL version more elegantly?
SELECT
    IF(home_team_id <= away_team_id, home_team_id, away_team_id) AS team_a,
    IF(home_team_id <= away_team_id, away_team_id, home_team_id) AS team_b,
    COUNT(*)
  FROM events ev
GROUP BY home_team_id, away_team_id
ORDER BY home_team_id, away_team_id
;

-- COALESCE requires datafu:
-- define COALESCE datafu.pig.util.Coalesce();
-- or use ternary: eg (isEmpty(A) ? 0 : First(A))

* Working with NULL Values: Negating a Condition on a Column That Contains NULL Values Section; Writing Comparisons Involving NULL in Programs; Mapping NULL Values to Other Values
-- concatenating bag
-- https://github.com/jeromatron/pygmalion/blob/master/udf/src/main/java/org/pygmalion/udf/RangeBasedStringConcat.java
* Calculating Differences Between Successive Rows
* Finding Cumulative Sums and Running Averages
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Expanding Data
--

-- === Flatten

-- There's no good FLATTEN or string split operator in MySQL without bullshit like a join on an integer table

-- separate advances in a retrosheet event:
-- FLATTEN STRSPLIT(REGEX_EXTRACT(event_cd, "\\.(.*)", 1) , ";")

-- Tokenize words

-- Split characters
-- Use FLATTEN(STRSPLIT("(?!^)"))

-- See text chapter: Wordbag
-- See statistics chapter: transpose data
-- See eventlog chapter: dividing intervals
-- See statistics chapter: Generating data

-- === Generating an Integers table

DROP TABLE IF EXISTS numbers1k;
CREATE TABLE `numbers1k` (
  `idx`  INT(20) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `ix0`  INT(20) UNSIGNED NOT NULL DEFAULT '0',
  `ixN`  INT(20) UNSIGNED          DEFAULT '0',
  `ixS`  INT(20) SIGNED   NOT NULL DEFAULT '0',
  `zip`  INT(1)  UNSIGNED NOT NULL DEFAULT '0',
  `uno`  INT(1)  UNSIGNED NOT NULL DEFAULT '1'
) ENGINE=INNODB DEFAULT CHARSET=utf8;

INSERT INTO numbers1k (ix0, ixN, ixS, zip, uno)
SELECT 
  (@row := @row + 1) - 1 AS ix0, 
  IF(@row=1, NULL, @row-2) AS ixN,
  (@row - 500) AS ixS,
  0 AS zip, 1 AS uno
 FROM 
(select 0 union all select 1 union all select 3 union all select 4 union all select 5 union all select 6 union all select 6 union all select 7 union all select 8 union all select 9) t,
(select 0 union all select 1 union all select 3 union all select 4 union all select 5 union all select 6 union all select 6 union all select 7 union all select 8 union all select 9) t2, 
(select 0 union all select 1 union all select 3 union all select 4 union all select 5 union all select 6 union all select 6 union all select 7 union all select 8 union all select 9) t3,
(SELECT @row:=0) r
;


DROP TABLE IF EXISTS numbers;
CREATE TABLE `numbers` (
  `idx`  INT(20) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `ix0`  INT(20) UNSIGNED NOT NULL DEFAULT '0',
  `ixN`  INT(20) UNSIGNED          DEFAULT '0',
  `ixS`  INT(20) SIGNED   NOT NULL DEFAULT '0',
  `zip`  INT(1)  UNSIGNED NOT NULL DEFAULT '0',
  `uno`  INT(1)  UNSIGNED NOT NULL DEFAULT '1'
) ENGINE=INNODB DEFAULT CHARSET=utf8;

INSERT INTO numbers (ix0, ixN, ixS, zip, uno)
SELECT
  (@row := @row + 1) - 1 AS ix0, 
  IF(@row=1, NULL, @row-2) AS ixN,
  (@row - 500000) AS ixS,
  0 AS zip, 1 AS uno
FROM
(SELECT zip FROM numbers1k) t1, 
(SELECT zip FROM numbers1k) t2,
(SELECT @row:=0) r
;


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Eliminating Data
--

-- === Filter ===

-- Select only seasons since 1900
SELECT bat_season.* FROM bat_season
  WHERE yearID >= 1900
  ;
-- Select players whose name starts with 'Q' or is in the 'Phil/Flip/Felipe' family
-- note: SQL is non-case-sensitive
SELECT people.* FROM people
  WHERE nameFirst RLIKE "^Q.*" OR nameFirst RLIKE "lip"
  ;
-- Select at-bats with three straight caught-looking strikes (the most ignominious of outcomes)
SELECT events.* FROM events
  WHERE pitch_seq_tx RLIKE '.*C.*C.*C'
  ;

-- example with isNull, isEmpty

-- FILTER batting by AB IS NULL

-- make a note about floating-point comparison: < etc is OK, otherwise use ABS( (val1 - val2)/val1 ) < tol

-- === Limit **

-- Limit on whole table is not super-useful apart from extracting data to work with
SELECT bat_season.* FROM bat_season LIMIT 25 ;
-- Can't do this:
SELECT bat_season.* FROM bat_season LIMIT 25 OFFSET 50;

-- === Projection ===

-- fancy word for a boring obvious-seeing operation: selecting only some of the fields
-- mentioned because (a) you'll hear people use the word 'projection', and (b) it's not as obvious as it seems

-- Get just the teams a player played for in a year
SELECT playerID, yearID, teamID FROM batting;

-- === Sample ===

-- Consistent sample of events
SELECT ev.event_id,
    LEFT(MD5(ev.game_id),4) AS gid_hash,
    LEFT(MD5(CONCAT(ev.game_id, ev.event_id)), 4) AS evid_hash,
    ev.*
  FROM events ev
  WHERE LEFT(MD5(CONCAT(ev.game_id, ev.event_id)), 2) = '00';

-- Consistent sample of games -- all events from the game are retained
-- FLO200310030 has gid_hash 0000... and evid_hash 0097 and so passes both
SELECT ev.event_id,
    LEFT(MD5(ev.game_id),4) AS gid_hash,
    LEFT(MD5(CONCAT(ev.game_id, ev.event_id)), 4) AS evid_hash,
    ev.*
  FROM events ev
  WHERE LEFT(MD5(ev.game_id),2) = '00';


-- Out of 1962193 events in the 2010, 7665 expected (1/256th of the total);
-- got 8159 by game, 7695 by event
SELECT n_events, n_events/256, n_by_game, n_by_event
  FROM
    (SELECT COUNT(*) AS n_events    FROM events) ev,
    (SELECT COUNT(*) AS n_by_event  FROM events WHERE LEFT(MD5(CONCAT(game_id,event_id)),2) = '00') ev_e,
    (SELECT COUNT(*) AS n_by_game   FROM events WHERE LEFT(MD5(game_id),2) = '00') ev_g
    ;


--
-- === Filter with a sparse join

-- Select player seasons where they made the all-star team. There were multiple
-- All-Star games (!) in 1959-1962 so we have to select distinct
SELECT bats.*
  FROM bat_season bats
  INNER JOIN (SELECT DISTINCT playerID, yearID FROM allstarfull) ast
  ON (bats.`playerID` = ast.`playerID` AND bats.`yearID` = ast.`yearID`)
;

-- COGROUP bat_season and allstarfull
-- FILTER on size of allstarfull bag > 1


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Aggregation
--

-- Group on year; find COUNT(), count distinct, MIN(), MAX(), SUM(), AVG(), STDEV(), byte size

SELECT 
    MIN(HR)              AS hr_min, 
    MAX(HR)              AS hr_max, 
    AVG(HR)              AS hr_avg, 
    STDDEV_POP(HR)       AS hr_stddev,
    SUM(HR)              AS hr_sum, 
    COUNT(*)             AS n_recs,
    COUNT(*) - COUNT(HR) AS hr_n_nulls, 
    COUNT(DISTINCT HR)   AS hr_n_distinct -- doesn't count NULL
  FROM bat_season bat
;

SELECT 
    MIN(nameFirst)                     AS nameFirst_min, 
    MAX(nameFirst)                     AS nameFirst_max,
    --
    MIN(CHAR_LENGTH(nameFirst))        AS nameFirst_strlen_min, 
    MAX(CHAR_LENGTH(nameFirst))        AS nameFirst_strlen_max, 
    MIN(OCTET_LENGTH(nameFirst))       AS nameFirst_bytesize_max, 
    MAX(OCTET_LENGTH(nameFirst))       AS nameFirst_bytesize_max, 
    AVG(CHAR_LENGTH(nameFirst))        AS nameFirst_strlen_avg, 
    STDDEV_POP(CHAR_LENGTH(nameFirst)) AS nameFirst_strlen_stddev,
    LEFT(GROUP_CONCAT(nameFirst),25)   AS nameFirst_examples,
    SUM(CHAR_LENGTH(nameFirst))        AS nameFirst_strlen_sum,
    --    
    COUNT(*)                           AS n_recs,
    COUNT(*) - COUNT(nameFirst)        AS nameFirst_n_nulls, 
    COUNT(DISTINCT nameFirst)          AS nameFirst_n_distinct
  FROM bat_career bat
;

SELECT
  playerID,
  MIN(yearID) AS yearBeg,
  MAX(yearID) AS yearEnd,
  COUNT(*)    AS n_years,
    MIN(HR)              AS hr_min, 
    MAX(HR)              AS hr_max, 
    AVG(HR)              AS hr_avg, 
    STDDEV_POP(HR)       AS hr_stddev,
    SUM(HR)              AS hr_sum, 
    COUNT(*)             AS n_recs,
    COUNT(*) - COUNT(HR) AS hr_n_nulls, 
    COUNT(DISTINCT HR)   AS hr_n_distinct -- doesn't count NULL
  FROM bat_season bat
  GROUP BY playerID
  ORDER BY hr_max DESC
;

-- Count seasons per team
SELECT
  teamID, COUNT(*) AS n_seasons, MIN(yearID) as yearBeg, MAX(yearID) as yearEnd
  FROM teams tm
  GROUP BY teamID
  ORDER BY n_seasons DESC, teamID ASC
;

-- Histogram of Stolen Bases per season

SELECT
  SB, COUNT(*) AS n_SB
  FROM bat_season bat
  GROUP BY SB
  ORDER BY SB DESC
;

-- Histogram using a numbers table

SELECT ixN, SB, n_SB
FROM numbers
LEFT JOIN (SELECT
  SB AS SB, COUNT(*) AS n_SB
  FROM bat_season bat
  GROUP BY SB) hr_hist
  ON SB = ixN OR (SB IS NULL AND ixN IS NULL)
WHERE ixN <= 138 OR ixN IS NULL
ORDER BY ixN ASC
;

-- Median

SELECT COUNT(*), CEIL(COUNT(*)/2) AS midrow 
  FROM bat_career 
 ;
 
SELECT G, cols.*
  FROM bat_career bat,
    (SELECT COUNT(*) AS n_entries, CEIL(COUNT(*)/2) AS midrow FROM bat_career) cols
  ORDER BY HR
  LIMIT 1 OFFSET 8954
;

-- won-loss record by teams (sorted pair, home_win_a, away_win_a, home_win_b, away_win_b, other__check
* Selecting Only Groups with Certain Characteristics

-- === Cube and rollup
-- stats by team, division and league

-- 
-- === Putting tables in context with JOIN and friends
-- 

* Direct Join: Extend Records with Uniquely Matching Records from Another Table
  - hang full names off records from master file
* (add note) Joins on null values are dropped even when both are null. Filter nulls.

* Comparing a Table to Itself
* Self-join: teammates (played for same team same season, discarding second and later stints; players half table?)

* All those were guaranteed to have matches. 
* Many-to-many join: teams to stadiums; players to teams (Enumerating a Many-to-Many Relationship)
  - cogroup on team-year, flatten...
  - or join park-team-year table on player-team-year by team-year
  - note problem with stints, flag players with multiple stints.

* Sparse join for filtering: hall of fame table
* Left join: annotate with hall-of-fame
* Finding Rows with No Match in Another Table
* Semi-join: just care about the match, don't keep joined table; anti-join is where you keep the non-matches and also don't keep the joined table. Again, use left or right so that the small table occurs first in the list.
  - note that a semi-join has only one row per row in dominant table -- so needs to be a cogroup and sum or a join to distinct'ed table (extra reduce, but lets you do a fragment replicate join.)

--semijoin.pig daily = load 'NYSE_daily' as (exchange:chararray, symbol:chararray,            date:chararray, open:float, high:float, low:float,            close:float, volume:int, adj_close:float); divs  = load 'NYSE_dividends' as (exchange:chararray, symbol:chararray,            date:chararray, dividends:float); grpd  = cogroup daily by (exchange, symbol), divs by (exchange, symbol); sjnd  = filter grpd by not IsEmpty(divs); final = foreach sjnd generate flatten(daily)

* Sparse join for matching: geo names for stadiums
  - use a left join so you can fix up remnants

* Section 12-10 Using a Join to Fill in Holes in a List

Joseph scala park Saturday 10-2pm

* See advanced joins: bag left outer join from DataFu
* See advanced joins: Left outer join on three tables: http://datafu.incubator.apache.org/docs/datafu/guide/more-tips-and-tricks.html
* See Time-series: Range query
    * using cross
    * using prefix and UDFs

* See advanced joins: Sparse joins for filtering
    * HashMap (replicated) join
    * bloom filter join
* Out of scope: Bitmap index
* Out of scope: Bloom filter joins
* See time-series: Self-join for successive row differences

=== Handling duplicates

* Eliminating Duplicates from a Table
  - overall: park ids
  - game appearances: events table, group by game id, distinct
  - can also do a sum
* Eliminating Duplicates from a Query Result:
    * and from a Self-Join Result Section

* Don't do a sort-uniq or sort-count using pig ORDER because it doesn't put all of key on same reducer

* Getting the duplicated values -- group by, then emit bags with more than one size; call back to the won-loss example
  - player-stints?
* Using DISTINCT to Eliminate Duplicates
* Eliminating rows that have a duplicated value (ie you're not comparing the whole thing) 
* Finding Values Associated with Minimum and Maximum Values
* Selecting Only Groups with Certain Characteristics
* Determining Whether Values are Unique

-- Unique first names

-- But have you heard recounted the storied diamond exploits of Firpo Mayberry,
-- Zoilo Versalles, Pi Schwert or Bevo LeBourveau?  OK, then how about
-- Mysterious Walker, The Only Nolan, or Phenomenal Smith?  Mul Holland, Sixto
-- Lezcano, Welcome Gaston or Mox McQuery?  Try asking your spouse to that your
-- next child be named for Urban Shocker, Twink Twining, Pussy Tebeau, Bris Lord, Boob
-- Fowler, Crazy Schmit, Creepy Crespi, Cuddles Marshall, Vinegar Bend Mizell,
-- or Buttercup Dickerson.
* Distinct: players with a unique first name (once again we urge you: crawl through your data. Big data is a collection of stories; the power of its unusual effectiveness mode comes from the comprehensiveness of those stories. even if you aren't into baseball this celebration of the diversity of our human race and the exuberance of identity should fill you with wonder.)
SELECT nameFirst, nameLast, COUNT(*) AS n_usages
  FROM bat_career
  WHERE    nameFirst IS NOT NULL
  GROUP BY nameFirst
  HAVING   n_usages = 1
  ORDER BY nameFirst
  ;
* Counting Missing Values
* Counting and Identifying Duplicates
* Determining Whether Values are Unique

=== Set Operations

* Partition: SPLIT.
* Union (note that it doesn't dedupe and doesn't order)
    * don't combine the career stats tables by union-group; do it with cogroup.
    * distinct union: ???
* Distinct (collection to set)
* Intersect: semi-join (allstars)
* Difference (in a but not in b): cogroup keep only empty (non-allstars)
* Equality (use symmetric difference): result should be empty
* Symmetric difference: in A or B but not in A intersect B -- do this with aggregation: count 0 or 1 and only keep 1
* http://datafu.incubator.apache.org/docs/datafu/guide/set-operations.html
* http://www.cs.tufts.edu/comp/150CPA/notes/Advanced_Pig.pdf

=== Structural Group Operations (ie non aggregating)

* GROUP/COGROUP To Restructure Tables
* Group Elements From Multiple Tables On A Common Attribute (COGROUP)
* Denormalize Normalized
  - roll up stints
  - Normalize Denormalized (flatten)
* Join is a Group and Flatten
* So sometimes you want a group
* Group flatten regroup
    * OPS+ -- group on season, normalize, reflatten
    * player's highest OPS+: season, normalize, flatten, group on player, top
* See statistics chapter: Transpose Numeric Data

=== Sorting and Ordering

* Operations on the order of records: Sorting, Shuffling, Ranking and Numbering
  - ORDER by multiple fields: sort on OPS to three places then use games then playerid
  - note value of stabilizing list
  - (how do NULLs sort?)
  - ASC / DESC: fewest strikeouts per plate appearance
  - in SQL you can omit the sort expression from the table (use expression to sort by) -- is this also true in Pig?
* Sorting a Result Set (when can you count on reducer order?)
* Displaying One Set of Values While Sorting by Another
* Note about ORDER BY and keys across reducers
* RANK: Dense, not dense
* Number records with a serial or unique index
  - use rank with (the dense that give each a number)
  - use file name index and row number in mapper (ruby UDF)
* Sorting Subsets of a Table (order inside cogroup)
* Controlling Summary Display Order
* Sorting and NULL Values; Controlling Case Sensitivity of String Sorts
* Top K Records within a table using ORDER..LIMIT
    * whole table: most hr in a season
    * most hr season-by-season
* Selecting Records from the Beginning or End of a Result Set (Smallest or Largest Summary Values)
    * Top K Within a Group using GROUP...FOREACH GENERATE TOP
* Pulling a Section from the Middle of a Result Set: rank and filter? Modify the quantile/median code?
* Finding Values Associated with Minimum and Maximum Values
* Finding Rows Containing Per-Group Minimum or Maximum Values
* Shuffle a set of records
    * See notes on random numbers.
    * Don't use the pig ORDER operation for this (two passes) (can you count on the built-in sort?)

=== in Time-series chapter

* Running total http://en.wikipedia.org/wiki/Prefix_sum
* prefix sum value; by combining list ranking, prefix sums, and Euler tours, many important problems on trees may be solved by efficient parallel algorithms.[3]
* Self join of table on its next row (eg timeseries at regular sample)

=== how to do these

* Computing Team Standings
* Producing Master-Detail Lists and Summaries
* Find Overlapping Rows
* Find Gaps in Time-Series
* Find Missing Rows in Series / Count all Values


