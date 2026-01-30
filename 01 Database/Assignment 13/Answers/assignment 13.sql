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
 


-- Question 02 : 
--Create a SQL login, database user, and grant them SELECT 
--permission on the Users table only. 
 
 Create Login TestUser With Password = 'test123';
 Create User TestUser For Login TestUser;
 grant select on Users to TestUser;

--Question 03 : 
--Create a database role called "DataAnalysts" and grant it: 
-- - SELECT permission on all tables 
-- - EXECUTE permission on all stored procedures 
-- - Then add a user to this role. 
 
 create role DataAnalysts;

 grant select on schema::dbo to DataAnalysts;
 grant execute on schema::dbo to DataAnalysts;
 alter role DataAnalysts add member TestUser;
 
--Question 04 : 
--Write SQL to REVOKE INSERT and UPDATE permissions from a role 
-- called "DataEntry" on the Posts table. 

revoke insert, update on Posts from DataEntry;

--Question 05 : 
--Write SQL to DENY DELETE permission on the Users table to a 
--specific user, even if they have it through a role. 
--Explain why DENY is used instead of REVOKE 

deny delete on Users to TestUser;
-- if the user is a member of role that grant delete, 
-- so with revoke he can delete, but with delete he can't.
-- because deny is always win over grant.

--Question 06 : 
--Create a comprehensive audit trigger that tracks all changes 
--to the Comments table, storing: 
-- Operation type (INSERT/UPDATE/DELETE) 
-- Before and after values for UPDATE 
-- Timestamp and user who made the change 

create table changelog (
    changeid int identity primary key,
    tablename varchar(50),
    operationtype varchar(50),  -- 'insert', 'update', or 'delete'
    recordid int,
    oldvalue varchar(max),
    newvalue varchar(max),
    changetimestamp datetime default getdate(),
    UserName varchar(100) default SYSTEM_USER, 
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


--Question 08 : 
--Write a query to view all permissions granted to a specific role 
--or user, including the object name, permission type, and state.

SELECT
    dp.name AS PrincipalName,                 
    dp.type_desc AS PrincipalType,
    perm.permission_name AS Permission,
    perm.state_desc AS PermissionState,
    s.name AS SchemaName,
    o.name AS ObjectName,
    o.type_desc AS ObjectType
FROM sys.database_permissions AS perm
JOIN sys.database_principals AS dp
    ON perm.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects AS o
    ON perm.major_id = o.object_id
LEFT JOIN sys.schemas AS s
    ON o.schema_id = s.schema_id
WHERE dp.name in ('TestUser', 'DataAnalysts') -- ( user, role )
