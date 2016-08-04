select p.ProductId
      ,count(p.RowNumber) as NumberFirstSales
from (select ProductId
            ,row_number() over (partition by ProductId, CustomerId order by DateCreated asc) as RowNumber
      from Sales) p
where p.RowNumber = 1
group by p.ProductId
