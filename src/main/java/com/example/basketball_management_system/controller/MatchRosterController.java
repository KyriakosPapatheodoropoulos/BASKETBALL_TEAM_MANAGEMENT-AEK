package com.example.basketball_management_system.controller;

import com.example.basketball_management_system.dao.MatchDAO;
import com.example.basketball_management_system.dao.MatchRosterDAO;
import com.example.basketball_management_system.dao.PlayerDAO;
import com.example.basketball_management_system.model.Match;
import com.example.basketball_management_system.model.Player;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.stage.Stage;
import javafx.collections.ListChangeListener;
import java.util.List;
import java.util.stream.Collectors;

public class MatchRosterController {

    @FXML
    private ComboBox<Match> matchCombo;

    @FXML
    private ComboBox<String> sideCombo; // "Home team" ή "Away team"

    @FXML
    private TableView<Player> playersTable;

    @FXML
    private TableColumn<Player, Integer> idColumn;

    @FXML
    private TableColumn<Player, String> nameColumn;

    @FXML
    private TableColumn<Player, String> positionColumn;

    @FXML
    private TableColumn<Player, Integer> ageColumn;

    @FXML
    private Label selectedCountLabel;

    private final ObservableList<Player> playersData = FXCollections.observableArrayList();

    @FXML
    public void initialize() {
        // στησίματα στηλών
        idColumn.setCellValueFactory(new PropertyValueFactory<>("id"));
        nameColumn.setCellValueFactory(new PropertyValueFactory<>("name"));
        positionColumn.setCellValueFactory(new PropertyValueFactory<>("position"));
        ageColumn.setCellValueFactory(new PropertyValueFactory<>("age"));

        // πολλαπλή επιλογή στο table
        playersTable.getSelectionModel().setSelectionMode(SelectionMode.MULTIPLE);
        playersTable.setItems(playersData);

        // όταν αλλάζει επιλογή, ενημέρωσε το label "Selected X/12"
        playersTable.getSelectionModel().getSelectedItems().addListener((ListChangeListener<Player>) change ->
                updateSelectedCount()
        );

        // φόρτωσε τους αγώνες
        loadMatches();

        // επιλογές ομάδας (πλευρά)
        sideCombo.getItems().addAll("Home team", "Away team");

        // όταν αλλάζει match ή side, φόρτωσε παίκτες
        matchCombo.valueProperty().addListener((obs, oldV, newV) -> loadPlayersForSelection());
        sideCombo.valueProperty().addListener((obs, oldV, newV) -> loadPlayersForSelection());
    }

    private void loadMatches() {
        List<Match> matches = MatchDAO.getAllMatches(); // υποθέτουμε ότι υπάρχει
        matchCombo.getItems().setAll(matches);
    }

    private void loadPlayersForSelection() {
        Match match = matchCombo.getValue();
        String side = sideCombo.getValue();

        if (match == null || side == null) {
            playersData.clear();
            playersTable.getSelectionModel().clearSelection();
            updateSelectedCount();
            return;
        }

        // βρες teamId
        int teamId;
        if (side.equals("Home team")) {
            teamId = match.getHomeTeamId();
        } else {
            teamId = match.getAwayTeamId();
        }

        // φόρτωσε όλους τους παίκτες της ομάδας (μέχρι 15)
        List<Player> teamPlayers = PlayerDAO.getPlayersByTeam(teamId);
        playersData.setAll(teamPlayers);

        // καθάρισε επιλογές
        playersTable.getSelectionModel().clearSelection();
        updateSelectedCount();

        // προφόρτωσε ήδη αποθηκευμένη 12άδα (αν υπάρχει)
        List<Player> alreadyDeclared = MatchRosterDAO.getRosterForTeamInMatch(match.getMatchId(), teamId);

        for (Player rosterPlayer : alreadyDeclared) {
            for (int i = 0; i < playersData.size(); i++) {
                if (playersData.get(i).getPlayerId() == rosterPlayer.getPlayerId()) {
                    playersTable.getSelectionModel().select(i);
                }
            }
        }

        updateSelectedCount();
    }

