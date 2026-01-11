USE TechHealthDb;
GO


/* =====================================================================
   MID‑LEVEL SQL TASK
   FUNCTIONS + CORRELATED CTE + BUSINESS LOGIC ANALYTICS
   =====================================================================

   SCENARIO:
   The TechHealthDb team wants to analyze user performance trends and 
   generate a "Health Score" for each user based on their metrics.

   You must build:
   1. A scalar function
   2. A table-valued function
   3. A correlated CTE query that uses both functions

   =====================================================================
   PART 1 — SCALAR FUNCTION
   =====================================================================
   Create a scalar function: dbo.fn_CalcHealthScore
   Input:
       - avg_daily_steps INT
       - avg_sleep_hours DECIMAL(4,2)
       - avg_heart_rate INT

   Output:
       - INT score between 0 and 100

   Logic (example, but you may adjust):
       score =
           (avg_daily_steps / 200) +
           (avg_sleep_hours * 5) -
           (avg_heart_rate / 3)

       If score < 0 → return 0
       If score > 100 → return 100

   =====================================================================
   PART 2 — INLINE TABLE-VALUED FUNCTION
   =====================================================================
   Create a function: dbo.fn_UserDailyTrend(@UserId VARCHAR(10))

   It must return:
       - date
       - avg_daily_steps
       - avg_sleep_hours
       - avg_heart_rate
       - PrevDaySteps (using LAG)
       - StepDifference (avg_daily_steps - PrevDaySteps)
       - HealthScore (using fn_CalcHealthScore)

   Requirements:
       - Use a window function inside the TVF
       - Order by date
       - No multi-statement TVF (must be inline)

   =====================================================================
   PART 3 — CORRELATED CTE QUERY
   =====================================================================
   Write a SELECT that:
       - Returns all users from HealthMetrics
       - Uses a correlated CTE to compute:
            * Average StepDifference per user
            * Max HealthScore per user
            * 7-day rolling average of steps
       - Calls fn_UserDailyTrend inside the CTE
       - Calls fn_CalcHealthScore again in the outer query

   Requirements:
       - The CTE must reference the outer query's user_id 
         (this makes it correlated)
       - Use at least one window frame:
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW

   Output columns:
       - user_id
       - LatestHealthScore
       - AvgStepDifference
       - MaxHealthScore
       - SevenDayRollingSteps
       - TotalRecordsForUser (COUNT(*) OVER(PARTITION BY user_id))

   =====================================================================
   PART 4 — ORDERING
   =====================================================================
   Order the final result by:
       LatestHealthScore DESC

   =====================================================================
   WHAT THIS TASK TESTS
   =====================================================================
   ✔ Ability to design scalar and table-valued functions
   ✔ Ability to use window functions inside a TVF
   ✔ Ability to write correlated CTEs
   ✔ Ability to combine functions + analytics in one query
   ✔ Ability to structure multi-step logic cleanly
   ✔ Ability to think like a mid-level SQL developer

   =====================================================================
   END OF TASK
   ===================================================================== */


-- Creating fn_CalcHealthScore which calculates HealthScore for each user
CREATE FUNCTION fn_CalcHealthScore
(
    @avg_daily_steps INT,
    @avg_sleep_hours DECIMAL(4,2),
    @avg_heart_rate INT
)
RETURNS INT
AS
BEGIN
    DECLARE @HealthScore INT;

    SET @HealthScore =
          (@avg_daily_steps / 200)
        + (@avg_sleep_hours * 5)
        - (@avg_heart_rate / 3);

    IF @HealthScore < 0
        SET @HealthScore = 0;

    IF @HealthScore > 100
        SET @HealthScore = 100;

    RETURN @HealthScore;
END;
GO


-- Creating UserDailyTrend that returns table with information about a
-- user_id input including two calculated columns StepDifference and PrevDaySteps
CREATE FUNCTION dbo.UserDailyTrend
(
    @UserId VARCHAR(10)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        hm.[date],
        hm.avg_daily_steps,
        hm.avg_sleep_hours,
        hm.avg_heart_rate,

        LAG(hm.avg_daily_steps, 1, hm.avg_daily_steps)
            OVER (PARTITION BY hm.user_id ORDER BY hm.[date]) AS PrevDaySteps,

        hm.avg_daily_steps
        - LAG(hm.avg_daily_steps, 1, hm.avg_daily_steps)
            OVER (PARTITION BY hm.user_id ORDER BY hm.[date]) AS StepDifference,

        dbo.fn_CalcHealthScore(
            hm.avg_daily_steps,
            hm.avg_sleep_hours,
            hm.avg_heart_rate
        ) AS HealthScore

    FROM HealthMetrics hm
    WHERE hm.user_id = @UserId
);
GO


-- Final analytics query returning all the needed information including:
-- * Average StepDifference per user
-- * Max HealthScore per user
-- * 7-day rolling average of steps
;WITH cte AS
(
    SELECT
        u.user_id,
        t.[date],
        t.avg_daily_steps,
        t.StepDifference,
        t.HealthScore,

        AVG(t.StepDifference) OVER (PARTITION BY u.user_id) AS AvgStepDifference,
        MAX(t.HealthScore) OVER (PARTITION BY u.user_id) AS MaxHealthScore,
        AVG(t.avg_daily_steps) OVER (
            PARTITION BY u.user_id
            ORDER BY t.[date]
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS SevenDayRollingSteps,
        FIRST_VALUE(t.HealthScore) OVER (
            PARTITION BY u.user_id
            ORDER BY t.[date] DESC
        ) AS LatestHealthScore
    FROM HealthMetrics u
    CROSS APPLY dbo.UserDailyTrend(u.user_id) t
)

SELECT
    user_id,
    LatestHealthScore,
    AvgStepDifference,
    MaxHealthScore,
    SevenDayRollingSteps,
    COUNT(*) OVER (PARTITION BY user_id) AS TotalRecordsForUser
FROM cte
ORDER BY LatestHealthScore DESC;

