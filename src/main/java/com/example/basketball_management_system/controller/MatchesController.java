package com.example.basketball_management_system.controller;

import com.example.basketball_management_system.dao.MatchDAO;
import com.example.basketball_management_system.dao.TeamDAO;
import com.example.basketball_management_system.model.Match;
import com.example.basketball_management_system.model.Team;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.stage.Modality;
import javafx.stage.Stage;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;

public class MatchesController {

    @FXML private DatePicker datePicker;
    @FXML private ComboBox<Team> homeCombo;
    @FXML private ComboBox<Team> awayCombo;

    @FXML private TableView<Match> matchesTable;
    @FXML private TableColumn<Match, Integer> idColumn;
    @FXML private TableColumn<Match, LocalDate> dateColumn;
    @FXML private TableColumn<Match, String> homeColumn;
    @FXML private TableColumn<Match, String> awayColumn;
    @FXML private TableColumn<Match, String> scoreColumn;

    @FXML private TextField scoreHomeField;
    @FXML private TextField scoreAwayField;

    private final ObservableList<Match> matchesData = FXCollections.observableArrayList();
    private final ObservableList<Team> teamsData = FXCollections.observableArrayList();

    @FXML
    public void initialize() {
        // columns - προσαρμοσε αν έχεις διαφορετικά getters
        idColumn.setCellValueFactory(new PropertyValueFactory<>("id"));           // ή "matchId"
        dateColumn.setCellValueFactory(new PropertyValueFactory<>("date"));
        homeColumn.setCellValueFactory(new PropertyValueFactory<>("homeTeamName")); // ενα από τα δύο:
        awayColumn.setCellValueFactory(new PropertyValueFactory<>("awayTeamName")); //    A) έτοιμο getter ονόματος
        scoreColumn.setCellValueFactory(new PropertyValueFactory<>("scoreText"));   //    B) ή θα δούμε παρακάτω cell factory

        matchesTable.setItems(matchesData);

        // φόρτωσε ομάδες για combobox
        loadTeams();
        // φόρτωσε αγώνες
        loadMatches();

        // optional: default σημερινή ημερομηνία
        datePicker.setValue(LocalDate.now());
    }

    private void loadTeams() {
        List<Team> teams = TeamDAO.getAllTeams();
        teamsData.setAll(teams);
        homeCombo.setItems(teamsData);
        awayCombo.setItems(teamsData);
    }

    private void loadMatches() {
        matchesData.setAll(MatchDAO.getAllMatches());

        // Αν το μοντέλο Match δεν έχει getHomeTeamName()/getAwayTeamName()/getScoreText(),
        // βάλε cell factories για εμφάνιση
        homeColumn.setCellFactory(col -> new TableCell<>() {
            @Override protected void updateItem(String item, boolean empty) {
                super.updateItem(item, empty);
                if (empty) { setText(null); return; }
                Match m = getTableView().getItems().get(getIndex());
                setText(resolveTeamName(m.getHomeTeamId())); // προσαρμοσε getter
            }
        });

        awayColumn.setCellFactory(col -> new TableCell<>() {
            @Override protected void updateItem(String item, boolean empty) {
                super.updateItem(item, empty);
                if (empty) { setText(null); return; }
                Match m = getTableView().getItems().get(getIndex());
                setText(resolveTeamName(m.getAwayTeamId())); // προσαρμοσε getter
            }
        });

        scoreColumn.setCellFactory(col -> new TableCell<>() {
            @Override protected void updateItem(String item, boolean empty) {
                super.updateItem(item, empty);
                if (empty) { setText(null); return; }
                Match m = getTableView().getItems().get(getIndex());
                Integer sh = m.getScoreHome(); // προσαρμοσε getter
                Integer sa = m.getScoreAway();
                setText(sh == null || sa == null ? "-" : (sh + " - " + sa));
            }
        });
    }

    private String resolveTeamName(int teamId) {
        // απλό lookup από το ήδη φορτωμένο teamsData
        for (Team t : teamsData) {
            if (t.getTeamId() == teamId) return t.getName(); // προσαρμοσε getters
        }
        return "Team#" + teamId;
    }

