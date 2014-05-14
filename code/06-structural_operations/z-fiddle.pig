
-- foo = LIMIT bat_yrs 1;
--
-- bob = FOREACH foo GENERATE
--   (1,2) AS tup:tuple(a:int, b:int),
--   1 AS val:int,
--   (1)   AS tup1:tuple(a:int);
--
-- bob = FOREACH bob GENERATE
--   TOTUPLE(tup), TOTUPLE(1), TOTUPLE(tup1);
-- DUMP bob;
-- DESCRIBE bob;


CREATE TABLE test(in_d DECIMAL(6,3),   in_f FLOAT,         digits INT,
                  out_dd DECIMAL(6,3), out_fd DECIMAL(6,3), 
                  out_df FLOAT,        out_ff FLOAT);

INSERT INTO test(in_d, digits) VALUES (12.6,  0);
INSERT INTO test(in_d, digits) VALUES (12.5,  0);
INSERT INTO test(in_d, digits) VALUES (12.35, 0);
INSERT INTO test(in_d, digits) VALUES (12.25, 0);
INSERT INTO test(in_d, digits) VALUES (12.0,  0);
INSERT INTO test(in_d, digits) VALUES (11.6,  0);
INSERT INTO test(in_d, digits) VALUES (11.5,  0);
INSERT INTO test(in_d, digits) VALUES (11.35, 0);
INSERT INTO test(in_d, digits) VALUES (11.25, 0);
INSERT INTO test(in_d, digits) VALUES (11.0,  0);
INSERT INTO test(in_d, digits) VALUES (10.5,  0);
INSERT INTO test(in_d, digits) VALUES ( 9.5,  0);
INSERT INTO test(in_d, digits) VALUES ( 8.5,  0);
INSERT INTO test(in_d, digits) VALUES ( 7.5,  0);
INSERT INTO test(in_d, digits) VALUES (1.0,   0);
INSERT INTO test(in_d, digits) VALUES (0.0,   0);

INSERT INTO test(in_d, digits) SELECT -in_d, 0 FROM test 
  WHERE (in_d > 0) AND (digits = 0) ORDER BY in_d;

INSERT INTO test(in_d, digits) SELECT in_d, 1 FROM test 
  WHERE (digits = 0) ORDER BY in_d;

UPDATE test SET in_f = in_d;

UPDATE test SET 
  out_dd = ROUND(in_d, digits), -- round decimal to decimal
  out_fd = ROUND(in_f, digits), -- round float   to decimal
  out_df = ROUND(in_d, digits), -- round decimal to float
  out_ff = ROUND(in_f, digits)  -- round float   to float
;


SELECT test.*, out_dd - out_fd AS q1, out_df - out_ff AS q2
  FROM test
  ORDER BY digits ASC, ABS(in_d) DESC, q1, q2;


-- oracle    away from zero  away from zero
-- posgresql away from zero  (no yuo)
-- websql    away from zero  away from zero

-- 12.35	12.35000038147	1	12.4	12.4	12.39999961853	12.39999961853	1	1
-- -12.35	-12.35000038147	1	-12.4	-12.4	-12.39999961853	-12.39999961853	1	1
-- -11.25	-11.25	1	-11.3	-11.2	-11.300000190735	-11.199999809265	0	0
-- 11.25	11.25	1	11.3	11.2	11.300000190735	11.199999809265	0	0
-- 12.25	12.25	1	12.3	12.2	12.300000190735	12.199999809265	0	0
-- -12.25	-12.25	1	-12.3	-12.2	-12.300000190735	-12.199999809265	0	0
-- 10.5    10.5    0       11      10      11      10      0       0
-- -10.5   -10.5   0       -11     -10     -11     -10     0       0
-- -9.5    -9.5    0       -10     -10     -10     -10     1       1
-- 9.5     9.5     0       10      10      10      10      1       1
-- -8.5    -8.5    0       -9      -8      -9      -8      0       0
-- 8.5     8.5     0       9       8       9       8       0       0
-- 7.5     7.5     0       8       8       8       8       1       1
-- -7.5    -7.5    0       -8      -8      -8      -8      1       1
