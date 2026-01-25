-- ============================================
-- PART 1: AFTER TRIGGERS 
-- ============================================

-- AFTER INSERT TRIGGER Example 1
-- Automatically log when new posts are created
-- Audit table for tracking changes
Create Table AuditLog(
	AuditId int primary key identity(1,1),
	TableName varchar(100),
	OperationType varchar(20),
	UserId int,
	ChangeDate Datetime Default GetDate(),
	OldValue nvarchar(max),
	NewValue nvarchar(max),
	Details nvarchar(500)
)

Go
Create Or Alter Trigger trg_PostsAfterInsert
On Posts
After Insert
As 
Begin
	set NoCount On

	insert into AuditLog(TableName, OperationType, UserId, Details)
	Select 'Posts', 'Insert', i.OwnerUserId, 'New Post Created: ' + ISNULL(CAST(i.Title As varchar(200)), 'No Title')
	From inserted i

	Print 'Post Creation Logged'
End

Go
Insert into Posts(Body, CreationDate, LastActivityDate, PostTypeId, Score, ViewCount, Title, OwnerUserId)
Values('Test Body', GETDATE(), GETDATE(), 1, 0, 0, 'Test Title', 1)

Select *
From AuditLog

-- AFTER UPDATE TRIGGER Example 2
-- Track reputation changes for users
Go
Create Or Alter Trigger trg_UsersAfterUpdate
On Users
After Update
As
Begin
	Set NoCount On

	-- Only log if Reputation changed
	If UPDATE(Reputation)
	Begin
		Insert Into AuditLog(TableName, OperationType, UserId, OldValue, NewValue, Details)
		Select 'Users', 'Update', i.Id, 
		       CAST(d.Reputation as varchar), 
			   CAST(i.Reputation as varchar),
			   'Reputation changed from ' + CAST(d.Reputation as varchar) + ' to ' + CAST(i.Reputation as varchar)
		From inserted i 
		join deleted d on i.Id = d.Id
		where i.Reputation != d.Reputation
	End

	print 'User Update Logged'
End

Update Users
Set Reputation += 100
Where Id = 1

select *
from AuditLog

-- AFTER DELETE TRIGGER Example 3
-- log deletion attempts
Go
Create Or Alter Trigger trg_PostsAfterDelete
On Posts
After Delete
As 
Begin
	Set NoCount On

	insert into AuditLog(TableName, OperationType, UserId, OldValue, Details)
	select 'Posts', 'Delete', d.OwnerUserId, 
	       'Post Id: ' + CAST(d.Id as varchar),
		   'Post Deleted: ' + ISNULL(CAST(d.Title as varchar(200)), 'No Title')
 	From deleted d

	Print 'Post Deletion Logged'
End

-- Test AFTER DELETE (be careful - this actually deletes)
Delete from Posts
where Id = 100

Select * 
From AuditLog

-- ============================================
-- PART 2: INSTEAD OF TRIGGERS
-- ============================================
-- INSTEAD OF INSERT Example 1
-- Intercept insert and add validation
Create Table TestData (
	Id int primary key identity(1,1),
	Name varchar(100),
	Value int,
	CreatedDate DateTime Default GetDate(),
	ModifiedDate DateTime
)

Go
Create Or Alter Trigger trg_TestDataInsteadofInsert
On TestData
Instead Of Insert
As 
Begin
	Set NoCount On

	-- Validate DAta Before Actual Insert
	If Exists(Select 1 from inserted where Value < 0)
	Begin
		RaisError('Cannot insert negative value', 16, 1)
		return
	End	

	-- Perform The Actual Insert with modifications
	insert into TestData(Name, Value, ModifiedDate)
	select Upper(i.Name), i.Value, GETDATE() 
	from inserted i

	print 'Data Validated And Inserted'
End

insert into TestData(Name, Value)
values('Test 01', 1)

insert into TestData(Name, Value)
values('Test 02', -1)

select *
from TestData

-- INSTEAD OF UPDATE Example 2
-- Control which columns can be updated
Go
Create Or Alter Trigger trg_TestsDataInsteadOfUpdate
On TestData
Instead Of Update
As
Begin
	Set NoCount On

	-- Prevent Updating Name Column
	if UPDATE(Name)
	Begin
		RaisError('Cannot Update Name Column', 16, 1)
		return
	End

	-- Allow Update 
	Update T
	set T.Value = i.Value, T.ModifiedDate = GETDATE()
	From TestData T
	Join inserted i On t.id = i.id 

	-- Log Change
	insert into AuditLog(TableName, OperationType, Details)
	select 'TestData', 'Update', 
	       'Record with Id: ' + Cast(i.id as varchar) + 'Updated'
	from inserted i

	print 'Update Controlled and logged'
End

Update TestData
set Value = 150
where Id  = 2

Update TestData
Set Name = 'Name Changed'
Where Id = 2

select *
from TestData
where id = 2

-- INSTEAD OF DELETE Example 3
-- Implement soft delete instead of actual deletion
Alter Table TestData
Add IsDeleted Bit Default 0

Go
Create Or Alter Trigger trg_TestDataInsteadOfDelete
On TestData
instead Of Delete
As
Begin
	Set NoCount On

	-- instead of delete, just mark as deleted
	Update T
	Set IsDeleted = 1, ModifiedDate = GETDATE()
	from TestData T
	Join deleted d on T.id = d.id

	-- Log Change(Soft Delete)
	insert into AuditLog(TableName, OperationType, Details)
	select 'TestsData', 'Soft Delete',
	       'Record with Id: ' + CAST(d.id as varchar) + ' Soft Deleted'
	from deleted d

	print 'Soft Delete Performed'
End

-- Record is marked as deleted, not actually removed
Delete From TestData
where Id = 2

select *
from TestData

-- ============================================
-- PART 3: DDL TRIGGERS 
-- ============================================

-- Create table to log DDL events
CREATE TABLE DDLAuditLog (
    EventId INT IDENTITY(1,1) PRIMARY KEY,
    EventType VARCHAR(100),
    EventDate DATETIME DEFAULT GETDATE(),
    LoginName VARCHAR(100),
    TSQLCommand NVARCHAR(MAX),
    DatabaseName VARCHAR(100)
);
GO

-- DDL TRIGGER Example 1: Prevent table drops
Create Or Alter Trigger trg_PreventTableDrop
On Database
For Drop_Table
As
Begin
	Set NoCount On

	Declare @EventData xml = EventData()
	Declare @TableName varchar(100) = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'varchar(100)')

	--Select EVENTDATA()
	-- Log Attemp
	Insert Into DDLAuditLog(EventType, LoginName, TSQLCommand, DatabaseName)
	Values('Drop_Table_Prevented', SYSTEM_USER, 'Attempted to drop table: ' + @TableName, DB_NAME())

	Print 'Table Drop Prevented: ' + @TableName
	Rollback
End

-- Test DDL trigger (this will be prevented)
CREATE TABLE TempTest (Id INT);
DROP TABLE TempTest;  -- This will be blocked


-- DDL TRIGGER Example 2: Audit all table creates
Go
Create Or Alter Trigger trg_AuditTableCreation
On Database
For Create_Table
As
Begin
	Set NoCount On

	Declare @EventData xml = EventData()
	Declare @SQLCommand varchar(max) = @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'varchar(max)')

	insert into DDLAuditLog(EventType, LoginName, TSQLCommand, DatabaseName)
	values('Create_Table', SYSTEM_USER, @SQLCommand, DB_NAME())

	print 'Table Creation logged'
End

-- Test DDL trigger
Create Table Test02(id int primary key)