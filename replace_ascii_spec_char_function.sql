create function dbo.RemoveASCIIControlChar (@inputString varchar(8000))
returns varchar(8000)
as
begin
    declare 
        @badStrings varchar(100),
        @increment  int = 1;

    while @increment <= datalength(@inputString)
    begin
        if ascii(substring(@inputString, @increment, 1)) < 33 
            or ascii(substring(@inputString, @increment, 1)) = 127 --?????
        begin
            set @badStrings = char(ascii(substring(@inputString, @increment, 1)));
            set @inputString = replace(@inputString, @badStrings, '');
        end;

        set @increment = @increment + 1;
    end;

    return @inputString;
end;
go