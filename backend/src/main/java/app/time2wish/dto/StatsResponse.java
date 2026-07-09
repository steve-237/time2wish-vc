package app.time2wish.dto;

import java.util.List;
import java.util.Map;

public class StatsResponse {
    private long totalUsers;
    private long totalBirthdays;
    private Map<String, Long> planDistribution;
    private Map<String, Long> monthlyRegistrations;
    private List<AdminUserDto> recentUsers;
    private double totalRevenue;
    
    public StatsResponse() {
    }

    public StatsResponse(long totalUsers, long totalBirthdays, 
                         Map<String, Long> planDistribution, 
                         Map<String, Long> monthlyRegistrations, 
                         List<AdminUserDto> recentUsers,
                         double totalRevenue) {
        this.totalUsers = totalUsers;
        this.totalBirthdays = totalBirthdays;
        this.planDistribution = planDistribution;
        this.monthlyRegistrations = monthlyRegistrations;
        this.recentUsers = recentUsers;
        this.totalRevenue = totalRevenue;
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

    public Map<String, Long> getPlanDistribution() {
        return planDistribution;
    }

    public void setPlanDistribution(Map<String, Long> planDistribution) {
        this.planDistribution = planDistribution;
    }

    public Map<String, Long> getMonthlyRegistrations() {
        return monthlyRegistrations;
    }

    public void setMonthlyRegistrations(Map<String, Long> monthlyRegistrations) {
        this.monthlyRegistrations = monthlyRegistrations;
    }

    public List<AdminUserDto> getRecentUsers() {
        return recentUsers;
    }

    public void setRecentUsers(List<AdminUserDto> recentUsers) {
        this.recentUsers = recentUsers;
    }

    public double getTotalRevenue() {
        return totalRevenue;
    }

    public void setTotalRevenue(double totalRevenue) {
        this.totalRevenue = totalRevenue;
    }
}
