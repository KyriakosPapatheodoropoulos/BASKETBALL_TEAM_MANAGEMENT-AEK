package com.example.basketball_management_system.dao;

import com.example.basketball_management_system.DBConnection;
import com.example.basketball_management_system.model.Player;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PlayerDAO {

    // Επιστρέφει όλους τους παίκτες
    public List<Player> getAllPlayers() {
        List<Player> players = new ArrayList<>();
        String sql = "SELECT * FROM players ORDER BY player_id";

        try (Connection conn = DBConnection.connect();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Player p = new Player(
                        rs.getInt("player_id"),
                        rs.getString("name"),
                        rs.getInt("age"),
                        rs.getString("position"),
                        rs.getInt("team_id"),
                        rs.getInt("total_points"),
                        rs.getInt("total_assists"),
                        rs.getInt("total_rebounds")
                );
                players.add(p);
            }

        } catch (SQLException e) {
            System.out.println("❌ Error loading players: " + e.getMessage());
        }
        return players;
    }

    // Διαγραφή παίκτη
    public void deletePlayer(int playerId) {
        String sql = "DELETE FROM players WHERE player_id = ?";
        try (Connection conn = DBConnection.connect();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, playerId);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.out.println("❌ Error deleting player: " + e.getMessage());
        }
    }

    public static List<Player> getPlayersByTeam(int teamId) {
        List<Player> players = new ArrayList<>();

        String sql = """
            SELECT player_id, name, age, position, team_id,
                   total_points, total_assists, total_rebounds
            FROM players
            WHERE team_id = ?
            ORDER BY name
            """;

        try (Connection conn = DBConnection.connect();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, teamId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Player p = new Player(
                            rs.getInt("player_id"),
                            rs.getString("name"),
                            rs.getInt("age"),
                            rs.getString("position"),
                            rs.getInt("team_id"),
                            rs.getInt("total_points"),
                            rs.getInt("total_assists"),
                            rs.getInt("total_rebounds")
                    );
                    players.add(p);
                }
            }

        } catch (SQLException e) {
            System.out.println("Error loading players by team: " + e.getMessage());
        }

        return players;
    }
    public static int countPlayersByTeam(int teamId) {
        String sql = "SELECT COUNT(*) FROM players WHERE team_id = ?";

        try (Connection conn = DBConnection.connect();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, teamId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        } catch (SQLException e) {
            System.out.println("Error counting players: " + e.getMessage());
        }
        return 0;
    }

    public static boolean addPlayer(Player p) {
        // 1. έλεγχος ορίου 15 παικτών/ομάδα
        int current = countPlayersByTeam(p.getTeamId());
        if (current >= 15) {
            // δεν επιτρέπεται άλλος παίκτης
            return false;
        }

        String sql = "INSERT INTO players(name, age, position, team_id) VALUES (?, ?, ?, ?)";

        try (Connection conn = DBConnection.connect();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, p.getName());
            ps.setInt(2, p.getAge());
            ps.setString(3, p.getPosition());
            ps.setInt(4, p.getTeamId());

            int rows = ps.executeUpdate();
            return rows > 0;

        } catch (SQLException e) {
            System.out.println("Error adding player: " + e.getMessage());
            return false;
        }
    }
    public static boolean transferPlayer(int playerId, int newTeamId) {
        String sql = "CALL transfer_player(?, ?)";  // η procedure από το SQL

        try (Connection conn = DBConnection.connect();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, playerId);
            ps.setInt(2, newTeamId);
            ps.execute();      // δεν επιστρέφει ResultSet

            return true;
        } catch (SQLException e) {
            System.out.println("Error transferring player: " + e.getMessage());
            return false;
        }
    }


}
