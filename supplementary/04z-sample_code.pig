REGISTER '/Users/flip/ics/data_science_fun_pack/pig/pig/contrib/piggybank/java/piggybank.jar';
DEFINE CSVLoader org.apache.pig.piggybank.storage.CSVExcelStorage;

batting_war = LOAD '/Users/flip/ics/book/big_data_for_chimps/data/sports/baseball/baseball_reference/batting_war-20130315.csv'
        USING CSVLoader AS (
        name_common:chararray,player_id:chararray,
        year_id:int, team_id:chararray, stint_id:int, lg_id:chararray,
        plateappearances:int, games:int, innings:int,
        runs_bat:float, runs_br:float, runs_dp:float,
        runs_field:float, runs_infield:float, runs_outfield:float, runs_catcher:float,
        runs_good_plays:float, runs_defense:float, runs_position:float, runs_position_p:float,
        runs_replacement:float, runs_above_rep:float,
        runs_above_avg:float, runs_above_avg_off:float, runs_above_avg_def:float,
        waa:float, waa_off:float, waa_def:float,
        war:float, war_def:float, war_off:float, war_rep:float,
        salary:int, pitcher:chararray,
        teamrpg:float, opprpg:float, opprppa_rep:float, opprpg_rep:float,
        pyth_exponent:float, pyth_exponent_rep:float,
        waa_win_perc:float, waa_win_perc_off:float, waa_win_perc_def:float, waa_win_perc_rep:float
        );
batting_war = FOREACH batting_war GENERATE team_id, year_id, player_id, name_common, salary, pitcher, war;

team_seasons   = GROUP batting_war BY (team_id, year_id);
team_seasons   = FOREACH team_seasons {
        player_info = DISTINCT batting_war.(player_id, name_common, salary, pitcher, war);
        GENERATE group.team_id, group.year_id, player_info;
        };
-- dumpable = LIMIT team_seasons 10; DUMP dumpable;
EXPLAIN team_seasons;

STORE team_seasons INTO '/tmp/team_seasons.tsv';
