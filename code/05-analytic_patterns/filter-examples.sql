-- ==== FILTER
--      select only seasons since 1900:
SELECT bat_season.* FROM bat_season
  WHERE year_id >= 1900
  ;

-- ==== FILTER .. BY MATCHES
--      uses a regular expression to select players whose names are similar to your authors':

SELECT people.* FROM people
  WHERE name_first RLIKE "^Q.*" OR nameFirst RLIKE ".*lip.*"
  ;

-- ==== LIMIT
--      Retrieve only a set of records arbitrarily:

SELECT bat_season.* FROM bat_season LIMIT 25 ;


-- === LIMIT..OFFSET
--     Find the 95th percentile for our stats: G, PA, H, BB, HBP, OBP, SLG, OPS

-- find the row to get -- for lahman 2012, it's 2052
-- 41041	2052.05	10260.25	20520.50
SELECT COUNT(*), 0.05*COUNT(*), 0.25*COUNT(*), 0.50*COUNT(*) FROM bat_season WHERE PA > 60 AND year_id > 1900;

-- Find the 95th percentile values for our topline stats
SELECT H, BB, HBP, 2B, 3B, HR, G, PA, ROUND(OBP,3), ROUND(SLG,3), ROUND(OPS,3)
  FROM
    (SELECT H   FROM bat_season WHERE PA > 60 AND year_id > 1900 ORDER BY H   DESC LIMIT 1 OFFSET 2052) topH,
    (SELECT BB  FROM bat_season WHERE PA > 60 AND year_id > 1900 ORDER BY BB  DESC LIMIT 1 OFFSET 2052) topBB,
    (SELECT HBP FROM bat_season WHERE PA > 60 AND year_id > 1900 ORDER BY HBP DESC LIMIT 1 OFFSET 2052) topHBP,
    (SELECT 2B  FROM bat_season WHERE PA > 60 AND year_id > 1900 ORDER BY 2B  DESC LIMIT 1 OFFSET 2052) top2B,
    (SELECT 3B  FROM bat_season WHERE PA > 60 AND year_id > 1900 ORDER BY 3B  DESC LIMIT 1 OFFSET 2052) top3B,
    (SELECT HR  FROM bat_season WHERE PA > 60 AND year_id > 1900 ORDER BY HR  DESC LIMIT 1 OFFSET 2052) topHR,
    (SELECT G   FROM bat_season WHERE PA > 60 AND year_id > 1900 ORDER BY G   DESC LIMIT 1 OFFSET 2052) topG,
    (SELECT PA  FROM bat_season WHERE PA > 60 AND year_id > 1900 ORDER BY PA  DESC LIMIT 1 OFFSET 2052) topPA,
    (SELECT OBP FROM bat_season WHERE PA > 60 AND year_id > 1900 ORDER BY OBP DESC LIMIT 1 OFFSET 2052) topOBP,
    (SELECT SLG FROM bat_season WHERE PA > 60 AND year_id > 1900 ORDER BY SLG DESC LIMIT 1 OFFSET 2052) topSLG,
    (SELECT OPS FROM bat_season WHERE PA > 60 AND year_id > 1900 ORDER BY OPS DESC LIMIT 1 OFFSET 2052) topOPS
  ;

-- Results for PA > 60, year > 1900:
--   
-- %ile	  Row	H	 BB	HBP	2B	3B	HR	 G	 PA	OBP	SLG	OPS
-- 95th	 2052	175	75	7	34	9	25	155	669	0.394	0.519	0.895
-- 75th	10260	124	41	3	21	4	9	132	520	0.347	0.422	0.765
-- 50th	20521	66	22	1	11	1	3	93	294	0.313	0.359	0.676
