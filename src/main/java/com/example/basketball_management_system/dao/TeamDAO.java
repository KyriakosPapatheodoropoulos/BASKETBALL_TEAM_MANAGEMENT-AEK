package com.example.basketball_management_system.dao;

import com.example.basketball_management_system.DBConnection;
import com.example.basketball_management_system.model.Team;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class TeamDAO {

    public static List<Team> getAllTeams() {
        List<Team> teams = new ArrayList<>();
        String sql = "SELECT * FROM teams ORDER BY team_id";

        try (Connection conn = DBConnection.connect();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {

            while (rs.next()) {
                Team t = new Team(
                        rs.getInt("team_id"),
                        rs.getString("name"),
                        rs.getString("city"),
                        rs.getInt("wins"),
                        rs.getInt("losses")
                );
                teams.add(t);
            }

        } catch (SQLException e) {
            System.out.println("❌ Error loading teams: " + e.getMessage());
        }

        return teams;
    }
}
