use retail;

select * from transactions;

select * from productinventory;

select * from customerprofiles ;

SELECT MIN(transactionid)
  FROM salestransaction
  GROUP BY transactionid;
  
  describe salestransaction;
  describe transactions;
  describe productinventory;
  describe customerprofiles;
  
#Data Cleaning
#correct column names  
ALTER TABLE productinventory RENAME COLUMN ï»¿ProductID to ProductID;
  
ALTER TABLE salestransaction RENAME COLUMN ï»¿TransactionID to TransactionID;
  
ALTER TABLE customerprofiles RENAME COLUMN ï»¿CustomerID to CustomerID;
  
  #Identify duplicate values if any
select transactionid,count(*)
from salestransaction
group by transactionid
having count(*)>1;

select ProductId,count(*)
from productinventory
group by ProductId
having count(*)>1;

select CustomerId,count(*)
from customerprofiles
group by CustomerId
having count(*)>1;

#delete the duplicate row by create new table with distinct records

create table transactions as
select distinct * from salestransaction;

#Handle null values if any

SELECT * FROM customerprofiles where Location='UNKNOWN';

#Update missing values to UNKNOWN

SET SQL_SAFE_UPDATES = 0;

UPDATE customerprofiles
SET Location = 'UNKNOWN'
WHERE Location = '';

#change data type 

ALTER TABLE transactions MODIFY COLUMN Transactiondate DATE;
ALTER TABLE productinventory MODIFY COLUMN price DECIMAL(10,2);
ALTER TABLE transactions MODIFY COLUMN price DECIMAL(10,2);

#Clean spaces

UPDATE productinventory SET productname = TRIM(productname);

#handle outliers
SELECT MIN(price), MAX(price), AVG(price), STD(price) FROM transactions;

SELECT * FROM transactions
WHERE price > (SELECT AVG(price) + 3*STD(price) FROM transactions)
   OR price < (SELECT AVG(price) - 3*STD(price) FROM transactions);
   
#price differs in product and transaction table so updating with correct values
   
update transactions SET price = 93.12
WHERE price = 9312.00 AND productid = 51;

#Product sales analysis

#Top 10 high sales products
select ProductID,SUM(Price*QuantityPurchased) as TotalRevenue FROM
transactions
GROUP BY ProductID
order by TotalRevenue DESC
LIMIT 10;

#Lowest sales 10 products
SELECT ProductID,SUM(QuantityPurchased) as TotalUnitsSold
from transactions
GROUP BY ProductID
HAVING TotalUnitsSold > 0
order by TotalUnitsSold 
LIMIT 10;


#sales trends
select TransactionDate as DATETRANS,COUNT(TransactionID) as Transaction_count,
SUM(QuantityPurchased) as TotalUnitsSold,ROUND(Sum(Price*QuantityPurchased),2) as TotalSales
from transactions
group by TransactionDate
order by DATETRANS DESC;

#Customer segmentation

With Quantityofproducts as 
(select s.CustomerID,SUM(s.QuantityPurchased) as TotalQuantityPurchased from
transactions s join customerprofiles c
on s.CustomerID=c.CustomerID
GROUP BY s.CustomerID)
select CASE   
WHEN  TotalQuantityPurchased>=1 AND TotalQuantityPurchased<=10 then 'Low'
when TotalQuantityPurchased>=11  and TotalQuantityPurchased<=30 then 'Med'
ELSE 'High' 
END AS CustomerSegment,COUNT(*) from 
Quantityofproducts
group by CustomerSegment
;
#Repeated customers-total number of purchases made by each customer against each productID 
select CustomerID,ProductID,COUNT(TransactionID) as TimesPurchased
from transactions
GROUP BY CustomerID,ProductID
HAVING TimesPurchased>1
ORDER BY TimesPurchased DESC;

#low purchase frequency
select CustomerID,COUNT(TransactionID) AS NumberOfTransactions,SUM(Price*QuantityPurchased) as TotalSpent
from transactions
Group by CustomerID
HAVING COUNT(TransactionID)<=2
Order by NumberOfTransactions ASC,TotalSpent DESC;

#High Purchase frequency-the number of transaction along with the total amount spent by each customer which are on the higher side 
select CustomerID,COUNT(TransactionID) AS NumberOfTransactions,SUM(Price*QuantityPurchased) as TotalSpent
from transactions
Group by CustomerID
HAVING COUNT(TransactionID)>10 and sum(Price*QuantityPurchased)>1000
Order by TotalSpent DESC;

#Detect overstocked products

select p.productid,p.category,max(stocklevel),SUM(t.QuantityPurchased),SUM(t.Price*t.QuantityPurchased) as revenue from productinventory p join transactions t
on p.ProductID=t.ProductID
group by p.productid,p.category
order by revenue asc,max(stocklevel);

#DetectUnderstock products

select p.productid,p.category,min(stocklevel),SUM(t.QuantityPurchased),SUM(t.Price*t.QuantityPurchased) as revenue from productinventory p join transactions t
on p.ProductID=t.ProductID
group by p.productid,p.category
order by revenue desc;




#Product sales analysis
/*Beauty and Healthcare category generating the highest revenue indicates strong demand, 
effective marketing, or higher price points in this segment. This suggests focusing more 
inventory, marketing budgets, and personalized offers in this category to maximize profit.

home appliances have low price and available stock, but few units are sold. 
Without more data (e.g., customer feedback, 
marketing info, competitor analysis), the reason for low sales cannot be confirmed.”

#Customer Segmentation
7 Customers have purchased product quantity more than 30 (High)
559 Customers have purchased product quantity between 11 to 30
423 Customers have purchased product quantity between 1 to 10

#Customer behaviour Analysis

Customer id 685 has highest repated purchase for Beauty & Health category.shows strong brand/category loyalty. Consider exclusive loyalty rewards, 
early access to new products, or targeted offers for this customer.
Customer 936 has highest purchase
revenue with 12 transactions made.Maintain engagement with personalized communication, VIP perks, or retention campaigns.
and lowest purchase made by customer 94 with 1 transaction so one can Try win-back strategies
 like special discounts to encourage repeat purchases.
 
 #Inventory Management
 Beauty and health category product 139 have max stocklevel 390 with lowest revenue 484.10It  is likely overstocked and not selling well. It ties up capital and storage space.
Action: Investigate reasons (e.g., lack of demand, marketing, or high price) and consider discounts or promotional activities to boost sales..
 
 Beauty and health category product 17 have max stocklevel 208 with highest revenue 9450.00.It is popular—selling well and generating high revenue even with less stock.
Action: Monitor stock levels closely and prioritize replenishment to avoid stockouts and lost sales.