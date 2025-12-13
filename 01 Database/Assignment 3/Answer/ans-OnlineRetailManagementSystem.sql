CREATE DATABASE OnlineRetailManagementSystem;

USE OnlineRetailManagementSystem;


CREATE TABLE Suppliers(
	SupplierId INT IDENTITY PRIMARY KEY,
	Name VARCHAR(20) NOT NULL,
	Country VARCHAR(20) NOT NULL,
	Email VARCHAR(20) NOT NULL,
	Address VARCHAR(20) NOT NULL,
	ContactNumber VARCHAR(20) NOT NULL,

);

CREATE TABLE Categories(
	CategoryId INT IDENTITY PRIMARY KEY,
	Name VARCHAR(20) NOT NULL,
	Description VARCHAR(20) NOT NULL,
	MainCategory INT ,

	CONSTRAINT FK_MainCategory FOREIGN KEY (MainCategory) REFERENCES Categories(CategoryId) 

);


CREATE TABLE Products (
	ProductId INT IDENTITY PRIMARY KEY,
	StockQuantity INT NOT NULL,
	Name VARCHAR(20) NOT NULL,
	AddedDate DATE ,
	Description VARCHAR(20) NOT NULL,
	UnitPrice DECIMAL(10,2) NOT NULL,
	CategoryId INT,

	CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId)

);

CREATE TABLE StockTtransactions(
	TranId INT IDENTITY PRIMARY KEY,
	TranDate DATE NOT NULL,
	QuantityChange INT NOT NULL,
	Type BIT NOT NULL,
	Reference VARCHAR(20),
	ProductId INT ,

	CONSTRAINT FK_StockTtransactions_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId)

);

CREATE TABLE Products_Suppliers(
	SupplierId INT,
	ProductId INT,

	CONSTRAINT PK_Products_Suppliers PRIMARY KEY (SupplierId,ProductId),
	CONSTRAINT FK_Products_Suppliers_Suppliers FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId),
	CONSTRAINT FK_Products_Suppliers_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);

CREATE TABLE Customers(
	CustomerId INT IDENTITY PRIMARY KEY,
	FullName VARCHAR(20) NOT NULL,
	PhoneNumber VARCHAR(20) NOT NULL,
	Email VARCHAR(20) NOT NULL,
	ShippingAddress VARCHAR(50) NOT NULL,
	RegistrationDate Date NOT NULL,

);

CREATE TABLE Reviews(
	ReviewId INT IDENTITY PRIMARY KEY,
	Rating INT NOT NULL,
	ReviewDate DATE NOT NULL,
	Comment VARCHAR(50) NOT NULL,
	ProductId INT,
	CustomerId INT,

	CONSTRAINT FK_Reviews_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
	CONSTRAINT FK_Reviews_Customers FOREIGN KEY(CustomerId) REFERENCES Customers(CustomerId)

);

CREATE TABLE Payments(
	PaymentId INT IDENTITY PRIMARY KEY,
	PaymentDate Date NOT NULL,
	Amount DECIMAL(10,2) NOT NULL,
	Status BIT NOT NULL,
	Method VARCHAR(20) NOT NULL

);

CREATE TABLE Orders(
	OrderId INT IDENTITY PRIMARY KEY,
	Status BIT NOT NULL,
	TotalAmount DECIMAL(10,2) NOT NULL,
	OrdertDate Date NOT NULL,
	CustomerId INT,

	CONSTRAINT FK_Orders_Customers FOREIGN KEY(CustomerId) REFERENCES Customers(CustomerId)

);

CREATE TABLE Orders_payments(
	OrderId INT,
	PaymentId INT,

	CONSTRAINT PK_Orders_payments PRIMARY KEY (OrderId,PaymentId),
	CONSTRAINT FK_Orders_payments_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
	CONSTRAINT FK_Orders_payments_Payments FOREIGN KEY (PaymentId) REFERENCES Payments(PaymentId),

);

CREATE TABLE OrderItems(
	OrderItemId  INT IDENTITY PRIMARY KEY,
	Quantity INT NOT NULL,
	UnitPrice DECIMAL NOT NULL,
	OrderId INT,
	ProductId INT,

	CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
	CONSTRAINT FK_OrderItems_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId),

);

CREATE TABLE Shipments(
	ShipmentId INT  IDENTITY PRIMARY KEY,
	ShipmentDate Date NOT NULL,
	Status BIT NOT NULL,
	DeliveryDate Date NOT NULL,
	CarrierName VARCHAR(20) NOT NULL,
	TrackingNumber VARCHAR(20) NOT NULL,
	OrderId INT,

	CONSTRAINT FK_Shipments_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),

);