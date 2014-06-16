
-- sunset = FOREACH career_epochs GENERATE
--   player_id, beg_year, end_year, OPS_all,
--   (PA_young >= 700 ? OPS_young : Null),
--   (PA_prime >= 700 ? OPS_prime : Null),
--   (PA_older >= 700 ? OPS_older : Null),
--   (PA_young >= 700 AND PA_prime >= 700 ? OPS_young - OPS_prime : Null) AS diff_young,
--   (PA_prime >= 700 AND PA_prime >= 700 ? OPS_prime - OPS_all   : Null) AS diff_prime,
--   (PA_older >= 700 AND PA_prime >= 700 ? OPS_older - OPS_prime : Null) AS diff_older,
--   PA_all, PA_young, PA_prime, PA_older
--
--   , ((end_year + beg_year)/2.0 > 1990 ? 'post' : '-') AS epoch
--   ;
--
-- golden_oldies = ORDER sunset BY diff_older DESC;

-- If you sort to find older player Those more familiar with the game will also note an overrepresentation of

-- Look at the jobtracker
