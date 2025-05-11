-- Create Apple Table 

-- Stores Table

create table stores(
store_id varchar(10) Primary key,
store_name varchar(30),
city varchar(30),
country varchar(30)
);

select * from stores;

--CAREGORIES TABLE

create table category(
category_id varchar(10) primary key,
category_name varchar(30)
);

select * from category;

--PRODUCTS TABLE

create table products(
product_id varchar(10) primary key,
product_name varchar(35),
category_id varchar(10),
launch_date date,
price float,
constraint fk_category foreign key (category_id) references category(category_id)
);

select * from products;


--SALES TABLE
drop table Sales;
create table sales(
sale_id varchar(10) primary key,
sale_date date,
store_id varchar(10),
product_id varchar(10),
quantity int,
constraint fk_store foreign key (store_id) references stores(store_id),
constraint fk_product foreign key (product_id) references products(product_id)
);

select * from sales;

--WARRANTY TABLE

create table warranty(
claim_id varchar(10) primary key,
claim_date date,
sale_id varchar(10),
repair_status varchar(20),
foreign key (sale_id) references sales(sale_id)
);

select * from warranty;


-- NOW LET'S START ALL THE QUESTION AND ANSWERS --

-- Let's run some basic Query to see how our database or our table look like's 

--To view Data

select * from category;
select * from products;
select * from sales;
select * from stores;
select * from warranty;

--Exploratory Data Analysis

select distinct repair_status from warranty;

select distinct store_name from stores;

select distinct category_name from category;

select distinct product_name from products;

select count(*) from sales;


explain Analyze -- Get some 
  Select * from sales where product_id ='P-40';

select count(*) as Total_P40_sales from sales where product_id = 'P-40'

--Improve Query Performance
create index sales_product_id on sales(product_id);

select * from sales where product_id ='P-40';

--After creation of indexes query performances are increased to
--"Planning Time: 0.118 ms"
--"Execution Time: 6.324 ms"

create index sales_store_id on sales(store_id);

create index sales_quantity on sales(quantity);

create index sale_date on sales(sale_date);

create index sales_product_id_store_id on sales(product_id, store_id);

--Business Problems

--1.find number of stores in each country


Select country, Count(*) AS NO_Of_Stores from stores 
  Group by Country 
  Order BY 	2 DESC    -- 	{ Here 2 Means NO_Of_Stores } --



--2.calculate the total number of units sold by each store.
   -- In this Question we using the JOIN Clause --
Select * from sales
Select * from stores

SELECT 
    Sales.store_id, 
    Stores.store_name, 
    SUM(Sales.quantity) AS total_units_sold
FROM Sales  
JOIN Stores  
    ON Stores.store_id = Sales.store_id
GROUP BY Sales.store_id, Stores.store_name
ORDER BY total_units_sold DESC;

--  3.Identify how many sales occurred in December 2023.

Select COUNT(*) AS Total_Sales
    From Sales 
	  Where to_char(sale_date, 'MM-YYYY' )= '12-2023' ;
 
-- To_char is especially useful if your database stores dates as full timestamps, but you only want results based on month and year. --

-- TO_CHAR(sale_date, 'MM-YYYY') → Converts the date into a text format MM-YYYY, meaning:
                -- 12 for the month (December)
                 -- 2023 for the year

--  4 .Determine how many stores have never had a warranty claim filed.

Select  Count(*) From Stores 
 Where Store_id not in (  Select distinct store_id
       From sales  
	       right Join warranty on  
		         sales.sale_id = warranty.sale_id );

  

-- 5. Calcutate th percentage of warranty claims marked as "Rejected" .
Select * from warranty


Select ROUND 
   ( Count(claim_id)  / (Select Count(*) From warranty)::numeric * 100,1 ) AS Rejected_Percetage 
From Warranty
    Where repair_status = 'Rejected';


-- 6. Identify which store had the highest total units sold in the last year.
	     
	   
SELECT 
    s.store_id,  
    st.store_name, 
    SUM(s.quantity) AS total_units_sold
FROM sales AS s
JOIN stores AS st  
    ON st.store_id = s.store_id 
