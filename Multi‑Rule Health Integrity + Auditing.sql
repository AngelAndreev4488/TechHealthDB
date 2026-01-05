USE TechHealthDb;
GO

/* 
===========================================================
TRIGGER CHALLENGE #5 — Multi‑Rule Health Integrity + Auditing
===========================================================

You must create TWO triggers on the HealthMetrics table and 
TWO audit tables. This challenge tests BEFORE logic, AFTER 
logic, inserted/deleted usage, rollback behavior, and 
multi‑table updates.

-----------------------------------------------------------
TABLES YOU MUST CREATE
-----------------------------------------------------------

1) HealthMetricViolations
   Columns:
     - violation_id (PK, identity)
     - user_id
     - attempted_stress_level
     - violation_time (GETDATE())
     - violation_type (varchar)

2) AchievementCorrections
   Columns:
     - correction_id (PK, identity)
     - user_id
     - old_value
     - attempted_value
     - correction_time (GETDATE())

-----------------------------------------------------------
TRIGGER #1 — BEFORE INSERT/UPDATE ON HealthMetrics
-----------------------------------------------------------

This trigger must enforce THREE rules:

RULE A — Sleep hours cannot exceed 12
    If avg_sleep_hours > 12:
        Automatically set avg_sleep_hours = 12

RULE B — Stress level must be between 0 and 10
    If attempted avg_stress_level < 0 OR > 10:
        - ROLLBACK the transaction
        - Insert a row into HealthMetricViolations:
            user_id
            attempted_stress_level
            violation_time = GETDATE()
            violation_type = 'Invalid Stress Level'

RULE C — achievement_rate cannot decrease
    If new.achievement_rate < old.achievement_rate:
        - Allow the update
        - BUT automatically restore the old value
        - Insert a row into AchievementCorrections:
            user_id
            old_value
            attempted_value
            correction_time = GETDATE()

-----------------------------------------------------------
TRIGGER #2 — AFTER UPDATE ON HealthMetrics
-----------------------------------------------------------

Whenever workout_frequency increases:
    - Update Devices table
    - For all devices belonging to that user:
        IF device_status = 'Active':
            active_hours_daily = active_hours_daily + 1

Condition:
    Only fire when inserted.workout_frequency > deleted.workout_frequency

-----------------------------------------------------------
FINAL TEST SCRIPT YOU MUST WRITE
-----------------------------------------------------------

1. Insert a valid HealthMetrics row
2. Attempt an invalid stress level (should rollback + log violation)
3. Attempt to decrease achievement_rate (should correct + log)
4. Increase workout_frequency (should update Devices)
5. SELECT from:
       HealthMetrics
       Devices
       HealthMetricViolations
       AchievementCorrections

===========================================================
END OF CHALLENGE
===========================================================
*/

CREATE TABLE HealthMetricViolations (
    violation_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id VARCHAR(10) NOT NULL,
    attempted_stress_level DECIMAL(4,2),
    violation_time DATETIME DEFAULT GETDATE(),
    violation_type VARCHAR(100) NOT NULL,

    CONSTRAINT FK_HealthMetricViolations_Customers
    FOREIGN KEY (user_id)
    REFERENCES Customers(user_id)
);
GO

CREATE TABLE AchievementCorrections (
    corection_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id VARCHAR(10) NOT NULL,
    old_value DECIMAL(4,2),
    attempted_value DECIMAL(4,2),
    corection_time DATETIME DEFAULT GETDATE(),
    

    CONSTRAINT FK_AchievementCorrections_Customers
    FOREIGN KEY (user_id)
    REFERENCES Customers(user_id)
);
GO


