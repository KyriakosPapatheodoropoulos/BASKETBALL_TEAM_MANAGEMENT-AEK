# BASKETBALL_TEAM_MANAGEMENT-AEK

A desktop basketball team management application developed in Java, designed to support the organization and administration of team-related data through a structured software architecture and a relational database backend.

## Overview

This project focuses on the management of basketball team information, combining a Java-based application layer with a database-driven design. It follows a modular structure with separate packages for controllers, data access logic, and domain models, while database initialization and advanced SQL objects are included in dedicated scripts.

The repository also contains SQL files for schema creation, sample data, views, triggers, procedures, and functions, making the project suitable for both application development and database coursework.

## Features

- Management of basketball team data through a Java application
- Layered structure using:
  - `controller`
  - `dao`
  - `model`
- Database connectivity through a dedicated `DBConnection` class
- SQL scripts for full database setup
- Support for:
  - table creation
  - test data insertion
  - views
  - triggers
  - stored procedures
  - SQL functions

## Project Structure

BASKETBALL_TEAM_MANAGEMENT-AEK/
├── db_init/
│   ├── tables.sql
│   ├── testData.sql
│   ├── view.sql
│   ├── triggers.sql
│   ├── procedures.sql
│   ├── functions.sql
│   └── sqlcode.sql
├── src/
│   └── main/
│       ├── java/
│       │   └── com/example/basketball_management_system/
│       │       ├── controller/
│       │       ├── dao/
│       │       ├── model/
│       │       ├── DBConnection.java
│       │       └── HelloApplication.java
│       └── resources/
├── .gitignore
└── README.md
Technologies Used
Java
JavaFX
JDBC
SQL / PLpgSQL
Relational Database Design
MVC-style package separation
Database Setup

The db_init folder contains all required SQL scripts for building and populating the database.

Recommended execution order:

tables.sql
testData.sql
view.sql
functions.sql
procedures.sql
triggers.sql

Note: Depending on your DBMS and dependencies between objects, the execution order may need slight adjustment.

How to Run

Clone the repository:

git clone https://github.com/KyriakosPapatheodoropoulos/BASKETBALL_TEAM_MANAGEMENT-AEK.git
Open the project in your Java IDE (such as IntelliJ IDEA).
Configure the database connection inside DBConnection.java with your local database credentials.
Execute the SQL scripts from the db_init directory to initialize the database.

Run the application starting from:

HelloApplication.java
Educational Purpose

This project was developed as part of academic coursework and demonstrates:

Java application development
database connectivity
SQL scripting and database programming
modular software organization
practical use of controllers, DAOs, and models in a structured application
Future Improvements
Add a richer graphical interface
Improve validation and exception handling
Add user authentication and role-based access
Extend player, team, match, and statistics management
Provide export/reporting functionality
Author

Kyriakos Papatheodoropoulos
