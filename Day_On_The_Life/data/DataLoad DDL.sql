-- STEP 1: Creating RETAIL database 
-- Adjust Account if necessary
-- Depending on the image and its data volume limitation, DB PERM size may have to be adjusted
----------------------------------------------------------------------------------------------
/*
drop database retail;

CREATE DATABASE RETAIL FROM DBC AS
	PERMANENT = 12000000000,
	SPOOL     = 39000000000,
	TEMPORARY = 39000000000,
	ACCOUNT = 'DBC',
	FALLBACK,
	NO BEFORE JOURNAL,
	NO AFTER JOURNAL;

COMMENT ON RETAIL AS 'RETAIL database is a demo / training database created to demonstrate Teradata Database analytic functions in retail use case context.'; 

**/

DATABASE RETAIL;

--*************************************************************************************************
--*************************************************************************************************

-- STEP 2: Creating all necessary tables 


--Creating Call Center Calls table ------
-----------------------------------------

CREATE TABLE CALL_CENTER_CALLS
(CALL_ID VARCHAR(20),
CUSTOMER_ID DECIMAL(18,0),
CC_REP_ID DECIMAL(18,0),
CC_CALL_DT TIMESTAMP(6),
CALL_TYPE VARCHAR(50));



--Creating Customer Comment table ------
-----------------------------------------

CREATE TABLE CUST_COMMENT
(COMMENT_ID DECIMAL(18,0),
CUSTOMER_ID DECIMAL(18,0),
COMMENT_DT TIMESTAMP(6),
CHANNEL_TYPE VARCHAR(1),
CHANNEL_ID VARCHAR(20),
COMMENT_TEXT CLOB);



--Creating Customer table ------
-----------------------------------------

CREATE TABLE CUSTOMER
(CUSTOMER_ID DECIMAL(18,0) NOT NULL,
F_NAME VARCHAR(30),
L_NAME VARCHAR(30),
VALIDITY PERIOD(DATE) FORMAT 'YYYY-MM-DD' AS VALIDTIME,
CUST_ZIP VARCHAR(5),
CUST_LOCATION ST_GEOMETRY,
ETHNICITY VARCHAR(20),
GENDER CHAR(1),
CHURN_FLAG VARCHAR(1))
INDEX(CUST_LOCATION);



--Creating Product table ------
-----------------------------------------

CREATE TABLE PRODUCT
(PRODUCT_ID DECIMAL(18,0) NOT NULL,
PRODUCT_DESC VARCHAR(80),
CATEGORY VARCHAR(80));



--Creating Purchase table ------
-----------------------------------------

CREATE TABLE PURCHASE
(TRANSACTION_ID	VARCHAR(20),
LINE_ITEM_ID	DECIMAL (18,0),
CUSTOMER_ID	DECIMAL (18,0),
TRANSACTION_DT	TIMESTAMP(6),
STORE_ID	DECIMAL (18,0),
CHANNEL_TYPE	VARCHAR(1),
PRODUCT_ID	DECIMAL (18,0),
QTY	INTEGER,
UNIT_PRICE	FLOAT);



--Creating Server table ------
-----------------------------------------

CREATE TABLE SERVER
(SERVER_ID VARCHAR(5) NOT NULL,
SERVER_ZIP VARCHAR(5),
SERVER_LOCATION ST_GEOMETRY)
INDEX (SERVER_LOCATION);



--Creating Store table ------
-----------------------------------------

CREATE TABLE STORE
(STORE_ID DECIMAL(18,0) NOT NULL,
STORE_DESC VARCHAR(80),
STORE_ZIP VARCHAR(5),
STORE_LOCATION ST_GEOMETRY)
INDEX(STORE_LOCATION);



--Creating Store Visit table ------
-----------------------------------------

CREATE TABLE STORE_VISIT
(STORE_ID DECIMAL(18,0),
CUSTOMER_ID DECIMAL(18,0),
VISIT_DT TIMESTAMP(6),
ACTION VARCHAR(50));



--Creating Web table ------
-----------------------------------------

CREATE TABLE WEB 
(CUSTOMER_ID DECIMAL(18,0) NOT NULL,
SERVER_ID VARCHAR(5) NOT NULL,
PAGE VARCHAR(50),
BROWSE_ID VARCHAR(20))
PRIMARY TIME INDEX (TIMESTAMP(6), DATE '2016-01-01', MINUTES(1), COLUMNS (SERVER_ID), NONSEQUENCED); 




CREATE TABLE TelcoCustomerChurn (
      customerID VARCHAR(12),
      gender VARCHAR(6),
      SeniorCitizen SMALLINT,
      Partner VARCHAR(3),
      Dependents VARCHAR(3),
      tenure SMALLINT,
      PhoneService VARCHAR(3),
      MultipleLines VARCHAR(16),
      InternetService VARCHAR(11),
      OnlineSecurity VARCHAR(19),
      OnlineBackup VARCHAR(19),
      DeviceProtection VARCHAR(19),
      TechSupport VARCHAR(19),
      StreamingTV VARCHAR(19),
      StreamingMovies VARCHAR(19),
      Contract VARCHAR(14),
      PaperlessBilling VARCHAR(3),
      PaymentMethod VARCHAR(25),
      MonthlyCharges DECIMAL(15,5),
      TotalCharges DECIMAL(15,5),
      Churn VARCHAR(3))
PRIMARY INDEX (customerID);



/*
DROP TABLE CALL_CENTER_CALLS;
DROP TABLE CUST_COMMENT;
DROP TABLE CUSTOMER;
DROP TABLE PRODUCT;
DROP TABLE PURCHASE;
DROP TABLE SERVER;
DROP TABLE STORE;
DROP TABLE STORE_VISIT;
DROP TABLE WEB;
DROP TABLE TelcoCustomerChurn;
*/
