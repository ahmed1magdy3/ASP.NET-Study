-- STORED PROCEDURES 
-- ============================================
-- PART 1: BASIC STORED PROCEDURES
-- ============================================
-- EXAMPLE 1: Get top users by reputation
-----------------------------------------------
Go
Create Or Alter Procedure GetTopUsers
As
Begin
	Select Top(10) Id, DisplayName, Reputation, Location
	From Users
	Order By Reputation Desc
End

Go

Exec GetTopUsers

-----------------------------------------------
-- EXAMPLE 2: Get summary statistics
-----------------------------------------------
Go
Create Or Alter Procedure GetDatabaseStats
As
Begin
	-- User Stats
	Select Count(*) As TotalUsers,
		   AVG(Reputation) As AVGReputation,
		   MAX(Reputation) As MaxReputation
	From Users

	-- Post Stats
	Select COUNT(*) As TotalPosts,
	       AVG(Score) As AVGScore
	From Posts

	-- Badge Stats
	Select COUNT(*) As TotalBadges,
		   COUNT(Distinct UserId) As UsersWithBadges
	From Badges

End

Go

Exec GetDatabaseStats

-- ============================================
-- PART 2: STORED PROCEDURE PARAMETERS
-- Input, Output, and Input/Output Parameters
-- ============================================
-- INPUT PARAMETERS
-- ============================================
-- EXAMPLE 1: Get user details by ID (Input parameter)
Go
Create Or Alter Procedure GetUserById @UserId int
As
Begin
	-- User Data
	Select Id, DisplayName, Reputation, Location, CreationDate
	From Users
	Where Id = @UserId

	-- User Posts
	Select Id As PostId, Title, Score, ViewCount
	From Posts
	Where OwnerUserId = @UserId And Title is not null
	Order By Score Desc
End

Go

Exec GetUserById @UserId = 1;
Execute GetUserById 2;

-- EXAMPLE 2: Search posts by keyword and minimum score (Multiple Input parameters)
Go
Create Or Alter Procedure SearchPosts @Keyword nvarchar(100), @MinScore int = 0
As
Begin
	Select Id, Title, Score, ViewCount, CreationDate
	From Posts
	Where Title like '%' + @Keyword + '%' And Score >= @MinScore
	Order By Score Desc
End

Go

Exec SearchPosts 'SQL', 10;
Exec SearchPosts @Keyword = 'SQL', @MinScore = 50;
Exec SearchPosts @MinScore = 50, @Keyword = 'C#';
Exec SearchPosts @Keyword = 'Database';
--Invalid Exec SearchPosts @MinScore = 50;

-- ============================================
-- OUTPUT PARAMETERS
-- ============================================
-- EXAMPLE 3 : Get user statistics with output parameters
Go
Create Or Alter Procedure GetUserStats @UserId int, @PostCount int output,
@CommentCount int output, @BadgeCount int output, @AvgPostScore decimal(10,2) output
As
Begin
	-- Get Post Count And AVG Score
	Select @PostCount = COUNT(*), @AvgPostScore = AVG(Score)
	From Posts
	Where OwnerUserId = @UserId

	-- Get Comment Count
	Select @CommentCount = COUNT(*)
	From Comments
	Where UserId = @UserId

	-- Get Badge Count
	Select @BadgeCount = COUNT(*)
	From Badges
	Where UserId = @UserId

	Set @AvgPostScore = ISNULL(@AvgPostScore, 0);
	Set @PostCount = ISNULL(@PostCount, 0);
	Set @CommentCount = ISNULL(@CommentCount, 0);
	Set @BadgeCount = ISNULL(@BadgeCount, 0);
End

Go
Declare @Posts int, @Comments int, @Badges int, @AvgScore decimal(10,2)
Exec GetUserStats @UserId = 1, @PostCount = @Posts output, @CommentCount = @Comments output, @BadgeCount = @Badges output, @AvgPostScore = @AvgScore output;
Select @Posts, @Comments, @Badges, @AvgScore

-- ============================================
-- PART 3: ERROR HANDLING IN STORED PROCEDURES
-- Using TRY...CATCH blocks
-- ============================================
-- EXAMPLE 1: Safe user lookup with error handling
Go
Create Or Alter Procedure GetUserSafely @UserId int
As 
Begin
	Begin Try
		-- Check if User Exists
		If Not Exists (select 1 from Users where Id = @UserId)
		Begin
			RaisError('User With Id = %d does not exist', 16, 1, @UserId) with log
		End
		-- Get User Details
		Select Id, DisplayName, Reputation, Location
		From Users
		Where Id = @UserId

		Print 'User Retrieved Successfully'
	End Try
	Begin Catch
		-- Error Handling
		Select ERROR_NUMBER() As ErrorNumber,
			   ERROR_MESSAGE() As ErrorMessage,
			   ERROR_SEVERITY() As ErrorServerity,
			   ERROR_STATE() As ErrorState,
			   ERROR_LINE() As ErrorLine
		
		Print 'An Error Occurred while retrieving user'
	End Catch
End

