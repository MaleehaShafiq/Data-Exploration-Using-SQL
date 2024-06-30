use mintclassics;
-- Step 1: Explore Products Currently in Inventory
-- Query 1: List all products with their inventory details.
SELECT p.productCode, p.productName, p.quantityInStock, w.warehouseName
FROM Products p
JOIN Warehouses w ON p.warehouseCode = w.warehouseCode;

-- Step 2: Determine Important Factors Influencing Inventory Reorganization/Reduction
-- Query 2: Identify products stored in each warehouse and their quantities.
SELECT w.warehouseName, p.productName, p.quantityInStock
FROM Products p
JOIN Warehouses w ON p.warehouseCode = w.warehouseCode
ORDER BY w.warehouseName, p.productName;

-- Query 3: Check the sales figures for each product to understand their movement
SELECT p.productCode, p.productName, SUM(od.quantityOrdered) AS totalQuantitySold
FROM Products p
JOIN Orderdetails od ON p.productCode = od.productCode
GROUP BY p.productCode, p.productName
ORDER BY totalQuantitySold DESC;
-- The most sold item is 1992 Ferrari 360 Spider red with total quantity sold of 1808.

-- Step 3: Provide Analytic Insights and Data-Driven Recommendations
-- Query 4: Find products with high inventory but low sales.
SELECT p.productCode, p.productName, p.quantityInStock, IFNULL(SUM(od.quantityOrdered), 0) AS totalQuantitySold
FROM Products p
LEFT JOIN Orderdetails od ON p.productCode = od.productCode
GROUP BY p.productCode, p.productName, p.quantityInStock
HAVING totalQuantitySold < (SELECT AVG(od.quantityOrdered) FROM Orderdetails od);
/*The product with a high inventory and lowest sale is 1985 
Toyota Supra with an quantity of 7733 in stocks that has not been sold.*/

-- Query 5: Sales contribution by each warehouse
SELECT w.warehouseName, SUM(od.quantityOrdered * od.priceEach) AS totalSales
FROM Warehouses w
JOIN Products p ON w.warehouseCode = p.warehouseCode
JOIN Orderdetails od ON p.productCode = od.productCode
GROUP BY w.warehouseName
ORDER BY totalSales DESC;
/*
warehouseName    totalSales
East             3,853,922.49
North            2,076,063.66
South            1,876,644.83
West             1,797,559.63
*/

-- Query 6: Order fulfilment time by each warehouse
SELECT w.warehouseName, AVG(DATEDIFF(o.shippedDate, o.orderDate)) AS avgFulfillmentTime
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
JOIN warehouses w ON p.warehouseCode = w.warehouseCode
WHERE o.status = 'Shipped'
GROUP BY w.warehouseName;

/*
West warehouse has the shortest average fulfillment time at 3.52 days, indicating the most efficient order processing.
East warehouse has a reasonable fulfillment time at 4.00 days, showing solid performance.
South warehouse has the longest fulfillment time at 4.28 days, suggesting potential inefficiencies.
North warehouse has a fulfillment time of 3.88 days, indicating fairly efficient processing with room for improvement.
*/

--  Determining if any warehouse can  be closed:
/* Ensure that other warehouses can handle the additional stock from the South warehouse.
-- Step 1: Determine the Total Inventory in Each Warehouse:*/
SELECT w.warehouseCode, w.warehouseName, SUM(p.quantityInStock) AS currentInventory
FROM warehouses w
JOIN products p ON w.warehouseCode = p.warehouseCode
GROUP BY w.warehouseCode, w.warehouseName;

-- Step 2: Calculate the Total Capacity of Each Warehouse
SELECT 
    w.warehouseCode, 
    w.warehouseName, 
    w.warehousePctCap, 
    round(SUM(p.quantityInStock) / (w.warehousePctCap / 100),2) AS totalCapacity
FROM 
    Warehouses w
JOIN 
    Products p ON w.warehouseCode = p.warehouseCode
GROUP BY 
    w.warehouseCode, 
    w.warehouseName, 
    w.warehousePctCap;

-- Step 3: Finding the total capacity in south warehouse
SELECT 
    w.warehouseCode, 
    w.warehouseName, 
    SUM(p.quantityInStock) AS southInventory
FROM 
    Warehouses w
JOIN 
    Products p ON w.warehouseCode = p.warehouseCode
WHERE 
    w.warehouseName = 'South'
GROUP BY 
    w.warehouseCode, 
    w.warehouseName;
-- The total inventory in south warehouse is 79380

-- Step 4: Finding if other warehouses can absorb the quantity in south
WITH fullCapacities AS (
    SELECT 
        w.warehouseCode, 
        w.warehouseName, 
        (SUM(p.quantityInStock) / (w.warehousePctCap / 100)) AS totalCapacity
    FROM 
        Warehouses w
    JOIN 
        Products p ON w.warehouseCode = p.warehouseCode
    GROUP BY 
        w.warehouseCode, 
        w.warehouseName, 
        w.warehousePctCap
)

-- Main query to calculate the remaining capacity and check against South warehouse inventory
SELECT 
    w.warehouseCode, 
    w.warehouseName, 
    w.warehousePctCap,
    ROUND(fc.totalCapacity - SUM(p.quantityInStock), 2) AS remainingCapacity
FROM 
    Warehouses w
JOIN 
    Products p ON w.warehouseCode = p.warehouseCode
JOIN 
    fullCapacities fc ON fc.warehouseCode = w.warehouseCode
WHERE 
    w.warehouseName <> 'South'
GROUP BY 
    w.warehouseCode, 
    w.warehouseName, 
    w.warehousePctCap, 
    fc.totalCapacity
HAVING 
    ROUND(fc.totalCapacity - SUM(p.quantityInStock), 2) >= 
    (
        SELECT 
            SUM(p.quantityInStock)
        FROM 
            Warehouses w2
        JOIN 
            Products p ON w2.warehouseCode = p.warehouseCode
        WHERE 
            w2.warehouseName = 'South'
    );
        
/* 
Since both the East and West warehouses have a remaining capacity greater 
than the current inventory in the South warehouse, it is possible to relocate 
the inventory to these warehouses. However, other factors must be considered, such as:

1. Cost analysis: If the South warehouse is cheaper to run, closing it might not yield the desired cost savings.
2. Supplier and distribution network: The South warehouse might be strategically important for receiving supplies 
   and distributing products efficiently.
*/
