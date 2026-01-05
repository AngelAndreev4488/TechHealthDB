USE TechHealthDb;
GO

/* 
CORRELATED SUBQUERY EXERCISE #4 — Customer Performance vs Regional Average

Scenario:
Your company wants to identify customers whose health performance exceeds the average in their region.
Each customer is linked to a location via location_id, and their health metrics are tracked in HealthMetrics.

Task:
Write a query that returns a list of customers whose:
    - avg_daily_steps is higher than the average avg_daily_steps of all other customers in the same region
    - avg_sleep_hours is higher than the regional average
    - achievement_rate is higher than the regional average

Use a correlated subquery to compare each customer against the average of their region.

Output columns:
    - user_id
    - region
    - avg_daily_steps
    - avg_sleep_hours
    - achievement_rate

Additional rules:
- You must use **correlated subqueries** for all three comparisons
- You may use JOINs to access region data from GeoLocation
- Do not use window functions or CTEs
- Do not use GROUP BY in the outer query
- Do not use temp tables or views
*/


SELECT 
    c.user_id,
    geo.country,
    hm.avg_daily_steps,
    hm.avg_sleep_hours,
    hm.achievement_rate
FROM Customers c
JOIN GeoLocation geo 
    ON geo.location_id = c.location_id
JOIN HealthMetrics hm 
    ON hm.user_id = c.user_id
WHERE hm.avg_daily_steps >
(
    SELECT AVG(hm2.avg_daily_steps)
    FROM Customers c2
    JOIN GeoLocation geo2 
        ON geo2.location_id = c2.location_id
    JOIN HealthMetrics hm2 
        ON hm2.user_id = c2.user_id
    WHERE geo2.country = geo.country
      AND c2.user_id <> c.user_id
)
AND hm.avg_sleep_hours > 
(
    SELECT AVG(hm2.avg_sleep_hours)
    FROM Customers c2
    JOIN GeoLocation geo2 
        ON geo2.location_id = c2.location_id
    JOIN HealthMetrics hm2 
        ON hm2.user_id = c2.user_id
    WHERE geo2.country = geo.country
      AND c2.user_id <> c.user_id)
AND hm.achievement_rate > (
    SELECT AVG(hm2.achievement_rate)
    FROM Customers c2
    JOIN GeoLocation geo2 
        ON geo2.location_id = c2.location_id
    JOIN HealthMetrics hm2 
        ON hm2.user_id = c2.user_id
    WHERE geo2.country = geo.country
      AND c2.user_id <> c.user_id);