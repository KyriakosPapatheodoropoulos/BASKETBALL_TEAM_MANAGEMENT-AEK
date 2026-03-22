package com.example.basketball_management_system.dao;

import com.example.basketball_management_system.DBConnection;
import com.example.basketball_management_system.model.LogEntry;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class LogDAO {

    public static List<LogEntry> getAllLogs() {
        List<LogEntry> logs = new ArrayList<>();

        String sql = """
                SELECT id, table_name, action_type, description, created_at
                FROM logs
                ORDER BY id DESC
                """;

        try (Connection conn = DBConnection.connect();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                LogEntry entry = new LogEntry(
                        rs.getInt("id"),
                        rs.getString("table_name"),
                        rs.getString("action_type"),
                        rs.getString("description"),
                        // αν στο model έχεις String:
                        rs.getTimestamp("created_at").toString()
                        // αν έχεις LocalDateTime, τότε:
                        // rs.getTimestamp("created_at").toLocalDateTime()
                );
                logs.add(entry);
            }

        } catch (SQLException e) {
            System.out.println("Error loading logs: " + e.getMessage());
        }

        return logs;
    }
}
