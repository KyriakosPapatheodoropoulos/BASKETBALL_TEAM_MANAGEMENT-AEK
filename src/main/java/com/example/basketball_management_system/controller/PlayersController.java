package com.example.basketball_management_system.controller;

import com.example.basketball_management_system.dao.PlayerDAO;
import com.example.basketball_management_system.dao.TeamDAO;
import com.example.basketball_management_system.model.Player;
import com.example.basketball_management_system.model.Team;
import javafx.beans.property.SimpleIntegerProperty;
import javafx.beans.property.SimpleStringProperty;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.stage.Stage;
import javafx.util.StringConverter;

import java.util.List;

public class PlayersController {

    @FXML private TableView<Player> table;
    @FXML private TableColumn<Player, Number> colId;
    @FXML private TableColumn<Player, String> colName;
    @FXML private TableColumn<Player, Number> colAge;
    @FXML private TableColumn<Player, String> colPosition;
    @FXML private TableColumn<Player, Number> colTeam;
    @FXML private TableColumn<Player, Number> colPts;
    @FXML private TableColumn<Player, Number> colAst;
    @FXML private TableColumn<Player, Number> colReb;

    @FXML private TextField txtName;
    @FXML private TextField txtAge;
    @FXML private ComboBox<String> cbPosition;
    @FXML private ComboBox<Team> cbTeam;
    @FXML private Label lblStatus;

    private final PlayerDAO playerDAO = new PlayerDAO();
    private final TeamDAO teamDAO   = new TeamDAO();

    private final ObservableList<Player> data  = FXCollections.observableArrayList();
    private final ObservableList<Team>   teams = FXCollections.observableArrayList();

    @FXML
    public void initialize() {
        // Bindings για τις στήλες του πίνακα
        colId.setCellValueFactory(c -> new SimpleIntegerProperty(c.getValue().getPlayerId()));
        colName.setCellValueFactory(c -> new SimpleStringProperty(c.getValue().getName()));
        colAge.setCellValueFactory(c -> new SimpleIntegerProperty(c.getValue().getAge()));
        colPosition.setCellValueFactory(c -> new SimpleStringProperty(c.getValue().getPosition()));
        colTeam.setCellValueFactory(c -> new SimpleIntegerProperty(c.getValue().getTeamId()));
        colPts.setCellValueFactory(c -> new SimpleIntegerProperty(c.getValue().getTotalPoints()));
        colAst.setCellValueFactory(c -> new SimpleIntegerProperty(c.getValue().getTotalAssists()));
        colReb.setCellValueFactory(c -> new SimpleIntegerProperty(c.getValue().getTotalRebounds()));

        table.setItems(data);

        // Γέμισμα ComboBox ομάδων
        teams.setAll(teamDAO.getAllTeams());
        cbTeam.setItems(teams);
        cbTeam.setConverter(new StringConverter<>() {
            @Override
            public String toString(Team t) {
                return t == null ? "" : t.getName() + " (id:" + t.getTeamId() + ")";
            }

            @Override
            public Team fromString(String s) {
                return null; // δεν το χρειαζόμαστε
            }
        });

        refresh();
    }

    /* ---------- Βοηθητικές μέθοδοι ---------- */

    private void refresh() {
        List<Player> players = playerDAO.getAllPlayers();
        data.setAll(players);
        lblStatus.setText("Loaded " + data.size() + " players");
    }

    private void clearForm() {
        txtName.clear();
        txtAge.clear();
        cbPosition.getSelectionModel().clearSelection();
        cbTeam.getSelectionModel().clearSelection();
    }

    private void alert(Alert.AlertType type, String title, String msg) {
        Alert a = new Alert(type);
        a.setTitle(title);
        a.setHeaderText(null);
        a.setContentText(msg);
        a.showAndWait();
    }

    /* ---------- Handlers κουμπιών ---------- */

    @FXML
    public void onRefresh() {
        refresh();
    }

