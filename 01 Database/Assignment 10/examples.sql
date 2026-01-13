--=================================================================
---------------------------- Views --------------------------------
--=================================================================
-- Simple View
--=================================================================
-- Example 01 : User Summary View
-- Shows basic user information With High Reputation
Go

Create Or Alter View V_UserWithHighReputationSummary
As
	Select Id As UserId, DisplayName, Reputation As UserReputation, Location,
	       UpVotes, DownVotes, CreationDate
	From Users
	Where Reputation > 5000

Go

Select *
From V_UserWithHighReputationSummary
Where UserReputation > 1000

-------------------------------------------------------------------
-- Example 02 : Post Basic Info View
Go

Create Or Alter View V_PostBasicInfo(PostId, PostTitle, PostScore, PostViewCount, PostCreationDate, PostAuthorId)
As
	Select Id, Title, Score, ViewCount, CreationDate, OwnerUserId
	From Posts
	Where Title is not null

Go

Select *
From V_PostBasicInfo
Where PostScore > 50

--=================================================================
-- Complex View 
-- Views with JOINs, calculations, and aggregations
--=================================================================
-- Example 01 : Post with Author Details

Go
Create Or Alter View V_PostWithAuthor(PostId, PostTitle, PostScore, PostDate, AuthorName, AuthorReputation, PostAgeInDays, PostQuality)
As
	Select P.Id, P.Title, P.Score, P.CreationDate, U.DisplayName, U.Reputation,
		   DATEDIFF(DAY, P.CreationDate, GETDATE()),
		   Case
			When P.Score >= 50 Then 'Excellent'
			When P.Score >= 20 Then 'Good'
			When P.Score >= 5 Then 'Average'
			Else 'Low'
		   End
	From Posts P
	Join Users U On P.OwnerUserId = U.Id
	Where P.Title is not null

Go
Select *
From V_PostWithAuthor
Where PostQuality = 'Excellent'

-------------------------------------------------------------------
-- Example 02 : Top Contributors by Month
--=================================================================
Go
Create Or Alter View V_MonthlyTopContributers(UserId, UserName, PostYear, PostMonth, PostsInMonth, AVGScoreInMonth, TotalViewsPerMonth)
As
	Select U.Id, U.DisplayName, YEAR(P.CreationDate), MONTH(P.CreationDate),
	       COUNT(P.Id), AVG(P.Score), SUM(P.ViewCount)
	From Users U
	Join Posts P On U.Id = P.OwnerUserId
	Where P.CreationDate is not null and P.Title is not null
	Group By U.Id, U.DisplayName, YEAR(P.CreationDate), MONTH(P.CreationDate)

Go
Select *
From V_MonthlyTopContributers
Where PostYear = 2010 And PostMonth = 12
Order By PostsInMonth Desc

--=================================================================
-- Indexed View (MATERIALIZED VIEW)
--=================================================================
-- Example 01 : Post Comment Statistics
-- Pre-calculates comment counts and scores per post
Go
Create Or Alter View V_PostCommentStats
With SchemaBinding
As
	Select PostId, COUNT_BIG(*) As CommentCount, Sum(ISNULL(Score, 0)) As TotalCommentScore
	       --Invalid , AVG(Score) As AVGCommentScore
	From dbo.Comments
	Group By PostId

Go

Create Unique Clustered Index IX_PostCommentStats
On V_PostCommentStats(PostId)

Select *
From V_PostCommentStats
Where CommentCount > 10

-------------------------------------------------------------------
-- Example 02 : User Badge Summary
-- Pre-calculates badge statistics per user
Go
Create Or Alter View V_UserBadgeSummary
With SchemaBinding
As
	Select UserId, COUNT_BIG(*) As BadgeCount
	From dbo.Badges
	Group By UserId

Go

Create Unique Clustered Index IX_UserBadge
On V_UserBadgeSummary(UserId)


Select *
From V_UserBadgeSummary
Where BadgeCount > 50

