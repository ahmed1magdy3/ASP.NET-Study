
use StackOverflow2010;

CREATE TABLE AccountBalance ( 
    AccountId INT PRIMARY KEY, 
    AccountName VARCHAR(100), 
    Balance DECIMAL(18,2) CHECK (Balance >= 0), 
    LastUpdated DATETIME DEFAULT GETDATE() 
); 
GO 
 
CREATE TABLE TransferHistory ( 
    TransferId INT IDENTITY(1,1) PRIMARY KEY, 
    FromAccountId INT, 
    ToAccountId INT, 
    Amount DECIMAL(18,2), 
    TransferDate DATETIME DEFAULT GETDATE(), 
    Status VARCHAR(20), 
    ErrorMessage VARCHAR(500) 
); 
GO 
CREATE TABLE AuditTrail ( 
    AuditId INT IDENTITY(1,1) PRIMARY KEY, 
    TableName VARCHAR(100), 
    Operation VARCHAR(50), 
    RecordId INT, 
    OldValue VARCHAR(500), 
    NewValue VARCHAR(500), 
    AuditDate DATETIME DEFAULT GETDATE(), 
    UserName VARCHAR(100) DEFAULT SYSTEM_USER 

); 
GO -- Insert sample data 
INSERT INTO AccountBalance (AccountId, AccountName, Balance) 
VALUES  
(101, 'Checking Account', 10000.00), 
(102, 'Savings Account', 25000.00), 
(103, 'Investment Account', 50000.00), 
(104, 'Emergency Fund', 15000.00); 
GO 


--Question 01 : 
--Write a simple transaction that transfers $500 from Account 101 
--to Account 102. 
--Use BEGIN TRANSACTION and COMMIT TRANSACTION. 
--Display the balances before and after the transfer. 
select * 
from AccountBalance
where AccountId in (101,102); -- 101 -> 10000
                              -- 102 -> 25000

begin transaction
    update AccountBalance
    set Balance -= 500
    where AccountId = 101;

    update AccountBalance
    set Balance += 500
    where AccountId = 102;

    commit;

select * 
from AccountBalance
where AccountId in (101,102); -- 101 -> 9500
                              -- 102 -> 25500

--Question 02 : 
--Write a transaction that attempts to transfer $1000 from Account 101 
--to Account 102, but then rolls it back using ROLLBACK TRANSACTION. 
--Verify that the balances remain unchanged.

select * 
from AccountBalance
where AccountId in (101,102); -- 101 -> 9500
                              -- 102 -> 25500

begin transaction
    update AccountBalance
    set Balance -= 1000
    where AccountId = 101;

    update AccountBalance
    set Balance += 1000
    where AccountId = 102;

    rollback;


select * 
from AccountBalance
where AccountId in (101,102); -- 101 -> 9500
                              -- 102 -> 25500


--Question 03 : 
--Write a transaction that checks if Account 101 has sufficient 
--balance before transferring $2000 to Account 102. 
--If insufficient, rollback the transaction. 
--If sufficient, commit the transaction. 

select * 
from AccountBalance
where AccountId in (101,102); -- 101 -> 9500
                              -- 102 -> 25500

begin transaction
    declare @balance DECIMAL(18,2);

    select @balance = Balance
    from AccountBalance
    where AccountId = 101;

    if @balance >= 2000
    begin
        update AccountBalance
        set Balance -= 2000
        where AccountId = 101;

        update AccountBalance
        set Balance += 2000
        where AccountId = 102;

        commit;
    end
    
    else
        rollback;


select * 
from AccountBalance
where AccountId in (101,102); -- 101 -> 7500
                              -- 102 -> 27500

--Question 04 : 
--Write a transaction using TRY...CATCH that transfers money 
--from Account 101 to Account 102. If any error occurs, 
--rollback the transaction and display the error message.

select * 
from AccountBalance
where AccountId in (101,102); -- 101 -> 7500
                              -- 102 -> 27500

begin try
begin transaction
        update AccountBalance
        set Balance -= 1000
        where AccountId = 101;

        update AccountBalance
        set Balance += 1000
        where AccountId = 102;

        commit;
