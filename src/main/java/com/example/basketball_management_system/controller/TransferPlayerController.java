package com.example.basketball_management_system.controller;

import com.example.basketball_management_system.dao.PlayerDAO;
import com.example.basketball_management_system.dao.TeamDAO;
import com.example.basketball_management_system.model.Player;
import com.example.basketball_management_system.model.Team;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.stage.Stage;
import javafx.util.StringConverter;

public class TransferPlayerController {

    @FXML private ComboBox<Player> cbPlayer;
    @FXML private ComboBox<Team> cbNewTeam;
    @FXML private Label lblInfo;

    private final ObservableList<Player> players = FXCollections.observableArrayList();
    private final ObservableList<Team> teams   = FXCollections.observableArrayList();

    @FXML
    public void initialize() {
        // Φόρτωσε παίκτες & ομάδες
        players.setAll(new PlayerDAO().getAllPlayers());
        teams.setAll(new TeamDAO().getAllTeams());

        cbPlayer.setItems(players);
        cbNewTeam.setItems(teams);

        cbPlayer.setConverter(new StringConverter<>() {
            @Override public String toString(Player p) {
                return p == null ? "" : "#" + p.getPlayerId() + " " + p.getName() + " (team " + p.getTeamId() + ")";
            }
            @Override public Player fromString(String s) { return null; }
        });

        cbNewTeam.setConverter(new StringConverter<>() {
            @Override public String toString(Team t) {
                return t == null ? "" : t.getName() + " (id:" + t.getTeamId() + ")";
            }
            @Override public Team fromString(String s) { return null; }
        });
    }

    @FXML
    private void onTransfer() {
        Player p = cbPlayer.getValue();
        Team t   = cbNewTeam.getValue();

        if (p == null || t == null) {
            lblInfo.setText("Select player and destination team.");
            return;
        }
        if (p.getTeamId() == t.getTeamId()) {
            lblInfo.setText("Player is already in that team.");
            return;
        }

        boolean ok = PlayerDAO.transferPlayer(p.getPlayerId(), t.getTeamId());
        if (ok) {
            lblInfo.setText("Transfer completed.");
        } else {
            lblInfo.setText("Error during transfer (check logs).");
        }
    }

    @FXML
    private void onClose() {
        Stage st = (Stage) cbPlayer.getScene().getWindow();
        st.close();
    }
}
