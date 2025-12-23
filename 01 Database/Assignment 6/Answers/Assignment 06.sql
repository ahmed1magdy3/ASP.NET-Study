

USE StackOverflow2010 ;

/*
Question 01 : 
	● Write a query to retrieve the top 15 users with the highest 
	reputation. 
	● Display their DisplayName, Reputation, and Location. 
	● Order the results by Reputation in descending order 
 */
 select TOP(15) u.DisplayName, u.Reputation, u.Location
 from  Users u
 order by u.reputation desc
 ;

 /*
Question 02 : 
	● Write a query to get the top 10 posts by score, but include  
	●  all posts that have the same score as the 10th post. 
	● Use TOP WITH TIES. Display Title, Score, and ViewCount. 
 */
 select TOP(10) WITH TIES Title, Score, ViewCount
 from Posts 
 order by Score desc
 ;
 /*
Question 03 : 
	● Write a query to implement pagination: skip the first 20 users  
	● and retrieve the next 10 users when ordered by reputation. 
	● Use OFFSET and FETCH. Display DisplayName and Reputation. 
 */
 select DisplayName, Reputation
 from Users 
 order by reputation desc
 offset 20 rows
 fetch next 10 rows only
 ;
 /*
Question 04: 
	●  Write a query to assign a unique row number to each post  
	●  ordered by Score in descending order. 
	● Use ROW_NUMBER(). Display the row number, Title, and Score. 
	● Only include posts with non-null titles. 
*/
select ROW_NUMBER()Over(Order By Score Desc) As RowNum, Title, Score
from Posts
where Title is not null
;
/*
Question 05 : 
	●  Write a query to rank users by their reputation using RANK(). 
	●  Display the rank, DisplayName, and Reputation. 
	● Explain what happens when two users have the same reputation. 
*/
select RANK() over (order by reputation desc) as RANK, DisplayName, Reputation
from Users 
-- it assigns the same rank to users who have the same reputation, when there’s a tie, the next rank is skipped.
;
/*
Question 06 :
	● Write a query to rank posts by score using DENSE_RANK(). 
	● Display the dense rank, Title, and Score. 
	● Explain how DENSE_RANK differs from RANK.
*/
select DENSE_RANK() over (order by Score desc) as dense_rank, Title, Score
from Posts
-- it assigns the same rank to rows with the same score, doesn't skip rank numbers after ties.
;

/*
Question 07 :  
	●  Write a query to divide all users into 5 equal groups (quintiles) 
	● based on their reputation. Use NTILE(5). 
	● Display the quintile number, DisplayName, and Reputation.
*/
select NTILE(5) Over(order By Reputation Desc) As Quantile,DisplayName, Reputation
from Users
;
/*
Question 08 : 
	● Write a query to rank posts within each PostTypeId separately. 
	● Use ROW_NUMBER() with PARTITION BY. 
	● Display PostTypeId, rank within type, Title, and Score. 
	● Order by Score descending within each partition.
*/

select PostTypeId, ROW_NUMBER() over (partition by PostTypeId order by Score desc) as RankWithinType,
    Title,Score
from Posts;
