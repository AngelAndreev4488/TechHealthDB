USE TechHealthDb;
GO

-- testing offset and fetch usage.
select * from Customers
order by age offset 20 rows fetch next 20 rows only;

-- testing ALL() usage.
SELECT age 
FROM Customers 
WHERE age < 30
AND age >= ALL (
	SELECT experience_years
	FROM Coaches
	WHERE experience_years <= 6);


-- Find all users who have at least one ACTIVE device.
SELECT user_id, age 
FROM Customers
WHERE EXISTS (
	SELECT 1
	FROM Devices 
	WHERE device_status = 'Active'
	AND Customers.user_id = Devices.user_id)



-- inner join
SELECT user_id, age, gender, geo.city
FROM Customers cu
JOIN GeoLocation geo ON geo.location_id = cu.location_id 

-- left join
SELECT user_id, age, gender, geo.city
FROM Customers cu
LEFT JOIN GeoLocation geo ON geo.location_id = cu.location_id 

-- full join
SELECT user_id, age, gender, geo.city
FROM Customers cu
FULL JOIN GeoLocation geo ON geo.location_id = cu.location_id 

-- outer join
SELECT cu.user_id, cu.age, cu.gender, geo.city
FROM Customers cu
FULL OUTER JOIN GeoLocation geo
    ON geo.location_id = cu.location_id
WHERE cu.user_id IS NULL
   OR geo.city IS NULL;


-- recursive cte
WITH RankedCoaches AS (
    SELECT 
        coach_id,
        first_name,
        last_name,
        experience_years,
        ROW_NUMBER() OVER (ORDER BY experience_years DESC) AS rn
    FROM Coaches
),
coach_hierarchy AS (
    -- Anchor: the most experienced coach (rn = 1)
    SELECT 
        coach_id,
        first_name,
        last_name,
        experience_years,
        rn,
        1 AS hierarchy_level
    FROM RankedCoaches
    WHERE rn = 1

    UNION ALL

    -- Recursive: join to the next row number
    SELECT 
        rc.coach_id,
        rc.first_name,
        rc.last_name,
        rc.experience_years,
        rc.rn,
        ch.hierarchy_level + 1
    FROM RankedCoaches rc
    JOIN coach_hierarchy ch
        ON rc.rn = ch.rn + 1
)
SELECT *
FROM coach_hierarchy
ORDER BY hierarchy_level;


WITH coach_hierarchy AS (
    SELECT coach_id, first_name, last_name, experience_years
    FROM Coaches

    UNION ALL
    SELECT e.coach_id, e.first_name, e.last_name, e.experience_years
    FROM Coaches e
    JOIN coach_hierarchy ch ON ch.coach_id = e.coach_id
)

SELECT *
FROM coach_hierarchy

