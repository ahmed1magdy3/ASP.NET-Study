-- ============================================
-- UNION FAMILY
-- Combining result sets from multiple queries
-- ============================================

-- Example 1: UNION - Removes duplicate rows
-- Scenario: Get all active users (either high reputation OR many posts)
-- Users With Reputation More Than 5000
-- Users With Posts More Than 20 
-- Display Id , DisplayName , Reputation 
Select Id, DisplayName, Reputation
From Users
Where Reputation > 5000
Union
Select U.Id, U.DisplayName, U.Reputation
From Users U
Inner Join Posts P On U.Id = P.OwnerUserId
Group By U.Id, U.DisplayName, U.Reputation
Having Count(P.Id) > 20

-- Example 2: UNION ALL - Keeps all rows including duplicates
-- Scenario: Get all active users (either high reputation OR many posts)
-- Users With Reputation More Than 5000
-- Users With Posts More Than 20
-- Display Id , DisplayName , Reputation 
-- Note (no duplicate removal)
Select Id, DisplayName, Reputation
From Users
Where Reputation > 5000
Union All
Select U.Id, U.DisplayName, U.Reputation
From Users U
Inner Join Posts P On U.Id = P.OwnerUserId
Group By U.Id, U.DisplayName, U.Reputation
Having Count(P.Id) > 20

-- Example 3: INTERSECT - Common rows in both queries
-- Scenario: Get all active users (BOTH high reputation AND many posts)
-- Users With Reputation More Than 5000
-- Users With Posts More Than 20
-- Display Id , DisplayName , Reputation 
Select Id, DisplayName, Reputation
From Users
Where Reputation > 5000
Intersect
Select U.Id, U.DisplayName, U.Reputation
From Users U
Inner Join Posts P On U.Id = P.OwnerUserId
Group By U.Id, U.DisplayName, U.Reputation
Having Count(P.Id) > 20


-- Example 4: EXCEPT - Rows in first query but NOT in second
-- Scenario: Get all active users (with high reputation but NOT many posts)
-- Users With Reputation More Than 5000
-- Users With Posts More Than 20
-- Display Id , DisplayName , Reputation
Select Id, DisplayName, Reputation
From Users
Where Reputation > 5000
Except
Select U.Id, U.DisplayName, U.Reputation
From Users U
Inner Join Posts P On U.Id = P.OwnerUserId
Group By U.Id, U.DisplayName, U.Reputation
Having Count(P.Id) > 20

-- ============================================
-- CTE (Common Table Expression) - Named temporary result set
-- ============================================
-- Example 1: Use CTE to find users above average reputation
-- Then Display DisplayName  , Reputation and AvgRep

With AVGReputation As(
	Select AVG(Reputation) As AVGRep
	From Users
)
Select U.DisplayName, U.Reputation, AR.AVGRep
From Users U Cross Join AVGReputation AR
Where U.Reputation > AR.AVGRep

-- Using SubQuery
Select U.DisplayName, U.Reputation, (Select AVG(Reputation) As AVGRep From Users) As AVGRep
From Users U 
Where U.Reputation > (Select AVG(Reputation) As AVGRep From Users)

-- Example 2 : Use CTE to calculate post statistics then filter
-- Then Display DisplayName , Reputation,  TotalPosts , AvgScore and TotalViews

With PostStats As (
	Select OwnerUserId, COUNT(*) TotalPosts, AVG(Score) AVGScore, Sum(ViewCount) TotalViews
	From Posts
	Group By OwnerUserId
)
Select U.DisplayName, U.Reputation, PS.TotalPosts, PS.AVGScore, PS.TotalViews
From Users U 
Inner Join PostStats PS On U.Id = PS.OwnerUserId
Where PS.TotalPosts > 10

-- Example 3 : Multiple CTEs - Calculate user's TotalPosts and TotalBadges 
-- Then Display DisplayName , Reputation , TotalPosts and TotalBadges For Each User

With UserPosts As (
	Select OwnerUserId, Count(*) As TotalPosts
	From Posts
	Group By OwnerUserId
), 
UserBadges As (
	Select UserId, Count(*) As TotlBadges
	From Badges
	Group By UserId
)
Select U.DisplayName, U.Reputation,
	   ISNULL(UP.TotalPosts, 0) As TotalPosts,
	   ISNULL(UB.TotlBadges, 0) As TotalBadges
From Users U
Left Join UserPosts UP On U.Id = UP.OwnerUserId
Left Join UserBadges UB On U.Id = UB.UserId;

-- ============================================
-- RECURSIVE CTE - References itself
-- ============================================

