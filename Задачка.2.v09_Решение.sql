--��������� �.�.
--������ 2 ������: v09
 
------------------------------------------------------------------
-- ���������
------------------------------------------------------------------
declare
  @Type_Id    int   = 1,
  @DateBegin  date  = '20000601',
  @DateEnd    date  = '20010131'

------------------------------------------------------------------
-- �������� ������
------------------------------------------------------------------
select [Info] = '�������� ������', * 
from [Test].[Contracts]
where [Type_Id] = @Type_Id

------------------------------------------------------------------
-- ���������
------------------------------------------------------------------
set nocount on;
set transaction isolation level read uncommitted;

select s2.Client_Id -- ������
      ,iif(min(s2.DateFrom) < @DateBegin, @DateBegin, min(s2.DateFrom)) as First_Date -- ���� ������ ������������ ������� �������� ��������(-��) ��������� ����
	  ,iif(max(s2.DateTo) > @DateEnd, @DateEnd, max(s2.DateTo)) as Last_Date ---- ���� ��������� ������������ ������� �������� ��������(-��) ��������� ����
from (select *
            ,sum(IsStart) over (partition by Client_Id order by DateFrom, DateTo
	                            rows unbounded preceding) as [Group]
      from  (select *
                   ,max(DateTo) over (partition by Client_Id order by DateFrom, DateTo
					   	              rows between unbounded preceding and 1 preceding) as PrevioseDateTo
             from [Test].[Contracts]
             where [Type_Id] = @Type_Id
			   and [DateFrom] <= @DateEnd
			   and DateTo >= @DateBegin) s1
cross apply (values (iif(DateFrom <= s1.PrevioseDateTo, null, 1 ))) as Flag(IsStart)) s2
group by s2.Client_Id, s2.[Group]
order by s2.Client_Id;