    @FXML
    private void onCreateMatch() {
        LocalDate date = datePicker.getValue();
        Team home = homeCombo.getValue();
        Team away = awayCombo.getValue();

        if (date == null || home == null || away == null) {
            alert(Alert.AlertType.WARNING, "Missing data", "Select date, home and away teams.");
            return;
        }
        if (home.getTeamId() == away.getTeamId()) {
            alert(Alert.AlertType.WARNING, "Invalid teams", "Home and Away cannot be the same team.");
            return;
        }

        boolean ok = MatchDAO.recordMatch(date, home.getTeamId(), away.getTeamId());
        if (ok) {
            loadMatches();
            scoreHomeField.clear();
            scoreAwayField.clear();
        } else {
            alert(Alert.AlertType.ERROR, "Error", "Could not create match.");
        }
    }

    @FXML
    private void onSetScore() {
        Match selected = matchesTable.getSelectionModel().getSelectedItem();
        if (selected == null) {
            alert(Alert.AlertType.WARNING, "No selection", "Select a match first.");
            return;
        }
        String hs = scoreHomeField.getText().trim();
        String as = scoreAwayField.getText().trim();
        int h, a;
        try {
            h = Integer.parseInt(hs);
            a = Integer.parseInt(as);
        } catch (NumberFormatException e) {
            alert(Alert.AlertType.WARNING, "Invalid score", "Scores must be integers.");
            return;
        }
        if (h < 0 || a < 0) {
            alert(Alert.AlertType.WARNING, "Invalid score", "Scores must be non-negative.");
            return;
        }

        boolean ok = MatchDAO.updateScore(selected.getMatchId(), h, a); // προσαρμοσε getter
        if (ok) {
            // το trigger σου ενημερώνει wins/losses
            loadMatches();
        } else {
            alert(Alert.AlertType.ERROR, "Error", "Could not update score.");
        }
    }

    @FXML
    private void onDeleteMatch() {
        Match selected = matchesTable.getSelectionModel().getSelectedItem();
        if (selected == null) {
            alert(Alert.AlertType.WARNING, "No selection", "Select a match to delete.");
            return;
        }
        Alert confirm = new Alert(Alert.AlertType.CONFIRMATION, "Delete selected match?", ButtonType.OK, ButtonType.CANCEL);
        confirm.setHeaderText(null);
        if (confirm.showAndWait().orElse(ButtonType.CANCEL) != ButtonType.OK) return;

        boolean ok = MatchDAO.deleteMatch(selected.getMatchId()); // προσαρμοσε getter
        if (ok) loadMatches();
        else alert(Alert.AlertType.ERROR, "Error", "Could not delete match.");
    }

    @FXML
    private void onRefresh() {
        loadMatches();
    }

    @FXML
    private void onClose() {
        Stage st = (Stage) matchesTable.getScene().getWindow();
        st.close();
    }

    private void alert(Alert.AlertType type, String title, String msg) {
        Alert a = new Alert(type);
        a.setTitle(title); a.setHeaderText(null); a.setContentText(msg);
        a.showAndWait();
    }
    @FXML
    private void onManageRoster() {
        // 1. Ποιον αγώνα διαλέξαμε;
        Match selected = matchesTable.getSelectionModel().getSelectedItem();
        if (selected == null) {
            alert(Alert.AlertType.WARNING, "No selection", "Select a match first.");
            return;
        }

        try {
            // 2. Φόρτωση FXML για ρόστερ αγώνα
            FXMLLoader loader = new FXMLLoader(
                    getClass().getResource("/fxml/MatchRoster.fxml")
            );
            Parent root = loader.load();

            // 3. Πέρνα τον αγώνα στον controller της 12άδας
            MatchRosterController rosterController = loader.getController();
            rosterController.setMatch(selected);

            // 4. Άνοιγμα νέου παραθύρου (modal)
            Stage stage = new Stage();
            stage.setTitle("Roster for match #" + selected.getMatchId());
            stage.initOwner(matchesTable.getScene().getWindow());
            stage.initModality(Modality.WINDOW_MODAL);
            stage.setScene(new Scene(root));
            stage.showAndWait();   // περιμένει μέχρι να κλείσει το παράθυρο

            // 5. Αν θες, μπορείς μετά να κάνεις refresh σε κάτι
            // π.χ. loadMatches(); ή refresh στατιστικών

        } catch (IOException e) {
            e.printStackTrace();
            alert(Alert.AlertType.ERROR, "Error", "Could not open roster window.");
        }
    }

}
