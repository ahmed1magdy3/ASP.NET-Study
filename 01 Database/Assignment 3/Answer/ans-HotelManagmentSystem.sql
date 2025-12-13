CREATE DATABASE HotelManagementSystem;

USE HotelManagementSystem;


CREATE TABLE PAYMENTS(
	PaymentId INT IDENTITY PRIMARY KEY,
	Method VARCHAR(20) NOT NULL,
	PaymentDate Date NOT NULL,
	Amount DECIMAL(10,2) NOT NULL,
	ConfirmationNumber INT NOT NULL

);


CREATE TABLE RESERVATIONS (
	ReservationId INT IDENTITY PRIMARY KEY,
	BookingDate DATE NOT NULL,
	CheckOutDate DATE NOT NULL,
	CheckInDate DATE NOT NULL,
	ReservationStatus BIT NOT NULL,
	TotalPrice DECIMAL NOT NULL,
	NumberOfAdults INT,
	NumberOfChildren INT

);

CREATE TABLE Reservations_Payment(
	ReservationId INT,
	PaymentId INT,

	CONSTRAINT PK_Reservations_Payment PRIMARY KEY (ReservationId,PaymentId),
	CONSTRAINT FK_Reservations_Payment_RESERVATIONS FOREIGN KEY (ReservationId) REFERENCES RESERVATIONS (ReservationId),
	CONSTRAINT FK_Reservations_Payment_PAYMENTS FOREIGN KEY (PaymentId) REFERENCES PAYMENTS (PaymentId)

);

CREATE TABLE Guests(
	GuestId INT IDENTITY PRIMARY KEY,
	FullName VARCHAR(20) NOT NULL,
	Nationality VARCHAR(20),
	PassportNumber VARCHAR(20),
	DateOfBirth DATE NOT NULL

);

CREATE TABLE Guest_ContactDetails(
	GuestId INT,
	ContactDetail VARCHAR(20)

	CONSTRAINT PK_Guest_ContactDetails PRIMARY KEY (GuestId,ContactDetail),
	CONSTRAINT FK_Guest_ContactDetails FOREIGN KEY (GuestId) REFERENCES Guests (GuestId)

);

CREATE TABLE Reservations_Guest(
	ReservationId INT,
	GuestId INT,

	CONSTRAINT PK_Reservations_Guest PRIMARY KEY (ReservationId,GuestId ),
	CONSTRAINT FK_Reservations_Guest_Guests FOREIGN KEY (GuestId) REFERENCES Guests(GuestId),
	CONSTRAINT FK_Reservations_Guest_RESERVATIONS FOREIGN KEY (ReservationId) REFERENCES RESERVATIONS(ReservationId)
);

CREATE TABLE Rooms (
	RoomNumber INT PRIMARY KEY,
	RoomType VARCHAR(20),
	Capacity INT NOT NULL,
	DailyRate INT,
	Availabilty BIT NOT NULL,
	HotelId INT NOT NULL

);

CREATE TABLE Room_Amenities(
	RoomNumber INT,
	Amenity VARCHAR(20),

	CONSTRAINT PK_Room_Amenities PRIMARY KEY (RoomNumber,Amenity),
	CONSTRAINT FK_Room_Amenities_Rooms FOREIGN KEY (RoomNumber) REFERENCES Rooms (RoomNumber)

);

CREATE TABLE Reservations_Rooms(
	RoomNumber INT,
	ReservationId INT,

	CONSTRAINT PK_Reservation_Rooms PRIMARY KEY (RoomNumber,ReservationId),
	CONSTRAINT FK_Reservation_Rooms_Rooms FOREIGN KEY (RoomNumber) REFERENCES Rooms(RoomNumber),
	CONSTRAINT FK_Reservation_Rooms_RESERVATIONS FOREIGN KEY (ReservationId) REFERENCES RESERVATIONS(ReservationId)
);

CREATE TABLE Hotels(
	HotelId INT IDENTITY PRIMARY KEY,
	Name VARCHAR(20) NOT NULL,
	Address VARCHAR(50) NOT NULL,
	City VARCHAR(20)NOT NULL,
	StarRating INT ,
	ContactNumber VARCHAR(20),
	ManagerId INT UNIQUE NOT NULL,

);



CREATE TABLE Staff(
	StaffId INT IDENTITY PRIMARY KEY,
	FullName VARCHAR(20) NOT NULL,
	Position VARCHAR(20) NOT NULL,
	Salary DECIMAL(10,2) NOT NULL,
	HotelId INT NOT NULL,

	CONSTRAINT FK_Staff_Hotels FOREIGN KEY (HotelId) REFERENCES Hotels(HotelId)

);

CREATE TABLE ServicesForGuests(
	ServiceId INT IDENTITY PRIMARY KEY ,
	ServiceName VARCHAR(20) NOT NULL,
	Charage DECIMAL(10,2) NOT NULL,
	RequestDate DATE ,
	StaffId INT NOT NULL,

	CONSTRAINT FK_ServicesForGuests_Staff FOREIGN KEY (StaffId) REFERENCES Staff(StaffId)

);

CREATE TABLE ReservationService (
	ServiceId INT,
	ReservationId INT,

	CONSTRAINT PK_ReservationService PRIMARY KEY (ServiceId,ReservationId),
	CONSTRAINT FK_ReservationService_ServicesForGuests FOREIGN KEY (ServiceId) REFERENCES ServicesForGuests(ServiceId),
	CONSTRAINT FK_ReservationService_RESERVATIONS FOREIGN KEY (ReservationId) REFERENCES RESERVATIONS(ReservationId)

);


-- ALTER TABLES TO ADD FORIEGN KEYS FOR MISSING RELASHIONSHIPS

ALTER TABLE ROOMS
	ADD CONSTRAINT FK_Rooms_Hotels FOREIGN KEY (HotelId) REFERENCES Hotels(HotelId);


ALTER TABLE Hotels
	ADD CONSTRAINT FK_Hotel_Manager FOREIGN KEY (ManagerId) REFERENCES Staff(StaffId);

