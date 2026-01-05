USE TechHealthDb;
GO

/* ================================================================
   STORED PROCEDURE REQUIREMENTS — TECHHEALTHDB PROJECT
   ================================================================

   OBJECTIVE:
   Create a stored procedure that retrieves filtered HealthMetrics 
   data for a specific user, with optional filtering parameters, 
   and returns a single, well‑structured result set that includes 
   relevant device information.

   ================================================================
   PROCEDURE REQUIREMENTS
   ================================================================

   1. NAME:
      The procedure must follow a clear naming convention:
      usp_GetUserHealthSummary

   2. INPUT PARAMETERS (minimum 2 required):
      @UserId            VARCHAR(10)   -- required
      @MinSteps          INT = NULL    -- optional
      @StartDate         DATE = NULL   -- optional
      @EndDate           DATE = NULL   -- optional

      Notes:
      - @UserId must always be provided.
      - Other parameters are optional and should filter only when not NULL.

   3. VALIDATION RULES:
      - If @UserId does not exist in Customers, return a message.
      - If @StartDate > @EndDate, return a message.
      - If @MinSteps < 0, default it to 0.

   4. QUERY LOGIC:
      The procedure must:
      - Select from HealthMetrics (main table)
      - JOIN Devices ON user_id
      - Apply filters based on provided parameters:
            * Filter by user_id (mandatory)
            * Filter by date range if both dates are provided
            * Filter by minimum steps if provided
      - Return a single result set only.

   5. OUTPUT REQUIREMENTS:
      The result set must include:
      - record_id
      - date
      - avg_daily_steps
      - avg_sleep_hours
      - avg_stress_level
      - achievement_rate
      - workout_frequency
      - device_type
      - device_status
      - active_hours_daily

   6. ORDERING:
      ORDER BY date DESC

   7. COMMENTS:
      The procedure must include clear comments explaining:
      - Parameter purpose
      - Validation logic
      - Filtering logic
      - JOIN purpose

   ================================================================
   WHAT THIS TASK TESTS (MID‑LEVEL SKILLS)
   ================================================================
   ✔ Ability to write stored procedures with parameters
   ✔ Ability to validate inputs
   ✔ Ability to JOIN multiple tables
   ✔ Ability to apply conditional filtering
   ✔ Ability to produce clean, readable SQL
   ✔ Ability to work with real‑world schema (TechHealthDb)

   ================================================================
   END OF TASK DESCRIPTION
   ================================================================
*/


CREATE PROCEDURE usp_GetUserHealthSummary
    @UserId VARCHAR(10),
    @MinSteps INT = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1
        FROM Customers
        WHERE user_id = @UserId
    )
    BEGIN 
        PRINT 'User does not exist in Customers table.';
        RETURN;
    END;
    IF @StartDate > @EndDate
        BEGIN
            PRINT 'Start date cannot be bigger than the end date.';
            RETURN;
        END;
    IF @MinSteps IS NULL OR @MinSteps < 0
        BEGIN
        SET @MinSteps = 0;
    END;
      SELECT hm.user_id, hm.record_id, hm.date, hm.avg_daily_steps, hm.avg_sleep_hours,
            hm.avg_stress_level, hm.achievement_rate, hm.workout_frequency,
            d.device_type, d.device_status, d.active_hours_daily
      FROM HealthMetrics hm
      JOIN Devices d ON d.user_id = hm.user_id
      WHERE hm.user_id = @UserId
          -- Optional date range filter (only applies if BOTH dates are provided)
          AND (
        @StartDate IS NULL 
        OR @EndDate IS NULL
        OR (hm.date >= @StartDate AND hm.date <= @EndDate))
          -- Optional minimum steps filter 
          AND hm.avg_daily_steps >= @MinSteps
          ORDER BY hm.date DESC;
END;

-- 🧪 TEST 1 — Only required parameter (returns ALL records for the user)
EXEC usp_GetUserHealthSummary 
    @UserId = 'TH040';

SELECT * FROM HealthMetrics
WHERE user_id = 'TH053'


