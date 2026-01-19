
-- Stored Procedures part2

use StackOverflow2010;

--QUESTION 6 
--Create a stored procedure named sp_UpdatePostScore that updates the score of a post. 
--The procedure should: 
--● Accept a post ID and a new score as input 
--● Validate that the post exists 
--● Use transactions and TRY…CATCH to ensure safe updates 
--● Roll back changes if an error occurs 
go
create or alter procedure sp_UpdatePostScore @PostId int, @newScore int
as  
begin
begin try
	begin transaction
		if not exists (select 1 from Posts where Id = @PostId)
			raiserror ('Post with Id %d is not found',16,1,@PostId)

		update Posts
		set Score = @newScore
		where Id = @PostId;
		commit;

		select 'Updated Successfully';
end try

begin catch
	if @@TRANCOUNT > 0
		rollback

	select  ERROR_MESSAGE() as Error;

end catch
end
go

select Title, Score from Posts where Id = 9; -- oldscore = 1743

exec sp_UpdatePostScore @PostId = 9, @newScore = 1000;

--QUESTION 7 
--Create a stored procedure named sp_GetTopUsersByReputation that retrieves the top N 
--users whose reputation is above a specified minimum value. 
--Then create a permanent table named TopUsersArchive and insert the results returned by the 
--procedure into this table.

go
create or alter procedure sp_GetTopUsersByReputation @N_Users int, @Min_Reputation int
as
begin
begin try
	if @N_Users < 1
		raiserror ('N_Users must be > 0',16,1)

	if @Min_Reputation < 0
		raiserror ('Min_Reputation must be >= 0',16,1)

	select top(@N_Users) Id,DisplayName, Reputation
	from Users
	where Reputation >= @Min_Reputation
	order by Reputation desc;

end try

begin catch
	select ERROR_MESSAGE() as Error;
end catch

end
go

create table TopUsersArchive(
	UserId int,
	Name varchar(100),
	Reputation int
)

insert into TopUsersArchive (UserId, Name, Reputation)
exec sp_GetTopUsersByReputation @N_Users = 5, @Min_Reputation = 1000;

select * from TopUsersArchive;

--QUESTION 8 
--Create a stored procedure named sp_InsertUserLog that inserts a new record into a UserLog table. 
--The procedure should: 
--● Accept user ID, action, and details as input 
--● Return the newly created log ID using an output parameter 

create table UserLog(
	LogId int identity,
	UserId int,
	Action varchar(50),
	Details varchar(200)
)

go
create or alter procedure sp_InsertUserLog @UserId int, @Action varchar(50), @Details varchar(200), @LogId int output
as
begin
begin try	
	if not exists (select 1 from Users where Id = @UserId)
		raiserror ('User doesn''t exist',16,1)

	insert into UserLog (UserId,Action,Details)
	values (@UserId,@Action,@Details);

	set @logId = SCOPE_IDENTITY();

end try

begin catch
	select ERROR_MESSAGE() as Error;
	set @logId = -1;

end catch
end
go

declare @Log_id int;
exec sp_InsertUserLog @UserId = 1, @Action = 'insert', @Details = 'Inserting', @LogId = @Log_id output;
select @Log_id as LogId;


--QUESTION 9 
--Create a stored procedure named sp_UpdateUserReputation that updates a user’s reputation. 
--The procedure should: 
--● Validate that the reputation value is not negative 
--● Validate that the user exists 
--● Return the number of rows affected 
--● Handle errors appropriately 
go
create or alter procedure sp_UpdateUserReputation @UserId int, @new_Reputation int, @RowsAffected int output
as
begin
set nocount on
begin try
	if not exists (select 1 from Users where Id = @UserId)
		raiserror ('UserId %d doesn''t exist',16,1,@UserId)

	if @new_Reputation < 0
		raiserror ('new_Reputation %d must be Positive',16,1,@new_Reputation)

	update Users
	set Reputation = @new_Reputation
	where Id = @UserId;

	select 'Updated Successfully';
	set @RowsAffected = @@ROWCOUNT;

