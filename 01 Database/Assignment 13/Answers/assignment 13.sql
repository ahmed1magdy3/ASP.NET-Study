--Question 01 : 
--Write the SQL commands to: 
-- a) Disable the trigger trg_Posts_LogInsert 
-- b) Enable the trigger trg_Posts_LogInsert 
-- c) Check if the trigger is disabled or enabled 
 
DISABLE TRIGGER trg_Posts_LogInsert ON Posts;

Enable TRIGGER trg_Posts_LogInsert ON Posts;


SELECT name, is_disabled
FROM sys.triggers
WHERE object_id = OBJECT_ID('trg_Posts_LogInsert');
 

--Question 06 : 
--Create a comprehensive audit trigger that tracks all changes 
--to the Comments table, storing: - Operation type (INSERT/UPDATE/DELETE) - Before and after values for UPDATE - Timestamp and user who made the change 

create table changelog (
    changeid int identity primary key,
    tablename varchar(50),
    operationtype varchar(50),  -- 'insert', 'update', or 'delete'
    recordid int,
    oldvalue varchar(max),
    newvalue varchar(max),
    changetimestamp datetime,
);

go
create or alter trigger trg_AuditComments
on Comments
for insert, update, delete
as
begin
    set nocount on;
    
    declare @operationtype varchar(10);
    declare @recordid int;
    declare @oldvalue varchar(max);
    declare @newvalue varchar(max);
    declare @changetimestamp datetime = getdate();

	-- insert
    if exists (select 1 from inserted)
    begin
        set @operationtype = 'insert';
        select @recordid = id, @newvalue = Text from inserted;

        insert into changelog (tablename, operationtype, recordid, oldvalue, newvalue, changetimestamp)
        values ('Comments', @operationtype, @recordid, null, @newvalue, @changetimestamp);
    end

    -- update
    if exists (select 1 from inserted) and exists (select 1 from deleted)
    begin
        set @operationtype = 'update';
        select @recordid = i.id, @oldvalue = d.Text, @newvalue = i.Text
        from inserted i
        join deleted d on i.id = d.id;

        insert into changelog (tablename, operationtype, recordid, oldvalue, newvalue, changetimestamp)
        values ('Comments', @operationtype, @recordid, @oldvalue, @newvalue, @changetimestamp);
    end

	-- delete
    if exists (select 1 from deleted)
    begin
        set @operationtype = 'delete';

        select @recordid = id, @oldvalue = text from deleted;

        insert into changelog (tablename, operationtype, recordid, oldvalue, newvalue, changetimestamp)
        values ('Comments', @operationtype, @recordid, @oldvalue, null, @changetimestamp);
    end
end
go



--Question 07 : 
--Write a query to view all triggers in the database along with: 
-- their status (enabled/disabled), type (AFTER/INSTEAD OF), and - the tables they're attached to. 

select 
    t.name as trigger_name,
    case 
        when t.is_disabled = 0 then 'enabled'
        else 'disabled'
    end as status,
case 
        when t.is_instead_of_trigger = 1 then 'instead of'
        else 'after'
    end as trigger_type,
    object_name(t.parent_id) as table_name
from sys.triggers t
order by table_name, trigger_name;
