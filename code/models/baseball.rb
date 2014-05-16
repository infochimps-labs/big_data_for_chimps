module Sports
  module Baseball

    class Park ; include Gorillib::Model
      field :park_id,      :string,  length: 5,  required: true
      field :park_name,    :string,  length: 0..50, required: true
      field :beg_date,     :date
      field :end_date,     :date
      field :is_active,    :boolean_10
      field :n_games,      :int,    in:     0..100000
      field :lng,          :float,  in:     -180..180
      field :lat,          :float,  in:     -90..90
      field :city,         :string, length: 0..25
      field :state_id,     :string, length: 2
      field :country_id,   :string, length: 2
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

    class Award  ; include Gorillib::Model
      field :award_id,      :string,     length: 3,       doc: "ID of the award: MVP (Most Valuable Player), CyY (Cy Young), ROY (Rookie of the Year)", required: true
      field :year_id,       :int,        in: 1800..2100,  doc: "Year of the award",                                                                     required: true
      field :lg_id,         :string,     length: 2,       doc: "League ID for the award in consideration",                                              required: true
      field :player_id,     :string,     length: 5..8,    doc: "Player ID receiving votes",                                                             required: true
      field :is_winner,     :boolean_10,                  doc: "If the player won the award, 1; else 0",                                                required: true
      field :vote_pct,      :float,      in: 0..100,      doc: "Fraction of the maximum points possible received. Ballots are weighted (in modern times, 14/9/8/7/6/5/4/3/2/1 points for first..tenth); a value of 100 thus means every ballot listed the player first."
      field :first_pct,     :float,      in: 0..100,      doc: "Fraction of the ballots listing this player first. For some years we have only a vote total, and not the ranked ballots: null values exist"
      field :n_firstv,      :int,        in: 0..1000,     doc: "Number of players who received at least one first-place vote"
      field :tie,           :boolean_10,                  doc: "If there was a tie, 1; else 0"
    end

    class HallOfFame ; include Gorillib::Model
      field :player_id,     :string,     length: 5..8,    doc: "Player ID", required: true
      field :inducted_by,   :string,     length: 0..16,   doc: "If inducted, the route to induction: BBWAA (Baseball Writers Assn, the typical route); Veterans; Negro League; Old Timers; Run Off, Special Election"
      field :is_inducted,   :boolean_10,                  doc: "If player is inducted into the Hall of Fame, 1; else 0", required: true
      field :is_pending,    :boolean_10,                  doc: "If player is still in current consideration, 1; else 0"
      field :max_pct,       :int,        in: 0..100,      doc: "The largest percentage of ballots voting to induct the player has yet received in a year. To be admitted by the Baseball Writers Assn, a player must receive votes from at least 75% of ballots; to maintain eligibility, a player must receive vots from at least 5% of ballots"
      field :n_ballots,     :int,        in: 0..100,      doc: "The number of years under consideration for the player -- that is, before they were inducted, lost eligibility, or hit the 15-year ceiling; or years since eligible for players in consideration"
      field :hof_score,     :int,        in: 0..5000,     doc: "A kludgey indicator of how readily the player was inducted; first-ballot hall-of-famers score above 1000, veterans committee holdouts about 300, bubble players about 100"
      field :year_eligible, :int,        in: 1800..2100,  doc: "The first year of consideration for the player; for most entries after the 1930s, this is the first year of eligibility"
      field :year_inducted, :int,        in: 1800..2100,  doc: "If inducted, the year of induction"
      field :pcts,          :string,     length: 0..255,  doc: "Percent of votes for each year from first eligibility, ordered by ascending year, delimited by pipe (|) character"
    end

    class EventLite ; include Gorillib::Model
      field :game_id,       :string,     length: 12,         required: true, doc: "Game ID, composed of home team ID, date, and game sequence id"
      field :event_seq,     :int,        in:     0..500,     required: true, doc: "Event sequence ID: All events are numbered consecutively throughout each game for easy reference. Note that there may be many events in a plate appearance, due to stolen bases and so forth."
      field :year_id,       :int,        in:     1800..2100, required: true, doc: "Year the game took place"
      field :game_date,     :date,                                           doc: "Game date, YYYY-mm-dd"
      field :game_seq,      :int,        in:     0..2,                       doc: "Game sequence ID: 0 if only one game; otherwise 1 for first game in day, 2 for the second)"
      field :away_team_id,  :string,     length: 3,                          doc: "Team ID for the away (visiting) team; they bat first in each inning."
      field :home_team_id,  :string,     length: 3,                          doc: "Team ID for the home team"
      #
      field :inn,           :int,        in:     0..50,                      doc: "Inning in which this play took place."
      field :inn_home,      :boolean_10,                                     doc: "0 if the visiting team is at bat, 1 if the home team is at bat"
      field :beg_outs_ct,   :int,        in:     0..2,                       doc: "Number of outs before this play."
      field :away_score,    :int,        in:     0..100,                     doc: "Away score, the number of runs for the visiting team before this play."
      field :home_score,    :int,        in:     0..100,                     doc: "Home score, the number of runs for the home team before this play."
      #
      field :event_desc,    :string,     length: 0..100,                     doc: "The complete description of the play using the format described for the event files."
      field :event_cd,      :int,        in:     0..24,                      doc: "Simplified event type -- see below."
      field :hit_cd,        :int,        in:     0..4,                       doc: "Value of hit: 0 = no hit; 1 = single; 2 = double; 3 = triple; 4 = home run."
      #
      field :ev_outs_ct,    :int,        in:     0..3,                       doc: "Number of outs recorded on this play."
      field :ev_runs_ct,    :int,        in:     0..2,                       doc: "Number of runs recorded on this play."
      field :bat_dest,      :int,        in:     0..6,                       doc: "The base which the batter reached at the conclusion of the play.  The value is 0 for an out, 4 if scores an earned run, 5 if scores and unearned, 6 if scores and team unearned."
      field :run1_dest,     :int,        in:     0..6,                       doc: "Base reached by the runner on first at the conclusion of the play, using the same coding as `bat_dest`.  If there was no advance, then the base shown will be the one where the runner started."
      field :run2_dest,     :int,        in:     0..6,                       doc: "Base reached by the runner on second at the conclusion of the play -- see `run1_dest`."
      field :run3_dest,     :int,        in:     0..6,                       doc: "Base reached by the runner on third at the conclusion of the play -- see `run1_dest`."
      #
      field :is_end_bat,    :boolean_10,                                     doc: "1 if the event terminated the batter's appearance; 0 means the same batter stayed at the plate, such as after a stolen base)."
      field :is_end_inn,    :boolean_10,                                     doc: "1 if the event terminated the inning."
      field :is_end_game,   :boolean_10,                                     doc: "1 if this is the last record of a game."
      #
      field :bat_team_id,   :string,     length: 3,                          doc: "Team ID of the batting team"
      field :fld_team_id,   :string,     length: 3,                          doc: "Team ID of the fielding team"
      field :pit_id,        :string,     length: 8,                          doc: "Player ID code for the pitcher responsible for the play (NOTE: this is the `res_pit_id` field in the original)."
      field :bat_id,        :string,     length: 5..8,                       doc: "Player ID code for the batter responsible for the play (NOTE: this is the `res_bat_id` field in the original)."
      field :run1_id,       :string,     length: 5..8,                       doc: "Player ID code for the runner on first base, if any."
      field :run2_id,       :string,     length: 5..8,                       doc: "Player ID code for the runner on second base, if any."
      field :run3_id,       :string,     length: 5..8,                       doc: "Player ID code for the runner on third base, if any."

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
