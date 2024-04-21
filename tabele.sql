CREATE TABLE AccountAccessFee (
   TransactionAmount INT,
   FeeAmount DECIMAL(10, 2) NOT NULL,
   Currency VARCHAR(3) NOT NULL
);

--Tabela BankBranch: Tabela BankBranch przechowuje szczegóły dotyczące oddziałów bankowych.
CREATE TABLE BankBranch (
   BankBranchID INT PRIMARY KEY,
   Adress VARCHAR(255) NOT NULL,
   PhoneNumber VARCHAR(20),
);


--Tabela Customer: Tabela Klient przechowuje dane o klientach indywidualnych.
CREATE TABLE Customer (
   CustomerID INT PRIMARY KEY,
   CustomerName VARCHAR(50)  NOT NULL,
   CustomerSurname VARCHAR(50)  NOT NULL,
   DataUrodzenia DATE  NOT NULL,
   Adress VARCHAR(255)  NOT NULL,
   Email VARCHAR(100),
   PhoneNumber VARCHAR(20),
  
);

--Tabela Company: Tabela Firma zawiera dane dotyczące podmiotów korporacyjnych, które są klientem w naszym banku.
CREATE TABLE Company (
  
   CompanyID INT PRIMARY KEY,
   NIP VARCHAR(20) NOT NULL,
   CompanyName VARCHAR(100) NOT NULL,
   Adress VARCHAR(255) NOT NULL,
   PhoneNumber VARCHAR(20),
   Email VARCHAR(100),
  
);

--Tabela Customer_Account: Ta tabela ustanawia relację wiele do wielu między klientami a kontami.
CREATE TABLE Customer_Account (
   CustomerID INT,
   AccountNumber VARCHAR(40),
   PRIMARY KEY (CustomerID, AccountNumber),
   FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
   FOREIGN KEY (AccountNumber) REFERENCES Account(AccountID)
);

--Tabela Account: Konto dla klientów indywidualnych i korporacyjnych w ustalonej walucie. Może być oszczędnościowe (bez oprocentowania) lub zwykłe.
CREATE TABLE Account (
   AccountID VARCHAR(40) PRIMARY KEY,
   DateOpen DATE  NOT NULL,
   DateClosed DATE,
   AccountType VARCHAR(20) CHECK (AccountType IN ('SavingAccount', 'StandardAccount'))  NOT NULL,
   Currency VARCHAR(3) NOT NULL,
   AccountBalance DECIMAL(15, 2) NOT NULL,
   CompanyID INT,
   CustomerID INT,
   AccountType2 VARCHAR(20) CHECK (AccountType2 IN ('CUSTOMER_ACCOUNT', 'COMPANY_ACCOUNT'))  NOT NULL,
   FOREIGN KEY(CompanyID) REFERENCES Company(CompanyID),
   FOREIGN KEY(CustomerID) REFERENCES Customer(CustomerID)
  
);

--Tabela BankEmployee: Tabela BankEmployee zawiera informacje o pracownikach banku.
CREATE TABLE BankEmployee (
   BankEmployeeID INT PRIMARY KEY,
   EmployeeName VARCHAR(50) NOT NULL,
   EmployeeSurname VARCHAR(50) NOT NULL,
   DateOfBirth DATE NOT NULL,
   Adress VARCHAR(255) NOT NULL,
   Email VARCHAR(100),
   PhoneNumber VARCHAR(20),
   StanowiskoPosition VARCHAR(100) NOT NULL,
   EmploymentDate DATE NOT NULL,
   TerminationDate DATE DEFAULT NULL,
   BankBranchID INT NOT NULL,
   FOREIGN KEY (BankBranchID) REFERENCES BankBranch(BankBranchID)
);



--Tabela Company_Account: Podobnie jak Customer_Account, ta tabela ułatwia relację wiele do wielu między firmami a kontami.
CREATE TABLE Company_Account (
   CompanyID INT,
   AccountNumber VARCHAR(40),
   PRIMARY KEY (CompanyID, AccountNumber),
   FOREIGN KEY (CompanyID) REFERENCES Company(CompanyID),
   FOREIGN KEY (AccountNumber) REFERENCES Account(AccountID)
);

