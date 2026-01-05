USE TechHealthDb;
GO

/* ================================================================
    Transactional Workout & Device Update Procedure
   TRANSACTION‑BASED LOGIC — TECHHEALTHDB PROJECT
   ================================================================

   OBJECTIVE:
   Create a stored procedure that performs a multi‑step update 
   across HealthMetrics and Devices, wrapped in a transaction to 
   ensure atomicity and rollback on failure.

   ================================================================
   PROCEDURE REQUIREMENTS
   ================================================================

   1. NAME:
      The procedure must follow a clear naming convention:
      usp_UpdateWorkoutAndDeviceStatus

   2. INPUT PARAMETERS:
      @UserId             VARCHAR(10)   -- required
      @WorkoutIncrement   INT           -- required
      @NewDeviceStatus    VARCHAR(20)   -- optional (default = NULL)

   3. TRANSACTION LOGIC:
      The procedure must:
      - BEGIN a transaction
      - UPDATE workout_frequency in HealthMetrics for the given user
      - IF @NewDeviceStatus IS NOT NULL:
          * UPDATE device_status in Devices for the same user
      - COMMIT the transaction if all updates succeed
      - ROLLBACK the transaction if any error occurs

   4. ERROR HANDLING:
      - Use TRY/CATCH blocks to manage rollback
      - Log any failure into dbo.ErrorLog with:
          * user_id
          * error_message
          * error_time = GETDATE()

   5. VALIDATION RULES:
      - If @UserId does not exist in HealthMetrics, return a message
      - If @WorkoutIncrement < 0, return a message

   6. COMMENTS:
      The procedure must include clear comments explaining:
      - Transaction purpose
      - Error handling logic
      - Conditional update logic

   ================================================================
   WHAT THIS TASK TESTS (MID‑LEVEL SKILLS)
   ================================================================
   ✔ Ability to use transactions for atomic operations
   ✔ Ability to handle errors with TRY/CATCH
   ✔ Ability to conditionally update multiple tables
   ✔ Ability to log errors professionally
   ✔ Ability to write clean, readable, and safe SQL

   ================================================================
   END OF TASK DESCRIPTION
   ================================================================
*/


CREATE PROCEDURE usp_UpdateWorkoutAndDeviceStatus
    @UserId VARCHAR(10),
    @WorkoutIncrement INT,
    @NewDeviceStatus VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate user
    IF NOT EXISTS (
        SELECT 1
        FROM HealthMetrics
        WHERE user_id = @UserId
    )
    BEGIN 
        PRINT 'User does not exist in HealthMetrics table.';
        RETURN;
    END;

    -- Validate increment
    IF @WorkoutIncrement < 0
    BEGIN 
        PRINT 'You should increment with a positive number.';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Always update workout frequency
        UPDATE HealthMetrics
        SET workout_frequency = workout_frequency + @WorkoutIncrement
        WHERE user_id = @UserId;

        -- Conditionally update device status
        IF @NewDeviceStatus IS NOT NULL
        BEGIN
            UPDATE Devices
            SET device_status = @NewDeviceStatus
            WHERE user_id = @UserId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        INSERT INTO ErrorLog (
            error_message,
            error_date,
            user_id
        )
        VALUES (
            ERROR_MESSAGE(),
            GETDATE(),
            @UserId
        );

        THROW;
    END CATCH;
END;

-- testing the procedure
EXEC usp_UpdateWorkoutAndDeviceStatus
    @UserId = 'TH053',
    @WorkoutIncrement = 1;

-- checking if the user_id workouts increases
SELECT * FROM HealthMetrics
WHERE user_id = 'TH053'

-- setting to lower value because hits check constraint
UPDATE HealthMetrics
SET workout_frequency = 3
WHERE user_id = 'TH053'

-- triggering an error with negative workout increment
EXEC usp_UpdateWorkoutAndDeviceStatus
    @UserId = 'TH053',
    @WorkoutIncrement = -1

-- check the old device status
SELECT device_status
FROM Devices
WHERE user_id = 'TH040';

-- setting it to 'Inactive' 
UPDATE Devices
SET device_status = 'Inactive'
WHERE user_id = 'TH040'

-- updating the device status
EXEC usp_UpdateWorkoutAndDeviceStatus
    @UserId = 'TH040',
    @WorkoutIncrement = 1,
    @NewDeviceStatus = 'Active';

-- check the new device status
SELECT device_status
FROM Devices
WHERE user_id = 'TH040'



