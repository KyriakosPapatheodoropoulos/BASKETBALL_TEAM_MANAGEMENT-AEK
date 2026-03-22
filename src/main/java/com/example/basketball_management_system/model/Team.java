package com.example.basketball_management_system.model;

public class Team {

    private int teamId;
    private String name;
    private String city;
    private String region;
    private int wins;
    private int losses;

    // === Main Constructor ===
    public Team(int teamId, String name, String city, String region, int wins, int losses) {
        this.teamId = teamId;
        this.name = name;
        this.city = city;
        this.region = region;
        this.wins = wins;
        this.losses = losses;
    }

    // Optional constructor (αν κάπου θες χωρίς city)
    public Team(int teamId, String name, String region, int wins, int losses) {
        this(teamId, name, null, region, wins, losses);
    }

    // Getters
    public int getTeamId()        { return teamId; }
    public String getName()       { return name; }
    public String getCity()       { return city; }
    public String getRegion()     { return region; }
    public int getWins()          { return wins; }
    public int getLosses()        { return losses; }

    // Setters (αν τα χρειάζεσαι)
    public void setWins(int wins)         { this.wins = wins; }
    public void setLosses(int losses)     { this.losses = losses; }

    @Override
    public String toString() {
        return name + " (" + region + ")";
    }
}
