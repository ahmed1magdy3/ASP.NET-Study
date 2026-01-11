
use StackOverflow2010;
--Question 01 : 
--Retrieve a list of users who meet at least one of these criteria: 
--1. Reputation greater than 8000 
--2. Created more than 15 posts 
--Display UserId, DisplayName, and Reputation. 
--Ensure that each user appears only once in the results. 

select u.Id ,u.DisplayName, u.Reputation
from Users u
where u.Reputation > 8000
union
select u.Id ,u.DisplayName, u.Reputation
from Users u
join Posts p on p.OwnerUserId = u.Id
group by  u.Id ,u.DisplayName, u.Reputation
having COUNT(p.Id) > 15
;


--Question 02 : 
--Find users who satisfy BOTH of these conditions simultaneously: 
--1. Have reputation greater than 3000 
--2. Have earned at least 5 badges 
--Display UserId, DisplayName, and Reputation. 
select u.Id ,u.DisplayName, u.Reputation
from Users u
where u.Reputation > 3000
intersect
select u.Id ,u.DisplayName, u.Reputation
from Users u
join Badges b on b.UserId = u.Id
group by  u.Id ,u.DisplayName, u.Reputation
having count(b.Id) >= 5
;

--Question 03 : 
--Identify posts that have a score greater than 20 but have never 
--received any comments. Display PostId, Title, and Score. 

select p.Id, p.Title, p.Score
from Posts p
where p.Score > 20
except
select p.Id, p.Title, p.Score
from Posts p
join Comments c on c.PostId = p.Id
where p.Score > 20
;
 
--Question 04 : 
--Create a new permanent table called Posts_Backup that stores all posts 
--with a score greater than 10. 
--The new table should include: Id, Title, Score, ViewCount, CreationDate, 
--OwnerUserId. 

select p.Id,p.Title,p.Score,p.ViewCount,p.CreationDate, p.OwnerUserId
into Posts_Backup
from Posts p
where p.Score > 10
;


--Question 05 : 
--Create a new table called ActiveUsers containing users who meet the 
--following criteria: 
--1. Reputation greater than 1000 
--2. Have created at least one post 
--The table should include: UserId, DisplayName, Reputation, Location, 
--and PostCount (calculated). 

select u.Id, u.DisplayName, u.Reputation, u.Location, COUNT(p.Id) as PostCount
into Active_Users
from Users u
join Posts p on p.OwnerUserId = u.Id
group by u.Id, u.DisplayName, u.Reputation, u.Location
having COUNT(p.Id) >= 1
;

--Question 06 : 
--Create a new empty table called Comments_Template that has the 
--exact same structure as the Comments table but contains no data rows. 

select *
into Comments_Template
from Comments
where 1=0
;

--Question 07 : 
--Create a summary table called PostEngagementSummary that 
--combines data from Posts, Users, and Comments tables. 
--The table should include:  PostId, Title, AuthorName, Score, ViewCount 
--CommentCount (calculated), TotalCommentScore (calculated) 
--Include only posts that have received at least 3 comments. 

select p.Id, p.Title, u.DisplayName 'AuthorName', p.Score,p.ViewCount,
		COUNT(c.Id) as 'CommentCount', SUM(c.Score) as 'TotalCommentScore' 
into PostEngagementSummary 
from Posts p
join Users u on u.Id = p.OwnerUserId
join Comments c on c.PostId = p.Id
group by p.Id, p.Title, u.DisplayName, p.Score,p.ViewCount
having COUNT(c.Id) >= 3
;

--Question 08 : 
--Develop a reusable calculation that determines the age of a post in 
--days based on its creation date. 
--Input: CreationDate (DATETIME) 
--Output: Age in days (INTEGER) 
--Test your solution by displaying posts with their calculated ages.

go
create or alter function PostAgeByDays (@CreationDate datetime)
returns int
as
begin
	declare @Age int ;
	set @Age =  DATEDIFF(day,@CreationDate,GETDATE())
	return @Age;
end;
go

select p.Title, p.CreationDate, dbo.PostAgeByDays(p.CreationDate)
from Posts p

--Question 09 : 
--Develop a reusable calculation that assigns a badge level to users based 
--on their reputation and post activity. 
--Inputs: Reputation (INT), PostCount (INT) 
--Output: Badge level (VARCHAR) 
--Logic: 
--'Gold' if reputation > 10000 AND posts > 50 
--'Silver' if reputation > 5000 AND posts > 20 
--'Bronze' if reputation > 1000 AND posts > 5 
--'None' otherwise 

