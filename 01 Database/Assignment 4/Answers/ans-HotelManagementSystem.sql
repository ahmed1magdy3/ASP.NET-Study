
USE HotelManagementSystem;
/*
1. INSERT OPERATIONS : 
	● Insert a Guest (FullName, Nationality, PassportNumber, DateOfBirth) 
	● Insert multiple Guests in one statement 
*/
INSERT INTO Guests 
	VALUES ('Ahmed Magdy','Egypt','EG123456','2000-1-1');

INSERT INTO Guests 
VALUES
	('John Carter', 'USA', 'A1234567', '1985-04-15'),
	('Maria Santos', 'Brazil', 'BR998877', '1990-09-02'),
	('Ahmed Hassan', 'Egypt', 'EG455322', '1982-12-20'),
	('Sophia Müller', 'Germany', 'DE778899', '1995-03-11');

/*
2. UPDATE OPERATIONS 
	● Increase DailyRate by 15% for all suites 
	● Update ReservationStatus: If CheckoutDate < GETDATE() → 'Completed' 
		If CheckinDate > GETDATE() → 'Upcoming' Else → 'Active' 
*/
UPDATE Rooms 
	SET DailyRate += DailyRate * 0.15 
	WHERE RoomType = 'suite'

UPDATE RESERVATIONS 
	SET ReservationStatus = CASE
								WHEN CheckOutDate < GETDATE() THEN 'Completed' 
								WHEN CheckInDate > GETDATE() THEN 'Upcoming'
								ELSE 'Active'
							END;

/*
3. DELETE OPERATIONS 
	● Delete Reservation_Guest for a reservation 
*/
DELETE Reservations_Guest WHERE ReservationId = 1;

/*
4. MERGE OPERATION 
	● Create table #StaffUpdates (StaffId, FullName, Position, Salary) 
	MERGE logic: 
	Match → Update Position + Salary 
	Not matched in Hotel DB → Insert 
	Not matched in Update table → Delete
*/

CREATE TABLE  #StaffUpdates (
StaffId INT, 
FullName VARCHAR(50),
Position VARCHAR(50), 
Salary DECIMAL (10,2)
) ;

MERGE INTO Staff AS Target
USING  #StaffUpdates AS Source
ON Target.StaffId = Source.StaffId

WHEN MATCHED THEN
	UPDATE SET
		 Target.Position = Source.Position,
		 Target.Salary = Source.Salary

WHEN NOT MATCHED BY Target THEN
	INSERT ( FullName, Position, Salary) 
	VALUES (source.FullName, source.Position, source.Salary)

WHEN NOT MATCHED BY Source THEN
	DELETE
;