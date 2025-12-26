-- ============================================
-- STRING FUNCTIONS
-- ============================================
-- LEN: Returns the length of a string
-- Return Display Name And Their Length

SELECT  DisplayName, LEN(DisplayName) AS NameLength
FROM Users;

-- SUBSTRING: Extracts part of a string
-- Return First 5 Chars In Display Name 

SELECT  DisplayName, SUBSTRING(DisplayName, 1, 5) AS FirstFiveChars
FROM Users;

-- REPLACE: Replaces substring occurrences
-- Replace C# To C sharp In Posts With Title Contain C#

SELECT  Title, REPLACE(Title, 'C#', 'C sharp') AS ModifiedTitle
FROM Posts
Where Title Is Not Null and Title like '%C#%';

-- CHARINDEX: Finds the position of a substring
-- Find Index Of SQL In Post's Title

SELECT  Title, CHARINDEX('SQL', Title) AS PositionOfSQL
FROM Posts
WHERE Title IS NOT NULL;

-- LTRIM / RTRIM: Removes leading or trailing spaces

SELECT  LTRIM('    Route   ')  , RTRIM('    Route   ')
FROM Users;

-- LOWER / UPPER: Case conversion
-- Return User Display Name 

SELECT  DisplayName, LOWER(DisplayName) AS Lowercase, UPPER(DisplayName) AS Uppercase
FROM Users;

-- CONCAT: Combines multiple strings
-- Combines Display Name Of User With His/Her Location 

Select DisplayName + Age
From Users;

Select DisplayName + ' - ' + Location
From Users;

Select CONCAT(DisplayName , Age) As UserInfo
From Users;

Select CONCAT(DisplayName , ' - ' , Location) As UserInfo
From Users;


-- ============================================
-- DATE & TIME FUNCTIONS
-- ============================================

-- GETDATE: Returns current date/time
-- Return DisplayName , CreationDate Of User and CurrentDateTime
SELECT  DisplayName, CreationDate, GETDATE() AS CurrentDateTime
FROM Users;

-- SYSDATETIME: Higher precision timestamp
SELECT  SYSDATETIME() AS HighPrecisionTime;

-- DATEADD: Adds time to a date
-- Return DisplayName , CreationDate Of User and Date Of One Year Later 
SELECT  DisplayName, CreationDate, DATEADD(YEAR, 1, CreationDate) AS OneYearLater
FROM Users;

-- DATEDIFF: Difference between two dates
-- Return DisplayName , CreationDate Of User and Number Of Days Since Creation
SELECT  DisplayName, CreationDate, DATEDIFF(DAY, CreationDate, GETDATE()) AS DaysSinceCreation
FROM Users;

-- FORMAT: Converts date to a custom format
SELECT  DisplayName, FORMAT(CreationDate, 'dd-MM-yyyy') AS FormattedDate
FROM Users;

-- DATENAME: Returns part of a date as text
SELECT  DisplayName, CreationDate, DATENAME(MONTH, CreationDate) AS MonthName
FROM Users;

-- ============================================
-- MATHEMATICAL FUNCTIONS
-- ============================================

-- ABS: Absolute value
SELECT Title,Score,ABS(Score) AS AbsoluteScore
FROM Posts
Where Title Is Not Null;


-- ROUND: Rounds to a specified precision
SELECT  DisplayName,Reputation,ROUND(Reputation / 100.0, 2) AS ReputationInHundreds
FROM Users;

-- CEILING: Rounds up to next integer
SELECT  DisplayName, Reputation, CEILING(Reputation / 100.0) AS CeilingValue
FROM Users;

-- FLOOR: Rounds down to previous integer
SELECT  DisplayName, Reputation, FLOOR(Reputation / 100.0) AS FloorValue
FROM Users;

-- RAND: Generates random number
SELECT RAND() AS RandomNumber;


-- ============================================
-- CONVERSION FUNCTIONS
-- ============================================

-- CAST: Converts a value to another data type
SELECT  DisplayName, CAST(Reputation AS VARCHAR(50)) AS ReputationAsString
FROM Users;

-- CONVERT: Similar to CAST but supports formatting
SELECT DisplayName,CreationDate, CONVERT(VARCHAR, CreationDate, 101) AS FormattedDate
FROM Users;

-- TRY_CAST: Returns NULL on conversion failure
SELECT  DisplayName, TRY_CAST(Location AS INT) AS LocationAsNumber
FROM Users;


-- PARSE: Converts strings to dates/numbers (culture-aware)
SELECT  PARSE('12/25/2010' AS DATE) AS ParsedDate;