end try
begin catch
    rollback;
    raiserror ('An Error Occured While Transaction',16,1);
    select ERROR_MESSAGE() as Error;
    return;
end catch

select * 
from AccountBalance
where AccountId in (101,102); -- 101 -> 6500
                              -- 102 -> 28500

--Question 05 : 
--Write a transaction that uses SAVE TRANSACTION to create 
--a savepoint after the first update. Then perform a second update 
--and rollback to the savepoint if an error occurs. 
begin try
begin transaction
        update AccountBalance
        set Balance -= 1000
        where AccountId = 101;

        save tran sp_1;

        update AccountBalance
        set Balance += 1000
        where AccountId = 102;

        commit;
end try
begin catch
    rollback transaction sp_1;
end catch


--Question 06 : 
--Write a transaction with nested BEGIN TRANSACTION statements. 
--Display @@TRANCOUNT at each level to demonstrate how it changes. 

begin transaction
    select @@TRANCOUNT as Tran_1;

    begin transaction 
         select @@TRANCOUNT as Tran_2;


    rollback; -- one rollback ends all transactions
    select @@TRANCOUNT as after_rollback;

--Question 07 : 
--Demonstrate ATOMICITY by writing a transaction that performs 
--multiple updates. 
--Show that if one fails, all are rolled back. 

begin try
begin transaction
        update AccountBalance
        set Balance -= 1000
        where AccountId = 101;
        
        ;raiserror('Imagin an Error Occured here',16,1);

        update AccountBalance
        set Balance += 1000
        where AccountId = 102;

        commit;
end try
begin catch
    rollback;
end catch

--Question 08 : 
--Demonstrate CONSISTENCY by writing a transaction that ensures 
--the total balance across all accounts remains constant. 
--Calculate total before and after transfer. 

declare @total_before decimal(18,2),
        @total_after  decimal(18,2);

select @total_before = sum(balance)
from AccountBalance;

begin try
begin transaction

   declare @balance DECIMAL(18,2);  -- already decalred

    select @balance = Balance
    from AccountBalance
    where AccountId = 101;

    if @balance >= 1000
    begin
        update AccountBalance
        set Balance -= 1000
        where AccountId = 101;

        update AccountBalance
        set Balance += 1000
        where AccountId = 102;

        commit;
    end
    else
    begin
        rollback;
        raiserror('Not Enough Balance',16,1);
    end
end try
begin catch
    select ERROR_MESSAGE() as error;
    raiserror('An Error Occured',16,1);
    if @@TRANCOUNT > 0
        rollback;
end catch

select @total_after = sum(balance)
from AccountBalance;


select @total_before as total_before,
       @total_after  as total_after; -- before = after then it's consistency
--Question 09 :  
--Demonstrate ISOLATION by setting different isolation levels 
--and explaining their effects. Use READ UNCOMMITTED, READ 
--COMMITTED, and SERIALIZABLE. 

begin transaction 
    update AccountBalance set Balance = 10000
    where AccountId = 101;

----------------------------------
-- if i openend another session
-----------------------------------

set transaction isolation level read committed; -- default level
begin transaction 
    select Balance from AccountBalance where AccountId = 101; 
    -- the last transaction on the same table didn't closed, so it can't read;

set transaction isolation level read uncommitted;
begin transaction 
    select Balance from AccountBalance where AccountId = 101;
    -- the last transaction on the same table didn't closed, but it can read the temprory data ;

set transaction isolation level SERIALIZABLE;
begin transaction 
    select Balance from AccountBalance where AccountId = 101;
     -- the last transaction on the same table didn't closed, so it can't read;

rollback;

--Question 10 :  
--Demonstrate DURABILITY by committing a transaction and 
--explaining that the changes will persist even after 
--system restart or failure. 

begin transaction 
    update AccountBalance set Balance = 10000
    where AccountId = 101;
    commit;
    -- the data is permanently saved on the disk, so after restarts the server the data will not be changed;