    @FXML
    public void onAddPlayer() {
        String name = txtName.getText().trim();
        String ageTxt = txtAge.getText().trim();
        String pos = cbPosition.getValue();
        Team team = cbTeam.getValue();

        if (name.isEmpty() || ageTxt.isEmpty() || pos == null || team == null) {
            alert(Alert.AlertType.WARNING, "Missing data",
                    "Συμπλήρωσε όνομα, ηλικία, θέση και ομάδα.");
            lblStatus.setText("Fill all fields");
            return;
        }

        int age;
        try {
            age = Integer.parseInt(ageTxt);
        } catch (NumberFormatException e) {
            alert(Alert.AlertType.WARNING, "Invalid age",
                    "Η ηλικία πρέπει να είναι ακέραιος αριθμός.");
            lblStatus.setText("Age must be a number");
            return;
        }

        Player p = new Player(
                0,                  // id (θα μπει από τη βάση)
                name,
                age,
                pos,
                team.getTeamId(),
                0, 0, 0             // στατιστικά αρχικά 0
        );

        // χρησιμοποιούμε το static PlayerDAO.addPlayer(p) με έλεγχο ορίου 15 παικτών
        boolean ok = PlayerDAO.addPlayer(p);
        if (!ok) {
            alert(Alert.AlertType.WARNING,
                    "Team is full",
                    "Η ομάδα αυτή έχει ήδη 15 παίκτες.\n" +
                            "Πρέπει να διαγράψεις κάποιον πριν προσθέσεις νέο.");
            lblStatus.setText("Team already has 15 players");
        } else {
            clearForm();
            refresh();
            lblStatus.setText("Player added");
        }
    }

    @FXML
    public void onDeleteSelected() {
        Player sel = table.getSelectionModel().getSelectedItem();
        if (sel == null) {
            alert(Alert.AlertType.WARNING, "No selection",
                    "Επίλεξε πρώτα έναν παίκτη για διαγραφή.");
            lblStatus.setText("Select a player first");
            return;
        }

        Alert confirm = new Alert(Alert.AlertType.CONFIRMATION,
                "Να διαγραφεί ο παίκτης " + sel.getName() + " ?",
                ButtonType.OK, ButtonType.CANCEL);
        confirm.setHeaderText(null);

        if (confirm.showAndWait().orElse(ButtonType.CANCEL) != ButtonType.OK) {
            return;
        }

        playerDAO.deletePlayer(sel.getPlayerId());
        refresh();
        lblStatus.setText("Player deleted");
    }

    @FXML
    private void onOpenRosterWindow() {
        try {
            javafx.fxml.FXMLLoader loader = new javafx.fxml.FXMLLoader(
                    getClass().getResource("/fxml/MatchRoster.fxml")
            );
            Parent root = loader.load();
            Stage stage = new Stage();
            stage.setTitle("Declare Match Roster");
            stage.setScene(new Scene(root));
            stage.show();
        } catch (Exception e) {
            e.printStackTrace();
            alert(Alert.AlertType.ERROR, "Error",
                    "Error opening Match Roster window:\n" + e.getMessage());
        }
    }

    @FXML
    private void onViewLogs() {
        try {
            javafx.fxml.FXMLLoader loader = new javafx.fxml.FXMLLoader(
                    getClass().getResource("/fxml/Logs.fxml")
            );
            Parent root = loader.load();
            Stage stage = new Stage();
            stage.setTitle("System Logs");
            stage.setScene(new Scene(root));
            stage.show();
        } catch (Exception e) {
            System.out.println("Error opening Logs window: " + e.getMessage());
            e.printStackTrace();
            alert(Alert.AlertType.ERROR, "Error",
                    "Error opening Logs window:\n" + e.getMessage());
        }
    }
    @FXML
    private void onViewStandings() {
        try {
            javafx.fxml.FXMLLoader loader = new javafx.fxml.FXMLLoader(
                    getClass().getResource("/fxml/Standings.fxml")
            );
            javafx.scene.Parent root = loader.load();
            javafx.stage.Stage stage = new javafx.stage.Stage();
            stage.setTitle("League Standings");
            stage.setScene(new javafx.scene.Scene(root));
            stage.show();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    @FXML
    private void onOpenTransferWindow() {
        try {
            javafx.fxml.FXMLLoader loader = new javafx.fxml.FXMLLoader(
                    getClass().getResource("/fxml/TransferPlayer.fxml")
            );
            javafx.scene.Parent root = loader.load();
            javafx.stage.Stage stage = new javafx.stage.Stage();
            stage.setTitle("Transfer Player");
            stage.setScene(new javafx.scene.Scene(root));
            stage.show();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}
