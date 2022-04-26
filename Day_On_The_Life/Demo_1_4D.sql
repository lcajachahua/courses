DATABASE RETAIL;

-- 4D Analytics Hands-on: Time Series Transformation          --
----------------------------------------------------------------

/* Transforming the Web Navigation Log into a Time Series Table */

SELECT $TD_TIMECODE_RANGE AS T_RANGE, 
COUNT(DISTINCT CUSTOMER_ID) AS QTY_CUSTOMERS, COUNT(PAGE) AS QTY_PAGES
FROM WEB 
WHERE TD_TIMECODE BETWEEN TIMESTAMP '2018-03-12 00:00:00.0000' AND TIMESTAMP '2018-05-21 23:59:59.000000'
GROUP BY TIME (DAYS(1))                                          
USING TIMECODE(TD_TIMECODE)
FILL (NULLS)
ORDER BY 1;


/* Transforming the Purchases Table into a Time Series Table */

SELECT $TD_TIMECODE_RANGE AS T_RANGE, CAST(END($TD_TIMECODE_RANGE) AS DATE) AS TRANS_DT, 
COUNT(DISTINCT CUSTOMER_ID) AS QTY_CUSTOMERS, AVG(UNIT_PRICE) AS AVG_PRICE
FROM PURCHASE 
WHERE TRANSACTION_DT BETWEEN TIMESTAMP '2018-03-12 00:00:00.0000' AND TIMESTAMP '2018-05-21 23:59:59.000000'
GROUP BY TIME (DAYS(1))                                          
USING TIMECODE(TRANSACTION_DT)
FILL (0)
ORDER BY 1;



-- 4D Analytics Hands-on: Temporal Table                      --
-- This query returns a list of customers from CUSTOMER table --
----------------------------------------------------------------

SELECT CUSTOMER_ID, F_NAME, L_NAME, CUST_ZIP, VALIDITY, 
CAST(CUST_LOCATION AS VARCHAR(50)) AS CUST_LOCATION
FROM CUSTOMER WHERE CUSTOMER_ID=1455
ORDER BY 4;


/* Getting currently valid records today */

CURRENT VALIDTIME                      
SELECT CUSTOMER_ID, F_NAME, L_NAME, CUST_ZIP, VALIDITY, 
CAST(CUST_LOCATION AS VARCHAR(50)) AS CUST_LOCATION
FROM CUSTOMER
ORDER BY 1, 4;


/* Getting valid records based on '2011-06-30' */  

VALIDTIME AS OF DATE '2011-08-30'      
SELECT CUSTOMER_ID, F_NAME, L_NAME, CUST_ZIP, VALIDITY, 
CAST(CUST_LOCATION AS VARCHAR(50)) AS CUST_LOCATION
FROM CUSTOMER
ORDER BY 1, 4;





-- 4D Analytics Hands-on: Geospatial Table                                    --
-- This query determines the distance between customers and available servers --
--------------------------------------------------------------------------------

/* Calculate distance between customer and server in KM */

VALIDTIME AS OF DATE '2018-05-31'
SELECT CUSTOMER_ID, S.SERVER_ID, CAST(CUST_LOCATION.ST_SphericalDistance(S.SERVER_LOCATION)/1000 AS DECIMAL(10,0)) AS KM_DISTANCE
FROM CUSTOMER C, SERVER S
	QUALIFY ROW_NUMBER() OVER(PARTITION BY CUSTOMER_ID ORDER BY KM_DISTANCE) = 1
ORDER BY 1, 3;

-- NOTE: Qualify will only get you the server with the shortest DISTANCE to a given customer --
















/* Ploting Customers in Tableau */  
CURRENT VALIDTIME                      
SELECT CUSTOMER_ID, F_NAME, L_NAME, CUST_ZIP, 
CUST_LOCATION.ST_X() AS CUS_LONG, 
CUST_LOCATION.ST_Y() AS CUS_LAT
FROM CUSTOMER C;



/* Ploting Servers in Tableau */  
SELECT SERVER_ID, SERVER_ZIP, 
SERVER_LOCATION.ST_X() AS SERVER_LONG, 
SERVER_LOCATION.ST_Y() AS SERVER_LAT
FROM SERVER;













/* Checking Web Sessions */

SELECT * FROM SESSIONIZE
         (ON (SELECT * FROM WEB)
             PARTITION BY CUSTOMER_ID ORDER BY TD_TIMECODE
               USING
               TIMECOLUMN('TD_TIMECODE')
               TIMEOUT(86400) 
               ) as T order by 2, 1; 
               
               

               
               
               
               
               
