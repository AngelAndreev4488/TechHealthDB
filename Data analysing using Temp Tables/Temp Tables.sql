USE TechHealthDb;
GO

-- Task: Perform a multi-step customer engagement analysis using temporary tables, 
-- including data cleaning, enrichment, aggregation, and final reporting.


-- Created TABLE DeviceSessions needed for the analysis and generated it with bulk 
-- random generated data from Copilot for the last 60 days before date 20.12.2025.
CREATE TABLE DeviceSessions (
    session_id INT IDENTITY(1,1) PRIMARY KEY,
    device_id VARCHAR(10) NOT NULL,
    user_id VARCHAR(10) NOT NULL,
    session_start DATETIME NOT NULL,
    session_end DATETIME NOT NULL
);

-- Adding Foreign key constraint
ALTER TABLE DeviceSessions
ADD CONSTRAINT FK_DeviceSessions_Devices
FOREIGN KEY (device_id)
REFERENCES Devices(device_id) 

-- link it with the Customers table since each device belongs to a user
ALTER TABLE DeviceSessions
ADD CONSTRAINT FK_DeviceSessions_Customers
FOREIGN KEY (user_id)
REFERENCES Customers(user_id);


CREATE TABLE #ActiveSessions (
    session_id INT IDENTITY(1,1) PRIMARY KEY,
    device_id VARCHAR(10) NOT NULL,
    user_id VARCHAR(10) NOT NULL,
    session_start DATETIME NOT NULL,
    session_end   DATETIME NOT NULL,
    session_duration AS DATEDIFF(MINUTE, session_start, session_end)
);


-- populate the temp table #ActiveSessions with data from the last 30 days
INSERT INTO #ActiveSessions
SELECT device_id, user_id, session_start, session_end
FROM DeviceSessions
WHERE session_start >= DATEADD(DAY, -30, GETDATE());


-- Creating temp table #CleanCustomers
CREATE TABLE #CleanCustomers (
    user_id VARCHAR(10) NOT NULL,
    age INT NOT NULL,
    gender CHAR(1) NOT NULL,
    occupation VARCHAR(100) NULL,
    income_bracket VARCHAR(20) NULL,
    registration_date DATE NOT NULL,
    subscription_type VARCHAR(50) NOT NULL,
    location_id INT NULL,

    CONSTRAINT CK_CleanCustomers_Age
        CHECK (age BETWEEN 0 AND 120),

    CONSTRAINT CK_CleanCustomers_Gender
        CHECK (gender IN ('M', 'F')),
);
ALTER TABLE #CleanCustomers
ADD CONSTRAINT PK_CleanCustomers
PRIMARY KEY (user_id);


-- Inserting data from Customers to #CleanCustomers after
-- Copilot created 50 rows with sample data for Customers
-- containing NULL's for the occupation, income_bracket and location_id
-- perfect for testing the COALESCE logic when filtering the data.

INSERT INTO #CleanCustomers
SELECT user_id,
    age,
    gender,
    UPPER(COALESCE(occupation, 'UNKNOWN')),
    UPPER(COALESCE(income_bracket, 'UNKNOWN')),
    registration_date,
    UPPER(subscription_type),
    COALESCE(location_id, -1)
FROM Customers;


-- Creating temp table #CleanDevices
-- Add computed columns device_age_days, days_since_last_sync

CREATE TABLE #CleanDevices (
    device_id VARCHAR(10) NOT NULL,
    user_id VARCHAR(10) NOT NULL,
    device_type VARCHAR(100) NOT NULL,
    purchase_date DATE NOT NULL,
    last_sync_date DATE NOT NULL,
    firmware_version VARCHAR(10) NOT NULL,
    battery_life_days DECIMAL(3,1) NOT NULL,
    sync_frequency_daily INT NOT NULL,
    active_hours_daily DECIMAL(3,1) NOT NULL,
    total_steps_recorded BIGINT NOT NULL,
    total_workouts_recorded INT NOT NULL,
    sleep_tracking_enabled BIT NOT NULL,
    heart_rate_monitoring_enabled BIT NOT NULL,
    gps_enabled BIT NOT NULL,
    notification_enabled BIT NOT NULL,
    device_status VARCHAR(50) NOT NULL,
    device_age_days AS DATEDIFF(DAY, purchase_date, CAST(GETDATE() AS DATE)),
    days_since_last_sync AS DATEDIFF(DAY, last_sync_date, CAST(GETDATE() AS DATE))


    CONSTRAINT PK_CleanDevices
        PRIMARY KEY (device_id)
);

