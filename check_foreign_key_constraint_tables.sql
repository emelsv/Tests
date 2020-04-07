select  object_name(f.parent_object_id) as TableName,
        col_name(fc.parent_object_id,fc.parent_column_id) as ColName
from    sys.foreign_keys f
        inner join sys.foreign_key_columns fc on f.object_id = fc.constraint_object_id
        inner join sys.tables t on t.object_id = fc.referenced_object_id
where   object_name(f.referenced_object_id) = 'TableName'