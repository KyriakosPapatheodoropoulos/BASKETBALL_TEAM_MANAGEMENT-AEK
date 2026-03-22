CREATE OR REPLACE FUNCTION get_player_stats(p_player_id INT)
RETURNS TABLE (
    player_id      INT,
    full_name      TEXT,
    jersey_number  INT,
    position       TEXT,
    games_played   INT,
    total_points   INT,
    total_rebounds INT,
    total_assists  INT,
    total_steals   INT,
    total_blocks   INT,
    total_turnovers INT,
    ft_made        INT,
    ft_attempts    INT,
    ft_pct         NUMERIC(5,2),
    two_made       INT,
    two_attempts   INT,
    two_pct        NUMERIC(5,2),
    three_made     INT,
    three_attempts INT,
    three_pct      NUMERIC(5,2),
    avg_points     NUMERIC(5,2),
    avg_rebounds   NUMERIC(5,2),
    avg_assists    NUMERIC(5,2)
) AS
$$
BEGIN
    RETURN QUERY
    SELECT *
    FROM v_player_season_stats
    WHERE player_id = p_player_id;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION sp_get_audit_log(
    p_limit     INT DEFAULT 200,
    p_entity    TEXT DEFAULT NULL,
    p_operation TEXT DEFAULT NULL,
    p_from      TIMESTAMPTZ DEFAULT NULL,
    p_to        TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    log_id      BIGINT,
    log_time    TIMESTAMPTZ,
    entity      TEXT,
    operation   TEXT,
    record_key  TEXT,
    description TEXT
)
LANGUAGE sql
AS $$
    WITH mapped AS (
        SELECT
            CASE p_entity
                WHEN 'PLAYERS' THEN 'players'
                WHEN 'GAMES'   THEN 'games'
                WHEN 'LINEUPS' THEN 'game_lineup'
                WHEN 'STATS'   THEN 'player_game_stats'
                WHEN 'STAFF'   THEN 'staff'
                ELSE NULL
            END AS table_filter
    )
    SELECT
        a.log_id,
        a.log_time,
        CASE a.table_name
            WHEN 'players'           THEN 'PLAYERS'
            WHEN 'games'             THEN 'GAMES'
            WHEN 'game_lineup'       THEN 'LINEUPS'
            WHEN 'player_game_stats' THEN 'STATS'
            WHEN 'staff'             THEN 'STAFF'
            ELSE 'OTHER'
        END AS entity,
        a.operation,
        a.record_key,
        a.description
    FROM audit_log a, mapped m
    WHERE (m.table_filter IS NULL OR a.table_name = m.table_filter)
      AND (p_operation IS NULL OR a.operation = p_operation)
      AND (p_from IS NULL OR a.log_time >= p_from)
      AND (p_to   IS NULL OR a.log_time <= p_to)
    ORDER BY a.log_id DESC
    LIMIT p_limit;
$$;

-- Επιστρέφει όλα τα παιχνίδια (ίδιο shape που χρειάζεσαι στο UI)
CREATE OR REPLACE FUNCTION sp_get_all_games()
RETURNS TABLE (
  game_id INT,
  game_date DATE,
  rescheduled_date DATE,
  rescheduled BOOLEAN,
  opponent_name TEXT,
  opponent_logo TEXT,
  home_game BOOLEAN,
  our_score INT,
  opponent_score INT
)
LANGUAGE sql
AS $$
  SELECT game_id, game_date, rescheduled_date, rescheduled,
         opponent_name, opponent_logo, home_game, our_score, opponent_score
  FROM games
  ORDER BY COALESCE(rescheduled_date, game_date);
$$;

CREATE OR REPLACE FUNCTION sp_get_game_by_id(p_game_id INT)
RETURNS TABLE (
  game_id INT,
  game_date DATE,
  rescheduled_date DATE,
  rescheduled BOOLEAN,
  opponent_name TEXT,
  opponent_logo TEXT,
  home_game BOOLEAN,
  our_score INT,
  opponent_score INT
)
LANGUAGE sql
AS $$
  SELECT game_id, game_date, rescheduled_date, rescheduled,
         opponent_name, opponent_logo, home_game, our_score, opponent_score
  FROM games
  WHERE game_id = p_game_id;
$$;

