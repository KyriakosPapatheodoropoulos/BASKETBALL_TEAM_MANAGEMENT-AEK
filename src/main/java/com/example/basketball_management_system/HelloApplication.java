/*package com.example.basketball_management_system;

import javafx.application.Application;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class HelloApplication extends Application {
    @Override
    public void start(Stage stage) throws Exception {
        FXMLLoader fxml = new FXMLLoader(getClass().getResource("/fxml/Players.fxml"));
        Scene scene = new Scene(fxml.load(), 900, 650);
        stage.setTitle("Basketball Management - Players");
        stage.setScene(scene);
        stage.show();
    }

    public static void main(String[] args) {
        launch();
    }
    @FXML
    private void onOpenMatches() {
        try {
            var loader = new javafx.fxml.FXMLLoader(getClass().getResource("/fxml/Matches.fxml"));
            var root = loader.load();
            var st = new javafx.stage.Stage();
            st.setTitle("Matches");
            st.setScene(new javafx.scene.Scene((Parent)root));
            st.show();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}*/
package com.example.basketball_management_system;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class HelloApplication extends Application {

    @Override
    public void start(Stage stage) throws Exception {
        FXMLLoader fxmlLoader = new FXMLLoader(
                getClass().getResource("/fxml/Welcome.fxml")
        );
        Scene scene = new Scene(fxmlLoader.load());
        stage.setTitle("Greek Elite League");
        stage.setScene(scene);
        stage.show();
    }

    public static void main(String[] args) {
        launch();
    }
}