-- TRY_PARSE: Safe version of PARSE
SELECT  TRY_PARSE('Invalid Date' AS DATE) AS SafeParsedDate;


-- ============================================
-- AGGREGATE FUNCTIONS
-- ============================================

-- SUM: Total of numeric values
SELECT  SUM(Reputation) AS TotalReputation
FROM Users;

-- COUNT: Number of rows/items
Select Count(*) As TotalUsers , COUNT(Age) As CountOfAge
From Users;

-- AVG: Average value
SELECT AVG(Reputation) AS AverageReputation
FROM Users;

-- MIN: Smallest value , MAX: Largest value
SELECT MIN(Reputation) AS MinimumReputation , MAX(Reputation) AS MaximumReputation
FROM Users;

-- COUNT_BIG: Count for very large datasets
SELECT  COUNT_BIG(*) AS TotalPostsBig
FROM Posts;

-- ============================================
-- LOGICAL FUNCTIONS
-- ============================================

-- IIF: Returns value based on Boolean condition
SELECT  DisplayName, Reputation, IIF(Reputation > 1000, 'High', 'Low') AS ReputationLevel
FROM Users;

-- CHOOSE: Selects a value from a list by index
SELECT  DisplayName, CHOOSE(2, 'Bronze', 'Silver', 'Gold') AS BadgeType
FROM Users;

-- NULLIF: Returns NULL if two values are equal
SELECT  DisplayName, NULLIF(Location, '') AS LocationOrNull
FROM Users;

-- COALESCE: Returns first non-null value

Select DisplayName , Coalesce(Location , EmailHash , DisplayName) As LocationOrAnotherValue
From Users;

-- ISNULL: Replaces NULL with a value
SELECT  DisplayName, ISNULL(Age, 0) AS AgeWithDefault
FROM Users;


-- ============================================
-- METADATA FUNCTIONS
-- ============================================

-- OBJECT_ID: ID of a table, view, or function
SELECT  OBJECT_ID('dbo.Users') AS UsersTableID;

-- COLUMNPROPERTY: Column metadata
SELECT COLUMNPROPERTY(OBJECT_ID('dbo.Users'), 'Location', 'AllowsNull') AS CanBeNull;

-- DB_NAME: Current database name
SELECT  DB_NAME() AS CurrentDatabaseName;

-- COL_NAME: Column name by table ID
SELECT  COL_NAME(OBJECT_ID('dbo.Users'), 1) AS FirstColumnName;

-- SCHEMA_NAME: Returns schema name
Select SCHEMA_ID('dbo')
SELECT  SCHEMA_NAME(1) AS SchemaName;

-- FILE_NAME / FILE_ID: File-level details
SELECT FILE_NAME(1) AS PrimaryFileName;
SELECT FILE_NAME(2) AS LogFileName;

-- GROUP BY Examples
-- Covering: Basic GROUP BY, Multiple Columns, HAVING, and JOIN with GROUP BY

-- ============================================
-- GROUP BY (Basics) 
-- ============================================

-- Example 1: Count posts by each user
-- Shows how many posts each user has created
SELECT  OwnerUserId, COUNT(*) AS TotalPosts
FROM Posts
Where Title Is Not Null and OwnerUserId Is Not Null
GROUP BY OwnerUserId;

-- Example 2: Calculate average score and total views by post type
SELECT  PostTypeId, AVG(Score) AS AverageScore, MAX(Score) AS HighestScore, MIN(Score) AS LowestScore
FROM Posts
Where Title Is Not Null
GROUP BY PostTypeId;

-- Example 3: Count badges by badge name
SELECT  Name AS BadgeName, COUNT(*) AS TimesAwarded, MIN(Date) AS FirstAwarded, MAX(Date) AS LastAwarded
FROM Badges
GROUP BY Name;


-- ============================================
-- GROUP BY Multiple Columns 
-- Works like nested grouping: first by column A, then by column B
-- ============================================

-- Example 4: Count posts by user and post type
SELECT  OwnerUserId, PostTypeId, COUNT(*) AS PostCount, AVG(Score) AS AvgScore
FROM Posts
Where Title is Not Null and OwnerUserId Is Not Null 
GROUP BY OwnerUserId, PostTypeId;

Select UserId , Name ,  Count(*) As BadgeCount
From Badges 
Group by UserId , Name

-- ============================================
-- GROUP BY with HAVING 
-- HAVING filters grouped results (after aggregation)
-- WHERE filters rows (before aggregation)
-- ============================================