end try
begin catch
	set @RowsAffected = -1;
	select ERROR_MESSAGE() as Error;

end catch
end
go

declare @RowCount int;
exec sp_UpdateUserReputation @UserId = 1, @new_Reputation = 44000, @RowsAffected = @RowCount output; --old_reputation = 44300
select @RowCount as RowsAffected;

select id, reputation from Users where id = 1;

--QUESTION 10 
--Create a stored procedure named sp_DeleteLowScorePosts that deletes all posts with a score 
--less than or equal to a given value. 
--The procedure should: 
--● Use transactions 
--● Return the number of deleted records as an output parameter 
--● Roll back changes if an error occurs 
go
create or alter procedure sp_DeleteLowScorePosts @LowScore int, @RowsAffected int output
as
begin
set nocount on
begin try
	begin transaction
		
		delete Posts
		where Score <= @LowScore;
		commit;

		set @RowsAffected = @@ROWCOUNT;
		select concat (@RowsAffected , ' rows deleted Successfully');

end try
begin catch
	select ERROR_MESSAGE() as Error;
	set @RowsAffected = -1;
	if @@TRANCOUNT > 0
		rollback;
end catch
end
go

declare @RowsCount int;
exec sp_DeleteLowScorePosts @LowScore = -30, @RowsAffected = @RowsCount output;
select @RowsCount as RowsAffected;

--QUESTION 11 
--Create a stored procedure named sp_BulkInsertBadges that inserts multiple badge records for 
--a user. 
--The procedure should: 
--● Accept a user ID 
--● Accept a badge count indicating how many badges to insert 
--● Insert multiple related records in a single operation 
go
create or alter procedure sp_BulkInsertBadges @UserId int, @BadgeCount int
as
begin
begin try
	if not exists (select 1 from Users where Id = @UserId)
		raiserror ('User doesn''t exist',16,1)

	if @BadgeCount < 0
		raiserror ('BadgeCount must be Positive',16,1);


	;with Times as (
	select 1 as n
	union all
	select n+1 from Times where n < @BadgeCount 
	)
	insert into Badges (Name,UserId,Date)
	select concat('Badge ',n), @UserId, GETDATE()
	from Times

end try
begin catch
	select ERROR_MESSAGE() as Error;
end catch
end
go

select COUNT(Id) from Badges where UserId = 1; -- old_value = 155
exec sp_BulkInsertBadges @UserId = 1, @BadgeCount = 5; -- new value = 160

--QUESTION 12 
--Create a stored procedure named sp_GenerateUserReport that generates a complete user 
--report. 
--The procedure should: 
--➢ Call another stored procedure internally to retrieve user statistics 
--➢ Combine user profile data and statistics 
--➢ Return a formatted report including a calculated user level

go
create or alter procedure sp_GenerateUserReport @UserId int
as
begin
-- with Q2  a procedure ( sp_GetUserSummary ) was created, i will execute it
-- and add CommentsCount , reputation and UserLevel
begin try
	if not exists (select 1 from Users where Id = @UserId)
		raiserror ('User doesn''t exist',16,1)

	declare @Posts int;
	declare @Badges int;
	declare @AVGScore int;
	declare @Comments int;
	exec sp_GetUserSummary @UserId = @UserId, @PostsCount = @Posts output, @badgesCount = @Badges output, @AVG_Score = @AVGScore output;
	
	select @Comments = COUNT(*)
	from Comments 
	where UserId = @UserId;

	select DisplayName, 
	Reputation, 
	@Posts as PostsCount,
	@AVGScore as Posts_AVG_Score,
	@Badges as BadgesCount,
	@Comments as CommentsCount,
	case
		when Reputation >= 10000 then  'Expert'
        when Reputation >= 5000  then 'Advanced'
        when Reputation >= 1000  then 'Intermediate'
        else 'Beginner'
	end as UserLevel
	from Users 
	where Id = @UserId;

end try
begin catch
	select ERROR_MESSAGE() as Error;
end catch
end
go

exec sp_GenerateUserReport @UserId = 1;