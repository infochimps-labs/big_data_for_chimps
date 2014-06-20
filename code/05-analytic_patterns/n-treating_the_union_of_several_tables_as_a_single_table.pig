IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons       = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Treating the Union of Several Tables as a Single Table
--
-- Note that this is not a Join (which requires a reduce, and changes the schema
-- of the records) -- this is more like stacking one table atop another, making
-- no changes to the records (schema or otherwise) and does not require a
-- reduce.

-- A common use of the UNION statement comes in 'symmetrizing' a relationship. For example, each line in the games table describes in a sense two game outcomes: one for the home team and one for the away team. We might reasonably want to prepare another table that listed game _outcomes_: game_id, team, opponent, team's home/away position, team's score, opponent's score. The game between BAL playing at BOS on XXX (final score BOS Y, BAL Z) would get two lines: `GAMEIDXXX BOS BAL 1 Y Z` and `GAMEID BAL BOS 0 Z Y`.

TODO copy over code


-- NOTE: The UNION operator is easy to over-use. For one example, in the next chapter we'll extend the first part of this code to prepare win-loss statistics by team. A plausible first guess would be to follow the UNION statement above with a GROUP statement, but a much better approach would use a COGROUP instead (both operators are explained in the next chapter). The UNION statement is mostly harmless but fairly rare in use; give it a second look any time you find yourself writing it in to a script.
