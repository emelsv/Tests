if object_id('dbo.BasicType') is not null
begin
    drop table dbo.dbo.BasicType;
end;

create table dbo.BasicType
(
    id int not null,
    [name] nvarchar(255) not null,
    constraint pk_basictype primary key (id asc),
    constraint ak_basictype unique ([name] asc)
)

if object_id('dbo.ObjectType') is not null
begin
    drop table dbo.ObjectType;
end;

create table dbo.ObjectType
(
    id int not null,
    [name] nvarchar(255) not null,
    constraint pk_objecttype primary key (id asc),
    constraint ak_objecttype unique ([name] asc)
)

--column
--stored procedure
go