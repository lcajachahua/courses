DATABASE ADLSLSAMER_MS_AZ;

--DROP TABLE Precio_Casas_Col;

CREATE MULTISET TABLE Precio_Casas_Col (
      id INTEGER,
      antiguedad_original VARCHAR(20),
      area NUMBER(8,2),
      areabalcon NUMBER(8,2),
      areaconstruida NUMBER(8,2),
      areaterraza NUMBER(8,2),
      balcon VARCHAR(10),
      banos SMALLINT,
      banoservicio VARCHAR(2),
      conjuntocerrado VARCHAR(2),
      cuarto_de_escoltas VARCHAR(2),
      cuartodeservicio VARCHAR(2),
      depositoocuartoutil VARCHAR(10),
      depositos VARCHAR(10),
      estrato SMALLINT,
      estudioobiblioteca VARCHAR(2),
      garajecubierto VARCHAR(2),
      garajes SMALLINT,
      gimnasio VARCHAR(2),
      habitaciones SMALLINT,
      halldealcobasoestar VARCHAR(2),
      instalaciondegas VARCHAR(10),
      jacuzzi VARCHAR(2),
      jardin VARCHAR(2),
      latitud NUMBER(18,10),
      longitud NUMBER(18,10),
      numeroascensores SMALLINT,
      parqueaderovisitantes VARCHAR(2),
      piscina VARCHAR(2),
      plantaelectrica VARCHAR(2),
      porteriaovigilancia VARCHAR(10),
      remodelado VARCHAR(2),
      saloncomunal VARCHAR(2),
      sauna_yo_turco VARCHAR(2),
      terraza VARCHAR(10),
      tiempodeconstruido VARCHAR(20),
      tipodegaraje VARCHAR(15),
      valor NUMBER(38,2),
      valorventa NUMBER(38,2),
      vigilancia VARCHAR(10),
      vista VARCHAR(10),
      zona_de_bbq VARCHAR(2),
      zonadelavanderia VARCHAR(2),
      zonaninos VARCHAR(2),
      zonasverdes VARCHAR(2))
PRIMARY INDEX (id);


-----------------------------------------
--- STEP 2: ENTENDIMIENTO DE LOS DATOS
----------------------------------------

--- FUENTE DE DATOS

select top 20 * from Precio_Casas_Col;


--- ANALISIS EXPLORATORIO