    private void updateSelectedCount() {
        int count = playersTable.getSelectionModel().getSelectedItems().size();
        selectedCountLabel.setText("Selected " + count + "/12");
    }

    @FXML
    private void onSave() {
        Match match = matchCombo.getValue();
        String side = sideCombo.getValue();

        if (match == null || side == null) {
            showAlert(Alert.AlertType.WARNING, "Missing selection",
                    "Please select match and team side first.");
            return;
        }

        int teamId = side.equals("Home team") ? match.getHomeTeamId() : match.getAwayTeamId();

        List<Player> selectedPlayers = playersTable.getSelectionModel().getSelectedItems();
        int count = selectedPlayers.size();

        if (count == 0) {
            showAlert(Alert.AlertType.WARNING, "No players selected",
                    "Please select players for the roster.");
            return;
        }

        if (count > 12) {
            showAlert(Alert.AlertType.WARNING, "Too many players",
                    "You selected " + count + " players.\nThe maximum allowed is 12.");
            return;
        }

        // αν θέλεις να επιβάλλεις και minimum 10:
        /*
        if (count < 10) {
            showAlert(Alert.AlertType.WARNING, "Too few players",
                    "You selected only " + count + " players. Minimum is 10.");
            return;
        }
        */

        List<Integer> playerIds = selectedPlayers.stream()
                .map(Player::getPlayerId)
                .collect(Collectors.toList());

        boolean ok = MatchRosterDAO.saveRosterForTeamInMatch(match.getMatchId(), teamId, playerIds);

        if (ok) {
            showAlert(Alert.AlertType.INFORMATION, "Success",
                    "Roster saved successfully.");
        } else {
            showAlert(Alert.AlertType.ERROR, "Error",
                    "There was an error saving the roster.\nCheck the logs or database constraints.");
        }
    }

    @FXML
    private void onClose() {
        Stage stage = (Stage) playersTable.getScene().getWindow();
        stage.close();
    }

    private void showAlert(Alert.AlertType type, String title, String msg) {
        Alert alert = new Alert(type);
        alert.setTitle(title);
        alert.setHeaderText(null);
        alert.setContentText(msg);
        alert.showAndWait();
    }
/*
    private Match match;

    @FXML
    private ListView<Player> homeList;

    @FXML
    private ListView<Player> awayList;

    @FXML
    private ListView<Player> selectedList;

    private final ObservableList<Player> homePlayers = FXCollections.observableArrayList();
    private final ObservableList<Player> awayPlayers = FXCollections.observableArrayList();
    private final ObservableList<Player> selectedPlayers = FXCollections.observableArrayList();

    public void setMatch(Match match) {
        this.match = match;

        // Φόρτωσε home & away ομάδες
        int homeId = match.getHomeTeamId();
        int awayId = match.getAwayTeamId();

        homePlayers.setAll(PlayerDAO.getPlayersByTeam(homeId));
        awayPlayers.setAll(PlayerDAO.getPlayersByTeam(awayId));

        // Αν έχει ήδη δηλωθεί 12άδα, φόρτωσέ την
        selectedPlayers.setAll(MatchRosterDAO.getRosterForTeamInMatch(int matchId,int teamId));
    }*/
private Match match;   // αν θέλεις να το κρατήσεις σαν πεδίο

    /**
     * Καλείται από το MatchesController όταν ανοίγουμε το παράθυρο ρόστερ
     * ώστε να είναι ήδη επιλεγμένος ο συγκεκριμένος αγώνας στο combo.
     */
    public void setMatch(Match match) {
        this.match = match;
        if (match != null) {
            // Βάζουμε τον αγώνα στο combo
            matchCombo.setValue(match);
            // και φορτώνουμε αμέσως τους παίκτες αν έχει ήδη επιλεγεί πλευρά
            loadPlayersForSelection();
        }
    }

}
