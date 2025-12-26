
use StackOverflow2010;

--Question 01 :
--●	Write a query to display all user display names in uppercase 
--along with the length of their display name.

select UPPER(DisplayName), LEN(DisplayName)
from Users;

--Question 02 :
--●	Write a query to show all posts with their titles and calculate 
--how many days have passed since each post was created.
--Use DATEDIFF to calculate the difference from CreationDate to today.

select Title, DATEDIFF(day,CreationDate,GETDATE())
from Posts;

--Question 03 :
--●	Write a query to count the total number of posts for each user.
--Display the OwnerUserId and the count of their posts.
--Only include users who have created posts.

select u.DisplayName, COUNT(p.Id) 'Number of Posts' 
from Users u
join Posts p on p.OwnerUserId = u.Id
group by u.DisplayName
--order by COUNT(p.Id) desc;



--Question 04:
--●	 Write a query to find users whose reputation is greater than 
--the average reputation of all users. Display their DisplayName 
-- and Reputation. Use a subquery in the WHERE clause.

select DisplayName, Reputation
from Users
where Reputation > ( select AVG(Reputation) from Users )


--Question 05 :
--●	Write a query to display each post title along with the first 
--50 characters of the title. If the title is NULL, replace it 
--with 'No Title'. Use SUBSTRING and ISNULL functions.

select Title ,SUBSTRING(ISNULL(Title,'No Title'),1,50)
from Posts
;


--Question 06 :
--●	Write a query to calculate the total score and average score 
--for each PostTypeId. Also show the count of posts for each type.
-- Only include post types that have more than 100 posts.

select pt.Type , SUM(p.Score) TotalScore , AVG(p.Score) AvgScore , COUNT(p.Id) PostsCount
from Posts p
join PostTypes pt on pt.Id = p.PostTypeId 
group by pt.Type
HAVING COUNT(p.Id) > 100
;

--Question 07 :
--●	Write a query to show each user's DisplayName along with 
--the total number of badges they have earned. Use a subquery 
--in the SELECT clause to count badges for each user.

select u.DisplayName, (select COUNT(b.Id) from Badges b where b.UserId = u.Id) badgesCount
from Users u
--order by badgesCount desc
;



--Question 08 :
--●	 Write a query to find all posts where the title contains the word 'SQL'. 
--Display the title, score, and format the CreationDate as 'Mon DD, YYYY'. Use CHARINDEX and FORMAT functions.

select Title, Score, CHARINDEX('SQL',Title)  , FORMAT(CreationDate,'MMM dd, yyyy')
from Posts
WHERE Title is not null
and CHARINDEX('SQL',Title) > 0
;

--Question 09 :
--●	Write a query to group comments by PostId and calculate:
--         Total number of comments
--         Sum of comment scores
--         Average comment score
--         Only show posts that have more than 5 comments.

select p.Id,p.Title ,COUNT(c.Id) CommentsCount, SUM(c.Score) SumOfCommentsScore, AVG(c.Score) AVGOfCommentsScore
from Comments c
join Posts p on p.Id = c.PostId
group by p.Id, p.Title -- (grouped by title to be displayed)
having COUNT(c.Id) > 5
;

--Question 10 :
--●	 Write a query to find all users whose location is not NULL.
-- Display their DisplayName, Location, and calculate their 
-- reputation level using IIF: 'High' if reputation > 5000, 
--          otherwise 'Normal'.

select DisplayName, Location ,IIF(Reputation > 5000, 'High', 'Normal')
from Users
where Location is not null
;
-- another solution by case when statment
select DisplayName, Location ,case 
								when (Reputation > 5000) then 'High'
								else 'Normal'
							  end
from Users
where Location is not null
;


--Question 11 :
--●	 Write a query using a derived table (subquery in FROM) to:
-- . First, calculate total posts and average score per user
-- . Then, join with Users table to show DisplayName
--  . Only include users with more than 3 posts
-- The derived table must have an alias.

select u.DisplayName, po.TotalPosts, po.AvgScore 
from
	(select p.OwnerUserId, COUNT(p.Id) TotalPosts, AVG(p.Score) AvgScore  
	from Posts p
	group by p.OwnerUserId) as po

join Users u on u.Id = po.OwnerUserId 
where po.TotalPosts > 3
;


--Question 12 :
--●	 Write a query to group badges by UserId and badge Name.
---Count how many times each user earned each specific badge.
-- Display UserId, badge Name, and the count.
-- Only show combinations where a user earned the same badge more than once

select b.UserId, b.Name, COUNT(*)
from Badges b
group by b.UserId, b.Name
having COUNT(*) > 1
;

--Question 13 :
--●	 Write a query to display user information along with their 
-- account age in years. Use DATEDIFF to calculate years between 
-- CreationDate and current date. Round the result to 2 decimal places.
-- Also show the absolute value of their DownVotes.

select DisplayName, ROUND (DATEDIFF(year,CreationDate,GETDATE()),2) AccountAge, ABS(DownVotes) AbsDownVotes
from Users
;

--Question 14 :
--●	Write a complex query that:
-- . Uses a derived table to calculate comment statistics per post
-- . Joins with Posts and Users tables
-- . Shows: Post Title, Author Name, Author Reputation, 
--  Comment Count, and Total Comment Score
--. Filters to only show posts with more than 3 comments 
--  and post score greater than 10
--. Uses COALESCE to replace NULL author names with 'Anonymous'

select p.Title 'Post Title', COALESCE (u.DisplayName,'Anonymous' )'Author Name', u.Reputation 'Author Reputation' 
		,CommentStates.TotalComments, CommentStates.TotalCommentsScore
from
	(select c.PostId, COUNT(c.Id) TotalComments, SUM(c.Score) TotalCommentsScore
	from Comments c
	group by c.PostId) as CommentStates
join Posts p on p.Id = CommentStates.PostId
left join Users u on u.Id = p.OwnerUserId
and TotalComments > 3 
and p.Score > 10
;


-- check left join with (where) and (and)
select DisplayName, p.Title
from Posts p
left join Users u on u.Id = p.OwnerUserId
and  u.DisplayName is null -- instead where