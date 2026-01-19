--➢ Part 01  Stored Procedure 
--QUESTION 1 
--Create a stored procedure named sp_GetRecentBadges that retrieves all badges earned by 
--users within the last N days. 
-- The procedure should accept one input parameter @DaysBack (INT) to determine how many 
--days back to search. 
-- Test the procedure using different values for the number of days. 
 go
 create or alter procedure sp_GetRecentBadges @DaysBack int
 as
	select b.Id,b.Name, b.Date
	from Badges b
	where b.Date > DATEADD(DAY,-@DaysBack,GETDATE())
go

exec sp_GetRecentBadges @DaysBack = 10;
exec sp_GetRecentBadges @DaysBack = 10000;


--QUESTION 2 
--Create a stored procedure named sp_GetUserSummary that retrieves summary statistics for a 
--specific user. 
-- The procedure should accept @UserId as an input parameter and return the following values 
--as output parameters: 
--● Total number of posts created by the user 
--● Total number of badges earned by the user 
--● Average score of the user’s posts 
 
 go
create or alter procedure sp_GetUserSummary @UserId int,
											@PostsCount int output,
											@badgesCount int output,
											@AVG_Score int output
as
	select @PostsCount = count(Id),
			@AVG_Score = AVG(Score)
	from Posts
	where OwnerUserId = @UserId;

	select @badgesCount = COUNT(Id)
	from Badges
	where UserId =  @UserId;
 go

declare @UserId int = 1
declare @Posts int 
declare @badges int 
declare @Score int 

exec sp_GetUserSummary @UserId = @UserId, 
						@PostsCount = @Posts output,
						@badgesCount = @badges output,
						@AVG_Score = @Score output

select @Posts,@badges,@Score;
 
--QUESTION 3 
--Create a stored procedure named sp_SearchPosts that searches for posts based on: 
--● A keyword found in the post title 
--● A minimum post score 
--The procedure should accept @Keyword as an input parameter and @MinScore as an 
--optional parameter with a default value of 0. 
--The result should display matching posts ordered by score. 
go
create or alter procedure sp_SearchPosts @Keyword varchar(50),
										 @MinScore int = 0
as
	select Title, Score
	from Posts
	where Title like '%' + @Keyword + '%'
		and Score  >= @MinScore
	order by Score desc

go

exec sp_SearchPosts @Keyword = 'sql'
exec sp_SearchPosts @Keyword = 'sql', @MinScore = 1000;

--QUESTION 3 
--Create a stored procedure named sp_GetUserOrError that retrieves user details by user ID. 
--If the specified user does not exist, the procedure should raise a meaningful error. 
--Use TRY…CATCH for proper error handling. 

go
create or alter procedure sp_GetUserOrError @UserId int
as
begin

	begin try
		if not exists(select 1 from Users where Id = @UserId)
		begin
            raiserror('User does not exist', 16, 1);
			return;
        end 

		select DisplayName,Reputation,CreationDate
		from Users
		where Id = @UserId

	end try

	begin catch
		Select ERROR_NUMBER() As ErrorNumber,
			   ERROR_MESSAGE() As ErrorMessage,
			   ERROR_SEVERITY() As ErrorServerity,
			   ERROR_STATE() As ErrorState,
			   ERROR_LINE() As ErrorLine
		
		Print 'An Error Occurred while retrieving user'
	end catch
end
go

exec sp_GetUserOrError @UserId = -5

--QUESTION 4 
--Create a stored procedure named sp_AnalyzeUserActivity that: 
--● Calculates an Activity Score for a user using the formula: 
--Reputation + (Number of Posts × 10) 
--● Returns the calculated Activity Score as an output parameter 
--● Returns a result set showing the user’s top 5 posts ordered by score 
go
create or alter procedure sp_AnalyzeUserActivity @UserId int,
												 @Activity_Score int output
as 
	declare @Posts int
	declare @Repu int

	select @Posts = COUNT(Id)
	from Posts p
	where p.OwnerUserId = @UserId

	select @Repu = Reputation
	from Users
	where Id = @UserId

	set @Activity_Score = @Repu + (@Posts * 10);

	select top(5) Title, Score 
	from Posts
	where OwnerUserId = @UserId
	order by Score desc

go

declare @Active_Score int;
exec sp_AnalyzeUserActivity @UserId = 5, @Activity_Score = @Active_Score output;
select @Active_Score

--QUESTION 5 
--Create a stored procedure named sp_GetReputationInOut that uses a single input/output 
--parameter. 
--The parameter should initially contain a UserId as input and return the corresponding user 
--reputation as output.


go
create or alter procedure sp_GetReputationInOut @param int output
as
	select @param = Reputation
	from Users
	where Id = @param
go

declare @repu int = 1
exec sp_GetReputationInOut  @repu  output
select @repu