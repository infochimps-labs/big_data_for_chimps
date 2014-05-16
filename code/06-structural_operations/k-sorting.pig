


-- Sort the seasons table by OPS


-- Find the top 20 seasons by OPS.  Pig is smart about eliminating records at
-- the map stage, dramatically decreasing the data size.




-- Use ORDER BY within a nested FOREACH to sort within a group. Here, we select
-- the top ten players by OPS for each season.  The first request to sort a
-- group does not require extra operations -- Pig simply specifies those fields
-- as secondary sort keys.



-- To select the records having the highest value for an expression, it does not
-- work to use MAX (that gives the value but not the records) and it does not
-- work to use ORDER BY .. LIMIT 1 (there might be more than one record).
-- Instead, use

-- An alternative is to use the 


