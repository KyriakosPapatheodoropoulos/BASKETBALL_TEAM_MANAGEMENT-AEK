package com.example.basketball_management_system.model;

public class Statistics {
    private int statId;
    private int matchId;
    private int playerId;
    private int points;
    private int assists;
    private int rebounds;

    public Statistics() {}

    public Statistics(int statId, int matchId, int playerId, int points, int assists, int rebounds) {
        this.statId = statId;
        this.matchId = matchId;
        this.playerId = playerId;
        this.points = points;
        this.assists = assists;
        this.rebounds = rebounds;
    }

    // Getters & Setters
    public int getStatId() { return statId; }
    public void setStatId(int statId) { this.statId = statId; }

    public int getMatchId() { return matchId; }
    public void setMatchId(int matchId) { this.matchId = matchId; }

    public int getPlayerId() { return playerId; }
    public void setPlayerId(int playerId) { this.playerId = playerId; }

    public int getPoints() { return points; }
    public void setPoints(int points) { this.points = points; }

    public int getAssists() { return assists; }
    public void setAssists(int assists) { this.assists = assists; }

    public int getRebounds() { return rebounds; }
    public void setRebounds(int rebounds) { this.rebounds = rebounds; }
}
