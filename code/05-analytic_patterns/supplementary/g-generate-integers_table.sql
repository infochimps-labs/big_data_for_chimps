
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

