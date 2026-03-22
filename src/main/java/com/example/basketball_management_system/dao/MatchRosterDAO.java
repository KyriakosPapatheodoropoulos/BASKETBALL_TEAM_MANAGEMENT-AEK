package com.example.basketball_management_system.dao;

import com.example.basketball_management_system.DBConnection;
import com.example.basketball_management_system.model.Player;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class MatchRosterDAO {

    /**
     * Επιστρέφει τη δηλωμένη 12άδα (ή λιγότερους) μιας συγκεκριμένης ομάδας σε συγκεκριμένο αγώνα.
     *
     * @param matchId id αγώνα
     * @param teamId  id ομάδας (home ή away)
     */
    public static List<Player> getRosterForTeamInMatch(int matchId, int teamId) {
        List<Player> roster = new ArrayList<>();

        String sql = """
                SELECT p.player_id, p.name, p.age, p.position, p.team_id,
                       p.total_points, p.total_assists, p.total_rebounds
                FROM match_roster mr
                JOIN players p ON mr.player_id = p.player_id
                WHERE mr.match_id = ?
                  AND p.team_id = ?
                ORDER BY p.name
                """;

        try (Connection conn = DBConnection.connect();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, matchId);
            ps.setInt(2, teamId);

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
                    roster.add(p);
                }
            }

        } catch (SQLException e) {
            System.out.println("Error loading match roster: " + e.getMessage());
        }

        return roster;
    }

    /**
     * Αποθηκεύει τη 12άδα μιας ομάδας για έναν αγώνα.
     *
     * 1) Σβήνει ό,τι υπήρχε ήδη στο match_roster για αυτόν τον αγώνα + αυτήν την ομάδα
     * 2) Εισάγει όλους τους νέους playerIds
     *
     * Χρησιμοποιεί transaction ώστε να γίνει είτε ΟΛΟ, είτε ΤΙΠΟΤΑ.
     *
     * @param matchId   αγώνας
     * @param teamId    ομάδα (home/away)
     * @param playerIds λίστα με τα player_id που δηλώνονται στη 12άδα
     * @return true αν έγινε επιτυχώς, false αν έσκασε exception
     */
    public static boolean saveRosterForTeamInMatch(int matchId, int teamId, List<Integer> playerIds) {
        String deleteSql = """
                DELETE FROM match_roster
                WHERE match_id = ?
                  AND player_id IN (
                      SELECT p.player_id
                      FROM players p
                      WHERE p.team_id = ?
                  )
                """;

        String insertSql = """
                INSERT INTO match_roster(match_id, player_id)
                VALUES (?, ?)
                """;

        try (Connection conn = DBConnection.connect()) {
            conn.setAutoCommit(false); // αρχή transaction

            // 1) Σβήνουμε την παλιά 12άδα αυτής της ομάδας για τον αγώνα
            try (PreparedStatement deleteStmt = conn.prepareStatement(deleteSql)) {
                deleteStmt.setInt(1, matchId);
                deleteStmt.setInt(2, teamId);
                deleteStmt.executeUpdate();
            }

            // 2) Εισάγουμε τη νέα λίστα παικτών
            try (PreparedStatement insertStmt = conn.prepareStatement(insertSql)) {
                for (Integer playerId : playerIds) {
                    insertStmt.setInt(1, matchId);
                    insertStmt.setInt(2, playerId);
                    insertStmt.addBatch();
                }
                insertStmt.executeBatch();
            }

            conn.commit();          // όλα καλά → commit
            conn.setAutoCommit(true);
            return true;

        } catch (SQLException e) {
            System.out.println("Error saving match roster: " + e.getMessage());
            // Αν θες, εδώ θα μπορούσαμε να κάνουμε και rollback,
            // αλλά με try-with-resources + νέο connection σε κάθε κλήση,
            // η σύνδεση θα κλείσει και η βάση θα κάνει rollback μόνη της.
            return false;
        }
    }

}
