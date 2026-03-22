
 νεο view γιατι σε περιπτωση που δεν μας κανει το κανω drop απο την βαση και κρατω το παλιο για αυτο δεν το σβηνω

CREATE OR REPLACE VIEW v_player_season_stats AS
SELECT
    p.player_id,
    p.first_name || ' ' || p.last_name AS full_name,
    p.jersey_number,
    p.position,
    p.age,
    p.height_cm,
    p.weight_kg,
    p.photo_path,

    -- Σύνολα
    COALESCE(SUM(s.points), 0)        AS total_points,
    COALESCE(SUM(s.rebounds), 0)      AS total_rebounds,
    COALESCE(SUM(s.assists), 0)       AS total_assists,
    COALESCE(SUM(s.steals), 0)        AS total_steals,
    COALESCE(SUM(s.blocks), 0)        AS total_blocks,
    COALESCE(SUM(s.turnovers), 0)     AS total_turnovers,

    COALESCE(SUM(s.ft_made), 0)       AS ft_made,
    COALESCE(SUM(s.ft_attempts), 0)   AS ft_attempts,
    COALESCE(SUM(s.two_made), 0)      AS two_made,
    COALESCE(SUM(s.two_attempts), 0)  AS two_attempts,
    COALESCE(SUM(s.three_made), 0)    AS three_made,
    COALESCE(SUM(s.three_attempts), 0) AS three_attempts,

    COUNT(DISTINCT s.game_id)         AS games_played,

    -- Μέσοι όροι
    CASE WHEN COUNT(DISTINCT s.game_id) > 0
         THEN COALESCE(SUM(s.points), 0)::numeric / COUNT(DISTINCT s.game_id)
         ELSE 0 END                   AS avg_points,

    CASE WHEN COUNT(DISTINCT s.game_id) > 0
         THEN COALESCE(SUM(s.rebounds), 0)::numeric / COUNT(DISTINCT s.game_id)
         ELSE 0 END                   AS avg_rebounds,

    CASE WHEN COUNT(DISTINCT s.game_id) > 0
         THEN COALESCE(SUM(s.assists), 0)::numeric / COUNT(DISTINCT s.game_id)
         ELSE 0 END                   AS avg_assists,

    -- ΠΟΣΟΣΤΑ
    CASE WHEN COALESCE(SUM(s.ft_attempts), 0) > 0
         THEN COALESCE(SUM(s.ft_made), 0)::numeric * 100
              / COALESCE(SUM(s.ft_attempts), 0)
         ELSE 0 END                   AS ft_pct,

    CASE WHEN COALESCE(SUM(s.two_attempts), 0) > 0
         THEN COALESCE(SUM(s.two_made), 0)::numeric * 100
              / COALESCE(SUM(s.two_attempts), 0)
         ELSE 0 END                   AS two_pct,

    CASE WHEN COALESCE(SUM(s.three_attempts), 0) > 0
         THEN COALESCE(SUM(s.three_made), 0)::numeric * 100
              / COALESCE(SUM(s.three_attempts), 0)
         ELSE 0 END                   AS three_pct

FROM players p
LEFT JOIN player_game_stats s
       ON s.player_id = p.player_id
WHERE p.active = TRUE          -- >>> εδώ το φίλτρο για το soft delete <<<
GROUP BY
    p.player_id,
    p.first_name,
    p.last_name,
    p.jersey_number,
    p.position,
    p.age,
    p.height_cm,
    p.weight_kg,
    p.photo_path
ORDER BY
    p.jersey_number;

