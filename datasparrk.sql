SELECT * FROM customer_details;
SELECT * FROM exchange_details;
SELECT * FROM product_details;
SELECT * FROM sales_details;
SELECT * FROM stores_details;

-- customer table
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'customer_details';
UPDATE customer_details 
SET Birthday = STR_TO_DATE(Birthday, '%Y-%m-%d') 
WHERE Birthday IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE customer_details 
MODIFY Birthday DATE;

-- sales table
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'sales_details';
SET SQL_SAFE_UPDATES = 0;
UPDATE sales_details
SET Order_Date = STR_TO_DATE(Order_Date, '%Y-%m-%d')
WHERE Order_Date IS NOT NULL; 
ALTER TABLE sales_details
MODIFY Order_Date DATE;

-- stores table
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'stores_details';
UPDATE stores_details 
SET Open_Date = STR_TO_DATE(Open_Date, '%Y-%m-%d');
ALTER TABLE stores_details
MODIFY Open_Date DATE;

-- exchange rate table
UPDATE exchange_details SET Date = DATE(Date)
WHERE Date is NOT NULL;
ALTER TABLE exchange_details
MODIFY Date DATE;
SELECT date
FROM exchange_details
WHERE STR_TO_DATE(Date, '%Y-%m-%d') IS NULL;

-- 1. Overall female count
SELECT COUNT(Gender) AS Female_count
FROM customer_details
WHERE Gender = 'Female';

-- 2. Overall male count
SELECT COUNT(Gender) AS Male_count
FROM customer_details
WHERE Gender = 'Male';

-- 3. Count of customers in country-wise
SELECT sd.Country, COUNT(DISTINCT c.CustomerKey) AS customer_count
FROM sales_details c
JOIN stores_details sd ON c.StoreKey = sd.StoreKey
GROUP BY sd.Country
ORDER BY customer_count DESC;

-- 4. Overall count of customers
SELECT COUNT(DISTINCT s.CustomerKey) AS customer_count
FROM sales_details s;

-- 5. Count of stores in country-wise
SELECT Country, COUNT(StoreKey) AS store_count
FROM stores_details
GROUP BY Country
ORDER BY store_count DESC;

-- 6. Store-wise sales
SELECT s.StoreKey, sd.Country, SUM(Unit_Price_USD * s.Quantity) AS total_sales_amount
FROM product_details pd
JOIN sales_details s ON pd.ProductKey = s.ProductKey
JOIN stores_details sd ON s.StoreKey = sd.StoreKey
GROUP BY s.StoreKey, sd.Country;

-- 7. Overall selling amount
SELECT SUM(Unit_Price_USD * sd.Quantity) AS total_sales_amount
FROM product_details pd
JOIN sales_details sd ON pd.ProductKey = sd.ProductKey;


-- 8. CP and SP difference and profit
SELECT 
    Product_name, 
    Unit_price_USD, 
    Unit_Cost_USD, 
    ROUND(CAST(Unit_price_USD - Unit_Cost_USD AS DECIMAL(10, 2)), 2) AS diff,
    ROUND(CAST((Unit_price_USD - Unit_Cost_USD) / Unit_Cost_USD * 100 AS DECIMAL(10, 2)), 2) AS profit
FROM 
    product_details;
    
-- 9. Brand-wise selling amount
SELECT 
    Brand, 
    ROUND(CAST(SUM(Unit_price_USD * sd.Quantity) AS DECIMAL(10, 2)), 2) AS sales_amount
FROM 
    product_details pd
JOIN 
    sales_details sd ON pd.ProductKey = sd.ProductKey
GROUP BY 
    Brand;    

-- 10. Subcategory-wise selling amount
SELECT Subcategory, COUNT(Subcategory) AS subcategory_count
FROM product_details
GROUP BY Subcategory;

SELECT 
    Subcategory, 
    ROUND(CAST(SUM(Unit_price_USD * sd.Quantity) AS DECIMAL(10, 2)), 2)AS TOTAL_SALES_AMOUNT
FROM 
    product_details pd
JOIN 
    sales_details sd ON pd.ProductKey = sd.ProductKey
GROUP BY 
    Subcategory
ORDER BY 
    TOTAL_SALES_AMOUNT DESC;
    
-- 11. Country-wise overall sales
SELECT s.Country, SUM(pd.Unit_price_USD * sd.Quantity) AS total_sales
FROM product_details pd
JOIN sales_details sd ON pd.ProductKey = sd.ProductKey
JOIN stores_details s ON sd.StoreKey = s.StoreKey
GROUP BY s.Country;

SELECT s.Country, COUNT(DISTINCT s.StoreKey), SUM(pd.Unit_price_USD * sd.Quantity) AS total_sales
FROM product_details pd
JOIN sales_details sd ON pd.ProductKey = sd.ProductKey
JOIN stores_details s ON sd.StoreKey = s.StoreKey
GROUP BY s.Country; 

