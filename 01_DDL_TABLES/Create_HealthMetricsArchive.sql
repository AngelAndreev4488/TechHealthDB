USE TechHealthDb;
GO


-- Create archive table for health metrics older than 2 years
CREATE TABLE HealthMetricsArchive (
    archive_id INT IDENTITY(1,1) PRIMARY KEY CHECK(archive_id > 0), -- Unique archive ID
    record_id VARCHAR(10), -- Links to HealthMetrics
    user_id VARCHAR(10),   -- Links to Customers
    month_date DATE CHECK (month_date < DATEADD(YEAR, -2, GETDATE())), -- Only old data
    avg_heart_rate INT CHECK(avg_heart_rate >= 0),
    avg_daily_steps INT CHECK(avg_daily_steps >= 0),
    avg_sleep_hours DECIMAL(3,1) CHECK(avg_sleep_hours >= 0),

    -- Foreign key to HealthMetrics
    CONSTRAINT FK_HealthMetricsArchive_HealthMetrics
    FOREIGN KEY (record_id)
    REFERENCES HealthMetrics(record_id),

    -- Foreign key to Customers
    CONSTRAINT FK_HealthMetricsArchive_Customers
    FOREIGN KEY (user_id)
    REFERENCES Customers(user_id)
);

-- Indexes for performance
CREATE NONCLUSTERED INDEX IDX_HealthMetricsArchive_user_id
ON HealthMetricsArchive (user_id);

CREATE NONCLUSTERED INDEX IDX_HealthMetricsArchive_month_date
ON HealthMetricsArchive (month_date);
