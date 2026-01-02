USE TechHealthDb;
GO

-- Find all customers who registered in the last 30 days.
SELECT user_id, occupation, income_bracket, registration_date
FROM Customers
WHERE registration_date >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE));

-- Find all health metric records from the last 3 months.
SELECT record_id, user_id, month_date, achievement_rate
FROM HealthMetrics
WHERE month_date >= DATEADD(MONTH, -3, CAST(GETDATE() AS DATE));

-- Find all customers whose last recorded health metric (month_date) is older than 6 months
SELECT 
    c.user_id,
    MAX(hm.month_date) AS last_metric_date,
    c.subscription_type,
    c.age
FROM Customers c
JOIN HealthMetrics hm ON hm.user_id = c.user_id
GROUP BY c.user_id, c.subscription_type, c.age
HAVING MAX(hm.month_date) < DATEADD(MONTH, -6, CAST(GETDATE() AS DATE));


-- Find all customers who purchased a product in the last 45 days AND 
-- have a health metric record from the same 45?day window.
SELECT 
    c.user_id,
    s.sale_date,
    hm.month_date,
    c.subscription_type,
    c.age
FROM Customers c
JOIN Sales s 
    ON s.user_id = c.user_id
JOIN HealthMetrics hm 
    ON hm.user_id = c.user_id
WHERE s.sale_date >= DATEADD(DAY, -45, CAST(GETDATE() AS DATE))
  AND hm.month_date >= DATEADD(DAY, -45, CAST(GETDATE() AS DATE));



-- Find all customers who have a health metric recorded in the same month as their registration month.
SELECT c.user_id, c.registration_date, hm.date, c.subscription_type
FROM Customers c
JOIN HealthMetrics hm ON hm.user_id = c.user_id
WHERE DATEPART(MONTH, c.registration_date) =  DATEPART(MONTH, hm.date)


SELECT date, record_id
from HealthMetrics
go

-- generating random dates 
WITH cte AS (
    SELECT record_id, [date]
    FROM HealthMetrics
    WHERE record_id BETWEEN 'MHM001' AND 'MHM050'
)
UPDATE cte
SET [date] =
    DATEADD(
        DAY,
        ABS(CHECKSUM(NEWID())) %
        DATEDIFF(DAY, '2023-06-01', CAST(GETDATE() AS DATE)),
        '2023-06-01'
    );


SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'HealthMetrics';



