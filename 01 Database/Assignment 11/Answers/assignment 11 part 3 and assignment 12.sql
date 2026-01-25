--➢ Part 02  Trigger 

use StackOverflow2010;

--QUESTION 1 
--Create an AFTER INSERT trigger on the Posts table that logs every new post creation into a 
--ChangeLog table. 
--The log should include: 
--● Table name 
--● Action type 
--● User ID of the post owner 
--● Post title stored as new data 
create table ChangeLog (
	LogId int primary key identity,
	TableName varchar(50),
	ActionType varchar(50),
	UserId int,
	newData varchar(max)

);
go
create or alter trigger trg_NewPost 
on Posts
after insert
as
begin
	set nocount on

	insert into ChangeLog (TableName,ActionType,UserId,newData)
	select 'Posts', 'insert', i.OwnerUserId, 'a new Post is created: ' + ISNULL( CAST(i.Title as varchar(50)),'No Title' ) 
	from inserted i

end
go

Insert into Posts(body, creationDate, LastActivityDate, PostTypeId, Score, ViewCount, Title, OwnerUserId)
Values('body', GETDATE(), GETDATE(), 1, 0, 0, 'test', 1)

select * from ChangeLog;


--QUESTION 2 
--Create an AFTER UPDATE trigger on the Users table that tracks changes to the Reputation column. 
--The trigger should: 
--● Log changes only when the reputation value actually changes 
--● Store both the old and new reputation values in the ChangeLog table 
go
create or alter trigger trg_PostsUpdateReputation
on Users
after update
as
begin
	set nocount on

	if UPDATE(reputation)
	begin
		insert into ChangeLog (TableName, ActionType,UserId,newData)
		select 'Users', 'update', i.Id,
		'Reputation is updated from ' + CAST(d.Reputation as varchar(20)) + ' to ' + cast(i.Reputation as varchar(20))
		from inserted i
		join deleted d on d.Id = i.Id
	end
end
go

update Users
set Reputation = 20
where Id = 1;

select * from ChangeLog;

--QUESTION 3 
--Create an AFTER DELETE trigger on the Posts table that archives deleted posts into a 
--DeletedPosts table. 
--All relevant post information should be stored before the post is removed. 

create table DeletedPosts(
	Id int primary key identity,
	PostId int,
	AcceptedAnswerId int,
	AnserCount int,
	Body varchar(max),
	ClosedDate datetime,
	CommentCount int,
	CummunityOwnedDate datetime,
	CreationDate datetime,
	FavouriteCount int,
	LastActitvityDate datetime,
	LastEditDate datetime,
	LastEditorDisplayName varchar(max),
	LastEditorUserId int,
	OwnerUserId int,
	ParentId int,
	PostTypeId int,
	Score int,
	Tags varchar(max),
	Title varchar(max),
	ViewCount int
);

go
create or alter trigger trg_AfterDeletePost
on Posts
after delete
as
begin
	insert into DeletedPosts 
	select d.Id, d.AcceptedAnswerId, d.AnswerCount, d.Body, d.ClosedDate, d.CommentCount, d.CommunityOwnedDate,
	d.CreationDate, d.FavoriteCount, d.LastActivityDate, d.LastEditDate, d.LastEditorDisplayName, d.LastEditorUserId,
	d.OwnerUserId,d.ParentId,d.PostTypeId,d.Score,d.Tags,d.Title,d.ViewCount
	from deleted d
end
go

delete Posts where id = 9;

select * from DeletedPosts;

--QUESTION 4 
--Create an INSTEAD OF INSERT trigger on a view named vw_NewUsers (based on the Users 
--table). 
--The trigger should: 
--● Validate incoming data 
--● Prevent insertion if the DisplayName is NULL or empty 

go
create or alter view vw_NewUsers
as
	select Id, DisplayName, CreationDate, DownVotes, LastAccessDate, Reputation, UpVotes, Views 
	from Users
	where datediff(day ,CreationDate, GETDATE()) <= 5;
go

create or alter trigger trg_ValidateDisplayName
on vw_NewUsers
instead of insert
as
begin
	if exists (select 1 from inserted where DisplayName is null or DisplayName like '')
	begin
		raiserror('cann''t insert a nullable name',16,1);
		return
	end
	else
	begin
		insert into vw_NewUsers (DisplayName, CreationDate, DownVotes,LastAccessDate,Reputation,UpVotes, Views)
		select i.DisplayName, GETDATE(),0,GETDATE(),0,0,0
		from inserted i
	end
