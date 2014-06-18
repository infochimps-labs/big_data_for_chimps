IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_tm_yr();

-- NOTE move this after the self-join and many-to-many joins.

-- ***************************************************************************
--
-- === Joining Records Without Discarding Non-Matches (Outer Join)
--
-- QEM: needs prose (perhaps able to draw from prose file)

-- The Baseball Hall of Fame is meant to honor the very best in the game, and each year a very small number of players are added to its rolls. It's a significantly subjective indicator, which is its cardinal virtue and its cardinal flaw -- it represents the consensus judgement of experts, but colored to some small extent by emotion, nostalgia, and imperfect quantitative measures. But as you'll see over and over again, the best basis for decisions is the judgement of human experts backed by data-driven analysis. What we're assembling as we go along this tour of analytic patterns isn't a mathematical answer to who the highest performers are, it's a basis for centering discussion around the right mixture of objective measures based on evidence and human judgement where the data is imperfect.

-- So we'd like to augment the career stats table we assembled earlier with columns showing, for hall-of-famers, the year they were admitted, and a `Null` value for the rest. (This allows that column to also serve as a boolean indicator of whether the players were inducted). If you tried to use the JOIN operator in the form we have been, you'll find that it doesn't work. A plain JOIN operation keeps only rows that have a match in all tables, and so all of the non-hall-of-famers will be excluded from the result. (This differs from COGROUP, which retains rows even when some of its inputs lack a match for a key). The answer is to use an 'outer join'

-- (Import prose)

career_stats = FOREACH (
  JOIN 
    bat_careers BY player_id LEFT OUTER,
    batting_hof BY player_id) GENERATE
  bat_careers::player_id..bat_careers::OPS, allstars::year_id AS hof_year;    

-- Since the batting_hof table has exactly one row per player, the output has exactly as many rows as the career stats table, and exactly as many non-null rows as the hall of fame table.
--
-- footnote:[Please note that the `batting_hof` table excludes players admitted to the Hall of Fame based on their pitching record. With the exception of Babe Ruth -- who would likely have made the Hall of Fame as a pitcher if he hadn't been the most dominant hitter of all time -- most pitchers have very poor offensive skills and so are relegated back with the rest of the crowd]

-- -- (sample data)
-- -- (Hank Aaron)... Year

-- (Code to count records)

-- In this example, there will be some parks that have no direct match to location names and, of course, there will be many, many places that do not match a park. The first two JOINs we did were "inner" JOINs -- the output contains only rows that found a match. In this case, we want to keep all the parks, even if no places matched but we do not want to keep any places that lack a park. Since all rows from the left (first most dataset) will be retained, this is called a "left outer" JOIN. If, instead, we were trying to annotate all places with such parks as could be matched -- producing exactly one output row per place -- we would use a "right outer" JOIN instead. If we wanted to do the latter but (somewhat inefficiently) flag parks that failed to find a match, you would use a "full outer" JOIN. (Full JOINs are pretty rare.)
-- 
-- TODO: discuss use of left join for set intersection.
-- 
-- In a Pig JOIN it is important to order the tables by size -- putting the smallest table first and the largest table last. (You'll learn why in the "Map/Reduce Patterns" (TODO:  REF) chapter.) So while a right join is not terribly common in traditional SQL, it's quite valuable in Pig. If you look back at the previous examples, you will see we took care to always put the smaller table first. For small tables or tables of similar size, it is not a big deal -- but in some cases, it can have a huge impact, so get in the habit of always following this best practice.
-- 
-- ------
-- NOTE
-- A Pig join is outwardly similar to the join portion of a SQL SELECT statement, but notice that  although you can place simple expressions in the join expression, you can make no further manipulations to the data whatsoever in that statement. Pig's design philosophy is that each statement corresponds to a specific data transformation, making it very easy to reason about how the script will run; this makes the typical Pig script more long-winded than corresponding SQL statements but clearer for both human and robot to understand.
-- ------

-- (Note about join on null keys)
-- 
-- (Note about left-right and placement within the statement)

-- ==== Joining Tables that do not have a Foreign-Key Relationship

-- All of the joins we've done so far have been on nice clean values designed in advance to match records among tables. In SQL parlance, the career_stats and batting_hof tables both had player_id as a primary key (a column of unique, non-null values tied to each record's identity). The team_id field in the bat_seasons and park_team_years tables points into the teams table as a foreign key: an indexable column whose only values are primary keys in another table, and which may have nulls or duplicates. But sometimes you must match records among tables that do not have a polished mapping of values. In that case, it can be useful to use an outer join as the first pass to unify what records you can before you bring out the brass knuckles or big guns for what remains.

-- Suppose we wanted to plot where each major-league player grew up -- perhaps as an answer in itself as a browsable map, or to allocate territories for talent scouts, or to see whether the quiet wide spaces of country living or the fast competition of growing up in the city better fosters the future career of a high performer. While the people table lists the city, state and country of birth for most players, we must geolocate those place names -- determine their longitude and latitude -- in order to plot or analyze them.

-- There are geolocation services on the web, but they are imperfect, rate-limited and costly for commercial use footnote:[Put another way, "Accurate, cheap, fast: choose any two]. Meanwhile the freely-available geonames database gives geo-coordinates and other information on more than seven million points of interest across the globe, so for informal work it can make a lot of sense to opportunistically decorate whatever records match and then decide what to do with the rest.

geolocated_somewhat = JOIN
  people BY (birth_city, birth_state, birth_country),
  places BY (city, admin_1, country_id)

-- In the important sense, this worked quite well: XXX% of records found a match.
-- (Question do we talk about the problems of multiple matches on name here, or do we quietly handle it?)

--
-- Experienced database hands might now suggest doing a join using some sort of fuzzy-match 
-- match or some sort of other fuzzy equality. However, in map-reduce the only kind of join you can do is an "equi-join" -- one that uses key equality to match records. Unless an operation is 'transitive' -- that is, unless `a joinsto b` and `b joinsto c` guarantees `a joinsto c`, a plain join won't work, which rules out approximate string matches; joins on range criteria (where keys are related through inequalities (x < y)); graph distance; geographic nearness; and edit distance. You also can't use a plain join on an 'OR' condition: "match stadiums and places if the placename and state are equal or the city and state are equal", "match records if the postal code from table A matches any of the component zip codes of place B". Much of the middle part of this book centers on what to do when there _is_ a clear way to group related records in context, but which is more complicated than key equality. 

-- exercise: are either city dwellers or country folk over-represented among major leaguers? Selecting only places with very high or very low population in the geonames table might serve as a sufficient measure of urban-ness; or you could use census data and the methods we cover in the geographic data analysis chapter to form a more nuanced indicator. The hard part will be to baseline the data for population: the question is how the urban vs rural proportion of ballplayers compares to the proportion of the general populace, but that distribution has changed dramatically over our period of interest. The US has seen a steady increase from a rural majority pre-1920 to a four-fifths majority of city dwellers today.

