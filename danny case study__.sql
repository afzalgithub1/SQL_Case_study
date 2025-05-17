create database danny_case;
use danny_case;
-- drop table daily_sales;
drop table sales_table;


CREATE TABLE sales (
 customer_id VARCHAR(1),
 order_date DATE,
  product_id INT);
  
INSERT INTO sales
VALUES
('A', '2021-01-01', '1'),
('A', '2021-01-01', '2'),
('A', '2021-01-07', '2'),
('A', '2021-01-10', '3'),
('A', '2021-01-11', '3'),
('A', '2021-01-11', '3'),
('B', '2021-01-01', '2'),
('B', '2021-01-02', '2'),
('B', '2021-01-04', '1'),
('B', '2021-01-11', '1'),
('B', '2021-01-16', '3'),
('B', '2021-02-01', '3'),
('C', '2021-01-01', '3'),
('C', '2021-01-01', '3'),
('C', '2021-01-07', '3');  

select * from sales;

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

  select * from menu;
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  select * from members;

  -------------======================-----QUESTIONS-----------------------===============================-----------=

--1. What is the total amount each customer spent at the restaurant?

select customer_id, sum(m.price) as money_spent

from sales as s
inner join menu as m
on s.product_id = m.product_id
group by 1
order by 2;

----------------------------------------------------------------------------------------

--2. How many days has each customer visited the restaurant?

select CUSTOMER_ID, count(distinct order_date) as cust_visit
from sales
group by 1
order by 2 desc;
--------------------------------------------------------------------

--3. What was the first item from the menu purchased by each customer?

/*select s.customer_id, m.product_name,
row_number() over(partition by product_name order by order_date) as first_ordered_item

from sales as s
inner join menu as m
on s.product_id = m.product_id;*/

-- my code

select customer_id, product_name , order_date, first_ordered_item
from
(
select s.customer_id, m.product_name , s.order_date ,
row_number() over(partition by customer_id order by order_date) as first_ordered_item

from sales as s
inner join menu as m
on s.product_id = m.product_id
) as sq
where FIRST_ORDERED_ITEM = 1;

-- this will also give customer details who ordered multiple order on same day
select customer_id, product_name , order_date, first_ordered_item
from
(
select s.customer_id, m.product_name , s.order_date ,
dense_rank() over(partition by customer_id order by order_date) as first_ordered_item

from sales as s
inner join menu as m
on s.product_id = m.product_id
) as sq
where FIRST_ORDERED_ITEM = 1;



--class solution
SELECT s.customer_id, m.product_name
FROM sales s
JOIN menu m USING(product_id)
WHERE s.order_date IN (
SELECT MIN(order_date)
 FROM sales
 GROUP BY customer_id);

 --chatgpt
SELECT s.customer_id, m.product_name
FROM sales s
JOIN menu m USING(product_id)
WHERE (s.customer_id, s.order_date) IN (
    SELECT customer_id, MIN(order_date)
    FROM sales
    GROUP BY customer_id
);

-----------------------------------------------------------------
--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name , count(s.order_date) as prod_purchase_count

from sales as s
inner join menu as m
on s.product_id = m.product_id

group by 1
order by 2 desc
limit 1;
-------------------------------------------------------------------

--5. Which item was the most popular for each customer?

SELECT customer_id, product_id, popular_item
FROM (
    SELECT 
        customer_id, 
        product_id, 
        COUNT(product_id) AS order_count, 
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) AS popular_item
    FROM sales
    GROUP BY customer_id, product_id
) AS sq
WHERE popular_item = 1;

------------------------------------------------------------------------

-- 6. Which item was purchased first by the customer after they became a member?

select * from sales;
select * from members;

select customer_id, product_name
from (
select
s.customer_id, s.order_date , m.product_name, row_number() over(partition by customer_id order by order_date) as latest_order
from sales as s
inner join menu as m on s.product_id = m.product_id
inner join members as me on s.customer_id = me.customer_id
where s.order_date >= me.join_date) as sq
where latest_order = 1;

-- class code

WITH after_join 
AS (
SELECT s.*
, m.product_name
, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS first
FROM sales s
JOIN members mm on s.customer_id =  mm.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date >= mm.join_date)

SELECT customer_id,product_name
FROM after_join
WHERE first = 1;
---------------------------------------------------------

--7. Which item was purchased just before the customer became a member?

select customer_id, product_name
from (
select
s.customer_id, s.order_date , m.product_name, dense_rank() over(partition by customer_id order by order_date desc) as latest_order
from sales as s
inner join menu as m on s.product_id = m.product_id
inner join members as me on s.customer_id = me.customer_id
where s.order_date < me.join_date) as sq
where latest_order = 1;

--- class code

WITH last_order_member
AS (
SELECT s.customer_id,s.product_id 
    , m.product_name
    , DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC)AS last
    -- using dense rank instead of row_num will take all equal rank output
FROM sales s
JOIN members mm USING(customer_id)
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date < mm.join_date)

SELECT customer_id,product_name
FROM last_order_member
WHERE last = 1;

--8. What is the total items and amount spent for each member before they became a member?

select s.customer_id, count(s.product_id) as total_item, sum(m.price) as total_spent
from sales as s
inner join menu as m on s.product_id = m.product_id
inner join members as me on s.customer_id = me.customer_id
WHERE s.order_date < me.join_date
group by s.customer_id
order by 1;

-- class code
SELECT s.customer_id,
 SUM(m.price) AS total_spent,
 COUNT(s.product_id) AS total_items
FROM sales s
JOIN members mm USING(customer_id)
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date < mm.join_date
GROUP BY 1;

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- case when product_name in ('curry', 'ramen') then

select sq.customer_id, sum(sq.points)
from
(
select s.customer_id, m.product_name,
case when m.product_name = 'sushi' then price*20
else price*10
end as points

FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id) as sq
group by 1;

select sq.customer_id, sum(sq.points)
from
(
select s.customer_id, m.product_id, m.price,
case when m.product_id = 1 then price*20
else price*10
end as points

FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id) as sq
group by 1;


-- class code
WITH points
AS (
SELECT s.customer_id, s.product_id,m.price,
 CASE 
        WHEN product_id = 1 THEN price * 20
        ELSE price *10
        END AS points
FROM sales s
JOIN menu m USING(product_id))

SELECT customer_id,
 SUM(points) AS total_points
FROM points
GROUP BY 1
;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select s.*, m.join_date

from sales as s
inner join members as m on s.customer_id = m.customer_id;

select * from sales;



----------------
WITH cust_points 
AS(

SELECT s.customer_id,
s.order_date,
mm.join_date,
DATE_ADD(mm.join_date, INTERVAL 6 DAY) AS end_promo,
s.product_id,
m.price,
 CASE 
        WHEN s.product_id = 1
            THEN m.price * 20 
        WHEN s.product_id != 1 AND 
        (s.order_date BETWEEN mm.join_date AND DATE_ADD(mm.join_date, INTERVAL 6 DAY))
            THEN (m.price * 20)
        ELSE m.price * 10
        END AS points
FROM sales s
JOIN members mm USING(customer_id)
JOIN menu m USING(product_id)
WHERE 
 s.order_date <= '2021-01-31'
)
SELECT customer_id
    , SUM(points)  AS total
FROM cust_points
GROUP BY customer_id;

