module com.example.basketball_management_system {
    // JavaFX modules
    requires javafx.controls;
    requires javafx.fxml;
    requires javafx.graphics;

    // JDBC / SQL
    requires java.sql;
    requires org.postgresql.jdbc;
    requires io.github.cdimascio.dotenv.java;


    // Επιτρέπει στο FXML να έχει πρόσβαση στους controllers
    opens com.example.basketball_management_system to javafx.fxml;
    opens com.example.basketball_management_system.model to javafx.base;
    // Εξάγει το package για χρήση από άλλα modules
    exports com.example.basketball_management_system;
    exports com.example.basketball_management_system.controller;
    opens com.example.basketball_management_system.controller to javafx.fxml;
}