/* Path to Purchase */

SELECT * FROM NPATH
(ON WEB PARTITION BY CUSTOMER_ID ORDER BY TD_TIMECODE
    USING
    MODE(NONOVERLAPPING)
    PATTERN('E{1,5}.C')
    SYMBOLS
    (PAGE = 'Purchase'  AS C 
     ,PAGE <> 'Purchase' AS E)
    RESULT
    (   FIRST(CUSTOMER_ID OF ANY(E,C))    AS CUSTOMER_ID
       ,FIRST(TD_TIMECODE OF ANY(E,C))    AS DS_START
       ,LAST(TD_TIMECODE OF ANY(E,C))     AS DS_END
       ,COUNT(* OF E)                   AS EVENT_CNT
      ,ACCUMULATE(PAGE OF ANY(E,C))    AS PATH)
) AS DT;














-- 4D Analytics: Hands-on 4. 4D Analytics with JSON Data    
-- It calculates max distance between customer and the web server based on web traffic data.        --
-- It also calculates the distance between customers and their closest web server                   --
-- based on GROUP BY TIME grouping.                                                                 --
-- It then calculates the difference between the max distance of actual web traffic                 --
-- and the closest server.                                                                          --
-- Web data is pulled from JSON table (same data as WEB table but in JSON format                    --
-- utilizing a view.                                                                                --
------------------------------------------------------------------------------------------------------

/* First, we'll create a view against Web data in JSON format */
/* So the JSON data looks like a relational table. */


REPLACE VIEW WEB_JSON (DATE_TIME, CUSTOMER_ID, SERVER_ID, PAGE, BROWSE_ID ) AS
 (select CAST(weblog."TD_TIMECODE" AS TIMESTAMP(6)),
  CAST(weblog."CUSTOMER_ID" AS DECIMAL (18,0)),
  CAST(weblog."SERVER_ID"   AS VARCHAR(5)),
  CAST(weblog."PAGE"        AS VARCHAR(50)),
  CAST(weblog."BROWSE_ID"   AS VARCHAR(20))
from WEB_JSON_ONLY);


/* ----------------------------------------------------------------------------------------------------- */
/* -- Second, we run 4D Analytics (time series, temporal, and geospatial) using web data in JSON format  */
 
SELECT T1.T_RANGE, T1.CUSTOMER_ID, T1.W_COUNT, T2.CLOSEST_DISTANCE, 
(T1.MAX_DISTANCE - T2.CLOSEST_DISTANCE) AS DIFFERENCE, T2.SERVER_ID AS CLOSEST_SERVER
FROM
	(VALIDTIME AS OF DATE '2018-05-31' 
		SELECT $TD_TIMECODE_RANGE AS T_RANGE, $TD_GROUP_BY_TIME AS T_GROUP, C.CUSTOMER_ID, COUNT(W.DATE_TIME) AS W_COUNT, 
		CAST(MAX(C.CUST_LOCATION.ST_SphericalDistance(S.SERVER_LOCATION))/1000 AS DECIMAL(10,0)) AS MAX_DISTANCE
		FROM WEB_JSON W, CUSTOMER C, SERVER S  
		WHERE W.SERVER_ID = S.SERVER_ID AND
			W.CUSTOMER_ID = C.CUSTOMER_ID AND
			W.DATE_TIME BETWEEN TIMESTAMP '2018-03-01 00:00:00.0000' AND TIMESTAMP '2018-05-31 23:59:59.000000'
		GROUP BY TIME (HOURS(4) AND C.CUSTOMER_ID)
		USING TIMECODE(W.DATE_TIME)
	) AS T1,
	(SELECT * FROM 
		(VALIDTIME AS OF DATE '2018-05-31'
		SELECT C.CUSTOMER_ID, S.SERVER_ID, CAST(C.CUST_LOCATION.ST_SphericalDistance(S.SERVER_LOCATION)/1000 AS DECIMAL(10,0)) AS CLOSEST_DISTANCE
		FROM CUSTOMER C, SERVER S 
		) D1
			QUALIFY ROW_NUMBER()OVER(PARTITION BY CUSTOMER_ID ORDER BY CLOSEST_DISTANCE) = 1
	) AS T2
WHERE T1.CUSTOMER_ID = T2.CUSTOMER_ID
ORDER BY 2,1;







--- https://downloads.teradata.com/extensibility/articles/fun-with-teradata-and-geometry
--- https://downloads.teradata.com/extensibility/articles/adding-geospatial-location-data-2-minute-guide
