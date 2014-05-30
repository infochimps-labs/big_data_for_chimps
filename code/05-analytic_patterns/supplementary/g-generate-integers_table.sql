
DROP TABLE IF EXISTS numbers1k;
CREATE TABLE `numbers1k` (
  `num`    INT(20) PRIMARY KEY AUTO_INCREMENT,
  `from_0` INT(20) NOT NULL DEFAULT '0',
  `w_null` INT(20)          DEFAULT '0',
  `zip`    INT(1)  NOT NULL DEFAULT '0',
  `uno`    INT(1)  NOT NULL DEFAULT '1'
) DEFAULT CHARSET=ascii;

INSERT INTO numbers1k (from_0, w_null, zip, uno)
SELECT
    (@row := @row + 1) - 1   AS from_0,
    IF(@row=1, NULL, @row-2) AS w_null,
    0                        AS zip,
    1                        AS uno
  FROM
    (select 0 union all select 1 union all select 3 union all select 4 union all select 5 union all select 6 union all select 6 union all select 7 union all select 8 union all select 9) t,
    (select 0 union all select 1 union all select 3 union all select 4 union all select 5 union all select 6 union all select 6 union all select 7 union all select 8 union all select 9) t2,
    (select 0 union all select 1 union all select 3 union all select 4 union all select 5 union all select 6 union all select 6 union all select 7 union all select 8 union all select 9) t3,
    (SELECT @row:=0) rr
  ;

DROP TABLE IF EXISTS numbers;
CREATE TABLE `numbers` (
  `num`    INT(20) PRIMARY KEY AUTO_INCREMENT,
  `from_0` INT(20) NOT NULL DEFAULT '0',
  `w_null` INT(20)          DEFAULT '0',
  `zip`    INT(1)  NOT NULL DEFAULT '0',
  `uno`    INT(1)  NOT NULL DEFAULT '1'
) DEFAULT CHARSET=ascii;
 
INSERT INTO numbers (from_0, w_null, zip, uno)
SELECT
    (@row := @row + 1) - 1   AS from_0,
    IF(@row=1, NULL, @row-2) AS w_null,
    0                        AS zip,
    1                        AS uno
  FROM
    (SELECT zip FROM numbers1k) t1,
    (SELECT zip FROM numbers1k) t2,
    (SELECT @row:=0) rr
  ;

