USE TechHealthDb;
GO

-- You want to analyze customers who are older than 30, 
-- have a subscription type of 'Premium', and live in a known location (i.e., location_id IS NOT NULL).

SELECT user_id, age, gender, occupation, subscription_type, location_id
FROM Customers
WHERE age > 30 AND 
	subscription_type = 'Premium' 
	AND location_id IS NOT NULL;


-- ?? Task:Write a query that returns:
-- user_id, age, occupation, subscription_type. Where: age BETWEEN 25 AND 40 OR
-- occupation Engineer. ORDER BY age (ascending)

SELECT user_id, age, occupation, subscription_type
FROM Customers
WHERE age BETWEEN 25 AND 40 OR
	occupation LIKE '%Engineer%'
ORDER BY age;


-- Task: Write a query that returns user_id, age, subscription_type, and location_id 
-- for customers whose location_id is IN (1, 2, 3) AND whose subscription_type
-- is NOT IN ('Basic', 'Free') AND whose age is greater than or equal to 18, 
-- ordered by subscription_type ascending.

SELECT user_id, age, subscription_type, location_id 
FROM Customers
WHERE location_id IN (1, 2, 3) AND
	subscription_type NOT IN ('Basic', 'Free')
	AND age >= 18
ORDER BY subscription_type;



-- Task: Write a query that returns user_id, occupation, income_bracket, and a fallback label 
-- using COALESCE for customers whose occupation IS NULL OR income_bracket IS NULL, ordered by user_id.

SELECT user_id, occupation, income_bracket, COALESCE(occupation, income_bracket, 'Unknown') AS 
	missing_info
FROM Customers
WHERE occupation IS NULL OR income_bracket IS NULL
ORDER BY user_id;



