package app.time2wish.dto;

public class StatsResponse {
    private long totalUsers;
    private long totalBirthdays;
    
    public StatsResponse() {
    }

    public StatsResponse(long totalUsers, long totalBirthdays) {
        this.totalUsers = totalUsers;
        this.totalBirthdays = totalBirthdays;
    }

    public long getTotalUsers() {
        return totalUsers;
    }

    public void setTotalUsers(long totalUsers) {
        this.totalUsers = totalUsers;
    }

    public long getTotalBirthdays() {
        return totalBirthdays;
    }

    public void setTotalBirthdays(long totalBirthdays) {
        this.totalBirthdays = totalBirthdays;
    }
}