-- Example 1 : Generate numbers from 1 to 10 using recursive CTE
-- NumberSequence -> [1 2 3 4 5 6 7 8 9 10]

With NumberSequence As (
	Select 1 As Number
	Union All
	Select Number + 1
	From NumberSequence
	Where Number < 10
)
Select Number
From NumberSequence;

-- ============================================
-- SELECT INTO
-- Creating new tables from query results
-- ============================================
-- Example 1 : Basic SELECT INTO - Copy entire table
-- Scenario: Create a backup of Users table

Select *
Into UsersBackup
From Users

-- Verify
Select COUNT(*)
From UsersBackup

-- Example 2 : SELECT INTO with filtering
-- Scenario: Create table of users With High Reputation only
Select Id, DisplayName, Reputation, Location
Into TopUsers
From Users
Where Reputation > 10000

-- Verify
Select *
From TopUsers
Order By Reputation Desc

-- Example 3: SELECT INTO empty table (template)
-- Scenario: Create table structure without data
Select *
Into PostsCopy
From Posts
Where 1 = 0

-- Verify
Select Count(*) 
From PostsCopy

-- ============================================
-- USER-DEFINED FUNCTIONS (UDFs)
-- Custom reusable functions
-- ============================================
-- SCALAR FUNCTIONS (Returns Single Value)
-- ============================================

-- SCALAR EXAMPLE 1: Calculate Reputation Level
Go
Create Or Alter Function GetReputationLevel(@Reputation int)
Returns Varchar(20)
As
Begin
	-- Body 
	Declare @ReputationLevel varchar(20)
	If @Reputation >= 10000
		Set @ReputationLevel = 'Expert'
	Else If @Reputation >= 5000
		Set @ReputationLevel = 'Advanced'
	Else If @Reputation >= 1000
		Set @ReputationLevel = 'Intermediate'
	Else
		Set @ReputationLevel = 'Beginner'
	Return @ReputationLevel
End
Go

-- Test Scalar Function 1
Select DisplayName, Reputation, dbo.GetReputationLevel(Reputation) As ReputationLevel
From Users
Where Id Between 1 And 10

-- SCALAR EXAMPLE 2: Calculate Days Since Post Creation
Go
Create Or Alter Function dbo.CalculateDaysSincePostCreation(@CreationDate Date)
Returns int
As
Begin
	Declare @Days int
	Set @Days = DATEDIFF(DAY, @CreationDate, GETDATE())
	Return @Days
End
Go
-- Test Scalar Function 2
Select Title, CreationDate, dbo.CalculateDaysSincePostCreation(CreationDate) As Days
From Posts
Where Title is not null
Order By CreationDate Desc

-- SCALAR EXAMPLE 3: Calculate User Activity Score
-- Formula: (Reputation * 0.5) + (UpVotes * 2) + (DownVotes * -1)
Go
Create Or Alter Function dbo.CalculateUserActivityScore(@Reputation int, @Upvotes int, @DownVotes int)
Returns Decimal(10,2)
As
Begin
	Declare @Score Decimal(10,2)
	Set @Score = (@Reputation * 0.5) + (@Upvotes * 2) + (@DownVotes * -1)
	Return @Score
End
Go
-- Test Scalar Function 3
Select DisplayName, Reputation, UpVotes, DownVotes, dbo.CalculateUserActivityScore(Reputation, UpVotes, DownVotes) As Score
From Users
Where Reputation > 1000
Order By Score Desc


-- ============================================
-- INLINE TABLE-VALUED FUNCTIONS (Single SELECT)
-- Best Performance - Acts like a view with parameters
-- ============================================

-- INLINE TVF EXAMPLE 1: Get User's Posts Above Score Threshold
Go
Create Or Alter Function GetUserHighScorePosts(@UserId int, @MinScore int)
Returns Table
As
	Return(
		Select Id As PostId, Title, Score, ViewCount, CreationDate, PostTypeId
		From Posts
		Where OwnerUserId = @UserId And Score >= @MinScore
	)
Go

-- Test Inline TVF 1
Select * From GetUserHighScorePosts(1, 50)
Select * From GetUserHighScorePosts(2, 70)

-- INLINE TVF EXAMPLE 2: Get Comments by Post with Score Filter
Go
Create Or Alter Function GetPostComments(@PostId int, @MinCommentScore int)
Returns Table
As
	Return(
		Select C.Id As CommentId, C.Text As CommentText, C.Score As CommentScore,
			   U.DisplayName As Commenter, U.Reputation As CommenterReputation
		From Comments C
		Inner Join Users U On C.UserId = U.Id
		Where C.PostId = @PostId And C.Score >= @MinCommentScore
	)
