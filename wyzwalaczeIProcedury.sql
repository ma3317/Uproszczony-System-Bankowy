GO
CREATE PROCEDURE CheckEligibilityForLoan
   @CustomerID INT,
   @IsEligible BIT OUTPUT
AS
BEGIN
   DECLARE @UnpaidRepayments INT;
   DECLARE @ActiveLoans INT;
   DECLARE @Today DATE;
   SET @Today = GETDATE();
   SELECT @UnpaidRepayments = COUNT(*)
   FROM Repayment R
   INNER JOIN Credit C ON R.CreditID = C.CreditID
   WHERE C.CustomerID = @CustomerID
   AND R.RepaymentStatus = 'Unpaid'
   AND R.DueRepaymentDate <= @Today;
   SELECT @ActiveLoans = COUNT(*)
   FROM Credit
   WHERE CustomerID = @CustomerID AND CreditStatus = 'Active';
   IF @UnpaidRepayments = 0 AND @ActiveLoans < 3
   BEGIN
       SET @IsEligible = 1;
   END
   ELSE
   BEGIN
       SET @IsEligible = 0;
   END;
END;
GO

--2)Procedura która spłaca zadaną ratę dla danego kredytu 
--i nalicza odsetki 100 zł/dzień jeżeli przyjmując dzisiejszą datę rata płacona 
--jest po terminie, dodaje nową transakcję której trigger pobierze pieniądze i 
--wyśle na odpowiednie konto. Jeżeli wszystkie raty kredytu są spłacone to zmienia status kredytu na unactive. 
--Wyświetla także pozostałą ilość rat do spłacenia kredytu.

CREATE PROCEDURE PayRepayment
   @CreditID INT,
   @RepaymentID INT
AS
BEGIN
   DECLARE @Today DATE = GETDATE();
   DECLARE @RemainingRepayments INT;
   DECLARE @LateDays INT;
   DECLARE @LateFee DECIMAL(15, 2);
   DECLARE @Amount DECIMAL(15, 2);
   DECLARE @SourceAccount VARCHAR(40);
   DECLARE @Currency VARCHAR(3);
   DECLARE @Result VARCHAR(MAX);
   SELECT @RemainingRepayments = COUNT(*)
   FROM Repayment
   WHERE CreditID = @CreditID AND RepaymentStatus = 'Unpaid';
   SELECT @LateDays = DATEDIFF(DAY, DueRepaymentDate, @Today)
   FROM Repayment
   WHERE CreditID = @CreditID AND RepaymentID = @RepaymentID;


   SET @LateFee = CASE WHEN @LateDays > 0 THEN @LateDays * 100.00 ELSE 0 END;
   SELECT @Amount = Amount
   FROM Repayment
   WHERE CreditID = @CreditID AND RepaymentID = @RepaymentID;
   SET @Amount = @Amount + @LateFee;
   SELECT @SourceAccount = AccountNumber, @Currency = Currency
   FROM Credit
   WHERE CreditID = @CreditID;
   IF (SELECT AccountBalance FROM Account WHERE AccountID = @SourceAccount) >= @Amount
   BEGIN
       INSERT INTO Transactions (TransactionAmount, Currency, TransactionDate)
       VALUES (@Amount, @Currency, @Today);
DECLARE @id INT
SELECT @id=TransactionID FROM Transactions WHERE TransactionDate=@Today AND       Currency=@Currency AND TransactionAmount=@Amount
       INSERT INTO Transfers VALUES(@id,NULL,@SourceAccount,NULL,'Yes',1)
       UPDATE Repayment
       SET Amount = Amount + @LateFee
       WHERE CreditID = @CreditID AND RepaymentID = @RepaymentID;
       UPDATE Repayment
       SET RepaymentStatus = 'Paid', PaidDate = @Today
       WHERE CreditID = @CreditID AND RepaymentID = @RepaymentID;
       IF @RemainingRepayments - 1 = 0
       BEGIN
           UPDATE Credit
           SET CreditStatus = 'Inactive'
           WHERE CreditID = @CreditID;
       END
       SET @Result = 'Late fee: ' + CAST(@LateFee AS VARCHAR(20)) +
                     ' Remaining repayments: ' + CAST((@RemainingRepayments - 1) AS VARCHAR(10));
   END
   ELSE
   BEGIN
       SET @Result = 'Insufficient funds in the source account.';
   END;
   PRINT @Result;
