--przykladowe dane

INSERT INTO ForeignBankAccounts VALUES (1)


INSERT INTO Customer VALUES(1,'XXXX','YYYYY','2000-01-23','Analizy_Matematycznej 38 Kraków','xyxy@gmail.com','990776554')
INSERT INTO Customer VALUES(2,'XXXXX','YYYYYY','2000-01-23','Grafu_Planarnego 38 Kraków','yyyxxx@gmail.com','990776554')


INSERT INTO Account VALUES(1,'2020-01-23',NULL,'StandardAccount','PLN',0,NULL,1,'CUSTOMER_ACCOUNT')
INSERT INTO Account VALUES(2,'2020-01-23',NULL,'StandardAccount','USD',0,NULL,1,'CUSTOMER_ACCOUNT')


INSERT INTO Cards VALUES(1,1,'2070-01-23','Debit')


INSERT INTO Customer_Account VALUES(1,1)
INSERT INTO Customer_Account VALUES(1,2)


INSERT INTO FixedLoanInterestRate VALUES(0,0.1)
INSERT INTO FixedLoanInterestRate VALUES(1,0.15)
INSERT INTO FixedLoanInterestRate VALUES(2,0.2)
INSERT INTO FixedLoanInterestRate VALUES(3,0.25)
INSERT INTO FixedLoanInterestRate VALUES(4,0.30)
INSERT INTO FixedLoanInterestRate VALUES(5,0.35)


INSERT INTO BankBranch VALUES(1,'Sql 20 Kraków','888999666')


INSERT INTO BankEmployee VALUES(1,'XXXXY','YYYYYX','2020-01-23','Ruczaj 50 Kraków','xxxyyx@gmail.com','888777000','Prezes','2020-01-23',NULL,1)




INSERT INTO AccountAccessFee VALUES(1,10,'PLN')
INSERT INTO AccountAccessFee VALUES(2,8,'PLN')
INSERT INTO AccountAccessFee VALUES(3,6,'PLN')
INSERT INTO AccountAccessFee VALUES(4,4,'PLN')
INSERT INTO AccountAccessFee VALUES(1,10,'EUR')
INSERT INTO AccountAccessFee VALUES(2,8,'EUR')
INSERT INTO AccountAccessFee VALUES(3,6,'EUR')
INSERT INTO AccountAccessFee VALUES(4,4,'USD')
INSERT INTO AccountAccessFee VALUES(1,10,'USD')
INSERT INTO AccountAccessFee VALUES(2,8,'USD')
INSERT INTO AccountAccessFee VALUES(3,6,'USD')
INSERT INTO AccountAccessFee VALUES(4,4,'USD')
INSERT INTO AccountAccessFee VALUES(0,60,'USD')
INSERT INTO AccountAccessFee VALUES(0,60,'USD')
INSERT INTO AccountAccessFee VALUES(0,60,'USD')




INSERT INTO TermDepositInterstRates VALUES(0,0)
INSERT INTO TermDepositInterstRates VALUES(1,0.1)
INSERT INTO TermDepositInterstRates VALUES(2,0.15)
INSERT INTO TermDepositInterstRates VALUES(3,0.20)
INSERT INTO TermDepositInterstRates VALUES(4,0.25)


INSERT INTO TermDeposit VALUES(1,'2020-01-23','PLN',4000,'2023-01-23',NULL,1,'CUSTOMER')


INSERT INTO AutomatedTellerMachine VALUES(1,'Sql 20 Kraków',1)
INSERT INTO AutomatedTellerMachineBalance VALUES(1,300000, 'PLN')
INSERT INTO AutomatedTellerMachineBalance VALUES(1,300000, 'USD')
INSERT INTO AutomatedTellerMachineBalance VALUES(1,300000, 'EUR')


INSERT INTO Credit VALUES(1,1,40000,'PLN','Fixed','2020-01-23','2020-06-23','Active',1,NULL,1,'CUSTOMER_CREDIT')


INSERT INTO Transactions VALUES(400,'PLN','2020-01-23')
INSERT INTO TransactionInBranch VALUES(1,1,1,'Wpłata',NULL,'-',NULL)


INSERT INTO Transactions VALUES(400,'PLN','2020-01-23')
INSERT INTO TransactionCard VALUES(2,2,1,'No',NULL)


INSERT INTO Transactions VALUES(4080,'PLN','2020-01-23')
INSERT INTO ExchangeCurrencyTransaction VALUES(3,'USD',1,2)


INSERT INTO Transactions VALUES(4080,'PLN','2020-01-23')
INSERT INTO Transfers VALUES(4,NULL,1,2,'No',NULL)


INSERT INTO Transactions VALUES(4080,'PLN','2020-01-23')
INSERT INTO ATMTransaction VALUES(5,1,1,'MakeDeposit')


INSERT INTO Transactions VALUES(40,'PLN','2020-01-23')
INSERT INTO ATMTransaction VALUES(6,1,1,'MakeWithdrawal')


INSERT INTO Company VALUES(1,'202390','xyz','i','99999','email')
INSERT INTO Account VALUES(3,'2020-01-23',NULL,'StandardAccount','PLN',0,1,NULL,'COMPANY_ACCOUNT')