--Tabela Credit: Ta tabela rejestruje informacje o kredytach udzielanych klientom lub firmom.
CREATE TABLE Credit (
   CreditID INT PRIMARY KEY,
   AccountNumber VARCHAR(40) NOT NULL,
   Amount INT NOT NULL,
   Currency VARCHAR(3) NOT NULL,
   InterestRateType VARCHAR(20) CHECK (InterestRateType IN ('Fixed')) NOT NULL,
   DataStart DATE NOT NULL,
   DataEnd DATE NOT NULL,
   CreditStatus VARCHAR(20) CHECK (CreditStatus IN ('Active', 'RepaidLoan')) NOT NULL,
   BankEmployeeID INT NOT NULL,
   CompanyID INT,
   CustomerID INT,
   CreditType VARCHAR(20) CHECK (CreditType IN ('CUSTOMER_CREDIT', 'COMPANY_CREDIT'))  NOT NULL,
   FOREIGN KEY(CompanyID) REFERENCES Company(CompanyID),
   FOREIGN KEY(CustomerID) REFERENCES Customer(CustomerID),
   FOREIGN KEY (BankEmployeeID) REFERENCES BankEmployee(BankEmployeeID),
   FOREIGN KEY (AccountNumber) REFERENCES Account(AccountID),
  
);


--Tabela Repayment: Tabela Repayment zawiera wszystkie raty danego kredytu oraz między innymi czy dana rata jest już spłacona.

CREATE TABLE Repayment (
   RepaymentID INT PRIMARY KEY IDENTITY(1,1),
   DueRepaymentDate DATE NOT NULL,
   Amount DECIMAL(15, 2) NOT NULL,
   Currency VARCHAR(3) NOT NULL,
   RepaymentStatus VARCHAR(50) CHECK (RepaymentStatus IN ('Paid', 'Unpaid')) NOT NULL,
   PaidDate DATE DEFAULT NULL,
   CreditID INT NOT NULL,
   FOREIGN KEY (CreditID) REFERENCES Credit(CreditID)
);


--Tabela FixedLoanInterestRate: Ta tabela przechowuje ustalone stopy procentowe dla pożyczek na stałym oprocentowaniu.
CREATE TABLE FixedLoanInterestRate (
   LoanPeriodInYears INT NOT NULL,
   InterstRate DECIMAL(5, 2)
);

--Tabela AutomatedTellerMachine: Tabela AutomatedTellerMachine zawiera informacje o bankomatach.
CREATE TABLE AutomatedTellerMachine (
   AutomatedTellerMachineID INT PRIMARY KEY,
   Adress VARCHAR(255) NOT NULL,
   BankBranchID INT NOT NULL,
   FOREIGN KEY (BankBranchID) REFERENCES BankBranch(BankBranchID)
);


--Tabela AutomatedTellerMachineBalance:
--Ta tabela rejestruje informacje o saldach bankomatów, bankomat może mieścić różne waluty w przeciwieństiwe do konta.
CREATE TABLE AutomatedTellerMachineBalance (
   AutomatedTellerMachineID INT,
   Balance INT CHECK (Balance >= 0) NOT NULL,
   Currency VARCHAR(3) NOT NULL,
   FOREIGN KEY (AutomatedTellerMachineID) REFERENCES AutomatedTellerMachine(AutomatedTellerMachineID)
);


--Tabela Cards:
--Tabela Cards zawiera szczegóły dotyczące kart bankowych.
CREATE TABLE Cards (
   CardID INT PRIMARY KEY,
   AccountID VARCHAR(40) NOT NULL,
   ExpirationDate DATE NOT NULL,
   CardType VARCHAR(50) CHECK (CardType IN ('Debit', 'Credit')) NOT NULL,
   FOREIGN KEY (AccountID) REFERENCES Account(AccountID)
);