END;


EXEC PayRepayment @CreditID = 2, @RepaymentID = 1;


--3) Procedura wpłacając pieniądze na konto przy założeniu, że wpłacać możemy przelewem, w oddziale banku lub w bankomacie
CREATE PROCEDURE DepositMoney
@TransactionID INT,
    @AccountID INT,
    @Amount DECIMAL(15, 2),
    @Currency VARCHAR(3),
    @DepositType VARCHAR(20),
    @BranchID INT = NULL,
    @ATMID INT = NULL,
    @SourceAccountID INT = NULL,
  @dateTransaction
AS
BEGIN
    BEGIN TRANSACTION;
    INSERT INTO Transactions (TransactionID,TransactionAmount, Currency, TransactionDate) VALUES (@TransactionID,@Amount, @Currency, @dateTransaction);
  
    SET @TransactionID = SCOPE_IDENTITY();
    IF @DepositType = 'BranchDeposit'
    BEGIN
        INSERT INTO TransactionInBranch (TransactionID, TypeOfTransaction, AccountID, EmployeeID, DestinationAccountID)
        VALUES (@TransactionID, 'Wpłata', @AccountID, NULL, @AccountID);
    END
    ELSE IF @DepositType = 'ATMDeposit'
    BEGIN
        INSERT INTO ATMTransaction (TransactionID, ATMID, AccountID, TypeTransaction)
        VALUES (@TransactionID, @ATMID, @AccountID, 'MakeDeposit');
    END
    ELSE IF @DepositType = 'TransferDeposit'
    BEGIN
        INSERT INTO Transfers (TransactionID, SourceAccountID, DestinationAccountID, IsDestinationAccountForeign)
        VALUES (@TransactionID, @SourceAccountID, @AccountID, 'No');
    END
    UPDATE Account
    SET AccountBalance = AccountBalance + @Amount
    WHERE AccountID = @AccountID;
    COMMIT;
END;
--4)Procedura wypłacająca pieniądze z konta ( wypłacamy przelewem, w oddziale lub w bankomacie). 
--Nie jest to procedura księgująca transakcje z zeszłego dnia czy później.
CREATE PROCEDURE WithdrawMoney
    @AccountID INT,
    @WithdrawalAmount DECIMAL(15, 2),
    @WithdrawalMethod VARCHAR(20)
AS
BEGIN
    DECLARE @CurrentBalance DECIMAL(15, 2);
    SELECT @CurrentBalance = AccountBalance
    FROM Account
    WHERE AccountID = @AccountID;
    IF @WithdrawalAmount > 0 AND @WithdrawalAmount <= @CurrentBalance
    BEGIN
        BEGIN TRANSACTION;
        IF @WithdrawalMethod = 'Transfer'
        BEGIN
            UPDATE Account
            SET AccountBalance = @CurrentBalance - @WithdrawalAmount
            WHERE AccountID = @AccountID;
            INSERT INTO Transactions (TransactionAmount, Currency, TransactionDate)VALUES (-@WithdrawalAmount, 'CurrencyCode', GETDATE());
            INSERT INTO Transfers (SourceAccountID, DestinationAccountID, TransactionID)VALUES (@AccountID, 'DestinationAccountID', SCOPE_IDENTITY());
        END
        ELSE IF @WithdrawalMethod = 'BranchTransaction'
        BEGIN
            UPDATE Account
            SET AccountBalance = @CurrentBalance - @WithdrawalAmount
            WHERE AccountID = @AccountID;
            INSERT INTO Transactions (TransactionAmount, Currency, TransactionDate) VALUES (-@WithdrawalAmount, 'CurrencyCode', GETDATE());
            INSERT INTO TransactionInBranch (EmployeeID, AccountID, TypeOfTransaction, TransactionID)
            VALUES (EmployeeID, @AccountID, 'Wypłata', SCOPE_IDENTITY());
        END
        ELSE IF @WithdrawalMethod = 'ATMTransaction'
        BEGIN
            UPDATE Account
            SET AccountBalance = @CurrentBalance - @WithdrawalAmount
            WHERE AccountID = @AccountID;


            INSERT INTO Transactions (TransactionAmount, Currency, TransactionDate)VALUES (-@WithdrawalAmount, 'CurrencyCode', GETDATE());
            INSERT INTO ATMTransaction (ATMID, AccountID, TypeTransaction, TransactionID) VALUES (ATMID, @AccountID, 'MakeWithdrawal', SCOPE_IDENTITY());
        END
        COMMIT;
    END