-- 12. Year-wise brand sales
SELECT 
    EXTRACT(YEAR FROM Order_Date) AS order_year, 
    pd.Brand, 
    ROUND(CAST(SUM(Unit_price_USD * sd.Quantity) AS DECIMAL(10, 2)), 2) AS year_sales
FROM 
    sales_details sd
JOIN 
    product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY 
    EXTRACT(YEAR FROM Order_Date), 
    pd.Brand;   
    

-- 13. Overall sales with quantity
SELECT Brand, SUM(Unit_Price_USD * sd.Quantity) AS sp, SUM(Unit_Cost_USD * sd.Quantity) AS cp,
       (SUM(Unit_Price_USD * sd.Quantity) - SUM(Unit_Cost_USD * sd.Quantity)) / SUM(Unit_Cost_USD * sd.Quantity) * 100 AS profit
FROM product_details pd
JOIN sales_details sd ON sd.ProductKey = pd.ProductKey
GROUP BY Brand;    

-- 14. Month-wise sales with quantity
SELECT DATE_FORMAT(Order_Date, '%Y-%m-01') AS month, SUM(Unit_Price_USD * sd.Quantity) AS sp_month
FROM sales_details sd
JOIN product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m-01')
LIMIT 0,1000;

-- 15. Month and year-wise sales with quantity
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m-01') AS month, 
    YEAR(Order_Date) AS year, 
    pd.Brand, 
    SUM(Unit_Price_USD * sd.Quantity) AS sp_month
FROM 
    sales_details sd
JOIN 
    product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY 
    month, 
    year,
    pd.Brand
LIMIT 0, 1000;

-- 16. Year-wise sales
SELECT 
    EXTRACT(YEAR FROM Order_Date) AS year, 
    SUM(Unit_Price_USD * sd.Quantity) AS sp_year
FROM 
    sales_details sd
JOIN 
    product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY 
    EXTRACT(YEAR FROM Order_Date);
    

-- 17. Comparing current month and previous month
WITH monthly_sales AS (
    SELECT DATE_FORMAT(Order_Date, '%Y-%m-01') AS month, SUM(Unit_Price_USD * sd.Quantity) AS sales
    FROM sales_details sd
    JOIN product_details pd ON sd.ProductKey = pd.ProductKey
    GROUP BY DATE_FORMAT(Order_Date, '%Y-%m-01')
)
SELECT month, sales, LAG(sales) OVER (ORDER BY month) AS Previous_Month_Sales
FROM monthly_sales;    

-- 18. Comparing current year and previous year sales
WITH yearly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM Order_Date) AS year, 
        SUM(Unit_Price_USD * sd.Quantity) AS sales
    FROM 
        sales_details sd
    JOIN 
        product_details pd ON sd.ProductKey = pd.ProductKey
    GROUP BY 
        EXTRACT(YEAR FROM Order_Date)
)
SELECT 
    year, 
    sales, 
    LAG(sales) OVER (ORDER BY year) AS Previous_Year_Sales
FROM 
    yearly_sales;
    
-- 19. Month-wise profit
WITH monthly_profit AS (
    SELECT 
        DATE_FORMAT(Order_Date, '%Y-%m-01') AS month, 
        SUM(Unit_Price_USD * sd.Quantity) - SUM(Unit_Cost_USD * sd.Quantity) AS profit
    FROM 
        sales_details sd
    JOIN 
        product_details pd ON sd.ProductKey = pd.ProductKey
    GROUP BY 
        DATE_FORMAT(Order_Date, '%Y-%m-01')
)
SELECT 
    month, 
    profit, 
    LAG(profit) OVER (ORDER BY month) AS Previous_Month_Profit,
    ROUND(((profit - LAG(profit) OVER (ORDER BY month)) / LAG(profit) OVER (ORDER BY month)) * 100, 2) AS profit_percent
FROM 
    monthly_profit;    
    
-- 20. Year-wise profit
WITH yearly_profit AS (
    SELECT YEAR(Order_Date) AS year, 
           SUM(Unit_Price_USD * sd.Quantity) - SUM(Unit_Cost_USD * sd.Quantity) AS profit
    FROM sales_details sd
    JOIN product_details pd ON sd.ProductKey = pd.ProductKey
    GROUP BY YEAR(Order_Date)
)
SELECT year, profit, LAG(profit) OVER (ORDER BY year) AS Previous_Year_Profit,
       ROUND(((profit - LAG(profit) OVER (ORDER BY year)) / LAG(profit) OVER (ORDER BY year)) * 100, 2) AS profit_percent
FROM yearly_profit;    
