package com.example.basketball_management_system.dao;

import com.example.basketball_management_system.model.Match;
import com.example.basketball_management_system.DBConnection;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class MatchDAO {

    // Χρησιμοποιούμε τον πίνακα matches:
    // match_id SERIAL PK
    // date DATE
    // home_team INT
    // away_team INT
    // score_home INT
    // score_away INT

    public static List<Match> getAllMatches() {
        List<Match> list = new ArrayList<>();

        String sql = """
                SELECT match_id, date, home_team, away_team, score_home, score_away
                FROM matches
                ORDER BY date DESC, match_id DESC
                """;

        try (Connection conn = DBConnection.connect();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                int id = rs.getInt("match_id");
                LocalDate date = rs.getDate("date").toLocalDate();
                int homeId = rs.getInt("home_team");
                int awayId = rs.getInt("away_team");

                Integer sh = (Integer) rs.getObject("score_home");
                Integer sa = (Integer) rs.getObject("score_away");

                Match m = new Match(id, date, homeId, awayId, sh, sa);
                list.add(m);
            }

        } catch (SQLException e) {
            System.out.println("Error loading matches: " + e.getMessage());
        }

        return list;
    }

    // Δημιουργία νέου αγώνα (χωρίς σκορ ακόμη)
    public static boolean recordMatch(LocalDate date, int homeTeamId, int awayTeamId) {
        String sql = """
                INSERT INTO matches(date, home_team, away_team)
                VALUES (?, ?, ?)
                """;

        try (Connection conn = DBConnection.connect();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setDate(1, Date.valueOf(date));
            ps.setInt(2, homeTeamId);
            ps.setInt(3, awayTeamId);

            int rows = ps.executeUpdate();
            return rows == 1;

        } catch (SQLException e) {
            System.out.println("Error inserting match: " + e.getMessage());
            return false;
        }
    }

    // Ενημέρωση σκορ αγώνα
    public static boolean updateScore(int matchId, int scoreHome, int scoreAway) {
        String sql = """
                UPDATE matches
                SET score_home = ?, score_away = ?
                WHERE match_id = ?
                """;

        try (Connection conn = DBConnection.connect();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, scoreHome);
            ps.setInt(2, scoreAway);
            ps.setInt(3, matchId);

            int rows = ps.executeUpdate();
            return rows == 1;

        } catch (SQLException e) {
            System.out.println("Error updating match score: " + e.getMessage());
            return false;
        }
    }

    // Διαγραφή αγώνα
    public static boolean deleteMatch(int matchId) {
        String sql = "DELETE FROM matches WHERE match_id = ?";

        try (Connection conn = DBConnection.connect();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, matchId);
            int rows = ps.executeUpdate();
            return rows == 1;

        } catch (SQLException e) {
            System.out.println("Error deleting match: " + e.getMessage());
            return false;
        }
    }
}