Go

-- Test Inline TVF 2
Select * From dbo.GetPostComments(47626, 0)

-- INLINE TVF EXAMPLE 3: Get User's Badges by Date Range
Go
Create Or Alter Function dbo.GetUserBadgesByDateRange(@UserID int, @StartDate DateTime, @EndDate DateTime)
Returns Table
As
	Return(
		Select Id As BadgeId, Name As BadgeName, Date As EarnedDate,
				DATEDIFF(DAY, @StartDate, Date) As EarnedAfter
		From Badges
		Where UserId = @UserID And Date Between @StartDate And @EndDate
	)
Go

-- Test Inline TVF 3
Select * From dbo.GetUserBadgesByDateRange(1, '2010/01/01', '2010/12/31')
Select * From dbo.GetUserBadgesByDateRange(5, '2010/05/01', '2010/12/31')

-- ============================================
-- MULTI-STATEMENT TABLE-VALUED FUNCTIONS
-- Can use multiple queries and complex logic
-- ============================================

-- MULTI-STATEMENT TVF EXAMPLE 1: Get Comprehensive User Profile
-- Get UserId , DisplayName , Reputation , Location , PostCount , CommentCount , 
-- BadgeCount , AvgPostScore , TotalViews , ReputationLevel , AccountAgeInDays
-- For User By UserId 
Go 
Create Or Alter Function dbo.GetUserProfile(@UserId int)
Returns @UserProfile Table(
UserId int,
DisplayName nvarchar(50),
Reputation int,
Location nvarchar(100),
PostCount int,
CommentCount int,
BadgeCount int,
AvgPostScore decimal(10,2),
TotalViews int,
ReputationLevel varchar(20),
AccountAgeInDays int
)
As
Begin
	Declare @PostCount int, @CommentCount int, @BadgeCount int
	Declare @AvgPostScore decimal(10,2), @TotalViews int

	-- Calc Posts Stats
	Select @PostCount = COUNT(*), @AvgPostScore = AVG(Score), @TotalViews = Sum(ViewCount)
	From Posts
	Where OwnerUserId = @UserId

	-- Calc Comment Count
	Select @CommentCount = COUNT(*)
	From Comments
	Where UserId = @UserId

	-- Calc Badge Count
	Select @BadgeCount = COUNT(*)
	From Badges
	Where UserId = @UserId

	Insert Into @UserProfile
	Select U.Id, U.DisplayName, U.Reputation, U.Location, @PostCount, 
	       @CommentCount, @BadgeCount, @AvgPostScore, @TotalViews, 
		   dbo.GetReputationLevel(Reputation), DATEDIFF(DAY, CreationDate, GETDATE())
	From Users U
	Where U.Id = @UserId
	Return
End
Go

-- Test Multi-Statement TVF 1
Select * From dbo.GetUserProfile(1)
Select * From dbo.GetUserProfile(5)

-- ============================================
-- COMPARISON QUERIES
-- ============================================

-- Using Scalar Function in WHERE clause
-- Get Users With Reputation Level Expert
-- then Display DisplayName, Reputation and ReputationLevel
Select DisplayName, Reputation, dbo.GetReputationLevel(Reputation)
From Users
Where dbo.GetReputationLevel(Reputation) = 'Expert'

-- Using Inline TVF with JOIN
-- Get Users With High Score Posts [20] And Reputation More Than 5000
Select U.DisplayName, U.Reputation, P.PostId, P.Title, P.Score
From Users U Cross Apply dbo.GetUserPostsAboveScore(U.id, 20) P
where U.Reputation > 5000

-- Using Multi-Statement TVF for complex reporting
-- Get User Profile For User With Id 1 
Select *
From dbo.GetUserProfile(1)

-- ============================================
-- CLEANUP DEMO OBJECTS
-- ============================================

/*
-- Drop all demo functions
DROP FUNCTION IF EXISTS dbo.GetReputationLevel;
DROP FUNCTION IF EXISTS dbo.CalculateDaysSincePost;
DROP FUNCTION IF EXISTS dbo.CalculateActivityScore;
DROP FUNCTION IF EXISTS dbo.GetUserHighScorePosts;
DROP FUNCTION IF EXISTS dbo.GetPostComments;
DROP FUNCTION IF EXISTS dbo.GetUserBadgesByDateRange;
DROP FUNCTION IF EXISTS dbo.GetUserProfile;
DROP FUNCTION IF EXISTS dbo.GetPostStatistics;
DROP FUNCTION IF EXISTS dbo.GetUserActivityTimeline;
*/

