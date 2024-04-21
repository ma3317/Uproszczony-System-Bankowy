go

CREATE FUNCTION Show_accounts_balances (@ClientId INT)
RETURNS TABLE
AS
    RETURN
      SELECT Account.Accountid,
             Account.Currency,
             AccountBalance
      FROM   Account
      WHERE  Account.CustomerID = @ClientID;

go 

--2) Widok wyświetlający liczbę kont danego klienta
CREATE VIEW number_of_accounts
AS
  SELECT Customer.CustomerID,
         CustomerName,
         CustomerSurname,
         Count(*) AS NumberOfAccounts
  FROM   Customer
         JOIN Account
           ON Account.CustomerID = Customer.CustomerID
  GROUP  BY Customer.CustomerID,
            CustomerName,
            CustomerSurname; 

--3)Funkcja, która liczy sumę w podanej walucie pieniędzy danego użytkownika na wszystkich jego kontach w danej walucie

GO
CREATE FUNCTION CalculateTotalAmountInCurrency1
(
   @UserID INT,
   @UserType VARCHAR(10),
   @Currency VARCHAR(3)
)
RETURNS DECIMAL(15, 2)
AS
BEGIN
   DECLARE @TotalAmount DECIMAL(15, 2);
   IF @UserType = 'Customer'
   BEGIN
       SELECT @TotalAmount = ISNULL(SUM(a.AccountBalance), 0)
       FROM Account a
       INNER JOIN Customer_Account ca ON a.AccountID = ca.AccountNumber
       WHERE a.Currency = @Currency
       AND ca.CustomerID = @UserID;
   END
   ELSE IF @UserType = 'Company'
   BEGIN
       SELECT @TotalAmount = ISNULL(SUM(a.AccountBalance), 0)
       FROM Account a
       INNER JOIN Company_Account coa ON a.AccountID = coa.AccountNumber
       WHERE a.Currency = @Currency
       AND coa.CompanyID = @UserID;
   END;
   RETURN @TotalAmount;
END;
GO


DECLARE @TotalAmount DECIMAL(15, 2);
SELECT @TotalAmount = dbo.CalculateTotalAmountInCurrency(1, 'Customer', 'PLN');
PRINT 'Total amount for CustomerID 1 in USD: ' + CAST(dbo.CalculateTotalAmountInCurrency1(1, 'Customer', 'USD') AS VARCHAR(20));




--4)Widok wszystkich kart w systemie wraz z numerem konta

GO
CREATE VIEW AllCardsForAccount AS
SELECT
   c.CardID,
   a.AccountID,
   c.ExpirationDate,
   c.CardType
FROM
   Cards c
JOIN
   Account a ON c.AccountID = a.AccountID;
GO


--5) Widok osób z kredytami - wyświetla informacje o osobach, które kiedykolwiek wzięły kredyt.
CREATE VIEW  clients_with_credits AS
SELECT * FROM Customer
WHERE CustomerID IN (SELECT CustomerID FROM Credit);

--6)Uznania (wpłaty) dla każdego konta. Jest to widok który wyświetla id konta, typ transakcji i kwota uznania
GO
CREATE VIEW Uznania AS
SELECT
   t.TransactionID,
   'TypTransakcji' AS TypTransakcji,
   t.TransactionAmount AS Kwota,
   a.AccountID
FROM
   Transactions t
JOIN
   TransactionCard tc ON t.TransactionID = tc.TransactionID
JOIN
   Account a ON tc.DestinationAccountID = a.AccountID
UNION ALL
SELECT
   t.TransactionID,
   'Wymiana walut' AS TypTransakcji,
   t.TransactionAmount AS Kwota,
   a.AccountID
FROM
   Transactions t
JOIN
   ExchangeCurrencyTransaction ect ON t.TransactionID = ect.TransactionID
JOIN
   Account a ON ect.DestinationAccountID = a.AccountID
UNION ALL
SELECT
   t.TransactionID,
   'Wplata w okienku' AS TypTransakcji,
   t.TransactionAmount AS Kwota,
   a.AccountID
FROM
   Transactions t
JOIN
   TransactionInBranch tib ON t.TransactionID = tib.TransactionID
JOIN
   Account a ON tib.AccountID = a.AccountID
WHERE
   tib.TypeOfTransaction = 'Wpłata'
