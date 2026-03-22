package com.example.basketball_management_system.model;

import java.time.LocalDate;

public class Match {
    private int matchId;
    private LocalDate date;
    private int homeTeamId;
    private int awayTeamId;
    private int scoreHome;
    private int scoreAway;

    public Match() {}

    public Match(int matchId, LocalDate date, int homeTeamId, int awayTeamId,
                 int scoreHome, int scoreAway) {
        this.matchId = matchId;
        this.date = date;
        this.homeTeamId = homeTeamId;
        this.awayTeamId = awayTeamId;
        this.scoreHome = scoreHome;
        this.scoreAway = scoreAway;
    }

    // Getters & Setters
    public int getMatchId() { return matchId; }
    public void setMatchId(int matchId) { this.matchId = matchId; }

    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }

    public int getHomeTeamId() { return homeTeamId; }
    public void setHomeTeamId(int homeTeamId) { this.homeTeamId = homeTeamId; }

    public int getAwayTeamId() { return awayTeamId; }
    public void setAwayTeamId(int awayTeamId) { this.awayTeamId = awayTeamId; }

    public int getScoreHome() { return scoreHome; }
    public void setScoreHome(int scoreHome) { this.scoreHome = scoreHome; }

    public int getScoreAway() { return scoreAway; }
    public void setScoreAway(int scoreAway) { this.scoreAway = scoreAway; }

    @Override
    public String toString() {
        return "Match #" + matchId + " " + homeTeamId + " vs " + awayTeamId +
                " (" + scoreHome + "-" + scoreAway + ")";
    }
}