-- Example 5: Find users with more than 10 posts
-- HAVING filters the grouped results

SELECT  OwnerUserId, COUNT(*) AS TotalPosts
FROM Posts
WHERE OwnerUserId IS NOT NULL
GROUP BY OwnerUserId
HAVING COUNT(*) > 10;

-- Example 6: Find posts with high average comment scores
-- Shows posts where comments are highly rated

SELECT  PostId, COUNT(*) AS CommentCount, AVG(Score) AS AvgCommentScore, SUM(Score) AS TotalCommentScore
FROM Comments
GROUP BY PostId
HAVING AVG(Score) > 2;

-- Example 7: Find badge names awarded to many users
-- Identifies popular badges with thresholds
SELECT  Name AS BadgeName, COUNT(*) AS TimesAwarded
FROM Badges
GROUP BY Name
HAVING COUNT(*) > 500;

-- ============================================
-- GROUP BY with JOIN 
-- Common pattern: JOIN → GROUP → Aggregate
-- ============================================

-- Example 8: Count posts per user with user information
-- Display Name 
-- Reputation 
-- Total Posts
-- Avg Score 

SELECT  u.DisplayName, u.Reputation, COUNT(p.Id) AS TotalPosts, AVG(p.Score) AS AvgPostScore, SUM(p.ViewCount) AS TotalViews
FROM Users u
INNER JOIN Posts p ON u.Id = p.OwnerUserId
GROUP BY u.Id, u.DisplayName, u.Reputation;


-- ============================================
-- Subquery Examples
-- ============================================
-- Subquery in WHERE 
-- Used for filtering based on another query's results
-- ============================================

-- Example 1: Find users with reputation higher than average

SELECT  DisplayName, Reputation, Location
FROM Users
WHERE Reputation > (SELECT AVG(Reputation) FROM Users);


-- Example 2: Find posts created by users from specific locations
SELECT  Title, Score, OwnerUserId
FROM Posts
WHERE OwnerUserId IN ( SELECT Id  FROM Users  WHERE Location IN ('New York', 'London', 'San Francisco'));

Select Title , Score , OwnerUserId 
From Posts P Inner Join Users U 
On U.Id = P.OwnerUserId
Where Location In ('New York' , 'London');



-- ============================================
-- Subquery in SELECT 
-- Returns one value per row (scalar subquery)
-- Used for calculated columns and lookups
-- ============================================

-- Example 3: Show each post with the average score of all posts
SELECT  Title, Score, (SELECT AVG(Score) FROM Posts) AS AvgScore, Score - (SELECT AVG(Score) FROM Posts) AS ScoreDifference
FROM Posts
WHERE Title IS NOT NULL;


-- Example 4: Show each user with their total number of posts
SELECT  DisplayName, Reputation, (SELECT COUNT(*)  FROM Posts p  WHERE p.OwnerUserId = Users.Id) AS TotalPosts,
(SELECT COUNT(*)  FROM Badges b  WHERE b.UserId = Users.Id) AS TotalBadges
FROM Users;


-- ============================================
-- Subquery in FROM (Derived Table) 
-- Creates a virtual table that must have an alias
-- ============================================

-- Example 5: Get user statistics from a pre-aggregated derived table
-- First calculates post stats per user, then filters the results
SELECT  UserStats.OwnerUserId, UserStats.TotalPosts, UserStats.AvgScore, u.DisplayName, u.Reputation
FROM (
    SELECT  OwnerUserId, COUNT(*) AS TotalPosts, AVG(Score) AS AvgScore, SUM(ViewCount) AS TotalViews
    FROM Posts
    WHERE OwnerUserId IS NOT NULL
    GROUP BY OwnerUserId ) AS UserStats
INNER JOIN Users u ON UserStats.OwnerUserId = u.Id
WHERE UserStats.TotalPosts > 5;


-- Example 6: Find top scoring posts with comment statistics
-- Combines post data with aggregated comment data from derived table
SELECT p.Title, p.Score AS PostScore, CommentStats.CommentCount, CommentStats.TotalCommentScore, u.DisplayName AS Author
FROM Posts p
INNER JOIN ( SELECT  PostId, COUNT(*) AS CommentCount, SUM(Score) AS TotalCommentScore,AVG(Score) AS AvgCommentScore
             FROM Comments
             GROUP BY PostId
             HAVING COUNT(*) > 3 ) AS CommentStats 
ON p.Id = CommentStats.PostId
INNER JOIN Users u ON p.OwnerUserId = u.Id
Where P.Title Is Not Null and p.Score > 10; 