--Question 11 : 
--Write a stored procedure that uses transactions to transfer 
-- money between two accounts. Include parameter validation, 
-- error handling, and proper transaction management. 
go
create or alter procedure usp_transfer_money (@SenderId int, 
                                              @ReceiverId int, 
                                              @balance DECIMAL(18,2))
as
begin

    if not exists (select 1 from AccountBalance where AccountId = @SenderId)
    begin
        raiserror('sender account not found',16,1);
        return;
    end

    if not exists (select 1 from AccountBalance where AccountId = @ReceiverId)
    begin
        raiserror('receiver account not found',16,1);
        return;
    end

    declare @bal DECIMAL(18,2);
    select @bal = Balance
    from AccountBalance
    where AccountId = @SenderId;

 if @bal < @balance
    begin
        raiserror('Not Enough Balance',16,1);
        return;
    end
 else
    begin
    begin try
    begin transaction 
       update AccountBalance
        set Balance -= @balance
        where AccountId = @SenderId;

        update AccountBalance
        set Balance += @balance
        where AccountId = @ReceiverId;

        commit;
    end try
    begin catch
        raiserror('An Error Occoured',16,1);
        select ERROR_MESSAGE() as Error;
        if @@TRANCOUNT > 0
            rollback;
    end catch
    end
end 
go


select * 
from AccountBalance
where AccountId in (101,102); -- 101 -> 6500
                              -- 102 -> 28500

exec usp_transfer_money @SenderId=101,@ReceiverId=102,@balance=500;

select * 
from AccountBalance
where AccountId in (101,102); -- 101 -> 6000
                              -- 102 -> 29000

--Question 12 : 
--Write a transaction that uses multiple savepoints to handle 
-- a multi-step operation. If step 2 fails, rollback to savepoint 1. 
-- If step 3 fails, rollback to savepoint 2. 

begin try
    begin transaction;

    -- step 1
    update accountbalance
    set balance -= 1000
    where accountid = 101;

    save transaction sp_step1;

    -- step 2
    update accountbalance
    set balance += 1000
    where accountid = 102;

    save transaction sp_step2;

    -- imagin error here
    raiserror ('error in step 3', 16, 1);

    update accountbalance
    set balance += 1000
    where accountid = 103;

    commit;
end try
begin catch
    if ERROR_MESSAGE() like '%step 3%'
    begin
        rollback transaction sp_step2;
        commit;
    end
    else if ERROR_MESSAGE() like '%step 2%'
    begin
        rollback transaction sp_step1;
        commit;
    end
    else -- if error in step 1
        rollback;

    select error_message() as errormessage;
end catch;


--QUESTION 13 : 
-- Write a transaction that handles a deadlock scenario using 
-- TRY...CATCH. Retry the operation if a deadlock is detected. 

declare @retry_count int = 0;
declare @max_retries int = 3;

while @retry_count < @max_retries
begin
    begin try
        begin transaction;

        -- step 1
        update accountbalance
        set balance -= 500
        where accountid = 101;

        -- step 2
        update accountbalance
        set balance += 500
        where accountid = 102;

        commit;
        break; -- exit loop
    end try
    begin catch
        if @@trancount > 0
            rollback;

        -- 1205 = deadlock
        if error_number() = 1205
        begin
            set @retry_count += 1;
        end
        else
        begin
            select error_message() as errormessage;
            break;
        end
    end catch
end


--QUESTION 14 : 
--Write a query to check the current transaction count    
--(@@TRANCOUNT) 
--and demonstrate how it changes within nested transactions. 

select @@trancount as tran_zero;

begin transaction;
select @@trancount as tran_1;

begin transaction;
select @@trancount as tran_2;

-- rollback ends all transactions
rollback;
select @@trancount as after_rollback;

--QUESTION 15 : 
--Write a transaction that logs all changes to the AuditTrail table. 
--Include before and after values for updates. 

declare @old_balance decimal(18,2);
declare @new_balance decimal(18,2);