END;


--5) Naliczanie opłaty miesięcznej za korzystanie z konta bankowego 
--dla zadanego miesiąca i roku. Jeżeli klient nie ma pieniędzy to naliczamy ujemne wartości, 
--tak aby gdy będzie chciał ponownie skorzystać z konta i wpłaci tam jakieś pieniądze to suma zostanie pobrana.

GO
CREATE PROCEDURE ApplyMonthlyFee
   @AccountID VARCHAR(40),
   @Month INT,
   @Year INT,
   @Result DECIMAL(10, 2) OUTPUT,
   @ResultCurrency VARCHAR(3) OUTPUT
AS
BEGIN
   DECLARE @Count INT
   Select @Count = Count(*) FROM Transfers as tf
   join Transactions tr ON tr.TransactionID = tf.TransactionID
   WHERE tf.SourceAccountID=@AccountID AND MONTH(tr.TransactionDate) = @Month AND YEAR(tr.TransactionDate) = @Year;
   SELECT @ResultCurrency = Currency FROM  Account
   Where AccountID=@AccountID
   SELECT @Result=FeeAmount FROM AccountAccessFee
   WHERE Currency = @ResultCurrency AND TransactionAmount=@Count
   UPDATE Account
   SET AccountBalance = AccountBalance- @Result
   WHERE AccountID = @AccountID;
END;
GO
DECLARE @Result DECIMAL(15, 2);
DECLARE @ResultCurrency VARCHAR(3);


EXEC ApplyMonthlyFee
   @AccountID = 2,
   @Month = 1,
   @Year = 2024,
   @Result = @Result OUTPUT,
   @ResultCurrency = @ResultCurrency OUTPUT;


PRINT 'Monthly Fee: ' + CAST(@Result AS VARCHAR(20)) + ', Currency: ' + @ResultCurrency;




--6)Procedura dotycząca depozytów o argumentach data i ID depozytu, która obliczy 
--ile zyskasz pieniędzy gdy wybierzesz danego dnia pieniądze z depozytu 

GO
CREATE PROCEDURE CalculateDepositProfit
   @Date DATE,
   @TermDepositID INT
AS
BEGIN
   DECLARE @StartDepositDate DATE
   DECLARE @EndDepositDate DATE
   DECLARE @DepositInterestRate DECIMAL(5, 2)
   DECLARE @Amount DECIMAL(15, 2)
   DECLARE @Profit DECIMAL(15, 2)


   SELECT @StartDepositDate = StartDepositDate, @EndDepositDate = DateOfDepositEnd
   FROM TermDeposit
   WHERE TermDepositID = @TermDepositID;


   IF @Date >= @StartDepositDate AND @Date <= @EndDepositDate
   BEGIN
       
       SELECT @DepositInterestRate = DepositInterestRates
       FROM TermDepositInterstRates
       WHERE MinimumLengthInYears = DATEDIFF(YEAR, @StartDepositDate, @EndDepositDate);


       SELECT @Amount = Amount
       FROM TermDeposit
       WHERE TermDepositID = @TermDepositID;


       SET @Profit = @Amount * @DepositInterestRate;


       
       PRINT 'Zysk dla dnia ' + CONVERT(VARCHAR, @Date) + ' wynosi ' + CONVERT(VARCHAR, @Profit) ;
   END
   ELSE
   BEGIN
       PRINT 'Podana data nie mieści się w okresie trwania depozytu.';
   END
END;
GO


EXEC CalculateDepositProfit @Date='2022-12-12' ,@TermDepositID=1

--Wyzwalacze

