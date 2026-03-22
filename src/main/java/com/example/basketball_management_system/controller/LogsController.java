
package com.example.basketball_management_system.controller;

import com.example.basketball_management_system.dao.LogDAO;
import com.example.basketball_management_system.model.LogEntry;
import javafx.collections.FXCollections;
import javafx.fxml.FXML;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.stage.Stage;

public class LogsController {

    @FXML
    private TableView<LogEntry> logsTable;

    @FXML
    private TableColumn<LogEntry, Integer> idColumn;

    @FXML
    private TableColumn<LogEntry, String> tableNameColumn;

    @FXML
    private TableColumn<LogEntry, String> actionTypeColumn;

    @FXML
    private TableColumn<LogEntry, String> descriptionColumn;

    @FXML
    private TableColumn<LogEntry, String> createdAtColumn;

    @FXML
    public void initialize() {
        idColumn.setCellValueFactory(new PropertyValueFactory<>("id"));
        tableNameColumn.setCellValueFactory(new PropertyValueFactory<>("tableName"));
        actionTypeColumn.setCellValueFactory(new PropertyValueFactory<>("actionType"));
        descriptionColumn.setCellValueFactory(new PropertyValueFactory<>("description"));
        createdAtColumn.setCellValueFactory(new PropertyValueFactory<>("createdAt"));

        loadLogs();
    }

    @FXML
    private void onRefresh() {
        loadLogs();
    }

    @FXML
    private void onClose() {
        Stage stage = (Stage) logsTable.getScene().getWindow();
        stage.close();
    }

    private void loadLogs() {
        // Δημιουργούμε καινούριο ObservableList κάθε φορά και το δένουμε στο table
        logsTable.setItems(
                FXCollections.observableArrayList(LogDAO.getAllLogs())
        );
    }
}
