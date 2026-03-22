CREATE OR REPLACE PROCEDURE add_player(
    p_team_id INT,
    p_first_name TEXT,
    p_last_name TEXT,
    p_jersey_number INT,
    p_position TEXT,
    p_age INT,
    p_height_cm NUMERIC,
    p_weight_kg NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO players (
        team_id, first_name, last_name, jersey_number, position,
        age, height_cm, weight_kg
    ) VALUES (
        p_team_id, p_first_name, p_last_name, p_jersey_number, p_position,
        p_age, p_height_cm, p_weight_kg
    );
END;
$$;



CREATE OR REPLACE PROCEDURE delete_player(p_player_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM players
    SET active=FALSE
    WHERE player_id = p_player_id;
END;
$$;



CREATE OR REPLACE PROCEDURE update_player(
    p_player_id INT,
    p_first_name TEXT,
    p_last_name TEXT,
    p_jersey_number INT,
    p_position TEXT,
    p_age INT,
    p_height_cm NUMERIC,
    p_weight_kg NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE players
    SET first_name = p_first_name,
        last_name = p_last_name,
        jersey_number = p_jersey_number,
        position = p_position,
        age = p_age,
        height_cm = p_height_cm,
        weight_kg = p_weight_kg
    WHERE player_id = p_player_id;
END;
$$;



CREATE OR REPLACE PROCEDURE add_game(
    p_game_date DATE,
    p_opponent_name TEXT,
    p_opponent_logo TEXT,
    p_home_game BOOLEAN,
    p_our_score INT,
    p_opponent_score INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO games (
        game_date, opponent_name, opponent_logo, home_game, our_score, opponent_score
    ) VALUES (
        p_game_date, p_opponent_name, p_opponent_logo, p_home_game, p_our_score, p_opponent_score
    );
END;
$$;



CREATE OR REPLACE PROCEDURE update_game(
    p_game_id INT,
    p_game_date DATE,
    p_opponent_name TEXT,
    p_opponent_logo TEXT,
    p_home_game BOOLEAN,
    p_our_score INT,
    p_opponent_score INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE games
    SET game_date = p_game_date,
        opponent_name = p_opponent_name,
        opponent_logo = p_opponent_logo,
        home_game = p_home_game,
        our_score = p_our_score,
        opponent_score = p_opponent_score
    WHERE game_id = p_game_id;
END;
$$;



CREATE OR REPLACE PROCEDURE delete_game(p_game_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM games
    WHERE game_id = p_game_id;
END;
$$;





CREATE OR REPLACE PROCEDURE add_player_to_lineup(
    p_game_id INT,
    p_player_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO game_lineup (game_id, player_id)
    VALUES (p_game_id, p_player_id);
END;
$$;


CREATE OR REPLACE PROCEDURE remove_player_from_lineup(
    p_game_id INT,
    p_player_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM game_lineup
    WHERE game_id = p_game_id AND player_id = p_player_id;
END;
$$;


CREATE OR REPLACE PROCEDURE save_player_stats(
    p_game_id INT,
    p_player_id INT,
    p_points INT,
    p_rebounds INT,
    p_assists INT,
    p_steals INT,
    p_blocks INT,
    p_turnovers INT,
    p_ft_made INT,
    p_ft_attempts INT,
    p_two_made INT,
    p_two_attempts INT,
    p_three_made INT,
    p_three_attempts INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM player_game_stats
        WHERE game_id = p_game_id AND player_id = p_player_id
    ) THEN
        UPDATE player_game_stats
        SET points = p_points,
            rebounds = p_rebounds,
            assists = p_assists,
            steals = p_steals,
            blocks = p_blocks,
            turnovers = p_turnovers,
            ft_made = p_ft_made,
            ft_attempts = p_ft_attempts,
            two_made = p_two_made,
            two_attempts = p_two_attempts,
            three_made = p_three_made,
            three_attempts = p_three_attempts
        WHERE game_id = p_game_id AND player_id = p_player_id;
    ELSE
        INSERT INTO player_game_stats (
            game_id, player_id, points, rebounds, assists, steals, blocks,
            turnovers, ft_made, ft_attempts, two_made, two_attempts,
            three_made, three_attempts
        )
        VALUES (
            p_game_id, p_player_id, p_points, p_rebounds, p_assists, p_steals,
            p_blocks, p_turnovers, p_ft_made, p_ft_attempts,
            p_two_made, p_two_attempts, p_three_made, p_three_attempts
        );
    END IF;
END;
$$;
CREATE OR REPLACE PROCEDURE delete_player_stats(
    p_game_id INT,
    p_player_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM player_game_stats
    WHERE game_id = p_game_id AND player_id = p_player_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_insert_staff(
    p_team_id   INT,
    p_full_name TEXT,
    p_age       INT,
    p_role      TEXT,
    p_photo     TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO staff (
        team_id,
        full_name,
        age,
        role,
        photo_path,
        active
    )
    VALUES (
        p_team_id,
        p_full_name,
        p_age,
        p_role,
        COALESCE(p_photo, 'image/default.png'),
        TRUE
    );
END;
$$;


CREATE OR REPLACE PROCEDURE sp_update_staff(
    p_staff_id INT,
    p_role     TEXT,
    p_age      INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE staff
    SET role = p_role,
        age  = p_age
    WHERE staff_id = p_staff_id;
END;
$$;


CREATE OR REPLACE PROCEDURE sp_update_game_score(p_game_id INT, p_our INT, p_opp INT)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE games SET our_score = p_our, opponent_score = p_opp WHERE game_id = p_game_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_clear_game_score(p_game_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE games SET our_score = NULL, opponent_score = NULL WHERE game_id = p_game_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_reschedule_game(p_game_id INT, p_new_date DATE)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE games SET rescheduled = TRUE, rescheduled_date = p_new_date WHERE game_id = p_game_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_mark_game_as_played(p_game_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE games
  SET game_date = COALESCE(rescheduled_date, game_date),
      rescheduled = FALSE,
      rescheduled_date = NULL
  WHERE game_id = p_game_id;
END;
$$;
