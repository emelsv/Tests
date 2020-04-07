declare 
	@search varchar(255),
	@obj_name_search varchar(255)

select 
	@obj_name_search = null,
	@search = 'Ограничение полки'--'-- Атрибуты класса "03_Уцененный товар" ClassID=893' --'ItemCopy'

select distinct
	s.name + '.' + o.name as [object_name],
	o.type_desc,
	object_definition(object_id(s.name + '.' + o.name)) as obj_def
from sys.sql_modules        m (nolock)
	inner join sys.objects  o (nolock)
		on m.object_id=o.object_id
	inner join sys.schemas	s (nolock)
		on o.schema_id = s.schema_id
where (@obj_name_search is null or o.name like '%' + @obj_name_search + '%')
	and m.definition like '%' + @search + '%'
order by 2,1