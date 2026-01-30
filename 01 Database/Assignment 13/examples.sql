-- ============================================
-- PART 4: LOGON TRIGGER
-- ============================================

-- Create table to log logon attempts
CREATE TABLE Master.dbo.LogonAudit (
    LogonId INT IDENTITY(1,1) PRIMARY KEY,
    LoginName VARCHAR(100),
    LogonTime DATETIME DEFAULT GETDATE(),
    ClientHost VARCHAR(100),
    AppName VARCHAR(200)
);
GO

Create Or Alter Trigger trg_LogonAudit
On ALL SERVER
For LOGON
As
Begin
	Set NoCount ON

	Declare @ClientHost nvarchar(100)

	Select @ClientHost = client_net_address
	from sys.dm_exec_connections
	where session_id = @@SPID

	Insert into master.dbo.LogonAudit(LoginName, ClientHost, AppName)
	Values(ORIGINAL_LOGIN(), @ClientHost, APP_NAME())

	if DATEPART(HOUR, GETDATE()) Between 5 And 8
	Begin
		RaisError('Logon Blocked during Off Hours', 16, 1)
	End
End

-- To drop logon trigger:
Drop Trigger trg_LogonAudit On ALl Server


-- ============================================
-- SETUP: CREATE TEST TABLES
-- ============================================

