--=================================================================
---------------------------- Index --------------------------------
--=================================================================
-------------------------------------------------------------------
-- Clustered Index 
--=================================================================
USE [NationalBankDB]
 -- Clustered Index on TransactionType In Table Transactions 
 ------------------------------------------------------------------
Create Clustered Index Ix_TransactionType
On Transactions(TransactionType)

Alter Table Transactions
Drop Constraint [PK__Transact__E733A2BE3FC6746E]

Alter Table Transactions
Add Constraint PK_TranNumber
Primary Key NonClustered(TransactionNumber)

Create Clustered Index Ix_TransactionType
On Transactions(TransactionType)
With(FillFactor = 80)

-- Non-Clustered Index 
--=================================================================
Use StackOverflow2010

-- Example 01 : Speed up queries filtering by reputation

Select DisplayName, Reputation, Location
From Users
Where Reputation > 8000
Order By Reputation Desc

Create NonClustered Index IX_UsersReputation
On Users(Reputation Desc)
Include(DisplayName, Location)

Select DisplayName, Reputation, Location
From Users
Where Reputation > 10000
Order By Reputation Desc

-- Unique Index 
--=================================================================
Select DisplayName
From Users
Where DisplayName = 'Jax'

Create Unique NonClustered Index IX_UsersDisplayName
On Users(DisplayName)

With RankedUsers As (
	Select *, ROW_NUMBER() Over(Partition By DisplayName Order By id) As RN
	From Users
)
Delete From RankedUsers
Where RN > 1

-- Composite Index 
--=================================================================
-- Scenario: Optimize queries filtering by user and sorting by score
Select Title, Score, ViewCount
From Posts
Where OwnerUserId = 1 And Score > 500 And Title Is not null And ViewCount > 1
Order By Score Desc

Create NonClustered Index IX_PostsOwnerScore
On Posts(OwnerUserId, Score Desc)
Include(Title, ViewCount)

-- Filtered Index 
--=================================================================
-- Scenario: Index only high-value posts
Select Title, Score, ViewCount
From Posts
Where Score > 5 And Title is not null
Order By Score Desc

Create NonClustered Index IX_PostsHighValue
On Posts(Score Desc)
Include(Title, ViewCount)
Where Score > 50 And Title is not null