
USE OnlineRetailManagementSystem;
/*
1. INSERT OPERATIONS : 
	● Insert a new Customer (FullName, PhoneNumber, Email, ShippingAddress, RegistrationDate) 
	● Insert 3 new Suppliers 
	● Insert 2 Categories 
	● Insert a Product but only (Name, UnitPrice) 
	● Create table ArchivedStock (TranId, ProductId, QuantityChange, TranDate) Insert into ArchivedStock all StockTransactions before 2023 
 */
 INSERT INTO Customers 
	VALUES ('Ahmed Magdy','01553151405','ahmedmagdy@gmail.com','Alex-Agamy','2025-1-1');

INSERT INTO Suppliers
	VALUES  ('Ahmed','Egypt','ahmed@gamil.com','cairo-nasr city','01234567890'),
			('Mohamed','United States','mohamed@gmail.com','new york','01234567891'),
			('Aly','China','aly@gmail.com','Beijing','01234567892')


INSERT INTO Categories 
	VALUES  ('Electronics','Electronics marts',null),
			('laptop','laptop marts',1)

INSERT INTO Products (name,UnitPrice)
	VALUES ('MSI',30000)

CREATE TABLE ArchivedStock 
(TranId INT, 
ProductId INT, 
QuantityChange INT, 
TranDate DATE
);

INSERT INTO ArchivedStock
	SELECT TranId, ProductId, QuantityChange, TranDate
	FROM StockTtransactions
	WHERE TranDate < '2023-1-1'

 /*
2. TEMPORARY TABLES 
	● Create #CustomerOrders with (OrderId, CustomerId, TotalAmount) Insert customers who made orders above 5000. 
	● Create ##TopRatedProducts with (ProductId, Rating) Insert products with rating ≥ 4.5 
 
*/
CREATE TABLE #CustomerOrders  (
OrderId INT, 
CustomerId INT, 
TotalAmount DECIMAL(10,2)
);
INSERT INTO #CustomerOrders
	SELECT OrderId,CustomerId,TotalAmount
	FROM Orders
	WHERE TotalAmount > 5000


CREATE TABLE  ##TopRatedProducts (
ProductId INT , 
Rating INT 
);
INSERT INTO  ##TopRatedProducts
	SELECT ProductId, Rating
	FROM Reviews
	WHERE Rating > 4.5


/*
3. UPDATE OPERATIONS 
	●  Increase all UnitPrice by 10% for products under 100 EGP 
	●  Update Order Status: If TotalAmount > 5000 → “Premium” Else → “Standard” 
 
 */
 UPDATE Products 
 SET UnitPrice += UnitPrice * 0.1 
 WHERE UnitPrice < 100;

UPDATE Orders
SET Status = CASE
				WHEN TotalAmount > 5000 THEN 'Premium'
				ELSE 'Standard'
			 END ;

-- or another solve with 2 update instead 1
UPDATE Orders
SET Status = 'Premium'
WHERE TotalAmount > 5000; 

UPDATE Orders
SET Status = 'Standard'
WHERE TotalAmount <= 5000; 

/*
4. DELETE OPERATIONS 
	● Delete a Review by ReviewId 
	● Delete all Orders with Status = “Cancelled 
	● Delete OrderItems for a given OrderId 
*/
DELETE Reviews WHERE ReviewId = 1;
DELETE Orders WHERE Status = 'Cancelled';
DELETE OrderItems WHERE OrderId = 1;

/*

5. MERGE OPERATION 
	● Create table #ProductsUpdate (ProductId, Name, UnitPrice, StockQuantity) 
	MERGE logic: 
	If product exists → UPDATE price & stock 
	If new → INSERT 
	If a product exists in main table but not in update table → DELETE 
*/

CREATE TABLE #ProductsUpdate (
ProductId INT, 
Name VARCHAR(50), 
UnitPrice DECIMAL(10,2), 
StockQuantity INT
);

MERGE INTO Products AS  Target
USING #ProductsUpdate AS Source
ON TARGET.ProductId = Source.ProductId

WHEN MATCHED THEN
	UPDATE SET
	Target.UnitPrice = Source.UnitPrice,
	Target.StockQuantity = Source.StockQuantity

WHEN NOT MATCHED BY Target THEN 
	INSERT (Name,UnitPrice,StockQuantity)
	VALUES (Source.Name,Source.UnitPrice,Source.StockQuantity)

WHEN NOT MATCHED BY Source THEN
	DELETE

;