USE TechHealthDb;
GO

/* 
STRING FUNCTION EXERCISE #3 — View-Based Health Insights

Scenario:
Your TechHealthDb tracks both customer health metrics and device usage. Management wants to build a dashboard that shows how device behavior correlates with health outcomes — but they want the logic split into reusable views for modularity and performance.

Task:
Create two SQL views:

1. View #1 — [ActiveDeviceStats]
    - Based on the Devices table
    - For each user, calculate:
        a. Total number of devices
        b. Average battery life
        c. Average daily active hours
    - Only include devices where device_status = 'Active'

2. View #2 — [HighStressUsers]
    - Based on the HealthMetrics table
    - Return users where:
        a. avg_stress_level > 2.5
        b. avg_sleep_hours < 8
        c. workout_frequency > 3

Final Query:
Write a SELECT that joins these two views on user_id and returns:

    - user_id
    - total_active_devices
    - avg_battery_life
    - avg_active_hours
    - avg_stress_level
    - avg_sleep_hours
    - workout_frequency

Additional Rules:
- You must use **two separate views**
- You must join them in a final SELECT
- You may use built-in numeric functions (AVG, COUNT, etc.)
- Do not use subqueries inside the final SELECT
- Do not use CTEs — only views and joins
*/

CREATE VIEW ActiveDeviceStats AS 
SELECT user_id, COUNT(device_id) AS number_of_devices,
    CAST(ROUND(AVG(battery_life_days), 2) AS DECIMAL(10,2)) AS 
        average_battery_life, 
    CAST(ROUND(AVG(active_hours_daily), 2) AS DECIMAL(10,2))
        AS average_daily_active_hours
FROM Devices
WHERE device_status = 'Active'
GROUP BY user_id;
GO

CREATE VIEW HighStressUsers AS 
SELECT user_id, avg_stress_level, avg_sleep_hours, workout_frequency 
FROM HealthMetrics
WHERE avg_stress_level > 1.5
AND avg_sleep_hours < 8
AND workout_frequency > 3;
GO

SELECT ads.user_id, 
    ads.number_of_devices,
    ads.average_battery_life, ads.average_daily_active_hours, hsu.avg_stress_level,
    hsu.avg_sleep_hours, hsu.workout_frequency
FROM ActiveDeviceStats ads
JOIN HighStressUsers hsu ON hsu.user_id = ads.user_id;
GO

