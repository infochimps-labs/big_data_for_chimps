
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


----
    # generate 100 files of 100,000 integers each; takes about 15 seconds to run
    time ruby -e '10_000_000.times.map{|num| puts num }' | gsplit -l 100000 -a 2 --additional-suffix .tsv -d - numbers

    # in mapper, read N and generate `(0 .. 99).map{|offset| 100 * N + offset }`
----

--
-- ==== Generate a won-loss record
--

SELECT t.teamID, ev.team_id, t.yearID, ev.year_ID,
    t.W, ev.wins,
    t.L, ev.loss,
    t.G - (t.W + t.L)  AS bdb_ties, ev.ties AS rs_ties,
    t.G, ev.G, t.Ghome AS bdb_Ghome, ev.Ghome AS rs_Ghome,
    ABS(t.W - ev.wins) + ABS(t.L - ev.loss) + ABS(t.G - ev.G) + ABS(t.Ghome - ev.Ghome) AS diff
  FROM      lahman.teams t
  RIGHT JOIN (
    SELECT team_id, year_id, SUM(win) AS wins, SUM(loss) AS loss, SUM(tie) AS ties,
        SUM(home_team) AS Ghome, COUNT(*) AS G
      FROM (
        SELECT home_team_id AS team_id, year_ID,
            1 AS home_team,
            IF ((forfeit_info = "" AND home_runs_ct > away_runs_ct) OR forfeit_info = "H", 1,0) AS win,
            IF ((forfeit_info = "" AND home_runs_ct < away_runs_ct) OR forfeit_info = "V", 1,0) AS loss,
            IF ((forfeit_info = "" AND home_runs_ct = away_runs_ct), 1,0) AS tie
          FROM games
          WHERE year_ID < 2013
        UNION ALL
        SELECT away_team_id AS team_id, year_ID,
            0 AS home_team,
            IF ((forfeit_info = "" AND home_runs_ct < away_runs_ct) OR forfeit_info = "V", 1,0) AS win,
            IF ((forfeit_info = "" AND home_runs_ct > away_runs_ct) OR forfeit_info = "H", 1,0) AS loss,
            IF ((forfeit_info = "" AND home_runs_ct = away_runs_ct), 1,0) AS tie
          FROM games
          WHERE year_ID < 2013
        ) g1
      GROUP BY team_id, year_ID
    ) ev
  ON ev.team_ID = IF(t.teamID = "LAA", "ANA", t.teamID) AND ev.year_id = t.yearID
  WHERE (ABS(t.W - ev.wins) + ABS(t.L - ev.loss) + ABS(t.G - ev.G) + ABS(t.Ghome - ev.Ghome) > 0)
  ORDER BY yearID DESC, diff DESC
  ;

in pig, just use FLATTEN and do the counting trick


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

-- Median

-- This is hard at scale. Use approximate median

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


-- === Counting on multiple levels
-- fraction of people with multiple stints per year (about 7%)

-- don't do this (needs two group-bys):
SELECT n_seasons, COUNT(*), COUNT(*)/n_seasons
  FROM (SELECT COUNT(*) AS n_seasons FROM batting) t1,
  (SELECT COUNT(*) AS n_stints FROM batting GROUP BY playerID, yearID HAVING n_stints > 1) stintful
  ;
-- instead use the summing trick (needs only one group-by):
SELECT COUNT(*), (COUNT(*)-SUM(IF(stint = 1, 1, 0)))/COUNT(*), COUNT(*) FROM batting WHERE stint <= 2;

--
-- === Putting tables in context with JOIN and friends
--

-- Direct Join: Extend Records with Uniquely Matching Records from Another Table
-- hang weight, height and BMI off of their OPS (overall hitting); ISO ("isolated power");
-- and number of stolen bases per time on base (loosely tied to speed)
--
SELECT bat.playerID, peep.nameCommon, begYear,
    peep.weight, peep.height,
    703*peep.weight/(peep.height*peep.height) AS BMI, -- measure of body type
    PA, OPS, ISO, IF(OBP*PA>0,SB/(OBP*PA),0) AS SBrate
  FROM bat_career bat
  JOIN people peep ON bat.playerID = peep.playerID
  WHERE PA > 500 AND begYear > 1910
  ORDER BY SBrate DESC
  ;

