USE TechHealthDb;
GO

/* 
STRING FUNCTION EXERCISE #2 — Advanced Numeric Analysis

Scenario:
Your HealthMetrics table tracks daily averages for each user. 
Management wants to identify users who show signs of high physical activity but also elevated stress levels
— a pattern that may indicate overtraining.

Task:
Write a T‑SQL query that returns a list of users meeting all of the following numeric conditions:

1. Their avg_daily_steps is above the overall average across all users
2. Their avg_exercise_minutes is in the top 25% of all users
3. Their avg_stress_level is above 7.0
4. Their avg_sleep_hours is below the overall average
5. Their workout_frequency is greater than 4
6. Their achievement_rate is between 80 and 100 (inclusive)

Output columns:
    user_id
    avg_daily_steps
    avg_exercise_minutes
    avg_stress_level
    avg_sleep_hours
    workout_frequency
    achievement_rate

Additional rules:
- Use built-in numeric functions only (e.g., AVG(), PERCENTILE_CONT, ROUND(), CEILING(), FLOOR(), etc.)
- Do not use subqueries in the SELECT clause
- You may use subqueries in the WHERE clause if needed
*/

WITH UserPercentile AS (
    SELECT 
    user_id,
    avg_daily_steps,
    avg_exercise_minutes,
    avg_stress_level,
    avg_sleep_hours,
    workout_frequency,
    achievement_rate,
    PERCENTILE_CONT(0.75)
        WITHIN GROUP(ORDER BY avg_exercise_minutes)
        OVER() AS p75
    FROM HealthMetrics
)

SELECT user_id, avg_daily_steps, avg_exercise_minutes, avg_stress_level, 
avg_sleep_hours, workout_frequency, achievement_rate
FROM UserPercentile
WHERE avg_daily_steps > (SELECT AVG(avg_daily_steps) FROM HealthMetrics)
AND avg_exercise_minutes >= p75 
AND avg_stress_level > 7.0
AND avg_sleep_hours < (SELECT AVG(avg_sleep_hours) FROM HealthMetrics)
AND workout_frequency > 4
AND achievement_rate BETWEEN 80 AND 100;




SELECT * FROM HealthMetrics