CREATE TRIGGER trg_HealthMetrics_Validation
ON HealthMetrics
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    /* ============================================
       1. BLOCK INVALID STRESS LEVEL (Rule B)
       ============================================ */
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE avg_stress_level < 0
           OR avg_stress_level > 10
    )
    BEGIN
        INSERT INTO HealthMetricViolations (
            user_id,
            attempted_stress_level,
            violation_time,
            violation_type
        )
        SELECT
            user_id,
            avg_stress_level,
            GETDATE(),
            'Invalid Stress Level'
        FROM inserted
        WHERE avg_stress_level < 0
           OR avg_stress_level > 10;

        -- Do NOT insert invalid rows into HealthMetrics
        RETURN;
    END;

    /* ============================================
       2 + 3. APPLY RULE A + RULE C INTO A TEMP TABLE
       ============================================ */
    ;WITH Cleaned AS (
        SELECT
            i.*,
            CASE 
                WHEN i.avg_sleep_hours > 12 THEN 12 
                ELSE i.avg_sleep_hours 
            END AS fixed_sleep
        FROM inserted i
    ),
    FinalData AS (
        SELECT
            c.user_id,
            c.record_id,
            c.date,
            c.avg_heart_rate,
            c.avg_resting_heart_rate,
            c.avg_daily_steps,
            c.fixed_sleep AS avg_sleep_hours,
            c.avg_deep_sleep_hours,
            c.avg_daily_calories,
            c.avg_exercise_minutes,
            c.avg_stress_level,
            c.avg_blood_oxygen,
            c.total_active_days,
            c.workout_frequency,

            CASE 
                WHEN d.achievement_rate IS NOT NULL 
                     AND c.achievement_rate < d.achievement_rate
                THEN d.achievement_rate
                ELSE c.achievement_rate
            END AS final_achievement_rate,

            d.achievement_rate AS old_rate,
            c.achievement_rate AS attempted_rate
        FROM Cleaned c
        LEFT JOIN HealthMetrics d 
            ON d.record_id = c.record_id
    )
    SELECT *
    INTO #FinalData
    FROM FinalData;

    /* ============================================
       4. LOG ACHIEVEMENT CORRECTIONS
       ============================================ */
    INSERT INTO dbo.AchievementCorrections (
        user_id,
        old_value,
        attempted_value,
        corection_time
    )
    SELECT
        user_id,
        old_rate,
        attempted_rate,
        GETDATE()
    FROM #FinalData
    WHERE old_rate IS NOT NULL
      AND attempted_rate < old_rate;

    /* ============================================
       5. PERFORM THE REAL INSERT/UPDATE
       ============================================ */
    MERGE HealthMetrics AS target
    USING #FinalData AS src
        ON target.record_id = src.record_id
    WHEN MATCHED THEN
        UPDATE SET
            user_id = src.user_id,
            date = src.date,
            avg_heart_rate = src.avg_heart_rate,
            avg_resting_heart_rate = src.avg_resting_heart_rate,
            avg_daily_steps = src.avg_daily_steps,
            avg_sleep_hours = src.avg_sleep_hours,
            avg_deep_sleep_hours = src.avg_deep_sleep_hours,
            avg_daily_calories = src.avg_daily_calories,
            avg_exercise_minutes = src.avg_exercise_minutes,
            avg_stress_level = src.avg_stress_level,
            avg_blood_oxygen = src.avg_blood_oxygen,
            total_active_days = src.total_active_days,
            workout_frequency = src.workout_frequency,
            achievement_rate = src.final_achievement_rate
    WHEN NOT MATCHED THEN
        INSERT (
            record_id, user_id, date, avg_heart_rate, avg_resting_heart_rate,
            avg_daily_steps, avg_sleep_hours, avg_deep_sleep_hours,
            avg_daily_calories, avg_exercise_minutes, avg_stress_level,
            avg_blood_oxygen, total_active_days, workout_frequency,
            achievement_rate
        )
        VALUES (
            src.record_id, src.user_id, src.date, src.avg_heart_rate,
            src.avg_resting_heart_rate, src.avg_daily_steps, src.avg_sleep_hours,
            src.avg_deep_sleep_hours, src.avg_daily_calories,
            src.avg_exercise_minutes, src.avg_stress_level,
            src.avg_blood_oxygen, src.total_active_days,
            src.workout_frequency, src.final_achievement_rate
        );
END;
GO



-- Recreate the foreign key without ON UPDATE CASCADE.
-- SQL Server does not allow INSTEAD OF UPDATE triggers on tables 
-- that have cascading UPDATE actions, so we remove the cascade 
-- to enable the validation trigger.
ALTER TABLE HealthMetrics
DROP CONSTRAINT FK_HealthMetrics_Customers;

ALTER TABLE HealthMetrics
ADD CONSTRAINT FK_HealthMetrics_Customers
FOREIGN KEY (user_id)
REFERENCES Customers(user_id);
GO


CREATE TRIGGER trg_UpdateDevices_OnWorkoutIncrease
ON HealthMetrics
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Update active devices only when workout_frequency increased
    UPDATE d
    SET d.active_hours_daily = d.active_hours_daily + 1
    FROM Devices d
    JOIN inserted i ON d.user_id = i.user_id
    JOIN deleted  de ON de.user_id = i.user_id
    WHERE i.workout_frequency > de.workout_frequency
      AND d.device_status = 'Active';
END;


-- TESTING THE SCRIPT
-- DROP CONSTRAINTS TO CHECK
ALTER TABLE HealthMetrics
DROP CONSTRAINT CK__HealthMet__avg_s__5AEE82B9;
ALTER TABLE HealthMetrics
DROP CONSTRAINT CK__HealthMet__achie__5EBF139D;


select top 3 * from HealthMetrics
ORDER BY record_id DESC;

-- Attempt an invalid stress level (should rollback + log violation)
UPDATE HealthMetrics
SET avg_stress_level = -13 
WHERE record_id = 'MHM053'

select * from HealthMetrics
WHERE record_id = 'MHM053';

SELECT * FROM HealthMetricViolations
WHERE user_id = 'TH053';


-- Attempt to decrease achievement_rate (should correct + log)
UPDATE HealthMetrics
SET achievement_rate = 0.08
WHERE record_id = 'MHM053'


-- CHECKING IS THE RESULT IN THE TABLE
SELECT * FROM AchievementCorrections

UPDATE HealthMetrics
SET workout_frequency = workout_frequency + 1
WHERE record_id = 'MHM053';

SELECT * FROM HealthMetrics
WHERE record_id = 'MHM053';

SELECT * FROM Devices
WHERE user_id = 'TH053';

SELECT * FROM HealthMetricViolations
WHERE user_id = 'TH053';

SELECT * FROM AchievementCorrections
WHERE user_id = 'TH053';