-- Jakie czynniki wpływają na zakup świeżych produktów?
-- Jak sprzedaż różni się w zależności od kodu pocztowego klienta, odległości od targowiska?
-- Jak rozkład cen produktów wpływa na sprzedaż? 

SELECT * 
FROM product_category;

-- Świeże produkty znajdują się pod product_category_id = 1

Select *
from product
where product_category_id = 1
order by product_id;

-- Aby wyłuskać informacje o sprzedaży produktów musimy połączyć tabelę product z custome purchases poprzez product_id.
-- Przy użyciu inner join otrzymamy produkty, które zostały faktycznie zakupione

Select *
from customer_purchases cp
inner join product p
on p.product_id = cp.product_id
where product_category_id = 1
order by p.product_id;

-- Czyścimy tabele z niepotrzebnych i zdubblowanych po łączeniu kolumn
-- Łączymy wynik z tabelą market_date_info poprzez market_date. Wybieramy right join,
-- ponieważ interesują nas także dni kiedy nie było zakupów

SELECT
    mdi.market_date,
    mdi.market_week,
    mdi.market_year,
    mdi.market_rain_flag,
    mdi.market_snow_flag,
    cp.market_date,
    cp.customer_id,
    cp.quantity,
    cp.cost_to_customer_per_qty,
    p.product_category_id
FROM customer_purchases cp
    INNER JOIN product p
        ON cp.product_id = p.product_id
            AND p.product_category_id = 1
    RIGHT JOIN market_date_info mdi
        ON mdi.market_date = cp.market_date;

-- SPRZEDAŻ TYGODNIOWA
-- Otrzymany wynik grupuję przez rok i tydzień tak, aby otrzymać sprzedaż z podziałem na tygodnie w danym roku
-- Wyciągam info czy pada deszcz lub śnieg max(market_rain_flag) = 1 czyli padał deszcz
-- określam min i max temperaturę w te tygodnie
-- wyciągam wartość sprzedaży zaokrągloną do 2 i zmieniającą wartość null na 0

SELECT
    mdi.market_year,
    mdi.market_week,
    MAX(mdi.market_rain_flag) AS market_week_rain_flag,
    MAX(mdi.market_snow_flag) AS market_week_snow_flag,
    MIN(mdi.market_min_temp) AS minimum_temperature,
    MAX(mdi.market_max_temp) AS maximum_temperature,
    MIN(mdi.market_season) AS market_season,
    ROUND(COALESCE(SUM(cp.quantity * cp.cost_to_customer_per_qty), 0), 2) AS weekly_category1_sales
FROM customer_purchases cp 
    INNER JOIN product p
        ON cp.product_id = p.product_id
            AND p.product_category_id = 1
    RIGHT JOIN market_date_info mdi
        ON mdi.market_date = cp.market_date
GROUP BY
    mdi.market_year,
    mdi.market_week;
    
-- Ograniczam się do potrzebynych wartości
-- Stosuje case oraz coalesce, aby uniknąć nulli 
-- Ustawiam flagę na kukurydzę, żeby zobaczyć czy jej obecność ma wpływ na sprzedaż świeżych produktów

SELECT
    mdi.market_year,
    mdi.market_week,
    COUNT(DISTINCT vi.vendor_id) AS vendor_count,
    COUNT(DISTINCT vi.product_id) AS unique_product_count,
    SUM(CASE WHEN p.product_qty_type = 'unit' THEN vi.quantity ELSE 0 END) AS unit_products_qty,
    SUM(CASE WHEN p.product_qty_type = 'lbs' THEN vi.quantity ELSE 0 END) AS bulk_products_lbs,
    ROUND(COALESCE(SUM(vi.quantity * vi.original_price), 0), 2) AS total_product_value,
    MAX(CASE WHEN p.product_id = 16 THEN 1 ELSE 0 END) AS corn_available_flag
FROM vendor_inventory vi 
   INNER JOIN product p
       ON vi.product_id = p.product_id
   RIGHT JOIN market_date_info mdi
       ON mdi.market_date = vi.market_date
GROUP BY
   mdi.market_year,
   mdi.market_week;








        