call TRNG_XSP.td_analyze (
'values',
'database = ADLSLSAMER_MS_AZ;
tablename = Precio_Casas_Col;
columns = all;');


--- ESTADISTICAS DESCRIPTIVAS

call TRNG_XSP.td_analyze ('statistics',
'database = ADLSLSAMER_MS_AZ;
tablename = Precio_Casas_Col;
extendedoptions = quantiles;
columns = area, banos, estrato, habitaciones, valor, garajes;');


call TRNG_XSP.td_analyze ('statistics',
'database = ADLSLSAMER_MS_AZ;
tablename = Precio_Casas_Col;
columns = area, banos, estrato, habitaciones, valor, garajes;
groupby = antiguedad_original;');


--- FRECUENCIAS

call TRNG_XSP.td_analyze ('frequency',
'database = ADLSLSAMER_MS_AZ;
tablename = Precio_Casas_Col;
columns = antiguedad_original, estrato, garajes, habitaciones;');


--- DATAEXPLORER

call TRNG_XSP.td_analyze ('dataexplorer',
'database = ADLSLSAMER_MS_AZ;
tablename = Precio_Casas_Col;
outputdatabase = ADLSLSAMER_MS_AZ;');

--- Descriptivos de variables categóricas
select * from TwmExploreFrequency ORDER BY xcol, xval;

--- Descriptivos de variables numéricas discretizadas (bins)
select * from TwmExploreHistogram ORDER BY xcol, xbin;

--- Descriptivo de variables numéricas
select * from TwmExploreStatistics ORDER BY xcol;

--- Exploratorio de Valores
select * from TwmExploreValues ORDER BY xtype, xcol;



--------------------------------------------
--- STEP 3: PREPARACIÓN DE LOS DATOS 
--------------------------------------------

--- RECODIFICACIÓN EN DUMMIES Y RAÍZ DEL PRECIO

call TRNG_XSP.td_analyze('vartran',
'database=ADLSLSAMER_MS_AZ;
tablename=Precio_Casas_Col;
outputstyle=table;
outputdatabase=ADLSLSAMER_MS_AZ;
outputtablename=trans;
keycolumns=id;
index=id;
designcode={designstyle(dummycode),designvalues(Entre 10 y 20 años/ant10_20,Entre 0 y 5 años/ant0_5,Entre 5 y 10 años/ant5_10,Más de 20 años/ant20_mas),columns(antiguedad_original)};
derive={formula(sqrt(x)),arguments(valor),outputname(rvalor)};');

SELECT TOP 10 * FROM trans;

--- IMPUTACIÓN DE VARIABLES

--update Precio_Casas_Col set estrato=0 where estrato is null;
--update Precio_Casas_Col set garajes=0 where garajes is null;
--update Precio_Casas_Col set banos=0 where banos is null;


--- Unimos los datos transformados y generamos marcas para las muestras de Entrenamiento, Validación

CREATE TABLE precios AS (
select id, area, habitaciones, 
CASE WHEN antiguedad_original='Entre 0 y 5 años' THEN 1 ELSE 0 END AS ant0_5,
CASE WHEN antiguedad_original='Entre 5 y 10 años' THEN 1 ELSE 0 END AS ant5_10,
CASE WHEN antiguedad_original='Entre 10 y 20 años' THEN 1 ELSE 0 END AS ant10_20,
CASE WHEN antiguedad_original='Más de 20 años' THEN 1 ELSE 0 END AS ant20_mas,
CASE WHEN antiguedad_original='Menos de 1 año' THEN 1 ELSE 0 END AS ant1_menos,
CASE WHEN antiguedad_original='1 a 8 años' THEN 1 ELSE 0 END AS ant1_8,
CASE WHEN antiguedad_original='9 a 15 años' THEN 1 ELSE 0 END AS ant9_15,
CASE WHEN antiguedad_original='16 a 30 años' THEN 1 ELSE 0 END AS ant16_30,
CASE WHEN antiguedad_original='Más de 30 años' THEN 1 ELSE 0 END AS ant30_mas,
CASE WHEN banos is null then 0 else banos end as banos, 
CASE WHEN garajes is null then 0 else garajes end as garajes, 
CASE WHEN estrato is null then 0 else estrato end as estrato, SQRT(valor) as rvalor, SAMPLEID as sid 
FROM Precio_Casas_Col
WHERE area between 20 and 2000 and valor between 50000000 and 5000000000
SAMPLE RANDOMIZED ALLOCATION 0.7, 0.3
) WITH DATA
PRIMARY INDEX (id);

SELECT TOP 10 * FROM precios;

/*
CREATE TABLE precios AS (
select id, area, 
CASE WHEN banos is null then 0 else banos end as banos, 
CASE WHEN garajes is null then 0 else garajes end as garajes, 
CASE WHEN estrato is null then 0 else estrato end as estrato, SQRT(valor) as rvalor, SAMPLEID as sid 
FROM Precio_Casas_Col
WHERE area between 20 and 2000 and valor between 50000000 and 5000000000
SAMPLE RANDOMIZED ALLOCATION 0.6, 0.4
) WITH DATA
PRIMARY INDEX (id);
*/


--- MATRIZ DE CORRELACIONES

call TRNG_XSP.td_analyze ('matrix',
'database = ADLSLSAMER_MS_AZ;
tablename = precios;
columns = all;
columnstoexclude = id, sid;
matrixtype = COR;');



--- PARTICIÓN DE MUESTRAS

CREATE MULTISET TABLE tch_train AS (
SELECT * FROM precios WHERE SID = 1
) WITH DATA
PRIMARY INDEX (id);

CREATE MULTISET TABLE tch_test AS (
SELECT * FROM precios WHERE SID = 2
) WITH DATA
PRIMARY INDEX (id);


------------------------------------
--- STEP 4: GENERACIÓN DE MODELOS
------------------------------------


--- MODELO DE REGRESIÓN LOGÍSTICA

call TRNG_XSP.td_analyze('linear',
'database=ADLSLSAMER_MS_AZ;
tablename=tch_train;
columns= all;
columnstoexclude=id,sid;
dependent=rvalor;
statstable=true;
stepwise=true;
outputdatabase=ADLSLSAMER_MS_AZ;
outputtablename=linearmodel;');


---------------------------------------
--- STEP 5: EVALUACIÓN DE MODELOS
---------------------------------------

--- Resultados del Modelo y Métricas
SELECT * FROM linearmodel;
SELECT * FROM linearmodel_rpt;


--- Reporte HTML
call TRNG_XSP.td_analyze ('report',
'database=ADLSLSAMER_MS_AZ;
tablename=linearmodel;
analysistype=linear');


---------------------------------------
--- STEP 6: IMPLEMENTACIÓN DE MODELOS
---------------------------------------

--- Scoring del modelo de Regresión Logística

call TRNG_XSP.td_analyze('linearscore',
'database=ADLSLSAMER_MS_AZ;
tablename=tch_test;
modeldatabase=ADLSLSAMER_MS_AZ;
modeltablename=linearmodel;
outputdatabase=ADLSLSAMER_MS_AZ;
outputtablename=linearmodelval;
predicted=rvalor_estimado;
retain=rvalor;
samplescoresize=10;
scoringmethod=scoreandevaluate;');


call TRNG_XSP.td_analyze ('matrix',
'database = ADLSLSAMER_MS_AZ;
tablename = linearmodelval;
columns = rvalor,rvalor_estimado;
matrixtype = COR;');

SELECT id, rvalor_estimado*rvalor_estimado as valor_estimado FROM linearmodelval;




-----------------------------------------------------------------
--- ELIMINAR TODAS LAS TABLAS CREADAS PARA INICIAR NUEVAMENTE
-----------------------------------------------------------------

DROP TABLE TwmExploreFrequency;
DROP TABLE TwmExploreHistogram;
DROP TABLE TwmExploreStatistics;
DROP TABLE TwmExploreValues;
DROP TABLE trans;
DROP TABLE precios;
DROP TABLE tch_train;
DROP TABLE tch_test;

DROP TABLE linearmodel;
DROP TABLE linearmodel_rpt;
DROP TABLE linearmodel_txt;

DROP TABLE linearmodelval;
DROP TABLE linearmodelval_txt;

