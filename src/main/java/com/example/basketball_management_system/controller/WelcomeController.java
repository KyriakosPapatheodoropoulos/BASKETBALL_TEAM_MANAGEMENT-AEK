package com.example.basketball_management_system.controller;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.layout.StackPane;
import javafx.stage.Stage;
import javafx.scene.Scene;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;

public class WelcomeController {

    @FXML private StackPane root;
    @FXML private Label titleLabel;
    @FXML private Label subtitleLabel;

    @FXML
    public void initialize() {
        // Ό,τι έξτρα styling θες εδώ
    }

    private void openWindow(String path, String title) throws Exception {
        FXMLLoader loader = new FXMLLoader(getClass().getResource(path));
        Parent root = loader.load();
        Stage stage = new Stage();
        stage.setTitle(title);
        stage.setScene(new Scene(root));
        stage.show();
    }

    @FXML
    private void onOpenPlayers() throws Exception {
        openWindow("/fxml/Players.fxml", "Players");
    }

    @FXML
    private void onOpenMatches() throws Exception {
        openWindow("/fxml/Matches.fxml", "Matches");
    }

    @FXML
    private void onOpenStandings() throws Exception {
        openWindow("/fxml/Standings.fxml", "Standings");
    }

    @FXML
    private void onExit() {
        Stage stage = (Stage) root.getScene().getWindow();
        stage.close();
    }
}