end
go

delete Users where id = 10251168;
insert into vw_NewUsers (DisplayName)
values ('');

select * from vw_NewUsers;

--QUESTION 5 
--Create an INSTEAD OF UPDATE trigger on the Posts table that prevents updates to the Id 
--column. 
--Any attempt to update the Id column should be: 
--● Blocked 
--● Logged in the ChangeLog table 

go
create or alter trigger trg_UpdatePostId
on Posts
instead of update
as
begin
set nocount on
	if UPDATE(Id)
	begin
	begin try
		insert into ChangeLog(TableName, ActionType,UserId, newData)
		select 'Posts', 'update', p.OwnerUserId, 'Blocked Update on PostId' + CAST(i.Id as varchar(20))
		from inserted i
		join Posts p on p.Id = i.Id;

		raiserror('Cann''t update Id',16,1);
		return;
	end try
	begin catch
		select ERROR_message() as error;
	end catch
	end


end
go

update Posts
set id = 131503
where id =67867;

select * from Posts where id = 67867;

select * from ChangeLog;

--QUESTION 6 
--● Add an IsDeleted flag 
--Create an INSTEAD OF DELETE trigger on the Comments table that implements a soft 
--delete mechanism. 
--Instead of deleting records: 
--● Mark records as deleted 
--● Log the soft delete operation 

alter table Comments
add IsDeleted int default 0

go
create or alter trigger trg_deleteComment
on Comments
instead of delete
as
begin
	
	update c
	set c.IsDeleted = 1
	from Comments c
	join deleted d on d.Id = c.Id;

	insert into ChangeLog (TableName, ActionType, UserId)
	select 'Comments','Delete', d.UserId
	from deleted d;

end
go

delete Comments where Id = 25;

select IsDeleted, Text from Comments where Id = 25;

select * from ChangeLog;

--QUESTION 7 
--Create a DDL trigger at the database level that prevents any table from being dropped. 
--All drop table attempts should be logged in the ChangeLog table. 

go
create or alter trigger trg_DDLTableDrop
on database
for drop_table
as
begin
	set nocount on
	declare @EventData xml = EventData();
	declare @TableName varchar(100) = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'varchar(100)');

	insert into ChangeLog (TableName, ActionType)
	values (@TableName, 'Drop table');

	rollback;
end
go

create table test_tbl (id int);
drop table test_tbl;

select * from ChangeLog;

--QUESTION 8 
--Create a DDL trigger that logs all CREATE TABLE operations. 
--The trigger should record: 
--● The action type 
--● The full SQL command used to create the table 

go
create or alter trigger trg_DDLTableCreate
on database
for create_table
as
begin
	set nocount on
	declare @EventData xml = EventData();

	Declare @SQLCommand varchar(max) = @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'varchar(max)');

	insert into ChangeLog(ActionType,newData)
	values ('Create Table',@SQLCommand)

end
go

create table test( id int );

select * from ChangeLog;

--QUESTION 9 
--Create a DDL trigger that prevents any ALTER TABLE statement that attempts to drop a 
--column. 
--All blocked attempts should be logged. 
go
create or alter trigger trg_DropColumn
on database
for alter_table
as
begin
    set nocount on;
    
    declare @EventData xml = EventData();
    declare @SQLCommand varchar(max) = @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'varchar(max)');
    declare @TableName varchar(100) = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'varchar(100)');

    if @SQLCommand like '%DROP COLUMN%'
    begin
        insert into ChangeLog (TableName, ActionType, newData)
        values (@TableName, 'Alter Table - Drop Column', @SQLCommand);
        
        rollback;
    end
end
go

alter table test_tbl add name varchar(200); -- valid
alter table test_tbl drop column name; -- unvalid

select * from ChangeLog;

--QUESTION 10 
--Create a single trigger on the Badges table that tracks INSERT, UPDATE, and DELETE 
--operations. 
--The trigger should: 
--● Detect the operation type using INSERTED and DELETED tables 
--● Log the action appropriately in the ChangeLog table 
go
create or alter trigger trg_Badges
on Badges
for insert, update, delete
as
begin
    set nocount on;

    if exists (select 1 from inserted)
    begin
        insert into ChangeLog (TableName, ActionType, newData)
        select 'Badges', 'Insert', 'Inserted Badge with Id: ' + cast(i.Id as varchar(10))
        from inserted i;
    end

    if exists (select 1 from deleted)
    begin

        insert into ChangeLog (TableName, ActionType, newData)
        select 'Badges', 'Delete', 'Deleted Badge with Id: ' + cast(d.Id as varchar(10))
        from deleted d;
    end


    if exists (select 1 from inserted) and exists (select 1 from deleted) or UPDATE(Name)
    begin
        insert into ChangeLog (TableName, ActionType, newData)
        select 'Badges', 'Update', 
               'Updated Badge with Id: ' + cast(i.Id as varchar(10)) + 
               ' from ' + cast(d.Name as varchar(100)) + 
               ' to ' + cast(i.Name as varchar(100))
        from inserted i
        join deleted d on i.Id = d.Id;
    end
