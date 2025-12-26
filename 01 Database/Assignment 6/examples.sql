-- ============================================
-- TOP - Limit number of rows returned
-- ============================================

-- Example 1: Get top 10 users by reputation
Select Top 10 DisplayName, Reputation, Location
From Users
Order By Reputation Desc

-- Example 2: Get top 5 posts with highest scores
Select Top 5 Title, Score, ViewCount, CreationDate
from Posts 
Where Title Is Not Null
Order By Score Desc

-- ============================================
-- TOP WITH TIES - Include rows with same value as last row
-- ============================================

-- Example 3: Get top 10 users by reputation, including ties
-- If multiple users have the same reputation as the 10th user, include them all
Select Top 10 With Ties DisplayName, Reputation, Location
From Users
Order By Reputation Desc

-- Example 4: Get top 5 posts by score, including all posts with same score as 5th
Select Top 5 With Ties Title, Score, ViewCount, CreationDate
from Posts 
Where Title Is Not Null
Order By Score Desc


-- ============================================
-- OFFSET & FETCH - Pagination (skip rows and take rows)
-- ============================================

-- Example 5: Skip first 10 users and get next 10 (pagination)
-- OFFSET skips rows, FETCH gets the next N rows
Select DisplayName, Reputation, Location
From Users
Order By Reputation Desc
Offset 10 Rows
Fetch Next 10 Rows Only

-- Example 6: Get posts 21-30 when ordered by score (page 3, 10 per page)
Select Title, Score, ViewCount, CreationDate
from Posts 
Where Title Is Not Null
Order By Score Desc
Offset 20 Rows
Fetch Next 10 Rows Only

-- ============================================
-- ROW_NUMBER - Assigns unique sequential number to each row
-- ============================================

-- Example 7: Assign row numbers to users ordered by reputation
Select ROW_NUMBER() Over(Order By Reputation Desc) As RowNum,
	   DisplayName, Reputation, Location
From Users

-- Example 8: Number posts sequentially by score
Select ROW_NUMBER() Over(Order By Score Desc) As RowNum,
       Title, Score, ViewCount, CreationDate
from Posts 
Where Title Is Not Null

-- ============================================
-- RANK - Assigns rank with gaps for ties
-- ============================================

-- Example 9: Rank users by reputation (ties get same rank, next rank skips)
-- If two users tie for rank 5, next user gets rank 7
Select RANK() Over(Order By Reputation Desc) As Rank,
	   DisplayName, Reputation, Location
From Users

-- Example 10: Rank posts by score
Select RANK() Over(Order By Score Desc) As Rank,
       Title, Score, ViewCount, CreationDate
from Posts 
Where Title Is Not Null

-- ============================================
-- DENSE_RANK - Assigns rank without gaps for ties
-- ============================================

-- Example 11: Dense rank users by reputation (no gaps in ranking)
-- If two users tie for rank 5, next user gets rank 6
Select Dense_Rank() Over(Order By Reputation Desc) As DenseRank,
	   DisplayName, Reputation, Location
From Users

-- Example 12: Dense rank posts by score
Select Dense_Rank() Over(Order By Score Desc) As DenseRank,
       Title, Score, ViewCount, CreationDate
from Posts 
Where Title Is Not Null

-- ============================================
-- NTILE - Divides rows into specified number of groups
-- ============================================

-- Example 13: Divide users into 100 quartiles based on reputation
Select NTILE(100) Over(Order By Reputation Desc) As Quartile,
	   DisplayName, Reputation, Location
From Users


-- Example 14: Divide posts into 10 groups (deciles) by score
Select NTILE(10) Over(Order By Score Desc) As Decile,
       Title, Score, ViewCount, CreationDate
from Posts 
Where Title Is Not Null


-- ============================================
-- PARTITION BY - Restart ranking within each group
-- ============================================

-- Example 15: Rank posts within each PostTypeId
-- Ranking restarts for each post type
Select PostTypeId,
	   ROW_NUMBER() Over(Partition By PostTypeId Order By Score Desc) As RankInType,
       Title, Score, ViewCount, CreationDate
from Posts 
Where Title Is Not Null

-- Example 16: Rank users within each location by reputation
Select Location,
	   Rank() Over(Partition By Location Order By Reputation Desc) As RankInLocation,
	   DisplayName, Reputation, Location
From Users
Where Location Is Not Null

-- Example 17: Get top 3 posts for each post type using ROW_NUMBER with PARTITION BY
Select *
From (Select PostTypeId,
	   ROW_NUMBER() Over(Partition By PostTypeId Order By Score Desc) As RankInType,
       Title, Score, ViewCount, CreationDate
from Posts 
Where Title Is Not Null) As RankedPosts
Where RankInType <= 3
