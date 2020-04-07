declare
    @ProviderID dbo.BIDENT = 2894880,
    @Items      xml =
    '
    <Items>
        <ItemId>4788803</ItemId>
        <ItemId>4788804</ItemId>
        <ItemId>150193088</ItemId>
    </Items>
    '
    set transaction isolation level read uncommitted;

    create table #items_tbl
    (
        ItemID dbo.BIDENT primary key
    )

    insert into #items_tbl (ItemID)
    select distinct T.Item.value('.', 'bigint') as ItemID
    from @Items.nodes('//Items/ItemId') as T (Item)

    /*
    select  IT.ItemID,
            PS.ClearingID as WarehouseID, 
            SA.StoreID,
            S.Name as StoreName,
            SA.QtyPresent as Qty
    from    #items_tbl IT
            left join dbo.StoreAmount SA on SA.ItemID = IT.ItemID
            left join dbo.PhysicalStore PS on SA.PhysicalStoreID = PS.ID
            left join dbo.Store S on SA.StoreID = S.ID
            left join dbo.ProviderItem PIT on IT.ItemID = PIT.ItemID and PIT.ProviderID = @ProviderID
    */

    declare @xml xml = 
    (
    select
        PS.ClearingID as warehouse_id,
        (
            select 1 as hz
            for xml raw, type
        )
    from #items_tbl IT
            left join dbo.StoreAmount SA on SA.ItemID = IT.ItemID
            left join dbo.PhysicalStore PS on SA.PhysicalStoreID = PS.ID
    for xml path('stocks'), root('data'), elements
    );

    select @xml
    
    drop table #items_tbl

    select stuff((select '; ' + isnull(cast(PI.ItemID as varchar(12)), '')
    from (values(11),(22),(33)) as PI (ItemID)
    for xml path('')), 1, 2, '')


    --exec dbo.ProviderItemStockGet
    --    @ProviderID = 2894880,
    --    @Items =
    --    '
    --    <Items>
    --        <ItemId>4788803</ItemId>
    --        <ItemId>4788804</ItemId>
    --        <ItemId>150193088</ItemId>
    --    </Items>
    --    '

SELECT a, b,c,
  STUFF((SELECT  distinct ', '+ t1.a +'-'+ t1.statecode
             FROM Tab1 t1
             where  t2.b = t1.a and
                    t2.c= t1.c 
             FOR XML PATH('concat'), Type
         ).Value('/concat[1]', 'varchar(max)'), 1, 1,'') AS ACCEPTED_SYMBOLS
from Tab1 t2;
