----------------------------------
           --TABLES--
----------------------------------
-- 1. Teams
CREATE TABLE teams (
    team_id      SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL UNIQUE,
    city         VARCHAR(100),
    logo_url     TEXT,
    is_our_team  BOOLEAN NOT NULL DEFAULT FALSE
);

-- 2. Players
CREATE TABLE players (
    player_id     SERIAL PRIMARY KEY,
    team_id       INT NOT NULL REFERENCES teams(team_id),
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    jersey_number INT NOT NULL CHECK (jersey_number BETWEEN 0 AND 99),
    position      VARCHAR(10) NOT NULL,  -- π.χ. 'PG','SG','SF','PF','C'
    age           INT CHECK (age > 0),
    height_cm     NUMERIC(5,2),          -- π.χ. 198.00
    weight_kg     NUMERIC(5,2),          -- π.χ. 95.50
	photo_path    TEXT NOT NULL DEFAULT 'images/default.png',
    active        BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE UNIQUE INDEX players_team_id_jersey_active_uq
ON players (team_id, jersey_number)
WHERE active = TRUE;

-- 3. Games (8 αγώνες)θυμισου να δεις το table.sql γιατι κατι αλλαε και το περασα κατευθειαν εκει
CREATE TABLE games (
    game_id          SERIAL PRIMARY KEY,
    game_date        DATE NOT NULL,
    opponent_name    VARCHAR(100), -- Προστέθηκε
    opponent_logo    VARCHAR(200), -- Προστέθηκε
    home_game        BOOLEAN NOT NULL DEFAULT TRUE, -- Μετονομάστηκε
    our_score        INT, -- Τροποποιήθηκε (επιτρέπει NULL)
    opponent_score   INT  -- Τροποποιήθηκε (επιτρέπει NULL)
);

-- 4. Game lineup – ποιοι 12 έπαιξαν σε κάθε αγώνα
CREATE TABLE game_lineup (
    game_id   INT NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    player_id INT NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
    PRIMARY KEY (game_id, player_id)
);


-- 5. Player game stats – στατιστικά παίκτη ανά αγώνα
CREATE TABLE player_game_stats (
    game_id         INT NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    player_id       INT NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,

    -- Προσθήκη της στήλης played με την προεπιλεγμένη τιμή
    played          BOOLEAN NOT NULL DEFAULT TRUE,
    points          INT NOT NULL DEFAULT 0,
    rebounds        INT NOT NULL DEFAULT 0,
    assists         INT NOT NULL DEFAULT 0,
    steals          INT NOT NULL DEFAULT 0,
    blocks          INT NOT NULL DEFAULT 0,
    turnovers       INT NOT NULL DEFAULT 0,

    ft_made         INT NOT NULL DEFAULT 0,
    ft_attempts     INT NOT NULL DEFAULT 0,
    two_made        INT NOT NULL DEFAULT 0,
    two_attempts    INT NOT NULL DEFAULT 0,
    three_made      INT NOT NULL DEFAULT 0,
    three_attempts  INT NOT NULL DEFAULT 0,

    CHECK (ft_made          >= 0 AND ft_attempts       >= 0 AND ft_made      <= ft_attempts),
    CHECK (two_made         >= 0 AND two_attempts      >= 0 AND two_made     <= two_attempts),
    CHECK (three_made       >= 0 AND three_attempts    >= 0 AND three_made   <= three_attempts),

    PRIMARY KEY (game_id, player_id)
);


-- 6. Staff – προπονητικό team
CREATE TABLE staff (
    staff_id    SERIAL PRIMARY KEY,
    team_id     INT NOT NULL REFERENCES teams(team_id),
    full_name   VARCHAR(100) NOT NULL,
    role        VARCHAR(50) NOT NULL, -- Head Coach, Assistant Coach, Trainer, Scouter
    age         INT,
    photo_path  TEXT,         -- π.χ. 'image/staff_headcoach.png'
    active      BOOLEAN NOT NULL DEFAULT TRUE -- Η στήλη 'active' προστέθηκε εδώ
);

-- 7. Log file για triggers
CREATE TABLE audit_log (
    log_id      BIGSERIAL PRIMARY KEY,
    log_time    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    table_name  TEXT NOT NULL,
    operation   TEXT NOT NULL,      -- INSERT / UPDATE / DELETE
    record_key  TEXT,               -- π.χ. "game_id=3, player_id=10"
    description TEXT
);


--------------------------
---------Triggers---------
--------------------------

CREATE OR REPLACE FUNCTION trg_check_lineup_limit()
RETURNS TRIGGER AS
$$
BEGIN
    IF (SELECT COUNT(*)
        FROM game_lineup
        WHERE game_id = NEW.game_id) >= 12 THEN
        RAISE EXCEPTION 'Δεν μπορούν να δηλωθούν πάνω από 12 παίκτες σε έναν αγώνα (game_id=%).', NEW.game_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_lineup_limit
BEFORE INSERT ON game_lineup
FOR EACH ROW
EXECUTE FUNCTION trg_check_lineup_limit();




CREATE OR REPLACE FUNCTION trg_audit_log()
RETURNS TRIGGER AS
$$
DECLARE
    key_text TEXT;
BEGIN
    IF TG_TABLE_NAME = 'player_game_stats' THEN
        key_text := 'game_id=' || COALESCE(NEW.game_id, OLD.game_id)::TEXT
                    || ', player_id=' || COALESCE(NEW.player_id, OLD.player_id)::TEXT;
    ELSIF TG_TABLE_NAME = 'players' THEN
        key_text := 'player_id=' || COALESCE(NEW.player_id, OLD.player_id)::TEXT;
    ELSIF TG_TABLE_NAME = 'games' THEN
        key_text := 'game_id=' || COALESCE(NEW.game_id, OLD.game_id)::TEXT;
    ELSE
        key_text := NULL;
    END IF;

    INSERT INTO audit_log(table_name, operation, record_key, description)
    VALUES (TG_TABLE_NAME, TG_OP, key_text, NULL);

    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Συνδέουμε το trigger με τους βασικούς πίνακες
CREATE TRIGGER log_players
AFTER INSERT OR UPDATE OR DELETE ON players
FOR EACH ROW EXECUTE FUNCTION trg_audit_log();


CREATE TRIGGER log_games
AFTER INSERT OR UPDATE OR DELETE ON games
FOR EACH ROW EXECUTE FUNCTION trg_audit_log();


CREATE TRIGGER log_player_game_stats
AFTER INSERT OR UPDATE OR DELETE ON player_game_stats
FOR EACH ROW EXECUTE FUNCTION trg_audit_log();







CREATE OR REPLACE FUNCTION trg_staff_role_limits()
RETURNS trigger AS $$
DECLARE
    cnt int;
BEGIN
    IF NEW.active IS DISTINCT FROM TRUE THEN
        RETURN NEW;
    END IF;

    IF NEW.role = 'Head Coach' THEN
        SELECT COUNT(*) INTO cnt
        FROM staff
        WHERE team_id = NEW.team_id
          AND role = 'Head Coach'
          AND active = TRUE
          AND staff_id <> COALESCE(NEW.staff_id, -1);

        IF cnt >= 1 THEN
            RAISE EXCEPTION 'Only one active Head Coach is allowed per team';
        END IF;
    END IF;

    IF NEW.role = 'Assistant Coach' THEN
        SELECT COUNT(*) INTO cnt
        FROM staff
        WHERE team_id = NEW.team_id
          AND role = 'Assistant Coach'
          AND active = TRUE
          AND staff_id <> COALESCE(NEW.staff_id, -1);

        IF cnt >= 2 THEN
            RAISE EXCEPTION 'Maximum 2 active Assistant Coaches are allowed per team';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER staff_role_limits
BEFORE INSERT OR UPDATE OF role, active, team_id
ON staff
FOR EACH ROW
EXECUTE FUNCTION trg_staff_role_limits();






----------------------------------
---------------VIEW---------------
----------------------------------


CREATE OR REPLACE VIEW v_player_season_stats AS
SELECT
    p.player_id,
    p.first_name || ' ' || p.last_name AS full_name,
    p.jersey_number,
    p.position,

    COUNT(DISTINCT s.game_id) AS games_played,

    COALESCE(SUM(s.points), 0)   AS total_points,
    COALESCE(SUM(s.rebounds), 0) AS total_rebounds,
    COALESCE(SUM(s.assists), 0)  AS total_assists,
    COALESCE(SUM(s.steals), 0)   AS total_steals,
    COALESCE(SUM(s.blocks), 0)   AS total_blocks,
    COALESCE(SUM(s.turnovers), 0) AS total_turnovers,

    -- Shooting totals
    COALESCE(SUM(s.ft_made), 0)      AS ft_made,
    COALESCE(SUM(s.ft_attempts), 0)  AS ft_attempts,
    COALESCE(SUM(s.two_made), 0)     AS two_made,
    COALESCE(SUM(s.two_attempts), 0) AS two_attempts,
    COALESCE(SUM(s.three_made), 0)   AS three_made,
    COALESCE(SUM(s.three_attempts), 0) AS three_attempts,

    -- Shooting percentages
    CASE WHEN SUM(s.ft_attempts)  > 0 THEN ROUND(SUM(s.ft_made)::NUMERIC   * 100 / SUM(s.ft_attempts), 2)  ELSE 0 END AS ft_pct,
    CASE WHEN SUM(s.two_attempts) > 0 THEN ROUND(SUM(s.two_made)::NUMERIC * 100 / SUM(s.two_attempts), 2) ELSE 0 END AS two_pct,
    CASE WHEN SUM(s.three_attempts) > 0 THEN ROUND(SUM(s.three_made)::NUMERIC * 100 / SUM(s.three_attempts), 2) ELSE 0 END AS three_pct,

    -- Μέσοι όροι ανά παιχνίδι
    ROUND(AVG(s.points)::NUMERIC,   2) AS avg_points,
    ROUND(AVG(s.rebounds)::NUMERIC,2) AS avg_rebounds,
    ROUND(AVG(s.assists)::NUMERIC, 2) AS avg_assists,
    ROUND(AVG(s.steals)::NUMERIC,  2) AS avg_steals,
    ROUND(AVG(s.blocks)::NUMERIC,  2) AS avg_blocks,
    ROUND(AVG(s.turnovers)::NUMERIC,2) AS avg_turnovers

FROM players p
LEFT JOIN player_game_stats s
       ON p.player_id = s.player_id
GROUP BY p.player_id, full_name, p.jersey_number, p.position;



----------------------------------------------
------------------FUNCTIONS-------------------
----------------------------------------------



CREATE OR REPLACE FUNCTION get_player_stats(p_player_id INT)
RETURNS TABLE (
    player_id      INT,
    full_name      TEXT,
    jersey_number  INT,
   "position"       TEXT,
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






------------------------
-------PROCEDURES-------
------------------------




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
    UPDATE players
	SET active= FALSE
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




-- =========================================
--  ΟΜΑΔΑ: Αθλητική Ένωση Κυπαρισσίας
-- =========================================

-- Αν έχεις ήδη πίνακα teams:
-- Προσαρμόζεις τα πεδία αν είναι διαφορετικά.
INSERT INTO teams (team_id, name, city)
VALUES (1, 'Αθλητική Ένωση Κυπαρισσίας', 'Κυπαρισσία');

-- Αν ο πίνακας teams έχει SERIAL/IDENTITY και δεν δέχεται manual team_id,
-- τότε κάνε:
-- INSERT INTO teams (name, city)
-- VALUES ('Αθλητική Ένωση Κυπαρισσίας', 'Κυπαρισσία');
-- και θεώρησε ότι το παραγόμενο team_id είναι 1 (ή δες το με SELECT * FROM teams).



INSERT INTO players
(team_id, first_name, last_name, jersey_number, position, age, height_cm, weight_kg, photo_path)
VALUES
(1, 'Giannis', 'Kouris', 4,  'PG', 22, 185.0, 78.0, 'image/player1.png'),
(1, 'Nikos', 'Papadopoulos', 7, 'C', 24, 210.0, 120.0, 'image/player2.png'),
(1, 'Dimitris', 'Lazarou', 9, 'SF', 25, 195.0, 88.0, 'image/player3.png'),
(1, 'Kostas', 'Georgiou', 11, 'PF', 27, 201.0, 96.0, 'image/player4.png'),
(1, 'Petros', 'Antonopoulos', 14, 'SG', 28, 188.0, 84.0, 'image/player5.png'),

(1, 'Markos', 'Karalis', 5, 'PG', 21, 183.0, 76.0, 'image/player6.png'),
(1, 'Vasilis', 'Raptis', 8, 'SG', 23, 190.0, 84.0, 'image/player7.png'),
(1, 'Andreas', 'Sarris', 10, 'SF', 22, 198.0, 89.0, 'image/player8.png'),
(1, 'Stelios', 'Gkritzalis', 12, 'PF', 26, 203.0, 97.0, 'image/player9.png'),
(1, 'Giorgos', 'Alexiou', 15, 'C', 29, 208.0, 108.0, 'image/player10.png'),

(1, 'Nektarios', 'Katsaros', 6, 'PG', 20, 180.0, 74.0, 'image/player11.png'),
(1, 'Panagiotis', 'Lymperopoulos', 13, 'SG', 22, 189.0, 85.0, 'image/player12.png'),
(1, 'Iasonas', 'Soulis', 17, 'SF', 24, 196.0, 87.0, 'image/player13.png'),
(1, 'Aris', 'Makris', 19, 'PF', 27, 202.0, 94.0, 'image/player14.png'),
(1, 'Christos', 'Melas', 21, 'C', 30, 212.0, 110.0, 'image/player15.png');




INSERT INTO staff (team_id, full_name, role, age, photo_path)
VALUES
    (1, 'Nikos Papadopoulos',   'Head Coach',       45, 'image/staff_headcoach.png'),
    (1, 'Giorgos Antoniou',     'Assistant Coach',  39, 'image/staff_assistant.png'),
    (1, 'Maria Konstantinou',   'Trainer',          34, 'image/staff_trainer.png'),
    (1, 'Ilias Dimitriou',      'Scouter',          37, 'image/staff_scouter.png');




INSERT INTO games
(game_id, game_date, opponent_name, opponent_logo, home_game, our_score, opponent_score)
VALUES
    (1, '2025-10-01', 'ΠΥΛΟΣ BULLS', '/image/Bulls_logo.png', TRUE,  78, 72),
    (2, '2025-10-08', 'ΚΟΡΩΝΗ HORNETS',    '/image/Hornets_logo.png',    FALSE, 65, 70),
    (3, '2025-10-15', 'ΝΑΥΑΡΙΝΟ HAWKS','/image/Hawks_logo.png',       TRUE,  88, 60),
    (4, '2025-10-22', 'ΜΕΣΣΗΝΗ BOBCATS',          '/image/Bobcats_logo.png',          FALSE, 72, 75),
    (5, '2025-10-29', 'ΠΥΛΟΣ BULLS',          '/image/Bulls_logo.png',          TRUE,  90, 82),
    (6, '2025-11-05', 'ΚΟΡΩΝΗ HORNETS',      '/image/Hornets_logo.png',      FALSE, 67, 63),
    (7, '2025-11-12', 'ΝΑΥΑΡΙΝΟ HAWKS',     '/image/Hawks_logo.png',     TRUE,  80, 77),
    -- Τελευταίος αγώνας: σκορ NULL για να το συμπληρώσεις από το INSERT STATS
    (8, '2025-11-19', 'ΜΕΣΣΗΝΗ BOBCATS',    '/image/Bobcats_logo.png',    FALSE, NULL, NULL);




-- Για απλότητα: στους 8 αγώνες παίζουν πάντα οι παίκτες 1–12

INSERT INTO game_lineup (game_id, player_id) VALUES
    -- Game 1
    (1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(1,7),(1,8),(1,9),(1,10),(1,11),(1,12),

    -- Game 2
    (2,1),(2,2),(2,3),(2,4),(2,5),(2,6),(2,7),(2,8),(2,9),(2,10),(2,11),(2,12),

    -- Game 3
    (3,1),(3,2),(3,3),(3,4),(3,5),(3,6),(3,7),(3,8),(3,9),(3,10),(3,11),(3,12),

    -- Game 4
    (4,1),(4,2),(4,3),(4,4),(4,5),(4,6),(4,7),(4,8),(4,9),(4,10),(4,11),(4,12),

    -- Game 5
    (5,1),(5,2),(5,3),(5,4),(5,5),(5,6),(5,7),(5,8),(5,9),(5,10),(5,11),(5,12),

    -- Game 6
    (6,1),(6,2),(6,3),(6,4),(6,5),(6,6),(6,7),(6,8),(6,9),(6,10),(6,11),(6,12),

    -- Game 7
    (7,1),(7,2),(7,3),(7,4),(7,5),(7,6),(7,7),(7,8),(7,9),(7,10),(7,11),(7,12),

    -- Game 8
    (8,1),(8,2),(8,3),(8,4),(8,5),(8,6),(8,7),(8,8),(8,9),(8,10),(8,11),(8,12);



INSERT INTO player_game_stats
    (game_id, player_id,
     points, rebounds, assists, steals, blocks, turnovers,
     ft_made, ft_attempts,
     two_made, two_attempts,
     three_made, three_attempts)
VALUES
    -- Game 1 (vs Panathinaikos, home, 78–72)
    (1, 1, 18, 6, 4, 2, 0, 3,  4, 5,  5,10, 1,3),
    (1, 2, 15, 5, 3, 1, 0, 2,  3, 4,  4, 9, 1,4),
    (1, 3, 12, 7, 2, 1, 1, 1,  2, 2,  4, 8, 0,2),
    (1, 4, 10, 4, 5, 0, 0, 2,  2, 3,  3, 7, 0,1),
    (1, 5,  8, 3, 2, 1, 0, 1,  0, 0,  4, 9, 0,2),
    (1, 6,  7, 2, 1, 1, 0, 1,  1, 2,  2, 5, 0,1),
    (1, 7,  4, 3, 1, 0, 1, 1,  0, 0,  2, 4, 0,1),
    (1, 8,  4, 2, 2, 0, 0, 1,  0, 0,  1, 3, 1,2),
    (1, 9,  0, 1, 1, 0, 0, 0,  0, 0,  0, 1, 0,1),
    (1,10,  0, 1, 0, 0, 0, 0,  0, 0,  0, 1, 0,1),
    (1,11,  0, 0, 1, 0, 0, 0,  0, 0,  0, 0, 0,1),
    (1,12,  0, 0, 0, 0, 0, 0,  0, 0,  0, 0, 0,0);



INSERT INTO player_game_stats
    (game_id, player_id,
     points, rebounds, assists, steals, blocks, turnovers,
     ft_made, ft_attempts,
     two_made, two_attempts,
     three_made, three_attempts)
VALUES
    -- Game 2 (vs Olympiacos, away, 65–70)
    (2, 1, 16, 5, 3, 1, 0, 3,  4, 5,  4, 9, 1,4),
    (2, 2, 11, 4, 2, 1, 0, 2,  1, 2,  4, 8, 0,3),
    (2, 3,  9, 6, 3, 1, 1, 1,  1, 2,  3, 7, 0,2),
    (2, 4,  8, 3, 4, 0, 0, 2,  2, 3,  2, 6, 0,1),
    (2, 5,  7, 3, 1, 1, 0, 1,  1, 2,  2, 5, 0,1),
    (2, 6,  5, 2, 1, 0, 0, 1,  1, 1,  2, 4, 0,1),
    (2, 7,  4, 3, 1, 0, 0, 1,  0, 0,  2, 4, 0,1),
    (2, 8,  3, 1, 1, 0, 0, 0,  0, 0,  1, 3, 0,1),
    (2, 9,  2, 1, 0, 0, 0, 0,  0, 0,  1, 2, 0,1),
    (2,10,  0, 1, 0, 0, 0, 0,  0, 0,  0, 1, 0,1),
    (2,11,  0, 0, 1, 0, 0, 0,  0, 0,  0, 0, 0,1),
    (2,12,  0, 0, 0, 0, 0, 0,  0, 0,  0, 0, 0,0);
-- ========================
-- GAME 3  (game_id = 3, our_score = 88)
-- ========================
INSERT INTO player_game_stats (game_id, player_id, points, rebounds, assists, steals, blocks, turnovers,
                               ft_made, ft_attempts, two_made, two_attempts, three_made, three_attempts)
VALUES
(3,  1, 22,  (1*2+3)%8, (1+3)%6, (1+2*3)%3, (1+3)%2, (1+3*3)%4, 1, 2, 10, 11, 3, 4),
(3,  2, 15,  (2*2+3)%8, (2+3)%6, (2+2*3)%3, (2+3)%2, (2+3*3)%4, 1, 2,  6,  7, 1, 2),
(3,  3, 14,  (3*2+3)%8, (3+3)%6, (3+2*3)%3, (3+3)%2, (3+3*3)%4, 0, 0,  7,  8, 0, 0),
(3,  4, 10,  (4*2+3)%8, (4+3)%6, (4+2*3)%3, (4+3)%2, (4+3*3)%4, 0, 0,  5,  6, 0, 0),
(3,  5,  9,  (5*2+3)%8, (5+3)%6, (5+2*3)%3, (5+3)%2, (5+3*3)%4, 1, 2,  3,  4, 1, 2),
(3,  6,  6,  (6*2+3)%8, (6+3)%6, (6+2*3)%3, (6+3)%2, (6+3*3)%4, 0, 0,  3,  4, 0, 0),
(3,  7,  4,  (7*2+3)%8, (7+3)%6, (7+2*3)%3, (7+3)%2, (7+3*3)%4, 0, 0,  2,  3, 0, 0),
(3,  8,  4,  (8*2+3)%8, (8+3)%6, (8+2*3)%3, (8+3)%2, (8+3*3)%4, 0, 0,  2,  3, 0, 0),
(3,  9,  2,  (9*2+3)%8, (9+3)%6, (9+2*3)%3, (9+3)%2, (9+3*3)%4, 0, 0,  1,  2, 0, 0),
(3, 10,  1, (10*2+3)%8,(10+3)%6,(10+2*3)%3,(10+3)%2,(10+3*3)%4, 1, 2,  0,  0, 0, 0),
(3, 11,  1, (11*2+3)%8,(11+3)%6,(11+2*3)%3,(11+3)%2,(11+3*3)%4, 1, 2,  0,  0, 0, 0),
(3, 12,  0, (12*2+3)%8,(12+3)%6,(12+2*3)%3,(12+3)%2,(12+3*3)%4, 0, 0,  0,  0, 0, 0);

-- ========================
-- GAME 4  (game_id = 4, our_score = 72)
-- ========================
INSERT INTO player_game_stats (game_id, player_id, points, rebounds, assists, steals, blocks, turnovers,
                               ft_made, ft_attempts, two_made, two_attempts, three_made, three_attempts)
VALUES
(4,  1, 18,  (1*2+4)%8, (1+4)%6, (1+2*4)%3, (1+4)%2, (1+3*4)%4, 0, 0,  9, 10, 0, 0),
(4,  2, 14,  (2*2+4)%8, (2+4)%6, (2+2*4)%3, (2+4)%2, (2+3*4)%4, 0, 0,  7,  8, 0, 0),
(4,  3, 12,  (3*2+4)%8, (3+4)%6, (3+2*4)%3, (3+4)%2, (3+3*4)%4, 0, 0,  6,  7, 0, 0),
(4,  4,  8,  (4*2+4)%8, (4+4)%6, (4+2*4)%3, (4+4)%2, (4+3*4)%4, 0, 0,  4,  5, 0, 0),
(4,  5,  7,  (5*2+4)%8, (5+4)%6, (5+2*4)%3, (5+4)%2, (5+3*4)%4, 1, 2,  3,  4, 0, 0),
(4,  6,  5,  (6*2+4)%8, (6+4)%6, (6+2*4)%3, (6+4)%2, (6+3*4)%4, 1, 2,  2,  3, 0, 0),
(4,  7,  4,  (7*2+4)%8, (7+4)%6, (7+2*4)%3, (7+4)%2, (7+3*4)%4, 0, 0,  2,  3, 0, 0),
(4,  8,  2,  (8*2+4)%8, (8+4)%6, (8+2*4)%3, (8+4)%2, (8+3*4)%4, 0, 0,  1,  2, 0, 0),
(4,  9,  1,  (9*2+4)%8, (9+4)%6, (9+2*4)%3, (9+4)%2, (9+3*4)%4, 1, 2,  0,  0, 0, 0),
(4, 10,  1, (10*2+4)%8,(10+4)%6,(10+2*4)%3,(10+4)%2,(10+3*4)%4, 1, 2,  0,  0, 0, 0),
(4, 11,  0, (11*2+4)%8,(11+4)%6,(11+2*4)%3,(11+4)%2,(11+3*4)%4, 0, 0,  0,  0, 0, 0),
(4, 12,  0, (12*2+4)%8,(12+4)%6,(12+2*4)%3,(12+4)%2,(12+3*4)%4, 0, 0,  0,  0, 0, 0);

-- ========================
-- GAME 5  (game_id = 5, our_score = 90)
-- ========================
INSERT INTO player_game_stats (game_id, player_id, points, rebounds, assists, steals, blocks, turnovers,
                               ft_made, ft_attempts, two_made, two_attempts, three_made, three_attempts)
VALUES
(5,  1, 24,  (1*2+5)%8, (1+5)%6, (1+2*5)%3, (1+5)%2, (1+3*5)%4, 0, 0, 12, 13, 0, 0),
(5,  2, 18,  (2*2+5)%8, (2+5)%6, (2+2*5)%3, (2+5)%2, (2+3*5)%4, 0, 0,  9, 10, 0, 0),
(5,  3, 15,  (3*2+5)%8, (3+5)%6, (3+2*5)%3, (3+5)%2, (3+3*5)%4, 0, 0,  7,  8, 0, 0),
(5,  4,  9,  (4*2+5)%8, (4+5)%6, (4+2*5)%3, (4+5)%2, (4+3*5)%4, 1, 2,  4,  5, 0, 0),
(5,  5,  8,  (5*2+5)%8, (5+5)%6, (5+2*5)%3, (5+5)%2, (5+3*5)%4, 0, 0,  4,  5, 0, 0),
(5,  6,  5,  (6*2+5)%8, (6+5)%6, (6+2*5)%3, (6+5)%2, (6+3*5)%4, 1, 2,  2,  3, 0, 0),
(5,  7,  5,  (7*2+5)%8, (7+5)%6, (7+2*5)%3, (7+5)%2, (7+3*5)%4, 1, 2,  2,  3, 0, 0),
(5,  8,  3,  (8*2+5)%8, (8+5)%6, (8+2*5)%3, (8+5)%2, (8+3*5)%4, 1, 2,  1,  2, 0, 0),
(5,  9,  2,  (9*2+5)%8, (9+5)%6, (9+2*5)%3, (9+5)%2, (9+3*5)%4, 0, 0,  1,  2, 0, 0),
(5, 10,  1, (10*2+5)%8,(10+5)%6,(10+2*5)%3,(10+5)%2,(10+3*5)%4, 1, 2,  0,  0, 0, 0),
(5, 11,  0, (11*2+5)%8,(11+5)%6,(11+2*5)%3,(11+5)%2,(11+3*5)%4, 0, 0,  0,  0, 0, 0),
(5, 12,  0, (12*2+5)%8,(12+5)%6,(12+2*5)%3,(12+5)%2,(12+3*5)%4, 0, 0,  0,  0, 0, 0);

-- ========================
-- GAME 6  (game_id = 6, our_score = 67)
-- ========================
INSERT INTO player_game_stats (game_id, player_id, points, rebounds, assists, steals, blocks, turnovers,
                               ft_made, ft_attempts, two_made, two_attempts, three_made, three_attempts)
VALUES
(6,  1, 16,  (1*2+6)%8, (1+6)%6, (1+2*6)%3, (1+6)%2, (1+3*6)%4, 0, 0,  8,  9, 0, 0),
(6,  2, 12,  (2*2+6)%8, (2+6)%6, (2+2*6)%3, (2+6)%2, (2+3*6)%4, 0, 0,  6,  7, 0, 0),
(6,  3, 11,  (3*2+6)%8, (3+6)%6, (3+2*6)%3, (3+6)%2, (3+3*6)%4, 1, 2,  5,  6, 0, 0),
(6,  4,  8,  (4*2+6)%8, (4+6)%6, (4+2*6)%3, (4+6)%2, (4+3*6)%4, 0, 0,  4,  5, 0, 0),
(6,  5,  7,  (5*2+6)%8, (5+6)%6, (5+2*6)%3, (5+6)%2, (5+3*6)%4, 1, 2,  3,  4, 0, 0),
(6,  6,  5,  (6*2+6)%8, (6+6)%6, (6+2*6)%3, (6+6)%2, (6+3*6)%4, 1, 2,  2,  3, 0, 0),
(6,  7,  3,  (7*2+6)%8, (7+6)%6, (7+2*6)%3, (7+6)%2, (7+3*6)%4, 1, 2,  1,  2, 0, 0),
(6,  8,  3,  (8*2+6)%8, (8+6)%6, (8+2*6)%3, (8+6)%2, (8+3*6)%4, 1, 2,  1,  2, 0, 0),
(6,  9,  1,  (9*2+6)%8, (9+6)%6, (9+2*6)%3, (9+6)%2, (9+3*6)%4, 1, 2,  0,  0, 0, 0),
(6, 10,  1, (10*2+6)%8,(10+6)%6,(10+2*6)%3,(10+6)%2,(10+3*6)%4, 1, 2,  0,  0, 0, 0),
(6, 11,  0, (11*2+6)%8,(11+6)%6,(11+2*6)%3,(11+6)%2,(11+3*6)%4, 0, 0,  0,  0, 0, 0),
(6, 12,  0, (12*2+6)%8,(12+6)%6,(12+2*6)%3,(12+6)%2,(12+3*6)%4, 0, 0,  0,  0, 0, 0);

-- ========================
-- GAME 7  (game_id = 7, our_score = 80)
-- ========================
INSERT INTO player_game_stats (game_id, player_id, points, rebounds, assists, steals, blocks, turnovers,
                               ft_made, ft_attempts, two_made, two_attempts, three_made, three_attempts)
VALUES
(7,  1, 21,  (1*2+7)%8, (1+7)%6, (1+2*7)%3, (1+7)%2, (1+3*7)%4, 1, 2, 10, 11, 0, 0),
(7,  2, 14,  (2*2+7)%8, (2+7)%6, (2+2*7)%3, (2+7)%2, (2+3*7)%4, 0, 0,  7,  8, 0, 0),
(7,  3, 13,  (3*2+7)%8, (3+7)%6, (3+2*7)%3, (3+7)%2, (3+3*7)%4, 1, 2,  6,  7, 0, 0),
(7,  4,  8,  (4*2+7)%8, (4+7)%6, (4+2*7)%3, (4+7)%2, (4+3*7)%4, 0, 0,  4,  5, 0, 0),
(7,  5,  7,  (5*2+7)%8, (5+7)%6, (5+2*7)%3, (5+7)%2, (5+3*7)%4, 1, 2,  3,  4, 0, 0),
(7,  6,  5,  (6*2+7)%8, (6+7)%6, (6+2*7)%3, (6+7)%2, (6+3*7)%4, 1, 2,  2,  3, 0, 0),
(7,  7,  4,  (7*2+7)%8, (7+7)%6, (7+2*7)%3, (7+7)%2, (7+3*7)%4, 0, 0,  2,  3, 0, 0),
(7,  8,  3,  (8*2+7)%8, (8+7)%6, (8+2*7)%3, (8+7)%2, (8+3*7)%4, 1, 2,  1,  2, 0, 0),
(7,  9,  3,  (9*2+7)%8, (9+7)%6, (9+2*7)%3, (9+7)%2, (9+3*7)%4, 1, 2,  1,  2, 0, 0),
(7, 10,  2, (10*2+7)%8,(10+7)%6,(10+2*7)%3,(10+7)%2,(10+3*7)%4, 0, 0,  1,  2, 0, 0),
(7, 11,  0, (11*2+7)%8,(11+7)%6,(11+2*7)%3,(11+7)%2,(11+3*7)%4, 0, 0,  0,  0, 0, 0),
(7, 12,  0, (12*2+7)%8,(12+7)%6,(12+2*7)%3,(12+7)%2,(12+3*7)%4, 0, 0,  0,  0, 0, 0);






BEGIN;

TRUNCATE TABLE
  player_game_stats,
  game_lineup,
  games,
  players,
  staff,
  teams
RESTART IDENTITY
CASCADE;

TRUNCATE TABLE audit_log RESTART IDENTITY;

COMMIT;



