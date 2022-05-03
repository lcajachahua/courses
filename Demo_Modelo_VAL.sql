DATABASE ADLSLSAMER_MS_AZ;

CREATE MULTISET TABLE telco_training (
      cust_id VARCHAR(20),
      churn_flag CHAR(1),
      open_dt DATE FORMAT 'YY/MM/DD',
      plan_rate SMALLINT,
      cust_days INTEGER,
      age SMALLINT,
      region VARCHAR(20),
      months_from_contract_end SMALLINT,
      voice_calls_avg DECIMAL(8,3),
      voice_minutes_avg DECIMAL(8,3),
      data_usage_avg DECIMAL(8,3),
      sms_usage_avg DECIMAL(8,3),
      voicemail_calls DECIMAL(8,3),
      support_calls DECIMAL(8,3),
      support_minutes DECIMAL(8,3),
      bill_dispute SMALLINT)
PRIMARY INDEX (cust_id);


CREATE MULTISET TABLE telco_testing (
      cust_id VARCHAR(20),
      churn_flag CHAR(1),
      plan_rate SMALLINT,
      cust_days INTEGER,
      age SMALLINT,
      region VARCHAR(20),
      months_from_contract_end SMALLINT,
      voice_calls_avg DECIMAL(8,3),
      voice_minutes_avg DECIMAL(8,3),
      data_usage_avg DECIMAL(8,3),
      sms_usage_avg DECIMAL(8,3),
      voicemail_calls DECIMAL(8,3),
      support_calls DECIMAL(8,3),
      support_minutes DECIMAL(8,3),
      bill_dispute SMALLINT)
PRIMARY INDEX (cust_id);

--------------------------------
--- PREPARACIÓN DE DATOS
--------------------------------

--- FUENTES DE DATOS

select top 20 * from telco_training;

select top 20 * from telco_testing;


--- ESTADISTICAS DESCRIPTIVAS