end
go

insert into Badges ( Name, UserId, Date) 
values ('new Badge', 1, GETDATE());

select top 1 id from Badges order by id desc;

update Badges 
set Name = 'test badge' 
where Id = 27676177;

delete from Badges where Id = 27676177;

select * from ChangeLog;

--QUESTION 11 
--Create a trigger that maintains summary statistics in a PostStatistics table whenever posts are 
--inserted, updated, or deleted. 
--The trigger should update: 
--● Total number of posts 
--● Total score 
--● Average score 
--for the affected users. 

create table PostStatistics (
    UserId int primary key,
    TotalPosts int,
    TotalScore int,
    AverageScore float
);

go
create or alter trigger trg_UpdatePostStatistics
on Posts
for insert, update, delete
as
begin
    set nocount on;

    declare @UserId int;
    declare @Score int;

    if exists (select 1 from inserted)
    begin
        select @UserId = OwnerUserId, @Score = Score from inserted;
        
        if exists (select 1 from PostStatistics where UserId = @UserId)
        begin
            update PostStatistics
            set TotalPosts = TotalPosts + 1,
                TotalScore = TotalScore + @Score,
                AverageScore = TotalScore * 1.0 / (TotalPosts + 1)
            where UserId = @UserId;
        end
        else
        begin
            insert into PostStatistics (UserId, TotalPosts, TotalScore, AverageScore)
            values (@UserId, 1, @Score, @Score * 1.0);
        end
    end

    if exists (select 1 from deleted)
    begin
        select @UserId = OwnerUserId, @Score = Score from deleted;

        if exists (select 1 from PostStatistics where UserId = @UserId)
        begin
            update PostStatistics
            set TotalPosts = TotalPosts - 1,
                TotalScore = TotalScore - @Score,
                AverageScore = case when TotalPosts - 1 > 0 then (TotalScore * 1.0) / (TotalPosts - 1) else 0 end
            where UserId = @UserId;
        end
    end

    if exists (select 1 from inserted) and exists (select 1 from deleted)
    begin
        select @UserId = OwnerUserId, @Score = Score from inserted;
        declare @OldScore int;
        select @OldScore = Score from deleted;

        if exists (select 1 from PostStatistics where UserId = @UserId)
        begin
            update PostStatistics
            set TotalScore = TotalScore - @OldScore + @Score,
                AverageScore = (TotalScore * 1.0) / TotalPosts
            where UserId = @UserId;
        end
    end
end
go

select * from PostStatistics;
insert into Posts (OwnerUserId, Score) values (1, 10);


--QUESTION 12 
--Create an INSTEAD OF DELETE trigger on the Posts table that prevents deletion of posts with 
--a score greater than 100. 
--Any prevented deletion should be logged.
go
create or alter trigger trg_PreventDeleteHighScore
on Posts
instead of delete
as
begin
    set nocount on;
	if exists (select 1 from deleted where Score > 100)
	begin
		
		insert into ChangeLog(TableName, UserId,ActionType ,newData)
		select 'Posts', d.OwnerUserId, 
		'Delete','block delete with postId ' + d.Id 
		from deleted d;

		raiserror('can''t delete posts with score > 100',16,1);
		rollback;
	end
	else
	begin
		declare @id int;
		select @id = id from deleted;

		delete from Posts 
		where Id =@id;
	end
end
go


--QUESTION 13 
--Write the SQL commands required to: 
--1. Disable a specific trigger on the Posts table 
--2. Enable the same trigger again 
--3. Check whether the trigger is currently enabled or disabled

DISABLE TRIGGER trg_PreventDeleteHighScore ON Posts;

Enable TRIGGER trg_PreventDeleteHighScore ON Posts;


SELECT name, is_disabled
FROM sys.triggers
WHERE object_id = OBJECT_ID('trg_PreventDeleteHighScore');