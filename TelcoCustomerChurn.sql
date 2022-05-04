  
CREATE MULTISET TABLE TelcoCustomerChurn (
      customerID VARCHAR(10),
      gender VARCHAR(6),
      SeniorCitizen INTEGER,
      Partner VARCHAR(3),
      Dependents VARCHAR(3),
      tenure INTEGER,
      PhoneService VARCHAR(3),
      MultipleLines VARCHAR(20),
      InternetService VARCHAR(20),
      OnlineSecurity VARCHAR(20),
      OnlineBackup VARCHAR(20),
      DeviceProtection VARCHAR(20),
      TechSupport VARCHAR(20),
      StreamingTV VARCHAR(20),
      StreamingMovies VARCHAR(20),
      Contract VARCHAR(20),
      PaperlessBilling VARCHAR(3),
      PaymentMethod VARCHAR(25),
      MonthlyCharges NUMBER(20,5),
      TotalCharges NUMBER(20,5),
      Churn VARCHAR(3))
PRIMARY INDEX (customerID);