WHERE sale_date >= (SELECT current_date - INTERVAL '1 year')
GROUP BY s.store_id, st.store_name
ORDER BY total_units_sold DESC
LIMIT 1;



--7.Count the number of unique products sold in the last year.

select * from sales;

Select COUNT(DISTINCT Product_id)
  From sales 
Where sale_date >= (SELECT current_date - INTERVAL '1 year')


--8.Find the average price of products in each category.
select * from products
select * from category

Select P.category_id,C.Category_name , 
ROUND(Avg(p.price)::numeric, 2) as Avg_price
From Products AS P
  JOIN Category AS C
     on P.category_id = C.category_id
	   Group by 1,2
Order BY 3 DESC


--9.How many warranty claims were filed in 2024?

Select * from warranty

Select Count(*) from warranty 
    Where  
      to_char(Claim_date ,'yyyy') = '2024'

--10.For each store, identify the best-selling day based on highest quantity sold.  ****** Tough Question *******

Select * From

 (
Select store_id, to_char(sale_date,'day') as day_name,
  sum(quantity) as Total_Quantity_sold,
  rank() over (partition by store_id order by sum(quantity)DESC) as rank  -- Here is ranking method is used and it is one of the most comman --
  from sales 
  group by 1 ,2
 ) as table_base_1
 
Where rank = 1

--11.Identify the least selling product in each country for each year based on total units sold.

Select * from sales;
select * from products
Select * from stores


with Product_rank
as
(
Select p.Product_name , st.country,sum(s.quantity),
rank() over(partition by st.country order by sum(s.quantity)) as least_sold_product
From sales  as s
 JOIN stores as st  ON s.store_id = st.store_id
  JOIN Products  as p 
      on s.product_id = p.product_id
	  Group by 1,2
)
select * from Product_rank where least_sold_product = 1;


--12.Calculate how many warranty claims were filed within 180 days of a product sale.

Select COUNT(*) as No_of_Warranty_claims From Warranty as W
  JOIN sales as s
   on w.sale_id = s.sale_id
 Where w.claim_date - s.sale_date > 0 and w.claim_date - s.sale_date <= 180

--13.Determin how many warranty claims were filed for products launched in the last two years

Select * from products
select * from warranty
select * from sales

SELECT 
    p.product_name, 
    COUNT(w.claim_id) AS total_warranty_claims, 
    COUNT(s.sale_id) AS total_sales
FROM Warranty AS w 
RIGHT JOIN sales AS s
    ON w.sale_id = s.sale_id
JOIN products AS p
    ON p.product_id = s.product_id
WHERE launch_date >= (current_date - INTERVAL '2 years')
GROUP BY 
    1
HAVING 
   COUNT(w.claim_id) > 0;


--14 .List the months in the last four years where sates exceeded units in the USA.


SELECT
    TO_CHAR(s.sale_date, 'MM-YYYY') AS Months,
    SUM(s.quantity) AS No_of_Units_Sold
FROM
    sales AS s
JOIN
    stores AS st
        ON s.store_id = st.store_id
WHERE
    st.country = 'United States'
    AND s.sale_date >= CURRENT_DATE - INTERVAL '4 years'
GROUP BY
    Months
HAVING
    SUM(s.quantity) > 5000;


--15.Identify the product category with the most warranty claims filed in the last two years.


Select c.Category_name , count(w.claim_id) as Total_Claim
  From Warranty as w
  LEFT JOIN sales as s
ON w.sale_id = s.sale_id
JOIN products as p
ON p.product_id = s.product_id
JOIN category as c
ON c.category_id = p.category_id
where w.claim_date >= CURRENT_DATE - INTERVAL '2years'
group by 1
order by 2 desc;

--16.Determine the percentage chance of receiving warranty claims after each purchase for each country.


select
country,
total_units,
total_claim,
ROUND((total_claim::numeric/total_units::numeric) * 100, 2 )as percentage_of_risk
from
(select
st.country,
sum(s.quantity) as total_units,
count(w.claim_id) as total_claim
from sales as s
join stores as st
on st.store_id = s.store_id
left join warranty as w
on w.sale_id = s.sale_id
group by 1
) tr
order by 4 desc;
-- =========================================================================
      -- !!!! From Here Advance Question's Start!!!! --
