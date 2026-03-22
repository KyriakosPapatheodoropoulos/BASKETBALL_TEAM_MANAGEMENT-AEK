-- 1. Teams
CREATE TABLE teams (
    team_id      SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL UNIQUE,
    city         VARCHAR(100),
    logo_url     TEXT,
    is_our_team  BOOLEAN NOT NULL DEFAULT FALSE
);


-- =========================
-- TABLE: players
-- =========================
CREATE TABLE players (
    player_id      SERIAL PRIMARY KEY,
    team_id        INT NOT NULL REFERENCES teams(team_id),

    first_name     VARCHAR(50) NOT NULL,
    last_name      VARCHAR(50) NOT NULL,

    jersey_number  INT NOT NULL
                   CHECK (jersey_number BETWEEN 0 AND 99),

    position       VARCHAR(10) NOT NULL,   -- PG, SG, SF, PF, C
    age            INT CHECK (age > 0),
    height_cm      NUMERIC(5,2),
    weight_kg      NUMERIC(5,2),

    photo_path     TEXT NOT NULL DEFAULT 'image/default.png',

    active         BOOLEAN NOT NULL DEFAULT TRUE
);

-- =========================
-- UNIQUE jersey per team (ONLY for active players)
-- =========================
CREATE UNIQUE INDEX players_team_id_jersey_active_uq
ON players (team_id, jersey_number)
WHERE active = TRUE;


-- 3. Games (8 αγώνες)
CREATE TABLE games (
    game_id             SERIAL PRIMARY KEY,
    game_date           DATE NOT NULL,
    opponent_name       VARCHAR(100), -- Προστέθηκε
    opponent_logo       VARCHAR(200), -- Προστέθηκε
    home_game           BOOLEAN NOT NULL DEFAULT TRUE, -- Μετονομάστηκε
    our_score           INT,          -- Τροποποιήθηκε (επιτρέπει NULL)
    opponent_score      INT,          -- Τροποποιήθηκε (επιτρέπει NULL)
    rescheduled_date    DATE,         -- Η στήλη 'rescheduled_date' προστέθηκε εδώ
    rescheduled         BOOLEAN NOT NULL DEFAULT FALSE -- Η στήλη 'rescheduled' προστέθηκε εδώ
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


