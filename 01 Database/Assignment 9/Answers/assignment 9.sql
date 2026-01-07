--Question 01 : 
--Optimize the performance of queries that search for posts by a specific 
--user with a minimum score threshold, ordered by score. 
--Example query pattern: 
--"Find all posts by user 5 with score > 50, ordered by score descending" 
 
--Tasks: 
--a) Design and implement an appropriate index structure 
--b) Ensure the index covers all columns needed by the query 
--c) Write a test query that demonstrates the optimization 
--d) Verify the index was created successfully 
 
Create NonClustered Index IX_Posts_User_Score
On Posts (OwnerUserId, Score Desc)
Include(Title)


Select  Title, Score
from Posts
Where OwnerUserId = 5 and Score > 50
Order by Score desc
;


--Question 02 : 
--Optimize queries that frequently access high-value posts. These queries 
--always filter for posts with score > 100 and non-null titles. 
 
--Tasks: 
--a) Design an index that only includes posts meeting these criteria 
--b) Include relevant columns in the index 
--c) Write a query that demonstrates the optimization 
--d) Explain why this specialized index design is beneficial 


Create NonClustered Index IX_HighValuePosts
On Posts(Score Desc)
Include(Title)
Where Score > 100 And Title is not null


Select Title, Score
From Posts
Where Score > 100
and Title is not null
;

-- used a filterd index to optimize size of index by limit pages on these criteria (score > 100 and title not null) only
-- and then the result is faster query performance (minimum pages).