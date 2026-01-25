--Question 01 : 
--Write the SQL commands to: 
-- a) Disable the trigger trg_Posts_LogInsert 
-- b) Enable the trigger trg_Posts_LogInsert 
-- c) Check if the trigger is disabled or enabled 
 
disable trigger trg_Posts_LogInsert ON Posts;

enable trigger trg_Posts_LogInsert ON Posts;


select name, is_disabled
from sys.triggers
where object_id = OBJECT_ID('trg_Posts_LogInsert');
 

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
after insert, update, delete
as
begin
    set nocount on;

    -- update
    insert into changelog (tablename, operationtype, recordid, oldvalue, newvalue, changetimestamp)
    select 'Comments', 'update', i.Id, d.Text, i.Text, getdate()
    from inserted i
    join deleted d on i.Id = d.Id;

    -- insert
    insert into changelog (tablename, operationtype, recordid, oldvalue, newvalue, changetimestamp)
    select 'Comments', 'insert', i.Id, null, i.Text, getdate()
    from inserted i
    where not exists (select 1 from deleted d where d.Id = i.Id);

    -- delete
    insert into changelog (tablename, operationtype, recordid, oldvalue, newvalue, changetimestamp)
    select 'Comments', 'delete', d.Id, d.Text, null, getdate()
    from deleted d
    where not exists (select 1 from inserted i where i.Id = d.Id);
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