--Tabela Currency Exchange Rates:
--Tabela CurrencyExchangeRates przechowuje kursy wymiany walut na określone daty handlowe.
CREATE TABLE CurrencyExchangeRates (
   TradingDate DATE PRIMARY KEY,
   Currency VARCHAR(3) NOT NULL,
   Price DECIMAL(10, 6) NOT NULL
);
--Tabela TermDeposit: Tabela TermDeposit przechowuje informacje o lokatach terminowych.
CREATE TABLE TermDeposit (
   TermDepositID INT PRIMARY KEY,
   StartDepositDate DATE NOT NULL,
   Currency VARCHAR(3) NOT NULL,
   Amount DECIMAL(15, 2) NOT NULL,
   DateOfDepositEnd DATE NOT NULL,
   CompanyID INT,
   CustomerID INT,
   DepositType VARCHAR(20) CHECK (DepositType IN ('CUSTOMER', 'COMPANY'))  NOT NULL,
   FOREIGN KEY(CompanyID) REFERENCES Company(CompanyID),
   FOREIGN KEY(CustomerID) REFERENCES Customer(CustomerID)
);


--Tabela TermDepositInterstRates:Ta tabela definiuje stopy procentowe dla lokat terminowych w zależności od okresu w latach lokaty.
CREATE TABLE TermDepositInterstRates (
   MinimumLengthInYears INT PRIMARY KEY,
   DepositInterestRates DECIMAL(5, 2) NOT NULL
);

--Tabela StandingOrders: Tabela StandingOrders obsługuje zlecenia stałe dla regularnych transakcji.
CREATE TABLE StandingOrders (
   StandingOrderID INT PRIMARY KEY,
   SourceAccountID VARCHAR(40) NOT NULL,
   DestinationAccountID VARCHAR(40),
   Amount DECIMAL(15, 2) NOT NULL,
   Currency VARCHAR(3) NOT NULL,
   StartDate DATE NOT NULL,
   FrequencyInDays INT NOT NULL,
   IsDestinationAccountForeign VARCHAR(3) NOT NULL CHECK (IsDestinationAccountForeign IN ('Yes', 'No')),
   ForeignDestinationAccountID INT,
   FOREIGN KEY(ForeignDestinationAccountID) REFERENCES ForeignBankAccounts(AccountID) ,
   FOREIGN KEY (SourceAccountID) REFERENCES Account(AccountID) ,
   FOREIGN KEY (DestinationAccountID) REFERENCES Account(AccountID)
);
--Tabela Transactions: Tabela Transactions rejestruje ogólne informacje o transakcjach, po tej tabeli dziedziczą różne typy transakcji które uszczegóławiają informacje o transakcjach.
CREATE TABLE Transactions (
   TransactionID INT PRIMARY KEY IDENTITY(1,1),
   TransactionAmount DECIMAL(15, 2) NOT NULL,
   Currency VARCHAR(3) NOT NULL,
   TransactionDate DATETIME NOT NULL
);
--Tabela TransactionCard: Ta tabela zawiera szczegóły dotyczące transakcji kartowych. Transakcja kartą może być wykonana na konto z naszego banku lub na konto obce.
CREATE TABLE TransactionCard (
   TransactionID INT NOT NULL,
   TransactionCardID INT PRIMARY KEY  IDENTITY(1,1),
   DestinationAccountID VARCHAR(40),
   CardID INT NOT NULL,
   IsDestinationAccountForeign VARCHAR(3) CHECK (IsDestinationAccountForeign IN ('Yes', 'No')) NOT NULL,
   ForeignDestinationAccountID INT,
   FOREIGN KEY(ForeignDestinationAccountID) REFERENCES ForeignBankAccounts(AccountID) ,
   FOREIGN KEY (CardID) REFERENCES Cards(CardID) ,
   FOREIGN KEY (DestinationAccountID) REFERENCES Account(AccountID) ,
   FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)
);