Go
Exec GetUserSafely @UserId = 1; -- Success
Exec GetUserSafely @UserId = 9999999;

-- ============================================
-- PART 4: DML WITH STORED PROCEDURES
-- INSERT, UPDATE, DELETE operations
-- ============================================

-- Setup: Create a test table for demonstrations
Create Table UserActivity(
	ActivityId int Primary Key Identity(1,1),
	UserId int Not null,
	ActivityType varchar(50),
	ActivityDate DateTime Default Getdate(),
	Description nvarchar(500),
	Score int Default 0
)

-- INSERT OPERATIONS

-- EXAMPLE 1: Insert new activity record
Go
Create Or Alter Procedure AddUserActivity @UserId int, @ActivityType varchar(50), @Description nvarchar(500), @ActivityId int Output
As
Begin
	Set NoCount On
	Begin Try
		Begin Transaction
		-- Validate User Exist
		If Not Exists (Select 1 From Users Where Id = @UserId)
		Begin
			RaisError('User does not exist', 16, 1)
		End

		-- Insert Activity
		Insert Into UserActivity(UserId, ActivityType, Description)
		Values(@UserId, @ActivityType, @Description)

		-- Get The New Activity Id
		Set @ActivityId = SCOPE_IDENTITY()
		Commit Transaction
		Select 'Activity Added Successfully' As Result, @ActivityId As NewActivityId

	End Try
	Begin Catch
		If @@TRANCOUNT > 0
			Rollback Transaction

		Select 'Error: ' + ERROR_MESSAGE() As Result
		Set @ActivityId = -1
	End Catch
End

Go
Declare @NewId int
Exec AddUserActivity @UserId = 500, @ActivityType = 'Post Created', @Description = 'User Created New Post about Databases', @ActivityId = @NewId Output;
Select @NewId As NewActivityId

Select *
From UserActivity

-- UPDATE OPERATIONS

-- EXAMPLE 2 : Update activity score
Go
Create Or Alter Procedure UpdateActivityScore @ActivityId int, @NewScore int, @UpdatedBy int = Null
As
Begin
	Set NoCount On
	Begin Try
		-- Check if Activity exist
		If Not Exists (Select 1 from UserActivity Where ActivityId = @ActivityId)
		Begin
			RaisError('Activity With Id %d does not exist', 16, 1, @ActivityId)
		End

		-- Update Score
		Update UserActivity
		Set Score = @NewScore, ActivityDate = GETDATE()
		Where ActivityId = @ActivityId

		Select 'Activity Updated Successfully' As Result, @ActivityId As ActivityId, @NewScore As NewScore
	End Try
	Begin Catch
		Select 'Error: ' + ERROR_MESSAGE() As Result
	End Catch
End

Go
Exec UpdateActivityScore @ActivityId = 2, @NewScore = 10;

Select *
From UserActivity

-- DELETE OPERATIONS

-- EXAMPLE 3: Delete old activities
Go
Create Or Alter Procedure DeleteOldActivities @DaysOld int, @DeleteCount int Output
As
Begin
	Set NoCount On
	Begin Try
		Begin Transaction
		Declare @CutOffDate DateTime
		Set @CutOffDate = DATEADD(Day, - @DaysOld, GETDATE())

		-- Delete Old Activities
		Delete From UserActivity
		Where ActivityDate < @CutOffDate

		Set @DeleteCount = @@ROWCOUNT
		Commit Transaction
		Select 'Activities deleted successfully' As Result, @DeleteCount As RocordsDeleted, @CutOffDate As CutOffDate
	End Try
	Begin Catch
		If @@TRANCOUNT > 0
			Rollback Transaction

		Select 'Error: ' + ERROR_MESSAGE() As Result
		Set @DeleteCount = -1
	End Catch
End

Go
Declare @Deleted int
Exec DeleteOldActivities @DaysOld = 365, @DeleteCount = @Deleted Output
Select @Deleted As DeletedRecords

-- ============================================
-- PART 4: INSERT BASED ON EXECUTE
-- Using EXECUTE results to insert data
-- ============================================
-- EXAMPLE 1: Create summary table from procedure results
-- First, create a stored procedure that returns data
Go
Create Or Alter Procedure GetActiveUsersSummary @MinReputation int
As
Begin
	Select U.Id As UserId, U.DisplayName, U.Reputation, Count(P.Id) As PostCount, count(B.Id) As BadgeCount
	From Users U
	Left Join Posts P On U.Id = P.OwnerUserId
	Left Join Badges B On U.Id = B.UserId
	Where U.Reputation >= @MinReputation
	Group By U.Id, U.DisplayName, U.Reputation
End


-- Create destination table
Create Table ActiveUsersSummary(
	UserId int,
	DisplayName varchar(100),
	Reputation int,
	PostCount int,
	BadgeCount int,
	CreationDate DateTime Default GetDate()
)

-- Insert results from stored procedure into table
Insert Into ActiveUsersSummary(UserId, DisplayName, Reputation, PostCount, BadgeCount)
Exec GetActiveUsersSummary @MinReputation = 5000;

-- Verify the insert
Select *
From ActiveUsersSummary