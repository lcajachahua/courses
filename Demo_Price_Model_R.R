
####################################################
## Modelo de Estimaci�n del Precio de Viviendas
####################################################

## Step 1: Business Understanding
## -----------------------------------

## Este dataset contiene informaci�n recolectada de precios y caracter�sticas de 142 mil viviendas 
## en Colombia. La informaci�n se encuentra disponible p�blicamente en el repositorio Kaggle: 
## https://www.kaggle.com/datasets/danieleduardofajardo/colombia-house-prediction

## Cargamos las librer�as

options(warn=-1)

LoadPackages <- function()
{library(dbplyr)
  library(tidyverse)
  library(lubridate)
  library(ggplot2)
  library(tdplyr)
  library(getPass)
  library(teradatasql)
  library(DBI)}

suppressPackageStartupMessages(LoadPackages())


## Cadena de conexion
con <- td_create_context(host = "tdprd.td.teradata.com", uid="lc250058", pwd=getPass(), dType = "native", logmech = "LDAP")
td_set_context(con)

## Creamos el DataFrame y traemos la cabecera

tdPrecios <- tbl(con, dplyr::sql("select id, area, habitaciones, antiguedad_original, 
CASE WHEN banos is null then 0 else banos end as banos, 
CASE WHEN garajes is null then 0 else garajes end as garajes, 
CASE WHEN estrato is null then 0 else estrato end as estrato, SQRT(valor) as rvalor, 
SAMPLEID as sid FROM ADLSLSAMER_MS_AZ.Precio_Casas_Col 
WHERE area between 20 and 2000 and valor between 50000000 and 5000000000 
SAMPLE RANDOMIZED ALLOCATION 0.7, 0.3"))

as.data.frame(head(tdPrecios))

## Tama�o de la tabla

td_nrow(tdPrecios)




## Step 2: Data Understanding
## -----------------------------------

## Exploraci�n de Valores

## Vamos a utilizar la funci�n td_explore_valib de Vantage Analytic Library, 
## Esta funci�n genera varias tablas donde se almacenan los resultados del an�lisis.

options(val.install.location = "TRNG_XSP")

eda01 <- td_explore_valib(data=tdPrecios)

#### 1. Exploratorio de Valores: Nos muestra los descriptivos generales de las variables en la tabla:  

arrange(as.data.frame(eda01$values.output),xcol)

#### 2. Descriptivo de variables num�ricas: Nos muestra los descriptivos b�sicos de las variables num�ricas en nuestra tabla de datos. 

arrange(as.data.frame(eda01$statistics.output),xcol)

#### 3. Descriptivos de variables de texto: Nos muestra los descriptivos b�sicos de las variables de texto en nuestra tabla de datos.

arrange(as.data.frame(eda01$frequency.output),xcol,xval)

#### 4. Descriptivos de variables num�ricas discretizadas (bins): Nos muestra los descriptivos resultantes de discretizar las variables num�ricas de nuestra tabla de datos.

arrange(as.data.frame(eda01$histogram.output),xcol,xbin)



## Step 3: Data Preparation
## -----------------------------------

## La Transformacion de Variables e Imputacion se hizo en la fase de adquisici�n



## Step 4: Modeling
## -----------------------------------

## Divisi�n de Muestras Train y Evaluation

tbl_train <- filter(tdPrecios, sid == 1)
tbl_test <- filter(tdPrecios, sid == 2)

## Generaci�n del Modelo de Estimaci�n de Precios

tdModel <- td_lin_reg_valib(data=tbl_train,
                            columns='all',
                            exclude.columns=c('id','sid','antiguedad_original'),
                            stepwise='True',
                            response.column='rvalor')

print(tdModel$model)
print(tdModel$statistical.measures)




## Step 5: Evaluation
## -----------------------------------

## Evaluando el Modelo con el dataset de test

tdEval <- td_lin_reg_evaluator_valib(data=tbl_test, model=tdModel$model, index.columns='id')
as.data.frame(tdEval$result)


## Step 6: Deployment
## -----------------------------------

## Score de datos nuevos

tdScore <- td_lin_reg_predict_valib(data=tbl_test, model=tdModel$model, response.column="rvalor_estim", index.columns='id')

head(tdScore)

## Calculamos el valor total

derive_1 <- tdDerive(formula='x*x', columns='rvalor_estim', out.column='valor_estim')
##retain <- tdRetain(columns='id')

FinalScore <- td_transform_valib(data=tdScore$result,
                          derive=derive_1,
                          key.columns='id', index.columns='id')

head(FinalScore$result)

## Llevamos la informaci�n a una Tabla de resultados llamada Precio_Score_R

copy_to(con, FinalScore$result, name = "Precio_Score_R")

## Cerramos la conexi�n
td_remove_context()

