--Microsoft Sql Server 2012
--Емельянов С.

set nocount on;

--***************************************************
-- Задача 1
--***************************************************

-- в тестовых таблицах нет данных за текущий 2017 год и предыдущий 2016 год

select g.good_name
      ,sum(iif(s.s_date >= convert(date, dateadd(d, -datepart(dy, getdate()), getdate()) + 1) and s.s_date < convert(date, getdate() + 1), coalesce(s.amount, 0), 0)) as YTD
	  ,sum(iif(s.s_date >=  convert(date, dateadd(d, 1 - day(getdate()), getdate())) and s.s_date < convert(date, getdate() + 1), coalesce(s.amount, 0), 0)) as MTD
	  ,sum(iif(s.s_date >= dateadd(q, datediff(q, 0, getdate()), 0) and s_date < convert(date, getdate() + 1), coalesce(s.amount, 0), 0)) as QTD
	  ,sum(iif(s.s_date >= dateadd(yy, -1, convert(date, dateadd(d, -datepart(dy, getdate()), getdate()) + 1)) and s.s_date < dateadd(yy, -1, convert(date, getdate() + 1)), coalesce(s.amount, 0), 0)) as PYTD
	  ,sum(iif(s.s_date >=  dateadd(yy, -1, convert(date, dateadd(d, 1 - day(getdate()), getdate()))) and s.s_date < dateadd(yy, -1, convert(date, getdate() + 1)), coalesce(s.amount, 0), 0)) as PMTD
	  ,sum(iif(s.s_date >= dateadd(yy, -1, dateadd(q, datediff(q, 0, getdate()), 0)) and s_date < dateadd(yy, -1, convert(date, getdate() + 1)), coalesce(s.amount, 0), 0)) as PQTD
from dbo.ref_goods g
left outer join dbo.sales s on g.id = s.id_good -- по товарам могут быть нулевые продажи 
group by g.good_name;

/*
select convert(date, dateadd(d, -datepart(dy, getdate()), getdate()) + 1) as Y;
select convert(date, dateadd(d, 1 - day(getdate()), getdate())) as D;
select dateadd(q, datediff(q, 0, getdate()), 0) as Q;
select dateadd(yy, -1, convert(date, dateadd(d, -datepart(dy, getdate()), getdate()) + 1)) as PY;
select dateadd(yy, -1, convert(date, dateadd(d, 1 - day(getdate()), getdate()))) as PD;
select dateadd(yy, -1, dateadd(q, datediff(q, 0, getdate()), 0)) as PQ;
select convert(date, getdate() + 1) as FD;
select dateadd(yy, -1, convert(date, getdate() + 1)) as PFD;
*/
go

--***************************************************
-- Задача 2
--***************************************************
select res.WeekNum, res.id, rg.good_name, rgg.good_group_name, res.s_date, res.amount, res.rate
from 
(
	select r.WeekNum, r.id,  r.id_good, r.s_date, r.amount, r.rate,
           row_number() over (partition by r.WeekNum, r.id_good  order by r.rate asc, r.s_date desc) as rn
    from (select case when d.s_date >= '20131201' and d.s_date < '20131209' then 1
                      when d.s_date >= '20131209' and d.s_date < '20131216' then 2
                      when d.s_date >= '20131216' and d.s_date < '20131223' then 3
                      when d.s_date >= '20131223' and d.s_date < '20140101' then 4
	             else null end as WeekNum,
	      d.id, d.id_good, d.s_date, d.amount, d.rate
    from [dbo].[docs] d
    where d.s_date >= '20131201' and d.s_date < '20140101') r
) res
inner join dbo.ref_goods rg on res.id_good = rg.id
inner join dbo.ref_good_groups rgg on rg.id_good_group = rgg.id
where res.rn = 1
order by res.WeekNum, res.id;

go

--***************************************************
-- Задача 3
--***************************************************
declare @startDate date,
        @finishDate date,
		@strStartDate nvarchar(10),
        @strFinishDate nvarchar(10),
		@dates nvarchar(max),
		@dates1 nvarchar(max),
		@rdates nvarchar(max),
		@sql nvarchar(max);

select @startDate = '20130101',
       @finishDate = '20130202';

select @strStartDate = cast(@startDate as nvarchar(10)),
       @strFinishDate = cast(dateadd(d, 1, @finishDate) as nvarchar(10)),
	   @dates = '';

set @dates = stuff((select distinct ',[' + convert(varchar(10), s_date, 104) + ']'
from dbo.sales
where s_date >= @startDate
  and s_date < @strFinishDate
for xml path('')), 1, 1, '');

--select @dates;

set @rdates = stuff((select ',isnull([' + convert(varchar(10), d.s_date, 104) + '], 0) as [' + convert(varchar(10), d.s_date, 104) + ']'
from (select distinct convert(date, s_date) as s_date
	  from dbo.sales
      where s_date >= @startDate
        and s_date < @strFinishDate) d
order by d.s_date asc
for xml path('')), 1, 1, '');

--select @rdates;

set @sql = '
select good_name, ' + @rdates + '
from 
(
select rg.good_name, convert(varchar(10), s.s_date, 104) as s_date, s.amount 
from dbo.sales s
inner join dbo.ref_goods rg on s.id_good = rg.id
where s.s_date >= ''' + @strStartDate + '''
  and s.s_date < ''' + @strFinishDate + '''
) c
pivot (sum(c.amount) for c.s_date in (' + @dates +')) p';

--print @sql

exec sp_executesql @sql;

go