--=================================================================
-- Partitioned View 
-- Combines data from multiple tables (horizontal partitioning)
--=================================================================
Create Table Users_HighRep(
	Id int Primary key,
	DisplayName NVarchar(50),
	Reputation int Check(Reputation >= 5000),
	Location varchar(200),
	CreationDate DateTime
)

Create Table Users_MediumRep(
	Id int Primary key,
	DisplayName NVarchar(50),
	Reputation int Check(Reputation >= 1000 And Reputation < 5000),
	Location varchar(200),
	CreationDate DateTime
)

Create Table Users_LowRep(
	Id int Primary key,
	DisplayName NVarchar(50),
	Reputation int Check(Reputation < 1000),
	Location varchar(200),
	CreationDate DateTime
)

Insert Into Users_HighRep
Select Id, DisplayName, Reputation, Location, CreationDate
From Users
Where Reputation >= 5000

Insert Into Users_MediumRep
Select Id, DisplayName, Reputation, Location, CreationDate
From Users
Where Reputation >= 1000 And Reputation < 5000

Insert Into Users_LowRep
Select Id, DisplayName, Reputation, Location, CreationDate
From Users
Where Reputation < 1000

-- Example 01 : All Users Partitioned
-- Combines all user partitions into single logical view
Go
Create Or Alter View V_AllUsersPartitions
As
	Select * From Users_HighRep
	Union All
	Select * From Users_MediumRep
	Union All
	Select * From Users_LowRep

Go

Select * 
From V_AllUsersPartitions
Where Reputation > 3000

-------------------------------------------------------------------
-- Example 02 : Filtered User Partitions
-- Shows only active users from each partition
Go
Create Or Alter View V_ActiveUsersPartitions
With Encryption
As
	Select *, 'High' As ReputationLevel From Users_HighRep
	Where Location is not null
	Union All
	Select *, 'Medium' As ReputationLevel From Users_MediumRep
	Where Location is not null
	Union All
	Select *, 'Low' As ReputationLevel From Users_LowRep
	Where Location is not null

Go
Select *
From V_ActiveUsersPartitions
Where ReputationLevel = 'High'

--=================================================================
-- Updatable Views
-- Views that allow INSERT, UPDATE, DELETE operations
--=================================================================

-- Example 01: Simple Updatable User View
-- Allows modifications to user display name and location
Go 
Create Or Alter View V_EditableUserInfo
As
	Select Id, DisplayName, Location, Reputation
	From Users

Go
Select *
From V_EditableUserInfo
Where Id = 1

Update V_EditableUserInfo
Set Location = 'London'
Where Id = 1

--=================================================================
-- VIEW WITH CHECK OPTION
-- Ensures that modifications through view meet WHERE criteria
--=================================================================
-- Example 02 : High Reputation Users Only
-- Only allows viewing and modifying users with reputation > 1000
Go
Create Or Alter View V_HighReputationUsers
As
	Select Id, DisplayName, Reputation, Location, UpVotes, DownVotes
	From Users
	Where Reputation > 1000
	With Check Option

Go
Select *
From V_HighReputationUsers
Where Id = 2

Update V_HighReputationUsers
Set UpVotes += 10
Where Id = 2

Update V_HighReputationUsers
Set Reputation = 500
Where Id = 2

-------------------------------------------------------------------
-- Example 03 : Active Posts Only
-- Only allows viewing and modifying posts with Score > 0
Go
Create Or Alter View V_ActivePosts
With Encryption
As
	Select P.Id As PostId, U.DisplayName, P.Title, P.Score, P.ViewCount
	From Posts P
	Join Users U On P.OwnerUserId = U.Id
	Where P.Score > 0 And P.Title is not null
	With Check Option

Go
Select *
From V_ActivePosts
Where Score > 20

Update V_ActivePosts
Set Score += 5
Where PostId = 130032

Update V_ActivePosts
Set Score = -1
Where PostId = 130032

Update V_ActivePosts
Set Score += 5, DisplayName = 'Omar'
Where PostId = 130032