UNION ALL
SELECT
   t.TransactionID,
   'Przelew' AS TypTransakcji,
   t.TransactionAmount AS Kwota,
   a.AccountID
FROM
   Transactions t
JOIN
   Transfers tr ON t.TransactionID = tr.TransactionID
JOIN
   Account a ON tr.DestinationAccountID = a.AccountID
UNION ALL
SELECT
   t.TransactionID,
   'Wplata w ATM' AS TypTransakcji,
   t.TransactionAmount AS Kwota,
   a.AccountID
FROM
   Transactions t
JOIN
   ATMTransaction at ON t.TransactionID = at.TransactionID
JOIN
   Account a ON at.AccountID = a.AccountID
WHERE
   at.TypeTransaction = 'MakeDeposit';
GO

--7)Funkcja suma wydatków z danego miesiąca i roku dla danego konta


GO
CREATE FUNCTION dbo.GetTotalExpenditureForAccount (
   @AccountID VARCHAR(40),
   @Month INT,
   @Year INT
)
RETURNS DECIMAL(15, 2)
AS
BEGIN
   DECLARE @TotalExpenditure DECIMAL(15, 2);
   SELECT @TotalExpenditure = SUM(t.TransactionAmount)
   FROM Transactions t
   LEFT JOIN TransactionCard tc ON t.TransactionID = tc.TransactionID
   LEFT JOIN TransactionInBranch tb ON t.TransactionID = tb.TransactionID
   LEFT JOIN Transfers tr ON t.TransactionID = tr.TransactionID
   LEFT JOIN ATMTransaction atm ON t.TransactionID = atm.TransactionID
   LEFT JOIN ExchangeCurrencyTransaction ect ON t.TransactionID = ect.TransactionID
   WHERE
       (
           (tc.DestinationAccountID = @AccountID) -- Wypłata z karty
           OR (tb.AccountID = @AccountID AND tb.TypeOfTransaction = 'Wypłata') 
-- Wypłata w oddziale
           OR (tr.SourceAccountID = @AccountID) -- Transfer z konta
           OR (atm.AccountID = @AccountID AND atm.TypeTransaction = 'MakeWithdrawal') 
-- Wypłata w bankomacie
           OR (ect.SourceAccountID = @AccountID) -- Wymiana walut
       )
       AND MONTH(t.TransactionDate) = @Month
       AND YEAR(t.TransactionDate) = @Year


   RETURN ISNULL(@TotalExpenditure, 0);
END;
GO
DECLARE @AccountID VARCHAR(40) = 1;
DECLARE @Month INT = 1;
DECLARE @Year INT = 2020;


DECLARE @TotalExpenditure DECIMAL(15, 2);


SET @TotalExpenditure = dbo.GetTotalExpenditureForAccount(@AccountID, @Month, @Year);


SELECT @TotalExpenditure AS TotalExpenditure;


--8) Funkcja zwracająca listę transakcji w danym bankomacie
CREATE FUNCTION ShowATMTransactions(@atmId INT)
RETURNS TABLE
AS
RETURN (
    SELECT
        T.TransactionID,
        T.TransactionAmount,
        T.Currency,
        A.TypeTransaction
    FROM Transactions T
    JOIN ATMTransaction A ON T.TransactionID = A.TransactionID
    WHERE A.ATMID = @atmId
);


--9) Funkcja zwracająca wszystkie transakcje w danym oddziale banku
CREATE FUNCTION showBranchTransactions()
RETURNS TABLE
AS
RETURN (
    SELECT
        t.TransactionID,
        t.TransactionAmount,
        t.Currency,
        t.TransactionDate,
        t2.EmployeeID,
        t2.TypeOfTransaction,
        t2.DestinationAccountID,
        t2.ForeignDestinationAccountID
    FROM Transactions t
    JOIN TransactionInBranch t2 ON t.TransactionID = t2.TransactionID
);

--10) Funkcja zwracająca listę lokat danego klienta
CREATE FUNCTION showTermDepositsForCustomer(@customerID INT)
RETURNS TABLE
AS
RETURN (
    SELECT
        t.TermDepositID,
        t.Amount,
        t.Currency,
        t.StartDepositDate,
        t.DateOfDepositEnd
    FROM TermDeposit t
    WHERE t.CustomerID = @customerID
);

