package com.example.basketball_management_system.controller;

import com.example.basketball_management_system.dao.TeamStandingsDAO;
import com.example.basketball_management_system.model.Team;
import javafx.beans.property.SimpleDoubleProperty;
import javafx.beans.property.SimpleIntegerProperty;
import javafx.beans.property.SimpleStringProperty;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.stage.Stage;

import java.util.List;

public class StandingsController {

    @FXML private TableView<Team> table;
    @FXML private TableColumn<Team, String>  colRegion;
    @FXML private TableColumn<Team, String>  colTeam;
    @FXML private TableColumn<Team, Number>  colWins;
    @FXML private TableColumn<Team, Number>  colLosses;
    @FXML private TableColumn<Team, Number>  colWinPct;

    private final ObservableList<Team> data = FXCollections.observableArrayList();

    @FXML
    public void initialize() {
        colRegion.setCellValueFactory(c -> new SimpleStringProperty(c.getValue().getRegion()));
        colTeam.setCellValueFactory(c -> new SimpleStringProperty(c.getValue().getName()));
        colWins.setCellValueFactory(c -> new SimpleIntegerProperty(c.getValue().getWins()));
        colLosses.setCellValueFactory(c -> new SimpleIntegerProperty(c.getValue().getLosses()));

        colWinPct.setCellValueFactory(c -> {
            int w = c.getValue().getWins();
            int l = c.getValue().getLosses();
            int games = w + l;
            double pct = (games == 0) ? 0.0 : (w * 100.0 / games);
            return new SimpleDoubleProperty(Math.round(pct * 10.0) / 10.0); // ένα δεκαδικό
        });

        table.setItems(data);
        loadStandings();
    }

    private void loadStandings() {
        List<Team> teams = TeamStandingsDAO.getStandings();
        data.setAll(teams);
    }

    @FXML
    private void onRefresh() {
        loadStandings();
    }

    @FXML
    private void onClose() {
        Stage st = (Stage) table.getScene().getWindow();
        st.close();
    }
}