--1)Wyzwalacz który gdy dodajemy nowe konto dodaje rekordy do tabel Customer_Account lub Company_Account
GO
CREATE TRIGGER Add_Account_Record
ON Account
AFTER INSERT
AS
BEGIN
   SET NOCOUNT ON;


   DECLARE @AccountType2 VARCHAR(20);


   SELECT @AccountType2 = AccountType2 FROM inserted;


   IF @AccountType2 = 'CUSTOMER_ACCOUNT'
   BEGIN
       INSERT INTO Customer_Account (CustomerID, AccountNumber)
       SELECT CustomerID, AccountID FROM inserted;
   END
   ELSE IF @AccountType2 = 'COMPANY_ACCOUNT'
   BEGIN
       INSERT INTO Company_Account (CompanyID, AccountNumber)
       SELECT CompanyID, AccountID FROM inserted;
   END
END;
GO

--2)Wyzwalacz który gdy dodajemy kredyt oblicza nam jego raty 
--pod warunkiem że klient może zaciągnąć kolejny kredyt. Liczona jest wysokość rat z uwzględnieniem oprocentowania stałego.


GO
CREATE TRIGGER AfterInsertCredit
ON Credit
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @CreditID INT, @LoanPeriodInYears INT, @InterestRate DECIMAL(5, 2),@Amount INT, @DataStart DATE, @DataEnd DATE, @Currency VARCHAR(3);
  SELECT @CreditID = CreditID, @Amount = Amount, @Currency = Currency, @DataStart = DataStart, @DataEnd = DataEnd FROM inserted;
  DECLARE @CustomerID INT;
  SELECT @CustomerID = CustomerID
  FROM inserted;
  DECLARE @IsEligible BIT;
  EXEC CheckEligibilityForLoan @CustomerID = @CustomerID, @IsEligible = @IsEligible OUTPUT;
IF @IsEligible = 1
BEGIN
   SET @LoanPeriodInYears = DATEDIFF(YEAR, @DataStart, @DataEnd);
   SELECT @InterestRate = InterstRate FROM FixedLoanInterestRate WHERE LoanPeriodInYears = @LoanPeriodInYears;
   DECLARE @NumberOfPayments DECIMAL(15, 2) = DATEDIFF(MONTH, @DataStart, @DataEnd);
   DECLARE @MonthlyPayment DECIMAL(15, 2) = (@Amount * @InterestRate+@Amount) / (@NumberOfPayments);
   DECLARE @RepaymentDate DATE = @DataStart;
   WHILE @RepaymentDate <= @DataEnd
   BEGIN
   	INSERT INTO Repayment (DueRepaymentDate, Amount, Currency,   RepaymentStatus,PaidDate, CreditID)
       VALUES (@RepaymentDate, @MonthlyPayment,  @Currency, 'Unpaid', NULL,@CreditID);
       SET @RepaymentDate = DATEADD(MONTH, 1, @RepaymentDate);
   END;
   END;
END;
GO

--3) Wyzwalacz sprawdzający czy możemy utworzyć konto o danym ID
CREATE TRIGGER CheckAccountIDBeforeInsert
ON Account
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @NewAccountID VARCHAR(40);
    DECLARE @ExistingAccountIDCount INT;

    
    SELECT @NewAccountID = AccountID
    FROM inserted;

    -- Sprawdź, czy istnieje konto o tym samym ID
    SELECT @ExistingAccountIDCount = COUNT(*)
    FROM Account
    WHERE AccountID = @NewAccountID;

    IF @ExistingAccountIDCount > 0
    BEGIN
     --wycofanie jeżeli istnieje takie id
        ROLLBACK;
    END;
END;


--4) Wyzwalacz sprawdzający czy możemy utworzyć kartę o konkretnym ID
CREATE TRIGGER CheckCardIDBeforeInsert
ON Cards
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @NewCardID INT;
    DECLARE @ExistingCardIDCount INT;

    
    SELECT @NewCardID = CardID
    FROM inserted;

   
    SELECT @ExistingCardIDCount = COUNT(*)
    FROM Cards
    WHERE CardID = @NewCardID;

   
    IF @ExistingCardIDCount > 0
    BEGIN
        --wycofujemy jezeli istnieje takie id
        ROLLBACK;
    END;
END;

--5) Wyzwalacz aktualizujący saldo w bankomacie po transakcji
CREATE TRIGGER UpdateATMBalance
ON ATMTransaction
AFTER INSERT
AS
BEGIN
    UPDATE atm
    SET Balance = Balance - t.TransactionAmount
    FROM AutomatedTellerMachineBalance atm
    JOIN INSERTED t ON atm.AutomatedTellerMachineID = t.AutomatedTellerMachineID;
END;


