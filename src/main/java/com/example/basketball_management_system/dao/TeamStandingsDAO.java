package com.example.basketball_management_system.dao;

import com.example.basketball_management_system.DBConnection;
import com.example.basketball_management_system.model.Team;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class TeamStandingsDAO {

    /**
     * Επιστρέφει τις ομάδες ταξινομημένες ανά region και νίκες (standings).
     */
    public static List<Team> getStandings() {
        List<Team> teams = new ArrayList<>();

        String sql = """
                SELECT team_id, name, region, wins, losses
                FROM teams
                ORDER BY region, wins DESC, losses ASC, name
                """;

        try (Connection conn = DBConnection.connect();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Team t = new Team(
                        rs.getInt("team_id"),
                        rs.getString("name"),
                        null,                        // city αν δεν το χρειάζεσαι εδώ
                        rs.getString("region"),
                        rs.getInt("wins"),
                        rs.getInt("losses")
                );
                teams.add(t);
            }

        } catch (SQLException e) {
            System.out.println("Error loading standings: " + e.getMessage());
        }

        return teams;
    }
}
