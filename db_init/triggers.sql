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

    ELSIF TG_TABLE_NAME = 'game_lineup' THEN
        key_text := 'game_id=' || COALESCE(NEW.game_id, OLD.game_id)::TEXT
                    || ', player_id=' || COALESCE(NEW.player_id, OLD.player_id)::TEXT;

    ELSIF TG_TABLE_NAME = 'players' THEN
        key_text := 'player_id=' || COALESCE(NEW.player_id, OLD.player_id)::TEXT;

    ELSIF TG_TABLE_NAME = 'games' THEN
        key_text := 'game_id=' || COALESCE(NEW.game_id, OLD.game_id)::TEXT;

    ELSIF TG_TABLE_NAME = 'staff' THEN
        key_text := 'staff_id=' || COALESCE(NEW.staff_id, OLD.staff_id)::TEXT;

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


-- 2) (Re)create triggers (drop πρώτα για να μην υπάρχουν διπλά)
DROP TRIGGER IF EXISTS log_players ON players;
DROP TRIGGER IF EXISTS log_staff ON staff;
DROP TRIGGER IF EXISTS log_games ON games;
DROP TRIGGER IF EXISTS log_player_game_stats ON player_game_stats;
DROP TRIGGER IF EXISTS log_game_lineup ON game_lineup;

CREATE TRIGGER log_players
AFTER INSERT OR UPDATE OR DELETE ON players
FOR EACH ROW EXECUTE FUNCTION trg_audit_log();

CREATE TRIGGER log_staff
AFTER INSERT OR UPDATE OR DELETE ON staff
FOR EACH ROW
EXECUTE FUNCTION trg_audit_log();

CREATE TRIGGER log_games
AFTER INSERT OR UPDATE OR DELETE ON games
FOR EACH ROW EXECUTE FUNCTION trg_audit_log();

CREATE TRIGGER log_player_game_stats
AFTER INSERT OR UPDATE OR DELETE ON player_game_stats
FOR EACH ROW EXECUTE FUNCTION trg_audit_log();

CREATE TRIGGER log_game_lineup
AFTER INSERT OR UPDATE OR DELETE ON game_lineup
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


-- 1) Function: deny stats changes if inactive player exists in lineup for that game
CREATE OR REPLACE FUNCTION deny_stats_if_inactive_in_lineup()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_game_id integer;
BEGIN
    -- Βρες game_id ανάλογα με operation
    IF TG_OP = 'DELETE' THEN
        v_game_id := OLD.game_id;
    ELSE
        v_game_id := NEW.game_id;
    END IF;

    -- Αν στην 12άδα υπάρχει παίκτης active=false, μπλοκάρουμε
    IF EXISTS (
        SELECT 1
        FROM game_lineup gl
        JOIN players p ON p.player_id = gl.player_id
        WHERE gl.game_id = v_game_id
          AND p.active = FALSE
    ) THEN
        RAISE EXCEPTION
            'Operation denied: inactive player exists in lineup for game_id=%',
            v_game_id
            USING ERRCODE = '45000';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

-- 1) Trigger on player_game_stats
DROP TRIGGER IF EXISTS trg_deny_stats_if_inactive_in_lineup ON player_game_stats;

CREATE TRIGGER trg_deny_stats_if_inactive_in_lineup
BEFORE INSERT OR UPDATE OR DELETE
ON player_game_stats
FOR EACH ROW
EXECUTE FUNCTION deny_stats_if_inactive_in_lineup();


-- 2) Function: deny reschedule/date changes in games if rules violated
CREATE OR REPLACE FUNCTION deny_game_date_change_if_invalid()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Τρέχει μόνο όταν αλλάζουν τα πεδία ημερομηνίας/αναβολής
    IF (NEW.game_date IS DISTINCT FROM OLD.game_date)
       OR (NEW.rescheduled_date IS DISTINCT FROM OLD.rescheduled_date)
       OR (NEW.rescheduled IS DISTINCT FROM OLD.rescheduled) THEN

        -- (A) inactive παίκτης στη 12άδα => deny
        IF EXISTS (
            SELECT 1
            FROM game_lineup gl
            JOIN players p ON p.player_id = gl.player_id
            WHERE gl.game_id = NEW.game_id
              AND p.active = FALSE
        ) THEN
            RAISE EXCEPTION
                'Reschedule denied: inactive player exists in lineup for game_id=%',
                NEW.game_id
                USING ERRCODE = '45000';
        END IF;

        -- (B) αν υπάρχουν ήδη stats => deny
        IF EXISTS (
            SELECT 1
            FROM player_game_stats s
            WHERE s.game_id = NEW.game_id
            LIMIT 1
        ) THEN
            RAISE EXCEPTION
                'Reschedule denied: stats already exist for game_id=%',
                NEW.game_id
                USING ERRCODE = '45000';
        END IF;

        -- (C) αν υπάρχει ήδη σκορ => deny (σύμφωνα με κανόνα σου)
        IF (OLD.our_score IS NOT NULL) OR (OLD.opponent_score IS NOT NULL)
           OR (NEW.our_score IS NOT NULL) OR (NEW.opponent_score IS NOT NULL) THEN
            RAISE EXCEPTION
                'Reschedule denied: score already set for game_id=%',
                NEW.game_id
                USING ERRCODE = '45000';
        END IF;

    END IF;

    RETURN NEW;
END;
$$;

-- 2) Trigger on games
DROP TRIGGER IF EXISTS trg_deny_game_date_change_if_invalid ON games;

CREATE TRIGGER trg_deny_game_date_change_if_invalid
BEFORE UPDATE
ON games
FOR EACH ROW
EXECUTE FUNCTION deny_game_date_change_if_invalid();




-- 3) Function: deny clearing score if inactive player exists in lineup
CREATE OR REPLACE FUNCTION deny_clear_score_if_inactive_in_lineup()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Αν προσπαθείς να κάνεις clear score
    IF (NEW.our_score IS NULL AND NEW.opponent_score IS NULL)
       AND (OLD.our_score IS NOT NULL OR OLD.opponent_score IS NOT NULL) THEN

        IF EXISTS (
            SELECT 1
            FROM game_lineup gl
            JOIN players p ON p.player_id = gl.player_id
            WHERE gl.game_id = NEW.game_id
              AND p.active = FALSE
        ) THEN
            RAISE EXCEPTION
                'Clear score denied: inactive player exists in lineup for game_id=%',
                NEW.game_id
                USING ERRCODE = '45000';
        END IF;

    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_clear_score_if_inactive_in_lineup ON games;

CREATE TRIGGER trg_deny_clear_score_if_inactive_in_lineup
BEFORE UPDATE
ON games
FOR EACH ROW
EXECUTE FUNCTION deny_clear_score_if_inactive_in_lineup();