-- Inserting data from Devices to #CleanDevices after
-- Copilot created 25 rows with sample data for Devices
INSERT INTO #CleanDevices
SELECT * FROM Devices;


-- create temp table #JoinedData
CREATE TABLE #JoinedData (
    user_id VARCHAR(10) NOT NULL,
    device_id VARCHAR(10) NOT NULL,
    device_type VARCHAR(100),
    session_start DATETIME,
    session_end DATETIME,
    session_duration INT,
    device_status VARCHAR(50),
    age INT,
    gender CHAR(1),
    occupation VARCHAR(30),
    income_bracket VARCHAR(20),
    subscription_type VARCHAR(20),
    location_id INT,
    device_age_days INT
)

-- Inserting the data in #JoinedData
INSERT INTO #JoinedData
SELECT cc.user_id, cdev.device_id, cdev.device_type, acss.session_start, acss.session_end, acss.session_duration,
    cdev.device_status, cc.age, cc.gender, cc.occupation, cc.income_bracket, cc.subscription_type, 
    cc.location_id, cdev.device_age_days
FROM #CleanCustomers cc
LEFT JOIN #ActiveSessions acss ON acss.user_id = cc.user_id
JOIN #CleanDevices cdev ON cdev.device_id = acss.device_id;

-- adding analytical columns to #JoinedData
ALTER TABLE #JoinedData
ADD session_hour INT,
    session_day VARCHAR(20),
    is_weekend BIT,
    activity_level VARCHAR(20);

UPDATE #JoinedData
SET 
    session_hour = DATEPART(HOUR, session_start),
    session_day = DATENAME(WEEKDAY, session_start),
    is_weekend = CASE 
                    WHEN DATENAME(WEEKDAY, session_start) IN ('Saturday', 'Sunday') 
                    THEN 1 
                    ELSE 0 
                 END,
    activity_level = CASE
                        WHEN session_duration < 30 THEN 'LOW'
                        WHEN session_duration BETWEEN 30 AND 90 THEN 'MEDIUM'
                        WHEN session_duration > 90 THEN 'HIGH'
                     END;

select * from #JoinedData

-- creating the last unified temp table #UserDeviceActivity
CREATE TABLE #UserDeviceActivity (
    user_id VARCHAR(10) NOT NULL,
    device_id VARCHAR(10) NOT NULL,
    device_type VARCHAR(100),
    session_start DATETIME,
    session_end DATETIME,
    session_duration INT,
    device_status VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    device_age_days INT,
    session_hour INT,
    session_day VARCHAR(20),
    is_weekend BIT,
    activity_level VARCHAR(20),  

    CONSTRAINT PK_UserDeviceActivity
    PRIMARY KEY (user_id, device_id, session_start),

    CHECK (session_duration > 0),
    CHECK (device_age_days >= 0)

);

-- adding the data in the #UserDeviceActivity
INSERT INTO #UserDeviceActivity
SELECT 
    jd.user_id,
    jd.device_id,
    jd.device_type,
    jd.session_start,
    jd.session_end,
    jd.session_duration,
    jd.device_status,
    geo.country,
    geo.city,
    jd.device_age_days,
    jd.session_hour,
    jd.session_day,
    jd.is_weekend,
    jd.activity_level
FROM #JoinedData jd
JOIN GeoLocation geo 
    ON geo.location_id = jd.location_id
    WHERE jd.session_duration > 0;
