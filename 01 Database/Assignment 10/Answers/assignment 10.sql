
use StackOverflow2010;

--Question 01 :
-- Create a view that displays basic user information including 
-- their display name, reputation, location, and account creation date. 
-- Name the view: vw_BasicUserInfo 
-- Test the view by selecting all records from it. 
 go
 create view vw_BasicUserInfo as 
 (
	 select DisplayName, Reputation, Location,CreationDate
	 from Users
 )
 go
 select * from vw_BasicUserInfo; 

--Question 02 : 
--Create a view that shows all posts with their titles, scores, 
-- view counts, and creation dates where the score is greater than 10. 
-- Name the view: vw_HighScoringPosts 
-- Test by querying posts from this view. 
 
 go
 create view vw_HighScoringPosts as
 (
	select Title, Score, ViewCount, CreationDate
	from Posts
	where Score > 10
 )
 go

 select * from vw_HighScoringPosts

--Question 03 : 
--Create a view that combines data from Users and Posts tables. 
-- Show the post title, post score, author name, and author reputation. 
-- Name the view: vw_PostsWithAuthors 
-- This is a complex view involving joins. 
  
go
create or alter view vw_PostsWithAuthors as
(
	select p.Title as PostTitle, 
			p.Score as PostScore, 
			u.DisplayName as AuthorName, 
			u.Reputation as AuthorReputation
	from users u
	join Posts p on p.OwnerUserId = u.Id
)
go

select * from vw_PostsWithAuthors

--Question 04 : 
--Create a view that aggregates comment statistics per post. 
-- Include: PostId, total comment count, sum of comment scores, 
-- and average comment score. 
-- Name the view: vw_PostCommentStats 
-- This is a complex view with aggregation. 

go
create or alter view vw_PostCommentStats 
as
(
	select c.PostId, 
			COUNT(c.Id) as CommentsCount, 
			SUM(c.Score) as SumCommentsScore,
			AVG(c.Score) as AVGCommentsScore
	from Comments c
	group by c.PostId

)
go

select * from vw_PostCommentStats;

--Question 05 : 
--Create an indexed view that shows user activity summaries. 
-- Include: UserId, DisplayName, Reputation, total posts count. 
-- Name the view: vw_UserActivityIndexed 
-- Make it an indexed view with a unique clustered index on UserId 
go
create or alter view vw_UserActivityIndexed 
With SchemaBinding
as
(
	select u.Id as UserId, 
			u.DisplayName ,
			u.Reputation, 
			COUNT_BIG(*) as PostsCount 
	from dbo.Users u
	join dbo.Posts p on p.OwnerUserId = u.Id
	group by u.Id, u.DisplayName ,u.Reputation
)
go

create unique clustered index IX_UserActivity on vw_UserActivityIndexed(UserId)

select * from vw_UserActivityIndexed ;

--Question 06 : 
--Create a partitioned view that combines high reputation users 
-- (reputation > 5000) and low reputation users (reputation <= 5000) 
-- from the same Users table using UNION ALL. 
-- Name the view: vw_UsersPartitioned 

go
create or alter view  vw_UsersPartitioned 
as
(
	select *, 'High' as ReputationPartion
	from Users
	where Reputation > 5000
	
	union all
	
	select *, 'Low' as ReputationPartion
	from Users
	where Reputation <= 5000 
)
go

select * from vw_UsersPartitioned

--Question 07 : 
--Create an updatable view on the Users table that shows 
-- UserId, DisplayName, and Location. 
-- Test the view by updating a user's location through the view. 
-- Name the view: vw_EditableUsers 
go
 create or alter view vw_EditableUsers
 as
 (
	select Id as UserId,
			DisplayName,
			Location
	from Users
 )
 go 

 update vw_EditableUsers
 set Location = 'London'
 where UserId = -1 

 select * from vw_EditableUsers;
--Question 08 : 
--Create a view with CHECK OPTION that only shows posts with 
-- score greater than or equal to 20. 
-- Name the view: vw_QualityPosts 
-- Ensure that any updates through this view maintain the score >= 20 condition .
go
create or alter view vw_QualityPosts
as
(
	select *
	from Posts
	where Score >= 20
)
	with check option
go

update vw_QualityPosts 
set Score = 15
where Id = 4; -- invalid

select * from vw_QualityPosts;
--Question 09 : 
--Create a complex view that shows comprehensive post information 
-- including post details, author information, and comment count. 
-- Include: PostId, Title, Score, AuthorName, AuthorReputation, CommentCount. 
go
create or alter view vw_PostInfo
as
(
	select p.Id as PostId,
			p.Title as PostTitle,
			u.DisplayName as AuthorName,
			COUNT(c.Id) as CommentCount
	from Users u
	join Posts p on p.OwnerUserId = u.Id
	join Comments c on c.PostId = p.Id 
	group by p.Id ,
			p.Title ,
			u.DisplayName
)
go

select * from vw_PostInfo where PostId = 4;


--Question 10 : 
--Create a view that shows badge statistics per user. 
-- Include: UserId, DisplayName, Reputation, total badge count,
-- and a list of unique badge names (comma-separated if possible, or just the count for simplicity). 
-- Name the view: vw_UserBadgeStats . 
go
create or alter view vw_UserBadgeStats
as
(
	select u.Id as UserId,
			u.DisplayName,
			u.Reputation,
			COUNT(b.Id) | ' ' | b.Name as BadgesCount
	from Users u
	join Badges b on b.UserId = u.Id
	group by u.Id, u.DisplayName, u.Reputation, b.Name
)
go
select * from vw_UserBadgeStats;

--Question 11 : 
--Create a view that shows only active users (those who have 
-- posted in the last 365 days from today, or have a reputation > 1000). -
-- Include: UserId, DisplayName, Reputation, LastActivityDate 
-- Name the view: vw_ActiveUsers. 

--Question 12 : 
--Create an indexed view that calculates total views and average 
-- score per user from their posts.
-- Include: UserId, TotalPosts, TotalViews, AvgScore
-- Name the view: vw_UserPostMetrics 
-- Create a unique clustered index on UserId. 
--Question 13 : 
--Create a view that categorizes posts based on their score ranges. 
-- Categories: 'Excellent' (>= 100), 'Good' (50-99), 'Average' (10-49), 
--'Low' (< 10) - Include: PostId, Title, Score, Category 
-- Name the view: vw_PostsByCategory