go
create or alter function UserBadgeLevel ( @Reputation int, @PostCount int)
returns varchar(20)
as
begin
	declare @BadgeLevel varchar(20);

	if (@Reputation > 10000 and @PostCount > 50)
		set @BadgeLevel = 'Gold';
	else if (@Reputation > 5000 and @PostCount > 20)
		set @BadgeLevel = 'Silver';
	else if (@Reputation > 1000 and @PostCount > 5)
		set @BadgeLevel = 'Bronze';
	else 
		set @BadgeLevel = 'None'

	return @BadgeLevel;
end;
go

select u.Id ,u.DisplayName, u.Reputation , COUNT(p.Id), dbo.UserBadgeLevel (u.Reputation,COUNT(p.Id))
from Users u
join Posts p on p.OwnerUserId = u.Id
group by u.Id ,u.DisplayName,u.Reputation
;

--Question 10 : 
--Develop a reusable query that retrieves posts created within a specified 
--number of days from today. 
--Input: @DaysBack (INT) - number of days to look back 
--Output: Table with PostId, Title, Score, ViewCount, CreationDate 
--Test with different day ranges (e.g., 30 days, 90 days). 

go
create or alter function PostsDaysBack (@DaysBack int)
returns table
as
	return (
		select p.Id, p.Title, p.Score, p.ViewCount,p.CreationDate
		from Posts p
		where DATEDIFF(day,p.CreationDate,GETDATE()) <= @DaysBack 
	);
go

select *
from dbo.PostsDaysBack(90);

--Question 11 : 
--Develop a reusable query that finds top users from a specific location or 
--all locations based on reputation threshold. 
--Inputs: @MinReputation (INT), @Location (VARCHAR) 
--Output: Table with UserId, DisplayName, Reputation, Location, 
--CreationDate 
--If @Location is NULL, return users from all locations. 
--Test with different parameters. 

go
create or alter function TopUsers (@MinReputation int , @Location varchar(50) = NULL)
returns table
as
 return (
	select u.Id, u.DisplayName, u.Reputation,Location,CreationDate
	from Users u
	where (@Location is null or u.Location = @Location)
	and u.Reputation >= @MinReputation
 );
go

select *
from dbo.TopUsers(1000,DEFAULT);

select *
from dbo.TopUsers(8000,'New York, NY'); 

--Question 12 : 
--Write a query to find the top 3 highest scoring posts for each PostTypeId. 
--Use a subquery or CTE with ROW_NUMBER() and PARTITION BY. 
--Display PostTypeId, Title, Score, and the rank. 

with HighestPosts as(
	select p.PostTypeId,p.Title, p.Score,ROW_NUMBER() over (partition by p.PostTypeId order by p.Score desc) as rank
	from Posts p 
)
select ph.*
from HighestPosts ph
where ph.rank <= 3
;

--Question 13 : 
--Write a query using a CTE to find all users whose reputation is above 
--the average reputation. The CTE should calculate  
--1. the average reputation first. 
--2. Display DisplayName, Reputation, and the average reputation. 

with AvgReputation as(
	select AVG(u.Reputation) as AvgReputation
	from Users u
	)
	select u.DisplayName, u.Reputation, av.AvgReputation 
	from Users u 
	cross join AvgReputation av
	;
--Question 14 : 
--Write a query using a CTE to calculate the total number of posts and 
--average score for each user. Then join with the Users table to display: 
--DisplayName, Reputation, TotalPosts, and AvgScore. 
--Only include users with more than 5 posts. 

with CalculatedPosts as(
	select p.OwnerUserId, COUNT(p.Id) as TotalPosts, AVG(p.Score) AvgScore
	from Posts p
	group by p.OwnerUserId
)
select u.DisplayName, u.Reputation,cp.TotalPosts,cp.AvgScore
from users u
join CalculatedPosts cp on cp.OwnerUserId = u.Id
where cp.TotalPosts > 5
;


--Question 15 : 
--Write a query using multiple CTEs: 
--First CTE: Calculate post count per user 
--Second CTE: Calculate badge count per user 
--Then join both CTEs with Users table to show: 
--DisplayName, Reputation, PostCount, and BadgeCount. 
--Handle NULL values by replacing them with 0. 
with CalculatedPosts as(
	select p.OwnerUserId, COUNT(p.Id) as TotalPosts
	from Posts p
	group by p.OwnerUserId
), 
CalculatedBadge as(
	select b.UserId, COUNT(b.Id) as TotalBadges
	from Badges b
	group by b.UserId
)
select u.DisplayName, u.Reputation, ISNULL(cp.TotalPosts,0), ISNULL(cb.TotalBadges,0)
from Users u
left join CalculatedPosts cp on cp.OwnerUserId = u.Id
left join CalculatedBadge cb on cb.UserId = u.Id
;

--Question 16 : 
--Display the generated numbers. 
--Write a recursive CTE to generate a sequence of numbers from 1 to 20.

with SequenceNumbers as(
	select 1 as number
	union all
	select number + 1
	from SequenceNumbers
	where number < 20
)
select *
from SequenceNumbers
;
