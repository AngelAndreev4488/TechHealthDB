USE TechHealthDb;
GO

/* =====================================================================
   MID‑LEVEL SQL DEVELOPER TASK
   ADVANCED WINDOW FUNCTION ANALYTICS — TECHHEALTHDB PROJECT
   =====================================================================

   OBJECTIVE:
   Create a SELECT query (or a view) that analyzes user health metrics 
   using a wide range of T‑SQL window functions, including:
   - Aggregate window functions
   - Ranking functions
   - Row navigation functions
   - Frame-based calculations

   =====================================================================
   REQUIREMENTS
   =====================================================================

   1. SOURCE TABLE:
      Use dbo.HealthMetrics as the primary dataset.

   2. PARTITIONING:
      All window functions must partition BY user_id.

   3. AGGREGATE WINDOW FUNCTIONS:
      Include the following (each using OVER(PARTITION BY user_id)):
      - SUM(avg_daily_steps)          AS TotalStepsPerUser
      - AVG(avg_sleep_hours)          AS AvgSleepPerUser
      - MIN(avg_heart_rate)           AS MinHeartRatePerUser
      - MAX(avg_heart_rate)           AS MaxHeartRatePerUser
      - COUNT(*)                      AS TotalRecordsPerUser
      - STDEV(avg_daily_calories)     AS CalorieStdDevPerUser
      - VAR(avg_daily_calories)       AS CalorieVariancePerUser

   4. RANKING & ROW FUNCTIONS:
      Include at least:
      - ROW_NUMBER() OVER(...)        AS RowNumByDate
      - RANK() OVER(...)              AS StepRankByDate
      - DENSE_RANK() OVER(...)        AS SleepRankByDate
      - NTILE(4) OVER(...)            AS QuartileBySteps

   5. VALUE NAVIGATION FUNCTIONS:
      Include:
      - LAG(avg_daily_steps, 1) OVER(...)   AS PrevDaySteps
      - LEAD(avg_daily_steps, 1) OVER(...)  AS NextDaySteps
      - FIRST_VALUE(avg_sleep_hours) OVER(...) AS FirstSleepRecord
      - LAST_VALUE(avg_sleep_hours) OVER(
            PARTITION BY user_id 
            ORDER BY date 
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS LastSleepRecord

   6. FRAME CLAUSE REQUIREMENT:
      At least one calculation must use a custom window frame, e.g.:
      - SUM(avg_daily_steps) OVER(
            PARTITION BY user_id 
            ORDER BY date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS SevenDayRollingSteps

   7. OUTPUT:
      The final query must return:
      - user_id
      - date
      - all window function columns listed above

   8. ORDERING:
      Final result must be ordered by:
      user_id, date ASC

   =====================================================================
   WHAT THIS TASK TESTS (MID‑LEVEL SKILLS)
   =====================================================================
   ✔ Ability to use aggregate window functions
   ✔ Ability to use ranking and row-numbering functions
   ✔ Ability to use LAG/LEAD and FIRST_VALUE/LAST_VALUE
   ✔ Ability to define custom window frames
   ✔ Ability to combine multiple analytic functions in one query
   ✔ Ability to produce clean, readable, well-structured SQL

   =====================================================================
   END OF TASK DESCRIPTION
   ===================================================================== */



SELECT user_id, 
    SUM(avg_daily_steps) OVER(PARTITION BY user_id) AS TotalStepsPerUser,
    AVG(avg_sleep_hours) OVER(PARTITION BY user_id) AS AvgSleepPerUser,
    MIN(avg_heart_rate) OVER(PARTITION BY user_id) AS MinHeartRatePerUser,
    MAX(avg_heart_rate) OVER(PARTITION BY user_id) AS MaxHeartRatePerUser,
    COUNT(*) OVER(PARTITION BY user_id) AS TotalRecordsPerUser,
    CAST(STDEV(avg_daily_calories) OVER(PARTITION BY user_id) AS NUMERIC(10,2 )) AS CalorieStdDevPerUser,
    CAST(VAR(avg_daily_calories) OVER(PARTITION BY user_id) AS NUMERIC(10, 2)) AS CalorieVariancePerUser,
    ROW_NUMBER() OVER(PARTITION BY date ORDER BY user_id) AS RowNumByDate,
    workout_frequency,
    RANK() OVER(PARTITION BY workout_frequency ORDER BY user_id) AS RowNumByWorkoutFrequency,
    avg_sleep_hours,
    DENSE_RANK() OVER(PARTITION BY avg_sleep_hours ORDER BY user_id) AS SleepRankByDate,
    avg_daily_steps,
    NTILE(4) OVER(PARTITION BY avg_daily_steps ORDER BY user_id) AS QuartileBySteps
FROM HealthMetrics;


SELECT user_id, [date],
    LAG(avg_daily_steps, 1, 0) OVER(PARTITION BY user_id ORDER BY [date]) AS PrevDaySteps,
    FIRST_VALUE(avg_sleep_hours) OVER(PARTITION BY user_id ORDER BY [date]) AS FirstSleepRecord,
    LAST_VALUE(avg_sleep_hours) OVER(
            PARTITION BY user_id 
            ORDER BY [date] 
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS LastSleepRecord,
    CAST(SUM(avg_daily_steps) OVER(PARTITION BY user_id 
        ORDER BY [date]
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) 
            AS NUMERIC(10,2)) AS SevenDayRollingSteps
FROM HealthMetrics
ORDER BY user_id;