--Tabela ExchangeCurrencyTransaction: Tabela ExchangeCurrencyTransaction obsługuje transakcje wymiany walut. Do wymiany walut potrzebujemy odrębnego konta w innej docelowej walucie aby tam przesłać wymienione środki, a usunąć je z konta pierwotnego.

CREATE TABLE ExchangeCurrencyTransaction (
   TransactionID INT NOT NULL,
   ExchangeTransactionID INT PRIMARY KEY  IDENTITY(1,1),
   DestinationCurrency VARCHAR(3) NOT NULL,
   SourceAccountID VARCHAR(40) NOT NULL,
   DestinationAccountID VARCHAR(40) NOT NULL,
   FOREIGN KEY (SourceAccountID) REFERENCES Account(AccountID),
   FOREIGN KEY (DestinationAccountID) REFERENCES Account(AccountID),
   FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)
);

--Tabela ATMTransaction:
--Ta tabela zawiera informacje o transakcjach dokonywanych w bankomatach, wpłatach i wypłatach pieniędzy z konta w naszym banku. Konta z obcych banków nie mogą korzystać z naszych bankomatów.
CREATE TABLE ATMTransaction (
   TransactionID INT NOT NULL,
   ATMTransactionID INT PRIMARY KEY  IDENTITY(1,1),
   ATMID INT NOT NULL,
   AccountID VARCHAR(40) NOT NULL,
   TypeTransaction VARCHAR(20) CHECK (TypeTransaction IN ('MakeDeposit', 'MakeWithdrawal')),
   FOREIGN KEY (ATMID) REFERENCES AutomatedTellerMachine(AutomatedTellerMachineID),
   FOREIGN KEY (AccountID) REFERENCES Account(AccountID),
   FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)
);

--Tabela TransactionInBranch: Ta tabela przechowuje transakcje przeprowadzane w oddziałach banku. Możliwa jest wpłata pieniędzy na swoje konto, wypłata, oraz zrobienie przelewu do naszego banku jak i klientów obcych banków.
CREATE TABLE TransactionInBranch (
   TransactionID INT NOT NULL,
   TransactionInBranchID INT PRIMARY KEY  IDENTITY(1,1),
   EmployeeID INT NOT NULL,
   AccountID VARCHAR(40) NOT NULL,
   TypeOfTransaction VARCHAR(50) CHECK (TypeOfTransaction IN ('Wpłata', 'Wypłata','Przelew','PrzelewNaKontoObce')) NOT NULL,
   DestinationAccountID VARCHAR(40),
   IsDestinationAccountForeign VARCHAR(3) CHECK (IsDestinationAccountForeign IN ('Yes', 'No','-')) NOT NULL,
   ForeignDestinationAccountID INT,
   FOREIGN KEY(ForeignDestinationAccountID) REFERENCES ForeignBankAccounts(AccountID) ,
   FOREIGN KEY (EmployeeID) REFERENCES BankEmployee(BankEmployeeID),
   FOREIGN KEY (AccountID) REFERENCES Account(AccountID) ,
   FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID),
   FOREIGN KEY (DestinationAccountID) REFERENCES Account(AccountID)
);

--Tabela Transfers:Tabela Transfers rejestruje transakcje przelewów zarówno na konto w naszym banku jak i na konta obce.
CREATE TABLE Transfers (
   TransactionID INT NOT NULL,
   TransferID INT PRIMARY KEY IDENTITY(1,1),
   BLIK VARCHAR(10),
   SourceAccountID VARCHAR(40) NOT NULL,
   DestinationAccountID VARCHAR(40),
   IsDestinationAccountForeign VARCHAR(3) CHECK (IsDestinationAccountForeign IN ('Yes', 'No')) NOT NULL,
   ForeignDestinationAccountID INT,
   FOREIGN KEY(ForeignDestinationAccountID) REFERENCES ForeignBankAccounts(AccountID) ,
   FOREIGN KEY (SourceAccountID) REFERENCES Account(AccountID) ,
   FOREIGN KEY (DestinationAccountID) REFERENCES Account(AccountID) ,
   FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)
);
