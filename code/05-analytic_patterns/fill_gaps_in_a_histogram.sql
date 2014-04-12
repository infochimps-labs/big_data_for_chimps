SET @Hbsz = 10;
SELECT bin, H, IFNULL(n_H,0)
  FROM      (SELECT @Hbsz * idx AS bin FROM numbers WHERE idx <= 430) nums
  LEFT JOIN (SELECT @Hbsz*CEIL(H/@Hbsz) AS H, COUNT(*) AS n_H
    FROM bat_career bat GROUP BY H) hist
  ON hist.H = nums.bin
  ORDER BY bin ASC
;

SELECT bin, H, IFNULL(n_H,0)
  FROM      (SELECT @Hbsz * ixN AS bin FROM numbers WHERE ixN <= 430 OR ixN IS NULL) nums
  LEFT JOIN (SELECT @Hbsz*CEIL(H/@Hbsz) AS H, COUNT(*) AS n_H
    FROM bat_career bat GROUP BY H) hist
  ON hist.H = nums.bin OR (hist.H IS NULL AND nums.bin IS NULL)
  ORDER BY bin ASC 
;
