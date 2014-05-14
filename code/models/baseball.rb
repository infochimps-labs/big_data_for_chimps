
module Sports

  module Baseball
    class Park
      include Gorillib::Model
      field :park_id,      :string,  length: 6, required: true
      field :park_name,    :string
      field :beg_date,     :date
      field :end_date,     :date
      field :is_active,    :boolean_10
      field :n_games,      :int,    in: 0..100000
      field :lng,          :float,  in: -180..180
      field :lat,          :float,  in: -90..90
      field :city,         :string
      field :state_id,     :string
      field :country_id,   :string
      field :postal_id,    :string
      field :streetaddr,   :string
      field :extaddr,      :string
      field :tel,          :string
      field :url,          :string
      field :url_spanish,  :string
      field :logofile,     :pathname
      field :allteams,     :string
      field :allnames,     :string
      field :comments,     :string, length: 0..1000
    end

    class EventLite
      include Gorillib::Model

      field :game_id,       :string,     length: 12,         required: true, doc: "Game ID, composed of home team ID, date, and game sequence id"
      field :event_seq,     :int,        in:     0..500,     required: true, doc: "Event sequence ID: All events are numbered consecutively throughout each game for easy reference. Note that there may be many events in a plate appearance, due to stolen bases and so forth."
      field :year_id,       :int,        in:     1800..2100, required: true, doc: "Year the game took place"
      field :game_date,     :date,                                           doc: "Game date, YYYY-mm-dd"
      field :game_seq,      :int,        in:     0..2,                       doc: "Game sequence ID: 0 if only one game; otherwise 1 for first game in day, 2 for the second)"
      field :away_team_id,  :string,     length: 3,                          doc: "Team ID for the away (visiting) team; they bat first in each inning."
      field :home_team_id,  :string,     length: 3,                          doc: "Team ID for the home team"

      field :inn,           :int,        in:     0..50,                      doc: "Inning in which this play took place."
      field :inn_home,      :boolean_10,                                     doc: "0 if the visiting team is at bat, 1 if the home team is at bat"
      field :beg_outs_ct,   :int,        in:     0..2,                       doc: "Number of outs before this play."
      field :away_score,    :int,        in:     0..100,                     doc: "Away score, the number of runs for the visiting team before this play."
      field :home_score,    :int,        in:     0..100,                     doc: "Home score, the number of runs for the home team before this play."

      field :event_desc,    :string,     length: 0..100,                     doc: "The complete description of the play using the format described for the event files."
      field :event_cd,      :int,        in:     0..24,                      doc: "Simplified event type -- see below."
      field :hit_cd,        :int,        in:     0..4,                       doc: "Value of hit: 0 = no hit; 1 = single; 2 = double; 3 = triple; 4 = home run."

      field :ev_outs_ct,    :int,        in:     0..3,                       doc: "Number of outs recorded on this play."
      field :ev_runs_ct,    :int,        in:     0..2,                       doc: "Number of runs recorded on this play."
      field :bat_dest,      :int,        in:     0..6,                       doc: "The base which the batter reached at the conclusion of the play.  The value is 0 for an out, 4 if scores an earned run, 5 if scores and unearned, 6 if scores and team unearned."
      field :run1_dest,     :int,        in:     0..6,                       doc: "Base reached by the runner on first at the conclusion of the play, using the same coding as `bat_dest`.  If there was no advance, then the base shown will be the one where the runner started."
      field :run2_dest,     :int,        in:     0..6,                       doc: "Base reached by the runner on second at the conclusion of the play -- see `run1_dest`."
      field :run3_dest,     :int,        in:     0..6,                       doc: "Base reached by the runner on third at the conclusion of the play -- see `run1_dest`."

      field :is_end_bat,    :boolean_10,                                     doc: "1 if the event terminated the batter's appearance; 0 means the same batter stayed at the plate, such as after a stolen base)."
      field :is_end_inn,    :boolean_10,                                     doc: "1 if the event terminated the inning."
      field :is_end_game,   :boolean_10,                                     doc: "1 if this is the last record of a game."

      field :bat_team_id,   :string,     length: 3,                          doc: "Team ID of the batting team"
      field :fld_team_id,   :string,     length: 3,                          doc: "Team ID of the fielding team"
      field :pit_id,        :string,     length: 8,                          doc: "Player ID code for the pitcher responsible for the play (NOTE: this is the `res_pit_id` field in the original)."
      field :bat_id,        :string,     length: 8,                          doc: "Player ID code for the batter responsible for the play (NOTE: this is the `res_bat_id` field in the original)."
      field :run1_id,       :string,     length: 8,                          doc: "Player ID code for the runner on first base, if any."
      field :run2_id,       :string,     length: 8,                          doc: "Player ID code for the runner on second base, if any."
      field :run3_id,       :string,     length: 8,                          doc: "Player ID code for the runner on third base, if any."

      index :event,     [:game_id,      :event_seq, :year_id],        primary: true
      index :inning,    [:year_id,      :game_id, :inn,  :inn_home]
      index :batter,    [:bat_id,       :year_id]
      index :pitcher,   [:pit_id,       :year_id]
      index :away_team, [:away_team_id, :year_id]
      index :home_team, [:home_team_id, :year_id]
      index :bat_team,  [:bat_team_id,  :year_id]
      index :fld_team,  [:fld_team_id,  :year_id]

      def self.sql_create(opts={})
        super({charset: 'ascii', partition_by: 'KEY(`year_id`)'}.merge(opts))
      end
    end

  end
end
