select p.ProductId 
      ,count(p.RowNumber) as NumberFirstSales 
from (select ProductId 
            ,row_number() over (partition by CustomerId order by DateCreated asc) as RowNumber 
      from Sales) p 
where p.RowNumber = 1 
group by p.ProductId 

select s.ProductId, count(s.ProductId) as NumberFirstSales 
from Sales s
inner join (select CustomerId
                  ,min(DateCreated) as MinDateCreated
            from Sales
            group by CustomerId) c on s.CustomerId = c.CustomerId and c.MinDateCreated = s.DateCreated
group by s.ProductId

--if field Id is primary key, an integer with auto-incremented
select s.ProductId, count(s.ProductId) as NumberFirstSales 
from Sales s
inner join (select CustomerId
                  ,min(Id) as MinId
            from Sales
            group by CustomerId) c on s.CustomerId = c.CustomerId and c.MinId = s.Id
group by s.ProductId