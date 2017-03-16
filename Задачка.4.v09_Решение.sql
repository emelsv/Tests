--��������� �.�.
--������ 4 ������: v09


-----------------------------------------------------
-- ������ �������� ����������:
-----------------------------------------------------
DECLARE
  @DateFrom         Date    = '20150101'
DECLARE
  @DateTo           Date    = DATEADD(Day,7, @DateFrom),
  @BaseCurrency_Id  Int     = 1

------------------------------------------------------------------
-- ���������
------------------------------------------------------------------
set nocount on;
set transaction isolation level read uncommitted;

select o.Client_Id
      ,o.Currency_Id
	  ,sum((o.DateValue * rv.Rate) / rv.Volume) as BaseBalance
from (select Client_Id
            ,Currency_Id
			,[Date]
			,sum(Value) as DateValue
      from [TestMoney].[Operations]
	  where Currency_Id <> @BaseCurrency_Id 
	    and [Date] between @DateFrom and @DateTo
	  group by Client_Id
	          ,Currency_Id
			  ,[Date]) o
cross apply (select top (1) Rate, Volume
             from [TestMoney].[Currencies Rates]
			 where Currency_Id = o.Currency_Id
			   and BaseCurrency_Id = @BaseCurrency_Id
			   and [Date] <= o.[Date] 
			 order by [Date] desc) rv
group by o.Client_Id, o.Currency_Id
order by o.Client_Id asc, o.Currency_Id asc
go

--��������� ������������ ������ ��� ������� �� ���� Date � ����������� ��������� Client_Id, Currency_Id, Value ������� [TestMoney].[Operations]
--��� �������� � ����� ������� � ������ ������������ ����������� ������� ��������� �� ������������ ������������� ��������� ����� �� ������������� �������
/*
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20161211-190956] ON [TestMoney].[Operations]
(
	[Date] ASC
)
INCLUDE ( 	[Client_Id],
	[Value],
	[Currency_Id]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
*/