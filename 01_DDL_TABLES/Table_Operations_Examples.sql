USE TechHealthDb;
GO

-- Task: Create a temporary table named #DeviceSyncLog with columns 
-- device_id (varchar(10)), sync_date (datetime), and sync_status (varchar(20)).

CREATE TABLE #DeviceSyncLog (
	device_id VARCHAR(10),
	sync_date DATETIME,
	sync_status VARCHAR(20)
)

-- Task: Rename the table HealthMetricsArchive to HealthMetricsHistory using sp_rename.
EXEC sp_rename 'HealthMetricsArchive', 'HealthMetricsHistory';


-- Task: Add a column restock_threshold (int, NOT NULL, default 10) to the Inventory table.
ALTER TABLE Inventory
ADD restock_threshold INTEGER NOT NULL DEFAULT 10;


-- Task: Drop the column notification_enabled from the Devices table.
ALTER TABLE Devices
DROP COLUMN notification_enabled;

-- Task: Truncate all rows from the ErrorLog table to reset logs.
TRUNCATE TABLE ErrorLog;

-- Task: Create a new table Customers_Backup and copy all rows from Customers into it.
SELECT * INTO Customers_Backup
FROM Customers;