CREATE TABLE BankAccounts (
    AccountId INT PRIMARY KEY,
    AccountHolder VARCHAR(100),
    Balance DECIMAL(18,2),
    LastModified DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE TransactionLog (
    LogId INT IDENTITY(1,1) PRIMARY KEY,
    AccountId INT,
    TransactionType VARCHAR(50),
    Amount DECIMAL(18,2),
    TransactionDate DATETIME DEFAULT GETDATE(),
    Status VARCHAR(20)
);
GO

-- Insert sample data
INSERT INTO BankAccounts (AccountId, AccountHolder, Balance)
VALUES 
    (1, 'Alice Johnson', 5000.00),
    (2, 'Bob Smith', 3000.00),
    (3, 'Charlie Brown', 7500.00);
GO


-- ============================================
-- PART 1: BASIC TRANSACTION - BEGIN, COMMIT, ROLLBACK
-- ============================================
-- EXAMPLE 1: Conditional COMMIT or ROLLBACK
Begin Transaction
	Declare @CurrentBalance Decimal(18,2)
	Declare @WithdrawAmount Decimal(18,2) = 10000

	Select @CurrentBalance = Balance
	From BankAccounts
	Where AccountId = 1

	If @CurrentBalance >= @WithdrawAmount
	Begin
		Update BankAccounts
		Set Balance -= @WithdrawAmount
		Where AccountId = 1

		print 'withdraw successful - transaction committed'
		Commit Transaction
	End
	Else
	Begin
		print 'Insufficient funds - Transaction Rolled Back'
		Rollback Transaction
	End

-- ============================================
-- PART 2: SAVE TRANSACTION (SAVEPOINTS)
-- ============================================
-- EXAMPLE 1:  SAVEPOINTS in complex operation
Begin Transaction
	Declare @Balance Decimal(18,2)

	Update BankAccounts
	Set Balance -= 500
	Where AccountId = 1

	Save Transaction AfterDebit

	Update BankAccounts
	Set Balance += 200
	Where AccountId = 2

	Save Transaction AfterFirstTransfer

	Update BankAccounts
	Set Balance += 300
	Where AccountId = 3

	Save Transaction AfterSecondTransfer

	Select @Balance = Balance
	From BankAccounts
	Where AccountId = 1

	If @Balance < 0
	Begin
		-- Cancel Second Transfer Only 
		Rollback Transaction AfterFirstTransfer

		Update BankAccounts
		Set Balance += 300
		Where AccountId = 1

		Select @Balance = Balance
		From BankAccounts
		Where AccountId = 1

		If @Balance < 0
		Begin
			-- Cancel Everything
			Rollback Transaction
			Return
		End
	End
Commit Transaction

-- ============================================
-- PART 3: TRY...CATCH WITH TRANSACTIONS
-- ============================================
-- EXAMPLE 1: TRY...CATCH with SAVEPOINT
Begin Try
	Begin Transaction

		-- Step 1
		Update BankAccounts
		SEt Balance -= 100
		Where AccountId = 1

		Save Transaction AfterStep1

		-- Step 2
		Begin Try 
			Update BankAccounts
			Set Balance /= 0
			Where AccountId = 2
		End Try
		Begin Catch
			print 'Step 2 failed, rolling back to AfterStep1'

			-- Undo Step 2 Only
			Rollback Transaction AfterStep1

			-- Alternative Action
			Update BankAccounts
			Set Balance += 50
			Where AccountId = 2
		End Catch

		Commit Transaction
End Try
Begin Catch
	If @@TRANCOUNT > 0
		Rollback Transaction

	print 'Entire Transaction Rolled Back: ' + Error_Message()
End Catch

-- ============================================
-- PART 4: NESTED TRANSACTIONS
-- ============================================
print 'Nested Transactions'
print 'TranCount at Start: ' + Cast(@@TranCount As varchar)
Begin Transaction -- Outer Transaction
	print 'After Outer Begin: TranCount = ' + Cast(@@TranCount As varchar)

	-- Step 1
	Update BankAccounts
	Set Balance -= 100
	Where AccountId = 1

	Begin Transaction -- Inner Transaction
		print 'After Inner Begin: TranCount = ' + Cast(@@TranCount As varchar)

		-- Step 2
		Update BankAccounts
		Set Balance += 100
		Where AccountId = 2

	Commit Transaction -- Inner Commit
	print 'After Inner Commit: TranCount = ' + Cast(@@TranCount As varchar)

Commit Transaction -- Outer Commit (Actual Commit)
print 'After Outer Commit: TranCount = ' + Cast(@@TranCount As varchar)


-- ============================================
-- PART 5: DCL (Data Control Language)
-- ============================================

-- CREATE USER Examples

 -- Create SQL Server login first (server level)
Create Login TestUser1 With Password = 'P@ssw0rd'
Create Login TestUser2 With Password = 'P@ssw0rd'
Create Login TestUser3 With Password = 'P@ssw0rd'

-- Create database users from logins
Create User TestUser1 For Login TestUser1
Create User TestUser2 For Login TestUser2
Create User TestUser3 For Login TestUser3

-- CREATE ROLE Examples
-- Role 1: Read-only users
Create Role db_readonly

-- Role 2: Data entry users (can insert/update)
Create Role db_dataentry

-- Role 3: Analysts (can read and execute procedures)
Create Role db_analyst

-- GRANT Examples
-- Grant SELECT on specific table
Grant Select On Users To db_readonly
Grant Select On Posts To db_readonly
Grant Select On Comments To db_readonly

-- Grant INSERT and UPDATE to data entry role
Grant Insert, Update On Posts To db_dataentry
Grant Insert, Update On Comments To db_dataentry

-- Grant EXECUTE on stored procedures
Grant Execute On GetUserSummary To db_analyst
Grant Execute On SearchPosts To db_analyst

-- Grant SELECT on all tables in schema
Grant Select On Schema::dbo To db_analyst

-- Grant to specific user
Grant Select On Users To TestUser1
Grant Insert, Update, Delete On Posts To TestUser2

-- ADD USERS TO ROLES
Alter Role db_readonly Add Member TestUser1
Alter Role db_dataentry Add Member TestUser2
Alter Role db_analyst Add Member TestUser3


-- REVOKE Examples
-- Revoke specific permission
Revoke Insert On Posts From db_dataentry

-- Revoke all permissions on object
Revoke All On Users From db_readonly

-- Revoke EXECUTE permission
Revoke Execute On SearchPosts From db_analyst

-- DENY Examples
-- DENY prevents access even if granted through role
Deny Delete On Posts To db_dataentry

-- DENY SELECT on specific table
Deny Select On AuditLog To db_readonly

-- DENY takes precedence over GRANT
-- If user has GRANT through role but DENY directly, DENY wins
/*
GRANT SELECT ON Users TO db_readonly;
DENY SELECT ON Users TO TestUser1;  -- TestUser1 cannot SELECT even if in db_readonly
GO
*/