begin try
    begin transaction;

    select @old_balance = balance
    from accountbalance
    where accountid = 101;

    update accountbalance
    set balance = balance + 500
    where accountid = 101;

    select @new_balance = balance
    from accountbalance
    where accountid = 101;

    insert into AuditTrail(tablename,operation,recordid,oldvalue,newvalue)
    values('accountbalance','update',101,
        cast(@old_balance as varchar(500)),
        cast(@new_balance as varchar(500))
    );

    commit;
end try
begin catch
    if @@TRANCOUNT > 0
        rollback;

    select ERROR_MESSAGE() as error;
end catch;


--QUESTION 16 : 
--Write a transaction that demonstrates the difference between 
--COMMIT and ROLLBACK by creating two identical transactions, 
--committing one and rolling back the other. 

-- before commit
select balance from accountbalance where accountid = 101; --5000

begin transaction
update accountbalance set balance = balance - 500 where accountid = 101;
commit;
-- after commit
select balance from accountbalance where accountid = 101; -- 4500

--------------------------------------------------------

-- before rollback
select balance from accountbalance where accountid = 101; --4500

begin transaction
update accountbalance set balance = balance - 500 where accountid = 101;
rollback;
-- after before rollback
select balance from accountbalance where accountid = 101; -- 4500

--QUESTION 17 : 
--Write a transaction that enforces a business rule: "Total 
--withdrawals in a single transaction cannot exceed $5000". 
--If violated, rollback the transaction. 

declare @withdraw_amount decimal(18,2) = 6000;

begin try
    begin transaction;

    if @withdraw_amount > 5000
    begin
        raiserror('Total withdrawals in a single transaction cannot exceed 5000',16,1);
    end

    update AccountBalance
    set Balance -= @withdraw_amount
    where AccountId = 101;

    commit;
end try
begin catch
    if @@TRANCOUNT > 0
        rollback;

    select ERROR_MESSAGE() as error;
end catch;


--QUESTION 18 : 
--Write a transaction that uses explicit locking hints (WITH (UPDLOCK)) 
--to prevent concurrent modifications during a transfer. 

begin try
    begin transaction;

    select Balance
    from AccountBalance with (updlock)
    where AccountId = 101;

    select Balance
    from AccountBalance with (updlock)
    where AccountId = 102;

    -- transfer
    update AccountBalance
    set Balance -= 500
    where AccountId = 101;

    update AccountBalance
    set Balance += 500
    where AccountId = 102;

    commit;
end try
begin catch
    if @@TRANCOUNT > 0
        rollback;

    select ERROR_MESSAGE() as error;
end catch;
-- to prevent any other session to update in the same rows;

--QUESTION 19 :  
--Write a comprehensive error handling transaction that catches 
--specific error numbers and handles them differently. 
--Handle: Constraint violations, insufficient funds, and general errors. 

declare @withdraw_amount decimal(18,2) = 12000;
declare @current_balance decimal(18,2);

begin try
    begin transaction;

    select @current_balance = balance
    from accountbalance
    where accountid = 101;

    if @current_balance < @withdraw_amount
        raiserror('insufficient funds',16,1);

    update accountbalance
    set balance -= @withdraw_amount
    where accountid = 101;

    commit;
end try
begin catch
    if @@trancount > 0
        rollback;


    declare @errnum int = error_number();
    declare @errmsg nvarchar(4000) = error_message();

    if @errnum = 547 -- foreign key / check / constraint violation
        print 'constraint violation: ' + @errmsg;
    else if @errmsg like '%insufficient funds%'
        print 'transaction failed due to insufficient funds: ' + @errmsg;
    else
        print 'general error: ' + @errmsg;
end catch;


--QUESTION 20: 
--Write a transaction monitoring query that shows all active 
--transactions in the database, including their status, start time, 
--and session information. 

select 
    at.transaction_id,
    at.transaction_begin_time,
    at.transaction_state,
    at.transaction_type,
    at.transaction_status,
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    s.status as session_status
from sys.dm_tran_active_transactions at
join sys.dm_tran_session_transactions st
    on at.transaction_id = st.transaction_id
join sys.dm_exec_sessions s
    on st.session_id = s.session_id
order by at.transaction_begin_time desc;
