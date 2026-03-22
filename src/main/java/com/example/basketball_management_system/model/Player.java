package com.example.basketball_management_system.model;

public class Player {
    private int playerId;
    private String name;
    private int age;
    private String position;
    private int teamId;
    private int totalPoints;
    private int totalAssists;
    private int totalRebounds;

    public Player() {}

    public Player(int playerId, String name, int age, String position, int teamId,
                  int totalPoints, int totalAssists, int totalRebounds) {
        this.playerId = playerId;
        this.name = name;
        this.age = age;
        this.position = position;
        this.teamId = teamId;
        this.totalPoints = totalPoints;
        this.totalAssists = totalAssists;
        this.totalRebounds = totalRebounds;
    }

    // Getters & Setters
    public int getPlayerId() { return playerId; }
    public void setPlayerId(int playerId) { this.playerId = playerId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public int getAge() { return age; }
    public void setAge(int age) { this.age = age; }

    public String getPosition() { return position; }
    public void setPosition(String position) { this.position = position; }

    public int getTeamId() { return teamId; }
    public void setTeamId(int teamId) { this.teamId = teamId; }

    public int getTotalPoints() { return totalPoints; }
    public void setTotalPoints(int totalPoints) { this.totalPoints = totalPoints; }

    public int getTotalAssists() { return totalAssists; }
    public void setTotalAssists(int totalAssists) { this.totalAssists = totalAssists; }

    public int getTotalRebounds() { return totalRebounds; }
    public void setTotalRebounds(int totalRebounds) { this.totalRebounds = totalRebounds; }

    @Override
    public String toString() {
        return name + " (" + position + ")";
    }
}
