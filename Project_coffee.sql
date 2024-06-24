USE Retail;

#first, lets explore our database of coffee shop sales

SELECT * FROM coffeeshopsales;


#what is the average price of all the different types of coffee at each store?

SELECT store_location, product_type, ROUND(AVG(unit_price),2) AS average
FROM coffeeshopsales
WHERE product_type LIKE '%coffee%'
GROUP BY store_location, product_type
ORDER BY store_location;


#Next, lets look at all our products and view how many times each 
#product_id was ordered across all stores, and see what was #1

SELECT product_id, COUNT(product_id) AS count_id
FROM coffeeshopsales
GROUP BY product_id
ORDER BY count_id DESC;

# product_id #71 is our highest selling product ID and there has been 3076 sold across all stores.

#lets figure out what product_id 71 is

SELECT product_detail 
FROM coffeeshopsales
WHERE product_id = '71'
LIMIT 1;

#chocalte croissant, easy to see how these are so popular!
#in the month of May, how much revenue did each individual store location make off of chocolate croissants?

#First, we should use our transaction date values in our dataset to create a new column
#that identifies which month the transaction took place in to make the month values
#more readable and accessible

ALTER TABLE coffeeshopsales
ADD COLUMN month_ TEXT;

SET SQL_SAFE_UPDATES = 0;

UPDATE coffeeshopsales
SET month_ = (CASE
		WHEN transaction_date LIKE '1%' THEN 'Jan'
        WHEN transaction_date LIKE '2%' THEN 'Feb'
        WHEN transaction_date LIKE '3%' THEN 'Mar'
        WHEN transaction_date LIKE '4%' THEN 'Apr'
        WHEN transaction_date LIKE '5%' THEN 'May'
        WHEN transaction_date LIKE '6%' THEN 'Jun'
        WHEN transaction_date LIKE '7%' THEN 'Jul'
        WHEN transaction_date LIKE '8%' THEN 'Aug'
        WHEN transaction_date LIKE '9%' THEN 'Sep'
        WHEN transaction_date LIKE '10%' THEN 'Oct'
        WHEN transaction_date LIKE '11%' THEN 'Nov'
        WHEN transaction_date LIKE '12%' THEN 'Dec'
        ELSE
			'n/a'
	END);

#Now let's identify how much each store made from chocolate croissants in May.

SELECT store_location,
month_,
product_id,
ROUND(SUM(unit_price),2) AS gross_profit_may
FROM coffeeshopsales
WHERE product_id = '71'
AND month_ = 'May'
GROUP BY store_location
ORDER BY gross_profit_may DESC;

#It looks like Hell's Kitchen's location sold the most chocolate croissants in the month of May
#with the location making $896, but is the chocolate croissant
#hell's kitchen's most frequently purchased item overall?

#Here I will use a simple subquery to perform a more complex aggregation that
#retrieves the max product count for Hell's kitchen in descending order.
SELECT product_detail, store_location, MAX(product_count) AS Max_quantity
FROM(
	SELECT product_detail, store_location, COUNT(product_id) AS product_count
	FROM coffeeshopsales
	GROUP BY product_detail,store_location)sub
WHERE store_location = "Hell's Kitchen"
GROUP BY product_detail, store_location
ORDER BY Max_quantity DESC LIMIT 5;

#we see that Hell's kitchen's most frequently bought item is the ouro barsileiro shot!

#Next, I'm going to be comparing the profits of each product
#between our lower manhatan location and our Astoria
#location for the month of Januray, while giving a rolling total
#to both quantify and visualize each locations differences in 
#total january revenue broken down by product

#This query will allow us to get a better picture of one
#location performing better over another.

WITH CTE AS (
	SELECT product_detail, 
    store_location, 
    SUM(unit_price) AS product_profit
FROM coffeeshopsales
WHERE month_ = 'Jan'
AND store_location = 'Lower Manhattan'
GROUP BY product_detail,store_location
),
CTE2 AS (
	SELECT product_detail, 
    store_location, 
    SUM(unit_price) AS product_profit
FROM coffeeshopsales
WHERE month_ = 'Jan'
AND store_location = 'Astoria'
GROUP BY product_detail,store_location
)
SELECT CTE.store_location,
CTE.product_detail,
CTE.product_profit,
SUM(CTE.product_profit) OVER(PARTITION BY CTE.store_location ORDER BY CTE.product_detail) 
AS rolling_total_manhattan,
CTE2.store_location,
CTE2.product_detail,
CTE2.product_profit,
SUM(CTE2.product_profit) OVER(PARTITION BY CTE2.store_location ORDER BY CTE2.product_detail) 
AS rolling_total_astoria
FROM CTE 
JOIN CTE2
 ON CTE.product_detail = CTE2.product_detail;
 
#This provides a much deeper picture that can uncover useful insights 
#in comparison to just showing the 2 locations monthly profits side by side

#Finally, our current coffee shop sales table seperates each individual product sale as a 
#transaction ID, even if its the same customer ordering multiple items at once
#like a latte ordered with a croissant.

#This is not very useful if we want to see things such as how much a customer
#is spending all together or understand what products customers tend to buy together.
#if we wanted to do this with our current table, we would have to look through the table 
#and find where the transaction time, date, and location are all match up. 
#This would be time consuming and not very practical!

#Let's figure out how much a customer is spending all together for their full order

#First, I will create a new column that gives the total amount spent for each individual transaction
ALTER TABLE coffeeshopsales
ADD total_spent INT;

UPDATE coffeeshopsales
SET total_spent = unit_price * transaction_qty;

#Now using our total transaction price, ill add together the transactions where the
#time, date, and location are all the same, giving us a customers' true total order amount.

SELECT store_id,
transaction_date,
transaction_time,
product_detail,
total_spent, 
SUM(total_spent) OVER(PARTITION BY transaction_time,transaction_date,store_id) AS total_order_price
FROM coffeeshopsales
ORDER BY transaction_date , transaction_time;

#Now we can easily see a full order price if a customer chooses to purchase more than 1 item
#and we can see what that total order amounts to. 

#At a quick glance we can see customers that are ordering more than 1 item 
#are combining a drink with a snack!