-- (add note) Joins on null values are dropped even when both are null. Filter nulls. (I can't come up with a good example of this)
-- (add note) in contrast, all elements with null in a group _will_ be grouped as null. This can be dangerous when large number of nulls: all go to same reducer

-- ==== Join against an integer table to Fill in Holes in a List

-- Take the a histogram showing stolen bases by season and make it have an entry for each row

SELECT idx, SB, n_SB
  FROM      (SELECT idx FROM numbers WHERE idx <= 138) nums
  LEFT JOIN (SELECT SB AS SB, COUNT(*) AS n_SB
    FROM bat_season bat GROUP BY SB) hist
  ON hist.SB = nums.idx
  ORDER BY idx ASC
;

-- To keep also the count of rows with NULL values for SB, use the has-a-null column of the numbers table:

SELECT ixN, SB, n_SB
  FROM      (SELECT ixN FROM numbers WHERE ixN <= 138) nums
  LEFT JOIN (SELECT SB AS SB, COUNT(*) AS n_SB
    FROM bat_season bat GROUP BY SB) hist
  ON hist.SB = nums.ixN OR (hist.SB IS NULL AND nums.ixN IS NULL)
  ORDER BY ixN ASC
;

-- You might also enjoy the random number table, holding 350 million 64-bit numbers directly from random.org (7 GB of 20-digit decimal numbers)
-- * 160-bit numbers in hexadecimal form
-- * 32 64-bit numbers (2048-bits per row)
-- 

-- Comparing a Table to Itself (Self-join)
-- teammates (played for same team same season, discarding second and later
-- stints; players half table?)  note that we're cheating a bit: players may
-- change teams during the season (happens in about 7% of player seasons). We're
-- only going to use the first stint of a season.

-- need to do this off combined table (batting only right now)
SELECT b1.playerID, b2.playerID, b1.nameCommon, b2.nameCommon, b1.teamID, b1.yearID
  FROM bat_war b1, bat_war b2
  WHERE b1.teamID = b2.teamID          -- same team
    AND b1.yearID = b2.yearID          -- same season
    AND b1.stint = 1 AND b2.stint = 1  -- don't match players to multiple teams per year
    AND b1.playerID != b2.playerID     -- reject self-teammates
  ORDER BY yearID DESC, teamID ASC, b1.playerID ASC

-- note the explosion: 90k player-seasons lead to 3,104,324 teammate-year pairs.
-- the distinct pairing is 2 million

SELECT DISTINCT b1.playerID, b2.playerID, b1.nameCommon, b2.nameCommon
  FROM bat_war b1, bat_war b2
  WHERE b1.teamID = b2.teamID          -- same team
    AND b1.yearID = b2.yearID          -- same season
    AND b1.stint = 1 AND b2.stint = 1  -- don't match players to multiple teams per year
    AND b1.playerID != b2.playerID     -- reject self-teammates
  ORDER BY b1.playerID ASC, b2.playerID ASC
  ;

-- Grouping the teammate pairs
--
SELECT b1.playerID, b1.nameCommon, GROUP_CONCAT(b2.playerID), b1.teamID, b1.yearID
  FROM bat_war b1, bat_war b2
  WHERE b1.teamID = b2.teamID          -- same team
    AND b1.yearID = b2.yearID          -- same season
    AND b1.stint = 1 AND b2.stint = 1  -- don't match players to multiple teams per year
    AND b1.playerID != b2.playerID     -- reject self-teammates
  GROUP BY b1.yearID, b1.playerID
  ORDER BY yearID DESC, playerID ASC
 ;

-- === Sparse join for matching: geo names for stadiums
--     using a left join so you can fix up remnants
--     note: haven't actually run this, need to load geonames

SELECT pk.*
  FROM      parks pk
  LEFT JOIN geonames.places gn
    ON (pk.city = gn.city AND pk.state = gn.region1)
    OR (pk.parkname = gn.placename)
;

-- See advanced joins: bag left outer join from DataFu
-- See advanced joins: Left outer join on three tables: http://datafu.incubator.apache.org/docs/datafu/guide/more-tips-and-tricks.html
-- See Time-series: Range query using cross
-- See Time-series: Range query using prefix and UDFs
-- See advanced joins: Sparse joins for filtering, with a HashMap (replicated)
-- Out of scope: Bitmap index
-- Out of scope: Bloom filter joins
-- See time-series: Self-join for successive row differences

-- === Enumerating a Many-to-Many Relationship

-- Every stadium a player has played in. (We're going to cheat on the detail of
-- multiple stints and credit every player with all stadiums visited by the team
-- of his first stint in a season
--

-- there are only a few many-to-many cases, so the 89583 seasons in batting
-- table expands to only 91904 player-park-years. But it's a cross product, so
-- beware.
SELECT COUNT(*) FROM batting bat WHERE bat.stint = 1;
SELECT bat.playerID, bat.teamID, bat.yearID, pty.parkID
  FROM       batting bat
  INNER JOIN park_team_years pty
    ON bat.yearID = pty.yearID AND bat.teamID = pty.teamID
  WHERE bat.stint = 1
  ORDER BY playerID
  ;

--
-- What if you only want the distinct player-team-years?
-- You might naively do a join and then a group by,
-- or a join and then distinct. Don't do that.

-- DON'T DO THE (pig equivalent) OF THIS to find the distinct teams, years and parks;
-- it's an extra reduce.
SELECT bat.playerID, bat.nameCommon,
    GROUP_CONCAT(DISTINCT pty.parkID) AS parkIDs, COUNT(DISTINCT pty.parkID) AS n_parks,
    GROUP_CONCAT(DISTINCT bat.teamID) AS teamIDs,
    MIN(bat.yearID) AS begYear, MAX(bat.yearID) AS endYear
  FROM       bat_war bat
  INNER JOIN park_team_years pty
    ON bat.yearID = pty.yearID AND bat.teamID = pty.teamID
  WHERE bat.stint = 1 AND playerID IS NOT NULL
  GROUP BY playerID
  HAVING begYear > 1900
  ORDER BY n_parks DESC, playerID ASC
  ;

--
-- So now we disclose the most important thing that SQL experts need to break
-- their brains of:
--
-- In SQL, the JOIN is supreme.
-- In Pig, the GROUP is supreme
--
-- A JOIN is, for the most part, just sugar around a COGROUP-and-FLATTEN.
-- Very often you'll find the simplest path is through COGROUP not JOIN.
--
-- In this case, if you start by thinkingn of the group, you'll see you can eliminate a whole reduce.
--
-- (show pig, including a DISTINCT in the fancy-style FOREACH)

--
-- === Finding rows with a match in another table (semi-join)
--
--     Semi-join: just care about the match, don't keep joined table; anti-join
--     is where you keep the non-matches and also don't keep the joined
--     table. Again, use left or right so that the small table occurs first in
--     the list.  note that a semi-join has only one row per row in dominant
--     table -- so needs to be a cogroup and sum or a join to distinct'ed table
--     (extra reduce, but lets you do a fragment replicate join.)
--

-- Select player seasons where they made the all-star team.
-- You might think you could do this with a join:
--
-- !! Don't do this !! generates extra rows
SELECT bats.*
  FROM       bat_season  bats
  INNER JOIN allstarfull ast
  ON (bats.`playerID` = ast.`playerID` AND bats.`yearID` = ast.`yearID`)
  ;
-- but there were multiple All-Star games (!) in 1959-1962
--
-- In pig, you do
--
-- FOREACH allstarfull GENERATE playerID;
-- COGROUP bat_season BY playerID and allstarfull BY playerID;
-- FILTER BY NOT isEmpty(allstarfull);
-- FOREACH GENERATE FLATTEN(bat_season)
--
-- ... although you might do a distinct-then-fragment join if the discarded table is small
SELECT bats.*
  FROM bat_season bats
  INNER JOIN (SELECT DISTINCT playerID, yearID FROM allstarfull) ast
  ON (bats.`playerID` = ast.`playerID` AND bats.`yearID` = ast.`yearID`)
  ;

-- === Finding rows with no match in another table (anti-join)
--     .... same as semi-join, but discard matches
--
SELECT bats.*
  FROM      bat_season bats
  LEFT JOIN (SELECT DISTINCT playerID, yearID FROM allstarfull) ast
    ON (bats.`playerID` = ast.`playerID` AND bats.`yearID` = ast.`yearID`)
  WHERE ast.playerID IS NULL
  ;
--
-- FOREACH allstarfull GENERATE playerID;
-- COGROUP bat_season BY playerID and allstarfull BY playerID;
-- FILTER BY isEmpty(allstarfull);
--

-- === Handling duplicates

-- === Eliminating Duplicates from a Table

-- Every team a player has played for
SELECT DISTINCT playerID, teamID from batting;

-- Eliminating Duplicates from a Query Result:
--
-- All parks a team has played in
--
SELECT teamID, GROUP_CONCAT(DISTINCT parkID ORDER BY parkID) AS parkIDs
  FROM park_team_years
  GROUP BY teamID
  ORDER BY teamID, parkID DESC
  ;

-- Finding records with a duplicated field
-- group by, then emit bags with more than one size; call back to the won-loss example

-- Teams who played in more than one stadium in a year
SELECT COUNT(*) AS n_parks, pty.*
  FROM park_team_years pty
  GROUP BY teamID, yearID
  HAVING n_parks > 1

-- Eliminating rows that have a duplicated value (ie the whole row isn't distinct,
-- just the field you're distinct-ing on.
-- Note: this chooses an arbitrary value from each group
SELECT COUNT(*) AS n_asg, ast.*
  FROM allstarfull ast
  GROUP BY yearID, playerID
  HAVING n_asg > 1
  ;

-- * Selecting Only Groups with Certain Characteristics
-- * Determining Whether Values are Unique

-- Unique first names

-- * Distinct: players with a unique first name (once again we urge you: crawl through your data. Big data is a collection of stories; the power of its unusual effectiveness mode comes from the comprehensiveness of those stories. even if you aren't into baseball this celebration of the diversity of our human race and the exuberance of identity should fill you with wonder.)
--
-- But have you heard recounted the storied diamond exploits of Firpo Mayberry,
-- Zoilo Versalles, Pi Schwert or Bevo LeBourveau?  OK, then how about
-- Mysterious Walker, The Only Nolan, or Phenomenal Smith?  Mul Holland, Sixto
-- Lezcano, Welcome Gaston or Mox McQuery?  Try asking your spouse to that your
-- next child be named for Urban Shocker, Twink Twining, Pussy Tebeau, Bris Lord, Boob
-- Fowler, Crazy Schmit, Creepy Crespi, Cuddles Marshall, Vinegar Bend Mizell,
-- or Buttercup Dickerson.
--

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

-- === Set Operations

-- Partition a Set into Subsets: SPLIT, but keep in mind that the SPLIT operation doesn't short-circuit.
-- Find the Union of Sets UNION-then-DISTINCT
--    (note that it doesn't dedupe, doesn't order, and doesn't check for same schema)
--    * don't combine the career stats tables by union-group; do it with cogroup.
-- Prepare a Distinct Set from a Collection of Records: DISTINCT
-- Intersect: semi-join (allstars)
-- * Difference (in a but not in b): cogroup keep only empty (non-allstars)
-- * Equality (use symmetric difference): result should be empty
-- * Symmetric difference: in A or B but not in A intersect B -- do this with aggregation: count 0 or 1 and only keep 1
-- * http://datafu.incubator.apache.org/docs/datafu/guide/set-operations.html
-- * http://www.cs.tufts.edu/comp/150CPA/notes/Advanced_Pig.pdf
--
-- === Structural Group Operations (ie non aggregating)
--
-- * GROUP/COGROUP To Restructure Tables
-- * Group Elements From Multiple Tables On A Common Attribute (COGROUP)
-- * Denormalize Normalized
--   - roll up stints
--   - Normalize Denormalized (flatten)
-- * Join is a Group and Flatten
-- * So sometimes you want a group
-- * Group flatten regroup
--     * OPS+ -- group on season, normalize, reflatten
--     * player's highest OPS+: season, normalize, flatten, group on player, top
-- * See statistics chapter: Transpose Numeric Data
--
-- === Sorting and Ordering
--
-- * Operations on the order of records: Sorting, Shuffling, Ranking and Numbering
--   - ORDER by multiple fields: sort on OPS to three places then use games then playerid
--   - note value of stabilizing list
-- - (how do NULLs sort?)
-- - ASC / DESC: fewest strikeouts per plate appearance


-- Finding Values Associated with Maximum Values

-- For each season by a player, select the team they played the most games for.
-- In SQL, this is fairly clumsy (involving a self-join and then elimination of
-- ties) In Pig, we can ORDER BY within a foreach and then pluck the first
-- element of the bag.

SELECT bat.playerID, bat.yearID, bat.teamID, MAX(batmax.Gmax), MAX(batmax.stints), MAX(teamIDs), MAX(Gs)
  FROM       batting bat
  INNER JOIN (SELECT playerID, yearID, COUNT(*) AS stints, MAX(G) AS Gmax, GROUP_CONCAT(teamID) AS teamIDs, GROUP_CONCAT(G) AS Gs FROM batting bat GROUP BY playerID, yearID) batmax
  ON bat.playerID = batmax.playerID AND bat.yearID = batmax.yearID AND bat.G = batmax.Gmax
  GROUP BY playerID, yearID
  -- WHERE stints > 1
  ;

-- About 7% of seasons have more than one stint; only about 2% of seasons have
-- more than one stint and more than a half-season's worth of games
SELECT COUNT(*), SUM(mt1stint), SUM(mt1stint)/COUNT(*) FROM (SELECT playerID, yearID, IF(COUNT(*) > 1 AND SUM(G) > 77, 1, 0) AS mt1stint FROM batting GROUP BY playerID, yearID) bat

-- TOP(topN, sort_column_idx, bag_of_tuples)
-- must have an explicit field -- can't use an expression

-- Leaderboard By Season-and-league

-- GROUP BY yearID, lgID

-- There is no good way to find the tuples associated with the minimum value.
-- EXERCISE: make a "BTM" UDF, having the same signature as the "TOP" operation,
-- to return the lowest-n tuples from a bag.

-- EXERCISE: find the Bill James' "Gray Ink" score for each player: four points
--   per season they were in the top ten for HR, RBI or AVG; three points for R,
--   H, SLG; two points for 2B, BB or SB, and one point for each season in the
--   top ten for G, AB or 3B.  (See
--   http://baseball-reference.com/about/leader_glossary.shtml[Baseball
--   Reference] for a bit more of a description and the pitching equivalent).
--   uses GROUP-TOP-FOREACH (isEmpty ? 1 : 0)-GROUP-FOREACH (summing and
--   weighting the composite pieces of ink.


-- 
-- === Sorting Operations
-- 



* RANK: Dense, not dense
* Number records with a serial or unique index
  - use rank with (the dense that give each a number)
  - use file name index and row number in mapper (ruby UDF)
* Sorting Subsets of a Table (order inside cogroup)
* Controlling Summary Display Order
* Sorting and NULL Values; Controlling Case Sensitivity of String Sorts
* 
-- ==== Top K Records within a table using ORDER..LIMIT
--      Most hr in a season
--      Describe pigs optimization of order..limit


-- ==== Season leaders

-- * Selecting top-k Records within Group
-- GROUP...FOREACH GENERATE TOP
-- most hr season-by-season

-- ==== Transpose record into attribute-value pairs
--      Group by season, transpose, and take the top 10 for each season, attribute pair


* Pulling a Section from the Middle of a Result Set: rank and filter? Modify the quantile/median code?

* Hard in SQL but easy in Pig: Finding Rows Containing Per-Group Minimum or Maximum Value, Displaying One Set of Values While Sorting by Another: 
--  - can only ORDER BY an explicit field. In SQL you can omit the sort expression from the table (use expression to sort by)
* Sorting a Result Set (when can you count on reducer order?)

-- ====  Shuffle a set of records
--         See notes on random numbers.

-- Note: ORDER BY is NOT stable; can't guarantee that records with same keys will keep same order
-- * Note about ORDER BY and keys across reducers -- for example, you can't do the sort | uniq trick

-- === In statistics Chapter
--
-- ==== Cube and rollup
-- stats by team, division and league

--
-- TODO
--
-- cogroup events by teamID
-- ... there's a way to do this in one less reduce in M/R -- can you in Pig?

-- === in Time-series chapter
--
-- * Running total http://en.wikipedia.org/wiki/Prefix_sum
-- * prefix sum value; by combining list ranking, prefix sums, and Euler tours, many important problems on trees may be solved by efficient parallel algorithms.[3]
-- * Self join of table on its next row (eg timeseries at regular sample)
--
-- === how to do these
--
-- * Computing Team Standings
-- * Producing Master-Detail Lists and Summaries
-- * Find Overlapping Rows
-- * Find Gaps in Time-Series
-- * Find Missing Rows in Series / Count all Values
-- * Calculating Differences Between Successive Rows
-- * Finding Cumulative Sums and Running Averages



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- == Tables
--
-- * `games`
--
-- * `events`: the amazing Retrosheet project has _play-by-play_ information for
--   nearly every game since the 1970s. By the time
--
-- * `pitchfx`: a true reminder that we live in the future, Major League
--   Baseball makes available the trajectory of every pitch from every game with
--   full game state since 2007.
--
-- * `allstarfull` table: About halfway through a season, players with a particularly strong
--   performance (or fanbase) are elected to the All-Star game.
--
-- * `halloffame` table: Players with exceptionally strong careers (or particularly strong fanbase
--   among old white journalists) are elected to the Hall of Fame (hof).
--
--
-- * playerID: unique identifier for each player, built from their name and an ascending index
-- * teamID: three-letter unique identifier for a team
-- * parkID: five-letter unique identifier for a park (stadium)
-- * G (Games): the number of 
