IMPORT 'common_macros.pig'; %DEFAULT out_dir '/data/out/baseball'; 

teams = load_teams();
teams = FILTER teams BY year_id == 2004 AND lg_id == 'AL';

team_opinions = FOREACH teams GENERATE
  team_id,
  case team_id WHEN 'BOS' THEN 'yay' WHEN 'NYA' THEN 'boo' ELSE 'meh' END AS opinion,
  teamname;

rmf                       $out_dir/team_opinions;
STORE team_opinions INTO '$out_dir/team_opinions';