call TRNG_XSP.td_analyze ('statistics',
'database = ADLSLSAMER_MS_AZ;
tablename = telco_training;
columns = plan_rate, cust_days, age, months_from_contract_end, voice_calls_avg, voice_minutes_avg, sms_usage_avg, support_minutes;');


call TRNG_XSP.td_analyze ('statistics',
'database = ADLSLSAMER_MS_AZ;
tablename = telco_training;
columns = plan_rate, cust_days, age, months_from_contract_end, voice_calls_avg, voice_minutes_avg, sms_usage_avg, support_minutes;
groupby = churn_flag;');


--- FRECUENCIAS

call TRNG_XSP.td_analyze ('frequency',
'database = ADLSLSAMER_MS_AZ;
tablename = telco_training;
columns = region, churn_flag;');


call TRNG_XSP.td_analyze ('frequency',
'database = ADLSLSAMER_MS_AZ;
tablename = telco_training;
columns = region, churn_flag;
style = crosstab;');


--- DATAEXPLORER

call TRNG_XSP.td_analyze ('dataexplorer',
'database = ADLSLSAMER_MS_AZ;
tablename = telco_training;
outputdatabase = ADLSLSAMER_MS_AZ;');

--- Descriptivos de variables categóricas
select * from TwmExploreFrequency ORDER BY xcol, xval;

--- Descriptivos de variables numéricas discretizadas (bins)
select * from TwmExploreHistogram ORDER BY xcol, xbin;

--- Descriptivo de variables numéricas
select * from TwmExploreStatistics ORDER BY xcol;

--- Exploratorio de Valores
select * from TwmExploreValues ORDER BY xtype, xcol;



--- TRANSFORMACIONES DE VARIABLES - RECODIFICACIÓN EN DUMMIES

call TRNG_XSP.td_analyze('vartran',
'database=ADLSLSAMER_MS_AZ;
tablename=telco_training;
outputstyle=table;
outputdatabase=ADLSLSAMER_MS_AZ;
outputtablename=tch_varflags;
keycolumns=cust_id;
index=cust_id;
designcode=
{designstyle(dummycode),designvalues(R1/FLAG_R1,R2/FLAG_R2,R3/FLAG_R3,R4/FLAG_R4,R5/FLAG_R5),columns(region)}
{designstyle(dummycode),designvalues(1/FLAG_churn),columns(churn_flag)};');

SELECT TOP 10 * FROM tch_varflags;




--- Unimos los datos transformados y generamos marcas para las muestras de Entrenamiento, Validación

CREATE TABLE TelcoCustomerChurn_dataset AS (
SELECT a.cust_id, a.plan_rate, a.cust_days, a.age, a.voice_calls_avg, a.voice_minutes_avg, a.data_usage_avg, 
a.sms_usage_avg, a.voicemail_calls, a.support_calls, a.support_minutes, a.bill_dispute, b.FLAG_R1, b.FLAG_R2, b.FLAG_R3, b.FLAG_R4, b.FLAG_R5, b.FLAG_churn, SAMPLEID as sid
FROM telco_training a
INNER JOIN tch_varflags b
ON a.cust_id=b.cust_id
SAMPLE RANDOMIZED ALLOCATION 0.6, 0.4
) WITH DATA
PRIMARY INDEX (cust_id);

SELECT TOP 10 * FROM TelcoCustomerChurn_dataset;



--- MATRIZ DE CORRELACIONES

call TRNG_XSP.td_analyze ('matrix',
'database = ADLSLSAMER_MS_AZ;
tablename = TelcoCustomerChurn_dataset;
columns = all;
columnstoexclude = cust_id, sid;
matrixtype = COR;');




--- PARTICIÓN DE MUESTRAS

CREATE MULTISET TABLE tch_train AS (
SELECT * FROM TelcoCustomerChurn_dataset WHERE SID = 1
) WITH DATA
PRIMARY INDEX (cust_id);

CREATE MULTISET TABLE tch_test AS (
SELECT * FROM TelcoCustomerChurn_dataset WHERE SID = 2
) WITH DATA
PRIMARY INDEX (cust_id);


--------------------------------
--- GENERACIÓN DE MODELOS
--------------------------------


--- MODELO DE REGRESIÓN LOGÍSTICA

call TRNG_XSP.td_analyze('logistic',
'database=ADLSLSAMER_MS_AZ;
tablename=tch_train;
columns= all;
columnstoexclude=cust_id,sid;
dependent=FLAG_churn;
response=1;
stepwise=true;
statstable=true;
successtable=true;
lifttable=true;
outputdatabase=ADLSLSAMER_MS_AZ;
outputtablename=tch_logmodel;');

--- Resultados del Modelo y Métricas
SELECT * FROM tch_logmodel;
SELECT * FROM tch_logmodel_rpt;

--- Reporte HTML
call TRNG_XSP.td_analyze ('report',
'database=ADLSLSAMER_MS_AZ;
tablename=tch_logmodel;
analysistype=logistic');

--- Evaluamos el modelo de Regresión Logística

call TRNG_XSP.td_analyze('logisticscore',
'database=ADLSLSAMER_MS_AZ;
tablename=tch_test;
modeldatabase=ADLSLSAMER_MS_AZ;
modeltablename=tch_logmodel;
outputdatabase=ADLSLSAMER_MS_AZ;
outputtablename=tch_logmodelval;
estimate=Estimate;
probability=Probability;
retain=FLAG_churn;
samplescoresize=10;
scoringmethod=scoreandevaluate;
lifttable=true;');

--- Indicadores de la Matriz de Confusion
SELECT FLAG_churn, Estimate, COUNT(1) AS n FROM tch_logmodelval GROUP BY 1,2;

--- Accuracy
SELECT (SELECT cast(count(*) as dec(8,3)) FROM tch_logmodelval WHERE FLAG_churn=Estimate)/
(SELECT cast(count(*) as dec(8,3)) FROM tch_logmodelval);

--- Reporte HTML
call TRNG_XSP.td_analyze ('report',
'database=ADLSLSAMER_MS_AZ;
tablename=tch_logmodelval;
analysistype=logisticscore');




--- MODELO DE ÁRBOLES DE DECISIÓN

call TRNG_XSP.td_analyze('decisiontree',
'database=ADLSLSAMER_MS_AZ;
tablename=tch_train; 
columns= all;
columnstoexclude=cust_id,sid;
dependent=FLAG_churn;
min_records=10;
max_depth=12;
binning=false;
algorithm=gainratio;
pruning=gainratio;
outputdatabase=ADLSLSAMER_MS_AZ;
outputtablename=tch_decisiontree;
overwrite=true;
operatordatabase=TRNG_XSP;');

SELECT TOP 10 * FROM tch_decisiontree;

--- Reporte HTML
call TRNG_XSP.td_analyze ('report',
'database=ADLSLSAMER_MS_AZ;
tablename=tch_decisiontree;
analysistype=decisiontree');


--- Evaluamos el modelo de Árbol

call TRNG_XSP.td_analyze('decisiontreescore',
'database=ADLSLSAMER_MS_AZ;
tablename=tch_test;
modeldatabase=ADLSLSAMER_MS_AZ;
modeltablename=tch_decisiontree;
outputdatabase=ADLSLSAMER_MS_AZ;
predicted=Predicted;
retain=FLAG_churn;
outputtablename=tch_treemodelval;
scoringmethod=scoreandevaluate;
samplescoresize=10;
includeconfidence=true;'); 

--- Indicadores de la Matriz de Confusion
SELECT FLAG_churn, Predicted, COUNT(1) AS n FROM tch_treemodelval GROUP BY 1,2;

--- Accuracy
SELECT (SELECT cast(count(*) as dec(8,3)) FROM tch_treemodelval WHERE FLAG_churn=Predicted)/
(SELECT cast(count(*) as dec(8,3)) FROM tch_treemodelval);

--- Reporte HTML
call TRNG_XSP.td_analyze ('report',
'database=ADLSLSAMER_MS_AZ;
tablename=tch_treemodelval;
analysistype=decisiontreescore');




--- IMPLEMENTACIÓN DEL MODELO (SCORING)

--- PREPARACIÓN DE DATOS

call TRNG_XSP.td_analyze('vartran',
'database=ADLSLSAMER_MS_AZ;
tablename=telco_testing;
outputstyle=table;
outputdatabase=ADLSLSAMER_MS_AZ;
outputtablename=tch_varflags_score;
keycolumns=cust_id;
index=cust_id;
designcode=
{designstyle(dummycode),designvalues(R1/FLAG_R1,R2/FLAG_R2,R3/FLAG_R3,R4/FLAG_R4,R5/FLAG_R5),columns(region)}
{designstyle(dummycode),designvalues(1/FLAG_churn),columns(churn_flag)};');

SELECT TOP 10 * FROM tch_varflags_score;


--- Unimos los datos transformados

CREATE TABLE TelcoCustomerChurn_score AS (
SELECT a.cust_id, a.plan_rate, a.cust_days, a.age, a.voice_calls_avg, a.voice_minutes_avg, a.data_usage_avg, 
a.sms_usage_avg, a.voicemail_calls, a.support_calls, a.support_minutes, a.bill_dispute, b.FLAG_R1, b.FLAG_R2, b.FLAG_R3, b.FLAG_R4, b.FLAG_R5, b.FLAG_churn
FROM telco_testing a
INNER JOIN tch_varflags_score b
ON a.cust_id=b.cust_id
) WITH DATA
PRIMARY INDEX (cust_id);

SELECT TOP 10 * FROM TelcoCustomerChurn_score;


--- SCORING DEL MODELO

call TRNG_XSP.td_analyze('logisticscore',
'database=ADLSLSAMER_MS_AZ;
tablename=TelcoCustomerChurn_score;
modeldatabase=ADLSLSAMER_MS_AZ;
modeltablename=tch_logmodel;
outputdatabase=ADLSLSAMER_MS_AZ;
outputtablename=tch_score;
probability=Probability;
scoringmethod=score;');

SELECT TOP 10 * FROM tch_score;








-------------------
--- CLUSTERING
-------------------

--- Transformaciones de variables - Estandarización

call TRNG_XSP.td_analyze('vartran',
'database=ADLSLSAMER_MS_AZ;
tablename=telco_training;
outputstyle=table;
outputdatabase=ADLSLSAMER_MS_AZ;
outputtablename=tch_zvar;
keycolumns=cust_id;
index=cust_id;
zscore=columns(plan_rate/zplan_rate,cust_days/zcust_days,age/zage,voice_calls_avg/zvoice_Calls,voice_minutes_avg/zvoice_minutes_avg);');

SELECT TOP 10 * FROM tch_zvar;


--- Identificando los K Centroides

call TRNG_XSP.td_analyze('Kmeans',
'database=ADLSLSAMER_MS_AZ;
tablename=tch_zvar;
columns=all;
columnstoexclude=cust_id;
outputdatabase=ADLSLSAMER_MS_AZ;
outputtablename=kmeans5;
kvalue=5;
iterations=10;
threshold=0.01;
operatordatabase=TRNG_XSP;');

select * from kmeans5 order by 1;


--- Transformaciones de variables - Estandarización de la tabla nueva de clientes

call TRNG_XSP.td_analyze('vartran',
'database=ADLSLSAMER_MS_AZ;
tablename=telco_testing;
outputstyle=table;
outputdatabase=ADLSLSAMER_MS_AZ;
outputtablename=tch_zvar_score;
keycolumns=cust_id;
index=cust_id;
zscore=columns(plan_rate/zplan_rate,cust_days/zcust_days,age/zage,voice_calls_avg/zvoice_Calls,voice_minutes_avg/zvoice_minutes_avg);');

SELECT TOP 10 * FROM tch_zvar_score;


--- Segmentando los clientes nuevos

call TRNG_XSP.td_analyze('Kmeansscore',
'database=ADLSLSAMER_MS_AZ;
modeldatabase=ADLSLSAMER_MS_AZ;
tablename=tch_zvar_score;
outputdatabase=ADLSLSAMER_MS_AZ;
outputtablename=mat_score_cluster;
modeltablename=kmeans5;
operatordatabase=TRNG_XSP;');

select top 10 cust_id, clusterid from mat_score_cluster;

--- Frecuencia por cada Cluster
select clusterid, count(1) n from mat_score_cluster group by 1 order by 2 desc;






-----------------------------------------------------------------
--- ELIMINAR TODAS LAS TABLAS CREADAS PARA INICIAR NUEVAMENTE
-----------------------------------------------------------------

DROP TABLE TwmExploreFrequency;
DROP TABLE TwmExploreHistogram;
DROP TABLE TwmExploreStatistics;
DROP TABLE TwmExploreValues;

DROP TABLE tch_varflags;
DROP TABLE TelcoCustomerChurn_dataset;

DROP TABLE tch_train;
DROP TABLE tch_test;

DROP TABLE tch_logmodel;
DROP TABLE tch_logmodel_rpt;
DROP TABLE tch_logmodel_txt;

DROP TABLE tch_logmodelval;
DROP TABLE tch_logmodelval_txt;
DROP TABLE TelcoCustomerChurn_score;
DROP TABLE tch_score;

DROP TABLE tch_decisiontree;
DROP TABLE tch_treemodelval;
DROP TABLE tch_treemodelval_rpt;

drop table tch_zvar;
drop table kmeans5;
drop table tch_zvar_score;
drop table mat_score_cluster;

