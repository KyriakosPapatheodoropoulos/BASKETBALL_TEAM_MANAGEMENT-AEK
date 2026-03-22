package com.example.basketball_management_system.model;

import java.time.LocalDateTime;

public class LogEntry {
    private final int id;
    private final String tableName;
    private final String actionType;
    private final String description;
    private final String createdAt;

    public LogEntry(int id, String tableName, String actionType, String description, String createdAt) {
        this.id = id;
        this.tableName = tableName;
        this.actionType = actionType;
        this.description = description;
        this.createdAt = createdAt;
    }

    public int getId() {
        return id;
    }

    public String getTableName() {
        return tableName;
    }

    public String getActionType() {
        return actionType;
    }

    public String getDescription() {
        return description;
    }

    public String getCreatedAt() {
        return createdAt;
    }
}
