
# mapper(array_fields_of: ParkTeamYear) do |park_id, team_id, year_id, beg_date, end_date, n_games|
#  yield [team_id, year_id, park_id, n_games]
# end
#
# reducer do |(team_id, year_id), stream|
#   parks   = stream. map{|park_id, n_games| [park_id, n_games.to_i] }
#   n_parks = stream.size
#   if n_parks > 1
#     yield [team_id, year_id.to_i, n_parks, parks.to_json]
#   end
# end
#
# # ALT        1884    [["ALT01",18]]
# # ANA   1997    [["ANA01",82]]
# # ...
# # CL4   1898    [["CLE05",40],[PHI09,9],[STL05,2],[ROC02,2],[CLL01,2],[CHI08,1],[ROC03,1]]
#
# === How a group works
#
# mapper(array_fields_of: ParkTeamYear) do |park_id, team_id, year_id, beg_date, end_date, n_games|
#  yield [team_id, year_id]
# end
#
# # In effect, what is happening in Java:
# reducer do |(team_id, year_id), stream|
#   n_parks = 0
#   stream.each do |*_|
#     n_parks += 1
#   end
#   yield [team_id, year_id, n_parks] if n_parks > 1
# end
#
# # (ln actual practice, the ruby version would call stream.size rather than iterating:
# #  n_parks = stream.size ; yield [team_id, year_id, n_parks] if n_parks > 1
