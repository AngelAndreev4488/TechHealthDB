USE TechHealthDB;
GO

-- Write a T-SQL query that returns all devices purchased in the last 30 days but whose last_sync_date 
-- is more than 3 days ago. For each result, include:
-- A computed column called days_since_last_sync showing how many days have passed since the last sync.

SELECT device_id, user_id, purchase_date, last_sync_date, 
DATEDIFF(DAY, last_sync_date, GETDATE()) AS days_since_last_sync
FROM Devices
WHERE purchase_date >= DATEADD(DAY, -30, GETDATE())
AND last_sync_date < DATEADD(DAY, -3, GETDATE());



-- Write a T‑SQL query that returns all customers who have logged at least one HealthMetrics record 
-- in the current month. For each qualifying user, return:
-- user_id, First day of the current month → month_start, Last day of the current month → month_end,
-- Number of HealthMetrics records they logged this month → records_this_month, 
-- A computed column days_since_last_record → days between their most recent date in HealthMetrics and today.
-- Add a column activity_flag:
-- '🔥 Active' if records_this_month >= 5
-- '🙂 Moderate' if between 2 and 4
-- '😴 Low' if 1
SELECT c.user_id, 
DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS month_start,
EOMONTH(GETDATE()) AS month_end,
ca.records_this_month AS records_this_month,
DATEDIFF(DAY, MAX(hm.date), GETDATE()) AS days_since_last_record,
CASE
	WHEN ca.records_this_month >= 5 THEN 'Active'
	WHEN ca.records_this_month BETWEEN 2 AND 4 THEN 'Moderate'
	WHEN ca.records_this_month <= 1 THEN 'Low'
	ELSE 'No activity'
END AS activity_flag
FROM Customers c
LEFT JOIN HealthMetrics hm ON hm.user_id = c.user_id
CROSS APPLY (
	SELECT COUNT(*) AS records_this_month
	FROM HealthMetrics hm2
	WHERE hm2.user_id = c.user_id
	AND hm2.date >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	AND hm2.date < DATEADD(MONTH, 1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))) ca
GROUP BY c.user_id, ca.records_this_month




