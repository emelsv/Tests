select  f.*
from    sys.foreign_keys f
        inner join sys.tables t on t.object_id = f.parent_object_id and t.schema_id = f.schema_id
        inner join sys.schemas s on t.schema_id = s.schema_id
where   f.name = 'ForeignKeyName'
        and t.name = 'TableName'
        and s.name = 'SchemaName'