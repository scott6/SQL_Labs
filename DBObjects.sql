-- ===============================
-- Basic SQL Server Training Labs
-- ===============================
-- This script contains SQL code for various training labs covering indexing, query optimization, security, and backup strategies in SQL Server. 
-- Each section is labeled with the corresponding lab topic.

CREATE DATABASE LabDB;
GO
USE LabDB;
GO
-- Create Orders table with 1 million rows for testing indexing and query optimization
CREATE TABLE Orders (
    OrderID INT IDENTITY PRIMARY KEY,
    CustomerID INT,
    OrderDate DATETIME,
    TotalAmount DECIMAL(10,2),
    Status VARCHAR(20)
);
-- Insert 1 million rows of sample data
WITH Numbers AS (
    SELECT TOP (1000000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.objects a CROSS JOIN sys.objects b
)
INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, Status)
SELECT
    n+1,
    DATEADD(day, n % 5, GETDATE()),
    (n%5)*10000,
    CASE (n % 5)
        WHEN 0 THEN 'Completed'
        WHEN 1 THEN 'In Progress'
        WHEN 2 THEN 'Pending'
        WHEN 3 THEN 'Cancelled'
        ELSE 'Waiting Approval'
    END
FROM Numbers;


-- Create Users table for SQL Injection lab
CREATE TABLE Users (
    UserID INT IDENTITY PRIMARY KEY,
    Username VARCHAR(50),
    Password VARCHAR(50)
);
INSERT INTO Users VALUES ('admin','admin123'), ('user','pass123');

-- Create a stored procedure for login functionality
-- Unsecured Stored Procedure
CREATE PROCEDURE sp_Login_Unsecured
    @Username VARCHAR(50),
    @Password VARCHAR(50)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'SELECT * FROM Users WHERE Username = ''' + @Username + ''' AND Password = ''' + @Password + '''';
    EXEC(@sql);
END;
-- Secured Stored Procedure
CREATE PROCEDURE sp_Login
    @Username VARCHAR(50),
    @Password VARCHAR(50)
AS
BEGIN
    SELECT * FROM Users WHERE Username = @Username AND Password = @Password;
END;
