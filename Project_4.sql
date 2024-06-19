use music_store;
/* Q1: Who is the senior most employee based on job title? */
select * from employee
order by levels desc
limit 1;
-- Ans: Adams Andrew is the most senior employee --

/* Q2: Which countries have the most Invoices? */
select count(*) as c,billing_country
from invoice
group by billing_country
order by c desc;
-- Ans: USA has the most amount of invoices that is 131 --

/* Q3: What are top 3 values of total invoice? */
select * from invoice
order by total desc
limit 3;
-- Ans: The top three values are 23.7, 19.8 and 19.8 --

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */
select billing_city, sum(total) as t
from invoice
group by billing_city
order by t desc
limit 1;
-- Ans: Prague has the best customers with an invoice total of 273.24 --

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
select customer.customer_id,customer.first_name,customer.last_name,sum(invoice.total) as invoice_total
from customer
join invoice on customer.customer_id = invoice.customer_id
group by customer.customer_id, customer.first_name, customer.last_name
order by invoice_total desc
limit 1; 
-- Ans: FrantiÅ¡ek FrantiÅ¡ek is the best customer with total invoice of 144.54 --

/* Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */
select distinct email,first_name,last_name 
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in(
    select track_id from track
    join genre on track.genre_id = genre.genre_id
    where genre.name="Rock")
        
order by email;
    
/* Q7: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */
select artist.artist_id, artist.name, count(artist.artist_id) as songs_count
from artist
join album2 on artist.artist_id = album2.artist_id
join track on album2.album_id =track.album_id
join genre on track.genre_id = genre.genre_id
where genre.name = "Rock"
group by artist.artist_id, artist.name
order by songs_count desc
limit 10;

/* Q8: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */
select name,milliseconds
from track
where milliseconds >(
 select avg(milliseconds) as avg_length
 from track)
order by milliseconds desc;

/* Q9: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */
SELECT 
    customer.first_name, 
    customer.last_name, 
    artist.name,
    round(SUM(invoice_line.unit_price * invoice_line.quantity),2) AS total_spent
FROM 
    customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
JOIN track ON invoice_line.track_id = track.track_id
JOIN album2 ON track.album_id = album2.album_id
JOIN artist ON album2.artist_id = artist.artist_id
GROUP BY 
    customer.first_name, 
    customer.last_name, 
    artist.name
ORDER BY 
    total_spent DESC;
    
/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */
WITH popular_genre AS (
    SELECT  
        customer.country,
        genre.genre_id,
        genre.name,
        COUNT(il.quantity) AS purchases,
        ROW_NUMBER() OVER (PARTITION BY customer.country ORDER BY COUNT(il.quantity) DESC) AS row_num
    FROM 
        customer
        JOIN invoice ON customer.customer_id = invoice.customer_id
        JOIN invoice_line AS il ON invoice.invoice_id = il.invoice_id
        JOIN track ON il.track_id = track.track_id
        JOIN genre ON track.genre_id = genre.genre_id
    GROUP BY 
        customer.country,
        genre.genre_id,
        genre.name
)
SELECT 
    country,
    genre_id,
    name,
    purchases
FROM 
    popular_genre
WHERE 
    row_num = 1
ORDER BY 
    country;

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */
WITH Customer_Country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customer_Country WHERE RowNo <= 1