-- -------------------------------------------------------------------



--  17.Analyze the year-by-year growth ratio for each store.  


WITH YearlySales AS (
    SELECT
        s.store_id,
        st.store_name,
        EXTRACT(YEAR FROM sale_date) AS Year_of_Sale,
        SUM(p.price * s.quantity) AS total_sale
    FROM
        sales AS s
    JOIN
        products AS p
            ON s.product_id = p.product_id
    JOIN
        stores AS st
            ON st.store_id = s.store_id
    GROUP BY
        s.store_id,
        st.store_name,
        EXTRACT(YEAR FROM sale_date)
),
GrowthRatio AS (
    SELECT
        store_name,
        Year_of_Sale,
        LAG(total_sale, 1, 0) OVER (PARTITION BY store_name ORDER BY Year_of_Sale) AS last_year_sale,
        total_sale AS current_year_sale
    FROM
        YearlySales
)
SELECT
    gr.store_name,
    gr.Year_of_Sale,
    gr.last_year_sale,
    gr.current_year_sale,
    ROUND(
        (gr.current_year_sale - gr.last_year_sale)::NUMERIC / gr.last_year_sale::NUMERIC * 100,
        2
    ) AS growth_ratio_YOY
FROM
    GrowthRatio AS gr
WHERE
    gr.last_year_sale > 0
ORDER BY
    gr.store_name,
    gr.Year_of_Sale;

--  18.Calculate the correlation between product price and warranty claims for products sold in the last five years, segmented by price range.


Select Case
When P.Price < 500 then 'Cheap Product'
when p.price between 500 and 1000 then 'Moderate Product'
else 'High Product' 
end as Price_segment,
  COUNT(w.claim_id) as total_claim
From warranty as w
  left join sales as s
on s.sale_id = w.sale_id
JOIN Products as p
on p.product_id = s.product_id
where claim_date >= current_date - interval '5years'
group by 1
order by 2 desc;

--  19.Identify the store with the highest percentage of "Completed" claims relative to total claims filed

select * from stores
select * from sales
select * from warranty
select * from  products


WITH CompletedRepairs AS (
    SELECT
	
        s.store_id,
        COUNT(w.claim_id) AS completed_repairs
    FROM
        sales AS s
    RIGHT JOIN
        warranty AS w
            ON s.sale_id = w.sale_id
    WHERE
        w.repair_status = 'Completed'
    GROUP BY
        s.store_id
),
TotalRepairs AS (
    SELECT
        s.store_id,
        COUNT(w.claim_id) AS total_repairs
    FROM
        sales AS s
    RIGHT JOIN
        warranty AS w
            ON s.sale_id = w.sale_id
    GROUP BY
        s.store_id
)
SELECT
    tr.store_id,
    tr.total_repairs,
    cr.completed_repairs,
    ROUND(
        (CAST(cr.completed_repairs AS NUMERIC) / CAST(tr.total_repairs AS NUMERIC)) * 100,
        2
    ) AS percentage_completed
FROM
    TotalRepairs AS tr
JOIN
    CompletedRepairs AS cr
        ON tr.store_id = cr.store_id
ORDER BY
    percentage_completed DESC;

--  20 .Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.

WITH MonthlySales AS (
    SELECT
        Store_id,
        EXTRACT(YEAR FROM Sale_Date) AS SaleYear,
        EXTRACT(MONTH FROM Sale_Date) AS SaleMonth,
        SUM(p.Price * s.Quantity) AS MonthlyProfit
    FROM
        Sales AS s
    JOIN
        Products AS p ON s.Product_ID = p.Product_ID
    GROUP BY
        Store_id,
        SaleYear,
        SaleMonth
)
SELECT
    ms.Store_id,
    ms.SaleYear,
    ms.SaleMonth,
    ms.MonthlyProfit,
    SUM(ms.MonthlyProfit) OVER (PARTITION BY ms.Store_id ORDER BY ms.SaleYear, ms.SaleMonth) AS RunningTotalProfit
FROM
    MonthlySales AS ms
ORDER BY
    ms.Store_id,
    ms.SaleYear,
    ms.SaleMonth;



