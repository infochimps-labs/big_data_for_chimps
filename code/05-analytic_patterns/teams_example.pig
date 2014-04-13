IMPORT 'common_macros.pig';

teams = load_teams();
teams = FILTER teams BY yearID == 2004 AND lgID == 'AL';

team_opinions = FOREACH teams GENERATE
  teamID,
  case teamID WHEN 'BOS' THEN 'yay' WHEN 'NYA' THEN 'boo' ELSE 'meh' END AS opinion,
  teamname;

DUMP team_opinions;
