require  'gorillib/model'
require  'gorillib/type/extended'
require  'gorillib/model/validations'
require  'wukong'
require  'wu/model/schema_converter'

class ParkTeamYear
  include Gorillib::Model

  field :park_id,       :string,     length: 5,          required: true, doc: "Retrosheet Park ID: 3-character city abbreviation and two-digit index"
  field :team_id,       :string,     length: 3,          required: true, doc: "Retrosheet Team ID: 2-character city abbreviation and one-digit index"
  field :year_id,       :int,        in:     1800..2100, required: true, doc: "Year of record"
  field :beg_date,      :date,                                           doc: "Date (YYYY-mm-dd) of the first game at the stadium within that season"
  field :end_date,      :date,                                           doc: "Date (YYYY-mm-dd) of the last game at the stadium within that season"
  field :n_games,       :int,        in:     1..200,                     doc: "Number of games played at that park by that team in the given year"

  index :pty,       [:park_id, :team_id, :year_id], primary: true
  index :team,      [:team_id, :year_id]
  index :yr,        [:year_id, :beg_date]

  def self.sql_create(opts={})
    super({charset: 'ascii', partition_by: 'KEY(`year_id`)'}.merge(opts))
  end
end

if ($0 == __FILE__) then
  puts ParkTeamYear.sql_create
  puts ParkTeamYear.pig_load(date_as_chararray: true)
end
