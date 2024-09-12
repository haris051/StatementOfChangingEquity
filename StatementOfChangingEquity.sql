drop procedure if Exists PROC_STATEMENT_OF_CHANGING_EQUITY;
DELIMITER $$
CREATE PROCEDURE `PROC_STATEMENT_OF_CHANGING_EQUITY`( 
													  
													  P_COMPANY_ID int,
													  P_ENTRY_DATE_FROM TEXT,
													  P_ENTRY_DATE_TO TEXT
													   
													)
BEGIN

Declare done int default 0;
Declare YearDate Text default null;
Declare ShareCapitalAccount int Default 0;
Declare ShareHolderCurrentAccount int Default 0;
Declare RetainedEarningAccount int Default 0;
Declare AccountChk Text Default "";
Declare YearCursor cursor for
WITH RECURSIVE Years AS
(
    SELECT
        convert(P_ENTRY_DATE_FROM,Date) AS DATE
    UNION ALL
        SELECT
            DATE + INTERVAL 1 Year
        FROM
            Years
        WHERE
            DATE < convert(P_ENTRY_DATE_TO,Date)
)
SELECT * FROM Years;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;


select 
		Share_Holder_Account,
		Dividend_Account,
		Retained_Earning_Account 
into 
		ShareCapitalAccount,
		ShareHolderCurrentAccount,
		RetainedEarningAccount 
from 
		company 
where 
		id = P_COMPANY_ID;


if ShareCapitalAccount is null OR ShareHolderCurrentAccount is null OR RetainedEarningAccount is null 
	then 
		if ShareCapitalAccount is null 
			then 
				SET AccountChk = "'Share Capital Account',";
		end if;
		if ShareHolderCurrentAccount is null 
			then 
				SET AccountChk = concat(AccountChk,"'Share Holder Current Account',");
		End if;
		if RetainedEarningAccount is null 
			then 
				SET AccountChk = concat(AccountChk,"'Retained Earning Account'");
		End if;
        
        select concat("Please Select ",AccountChk," from Company Setings") as Error;
else 


drop temporary table if exists Statement_Of_Changing_Equity;

create temporary Table Statement_Of_Changing_Equity(
														Description VARCHAR(100),
														ShareCapital Decimal(22,2) default null,
														ShareHolderCurrent Decimal(22,2) default null,
														RetainedEarning Decimal(22,2) default null,
														Total Decimal(22,2)
													);

OPEN YearCursor;

MainLoop: LOOP

Fetch YearCursor into YearDate;

IF done = 1 THEN LEAVE MainLoop;
END IF;


Insert into Statement_Of_Changing_Equity 
SELECT concat(
				'Balance as on Dec ',
				Day(LAST_DAY(DATE_ADD((convert(YearDate,Date) - Interval 1 year), INTERVAL 12-MONTH((convert(YearDate,Date) - Interval 1 year)) MONTH))),
				',',
				Year(LAST_DAY(DATE_ADD((convert(YearDate,Date) - Interval 1 year), INTERVAL 12-MONTH((convert(YearDate,Date) - Interval 1 year)) MONTH)))
			 )	
				as Description,
			   (select Round(cast(IFNULL(SUM(Balance),0) as Decimal(22,2)),2) from Daily_Account_Balance where EntryDate < Convert(YearDate,Date) and AccountId = ShareCapitalAccount) as ShareCapital,
			   (select Round(cast(IFNULL(SUM(Balance),0) as Decimal(22,2)),2) from Daily_Account_Balance where EntryDate < Convert(YearDate,Date) and AccountId = ShareHolderCurrentAccount) as ShareHolderCurrent,
			   (select Round(cast(IFNULL(SUM(Balance),0) as Decimal(22,2)),2) from Daily_Account_Balance where EntryDate < Convert(YearDate,Date) and AccountId = RetainedEarningAccount) as RetainedEarning,
			   (select Round(cast(IFNULL(SUM(Balance),0) as Decimal(22,2)),2) from Daily_Account_Balance where EntryDate < Convert(YearDate,Date) and AccountId = ShareCapitalAccount) + 
			   (select Round(cast(IFNULL(SUM(Balance),0) as Decimal(22,2)),2) from Daily_Account_Balance where EntryDate < Convert(YearDate,Date) and AccountId = ShareHolderCurrentAccount) + 
			   (select Round(cast(IFNULL(SUM(Balance),0) as Decimal(22,2)),2) from Daily_Account_Balance where EntryDate < Convert(YearDate,Date) and AccountId = RetainedEarningAccount) as Total 
			   
			   Union All 
			   
select	concat(
		    	'Net Movement During the Year ',
				Year(convert(YearDate,Date))
			  ) as Description,
			  null as ShareCapital,
			  (
			   
			   select 
						Round(cast(IFNULL(SUM(Balance),0) as Decimal(22,2)),2) from Daily_Account_Balance 
				where 
						EntryDate >= Convert(YearDate,Date) 
				  and 
						EntryDate <= Convert(LAST_DAY(DATE_ADD((convert(YearDate,Date)), INTERVAL 12-MONTH((convert(YearDate,Date))) MONTH)),Date) 
				  and 
						AccountId = ShareHolderCurrentAccount
			  
			  ) as ShareHolderCurrent,
			  null as RetainedEarning,
			  (
			  
			   select 
						Round(cast(IFNULL(SUM(Balance),0) as Decimal(22,2)),2) from Daily_Account_Balance 
			    where 
						EntryDate >= Convert(YearDate,Date) 
			      and 
						EntryDate <= Convert(LAST_DAY(DATE_ADD((convert(YearDate,Date)), INTERVAL 12-MONTH((convert(YearDate,Date))) MONTH)),Date) 
			      and 
						AccountId = ShareHolderCurrentAccount
			  
			  ) as Total
			  
			  Union All 
			  
			  select	concat(
								'Net Income During the Year ',
								 Year(convert(YearDate,Date))
							  ) as Description,
						 null as ShareCapital,
						 null as ShareHolderCurrent,
						 (
								select Round(cast(IFNULL(SUM(Balance),0) as Decimal(22,2)),2) 
								from  Daily_Account_Balance 
								where EntryDate >= Convert(YearDate,Date) 
								and   EntryDate <= Convert(LAST_DAY(DATE_ADD((convert(YearDate,Date)), INTERVAL 12-MONTH((convert(YearDate,Date))) MONTH)),Date)
								and   AccountId = RetainedEarningAccount
						 
						 ) as RetainedEarning,
                         (
								select Round(cast(IFNULL(SUM(Balance),0) as Decimal(22,2)),2) 
								from  Daily_Account_Balance 
								where EntryDate >= Convert(YearDate,Date) 
								and   EntryDate <= Convert(LAST_DAY(DATE_ADD((convert(YearDate,Date)), INTERVAL 12-MONTH((convert(YearDate,Date))) MONTH)),Date)
								and   AccountId = RetainedEarningAccount
						 
						 ) as Total;
			  



END LOOP;

CLOSE YearCursor;

select * from Statement_Of_Changing_Equity;
drop temporary table if exists Statement_Of_Changing_Equity;
end if;

END $$
DELIMITER ;