--DO
use Rezon
go

set ansi_nulls on;
set quoted_identifier on;
go

if not exists ( select  1 
                from    sys.indexes 
                where   [name] ='IX_TableName_FieldName' 
                        and object_id = object_id('dbo.TableName'))
begin
    create nonclustered index IX_TableName_FieldName on dbo.TableName
    (
        Field1,
        Field2
    )
    include
    (
        Field3,
        Field4
    )
    with (online = on); 
end
go

--UNDO
use Rezon
go

set ansi_nulls on;
set quoted_identifier on;
go

if exists ( select  1 
            from    sys.indexes 
            where   [name] ='IX_TableName_FieldName' 
                    and object_id = object_id('dbo.TableName'))
begin
    drop index IX_TableName_FieldName on dbo.TableName; 
end
go