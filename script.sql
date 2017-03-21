USE [test_db]
GO
/****** Object:  UserDefinedFunction [dbo].[f_node_childs_get]    Script Date: 21.03.2017 10:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[f_node_childs_get]
(
    @node_id int
)
RETURNS @result TABLE
(
    node_id int NOT NULL,
	parent_node_id int NULL,
	[level] tinyint NOT NULL,
	path_to_top nvarchar(4000) NOT NULL
)
AS
BEGIN
    DECLARE 
        @path_to_top nvarchar(4000);

    SELECT @path_to_top = path_to_top
    FROM dbo.nodes
    WHERE node_id = @node_id

    INSERT INTO @result
    SELECT 
        n.node_id,
        n.parent_node_id,
        n.[level],
        n.path_to_top
    FROM 
        dbo.nodes n
    WHERE 
        n.path_to_top LIKE @path_to_top + '%'
        AND n.path_to_top <> @path_to_top
    
    RETURN
END 


GO
/****** Object:  UserDefinedFunction [dbo].[f_split_string]    Script Date: 21.03.2017 10:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_split_string]
(
    @input_string varchar(max),
    @separator varchar(1)
)
RETURNS @result TABLE
(
        [value] varchar(max)
)
AS
BEGIN
    DECLARE
        @row xml;

    SET @row = cast(('<row>' + replace(@input_string, @separator ,'</row><row>')+'</row>') AS xml);

    INSERT INTO @result
    SELECT node.value('.', 'varchar(max)') AS [value]
    FROM @row.nodes('row') AS tbl(node)

    RETURN
END

GO
/****** Object:  Table [dbo].[nodes]    Script Date: 21.03.2017 10:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[nodes](
	[node_id] [int] IDENTITY(1,1) NOT NULL,
	[parent_node_id] [int] NULL,
	[level] [tinyint] NOT NULL,
	[path_to_top] [nvarchar](4000) NOT NULL,
 CONSTRAINT [PK_nodes] PRIMARY KEY CLUSTERED 
(
	[node_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[v_nodes_list]    Script Date: 21.03.2017 10:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[v_nodes_list]
with schemabinding
as
select 
    node_id,
    parent_node_id,
    [level],
    path_to_top
from
    dbo.nodes

GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [ucix_v_nodes_node_id]    Script Date: 21.03.2017 10:48:42 ******/
CREATE UNIQUE CLUSTERED INDEX [ucix_v_nodes_node_id] ON [dbo].[v_nodes_list]
(
	[node_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[f_node_all_leafs_get]    Script Date: 21.03.2017 10:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[f_node_all_leafs_get]
(
)
RETURNS TABLE 
AS
RETURN 
(
    SELECT n.*
    FROM
        dbo.nodes n WITH (NOLOCK)
        LEFT JOIN
        (  
            SELECT DISTINCT
                parent_node_id AS node_id
            FROM 
                dbo.nodes WITH (NOLOCK)
            WHERE 
                parent_node_id  IS NOT NULL
        ) p 
        ON n.node_id = p.node_id
    WHERE 
        p.node_id IS NULL)


GO
/****** Object:  UserDefinedFunction [dbo].[f_node_parents_get]    Script Date: 21.03.2017 10:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[f_node_parents_get]
(
    @node_id int
)
RETURNS TABLE 
AS
RETURN 
(
    SELECT 
        n1.* 
    FROM 
        dbo.nodes n
        CROSS APPLY dbo.f_split_string(n.path_to_top, '.') p
        INNER JOIN dbo.nodes n1 
        ON p.[value] = n1.node_id
    WHERE 
        n.node_id = @node_id
        AND 
        (
            p.[value] <> '' 
            AND n1.node_id <> n.node_id
        )
)


GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [uix_nodes_node_id]    Script Date: 21.03.2017 10:48:42 ******/
CREATE UNIQUE NONCLUSTERED INDEX [uix_nodes_node_id] ON [dbo].[nodes]
(
	[node_id] ASC
)
INCLUDE ( 	[parent_node_id],
	[level],
	[path_to_top]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [uix_v_nodes_list_node_id]    Script Date: 21.03.2017 10:48:42 ******/
CREATE UNIQUE NONCLUSTERED INDEX [uix_v_nodes_list_node_id] ON [dbo].[v_nodes_list]
(
	[node_id] ASC
)
INCLUDE ( 	[parent_node_id],
	[level],
	[path_to_top]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[nodes]  WITH NOCHECK ADD  CONSTRAINT [FK_nodes_nodes] FOREIGN KEY([parent_node_id])
REFERENCES [dbo].[nodes] ([node_id])
GO
ALTER TABLE [dbo].[nodes] CHECK CONSTRAINT [FK_nodes_nodes]
GO
/****** Object:  StoredProcedure [dbo].[node_all_leafs_get]    Script Date: 21.03.2017 10:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[node_all_leafs_get]
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT n.*
    FROM
        dbo.nodes n
        LEFT JOIN
        (  
            SELECT DISTINCT
                parent_node_id AS node_id
            FROM 
                dbo.nodes
            WHERE 
                parent_node_id  IS NOT NULL
        ) p 
        ON n.node_id = p.node_id
    WHERE 
        p.node_id IS NULL
END
GO
/****** Object:  StoredProcedure [dbo].[node_childs_get]    Script Date: 21.03.2017 10:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[node_childs_get]
    @node_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    declare @path_to_top nvarchar(4000);

    SELECT @path_to_top = path_to_top
    FROM dbo.nodes
    WHERE node_id = @node_id

    SELECT n.*
    FROM 
        dbo.nodes n
    WHERE 
        n.path_to_top LIKE @path_to_top + '%'
        AND n.path_to_top <> @path_to_top
END


GO
/****** Object:  StoredProcedure [dbo].[node_del]    Script Date: 21.03.2017 10:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[node_del]
    @node_id int
AS
BEGIN
	SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @trancount int,
        @level int,
        @path_to_top nvarchar(4000) = '',
        @new_path_to_top nvarchar(4000) = '',
        @parent_node_id int;

    BEGIN TRY
        SELECT
            @parent_node_id = parent_node_id,
            @level = [level],
            @path_to_top = path_to_top,
            @new_path_to_top = REPLACE(path_to_top, CAST(@node_id AS nvarchar(10)) +'.', '')
        FROM dbo.nodes
        WHERE
            node_id = @node_id

--        ;THROW 50001, 'Not implemented exception', 1

        SET @trancount = @@TRANCOUNT;
        
        IF @trancount > 0
            SAVE TRANSACTION parent_node_null_ins;
        ELSE
            BEGIN TRAN;

        UPDATE n
        SET n.parent_node_id = IIF(n.[level] = @level + 1, @parent_node_id, n.parent_node_id), 
            n.[level] = n.[level] - 1, 
            n.path_to_top = REPLACE(n.path_to_top, @path_to_top, @new_path_to_top)
        FROM
            dbo.nodes n 
            INNER JOIN 
            (
                SELECT
                    node_id, 
                    parent_node_id, 
                    [level], 
                    path_to_top
                FROM
                    dbo.f_node_childs_get(@node_id)
            )c
            ON n.node_id = c.node_id 
        
        DELETE FROM dbo.nodes
        WHERE node_id = @node_id
        
        IF @trancount = 0
            COMMIT TRAN;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF(XACT_STATE() = 1)
        BEGIN
            IF @trancount = 0
                COMMIT TRAN;
        END

        IF(XACT_STATE() = -1)
        BEGIN
            IF @trancount > 0
                ROLLBACK TRANSACTION parent_node_null_ins
            ELSE
                ROLLBACK TRAN;

            SET @node_id = NULL;
        END

        DECLARE 
            @err_nmr int = ERROR_NUMBER(),
            @err_msg nvarchar(4000) = ERROR_MESSAGE(),
            @err_ste int = ERROR_STATE();

        ;THROW @err_nmr,  @err_msg, @err_ste;
    END CATCH
END



GO
/****** Object:  StoredProcedure [dbo].[node_ins]    Script Date: 21.03.2017 10:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[node_ins]
    @parent_node_id int = NULL,
    @node_id int OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @trancount int,
        @level tinyint = 1,
        @path_to_top nvarchar(4000) = '';

    BEGIN TRY

        SET @trancount = @@TRANCOUNT;
        
        IF @trancount > 0
            SAVE TRANSACTION parent_node_null_ins;
        ELSE
            BEGIN TRAN;

        INSERT INTO dbo.nodes 
        (parent_node_id, [level], path_to_top)
        VALUES
        (@parent_node_id, @level, @path_to_top);

        SET @node_id = SCOPE_IDENTITY();

        IF @parent_node_id IS NOT NULL
        BEGIN
            SELECT 
                @level          = [level] + 1,
                @path_to_top    = path_to_top
            FROM dbo.nodes
            WHERE
                node_id = @parent_node_id
        END;
    
        UPDATE dbo.nodes
        SET
            [level] = @level, 
            path_to_top = @path_to_top + CAST(@node_id as nvarchar(4000)) + '.'
        WHERE 
            node_id = @node_id;

        IF @trancount = 0
            COMMIT TRAN;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF(XACT_STATE() = 1)
        BEGIN
            IF @trancount = 0
                COMMIT TRAN;
        END

        IF(XACT_STATE() = -1)
        BEGIN
            IF @trancount > 0
                ROLLBACK TRANSACTION parent_node_null_ins
            ELSE
                ROLLBACK TRAN;

            SET @node_id = NULL;
        END
        
        DECLARE 
            @err_nmr int = ERROR_NUMBER(),
            @err_msg nvarchar(4000) = ERROR_MESSAGE(),
            @err_ste int = ERROR_STATE();

        ;THROW @err_nmr,  @err_msg, @err_ste;
    END CATCH
END


GO
/****** Object:  StoredProcedure [dbo].[node_move]    Script Date: 21.03.2017 10:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[node_move]
    @node_id int,
    @new_parent_node_id int
AS
BEGIN
	SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @trancount int,
        @level int,
        @path_to_top nvarchar(4000) = '',
        @new_path_to_top nvarchar(4000) = '',
        @parent_node_id int;

    BEGIN TRY
        SELECT
            @parent_node_id = parent_node_id,
            @level = [level],
            @path_to_top = path_to_top,
            @new_path_to_top = REPLACE(path_to_top, CAST(@node_id AS nvarchar(10)) +'.', '')
        FROM dbo.nodes
        WHERE
            node_id = @node_id

        ;THROW 50001, 'Not implemented exception', 1

        SET @trancount = @@TRANCOUNT;
        
        IF @trancount > 0
            SAVE TRANSACTION parent_node_null_ins;
        ELSE
            BEGIN TRAN;

        UPDATE n
        SET n.parent_node_id = IIF(n.[level] = @level + 1, @parent_node_id, n.parent_node_id), 
            n.[level] = n.[level] - 1, 
            n.path_to_top = REPLACE(n.path_to_top, @path_to_top, @new_path_to_top)
        FROM
            dbo.nodes n 
            INNER JOIN 
            (
                SELECT
                    node_id, 
                    parent_node_id, 
                    [level], 
                    path_to_top
                FROM
                    dbo.f_node_childs_get(@node_id)
            )c
            ON n.node_id = c.node_id 
        
        DELETE FROM dbo.nodes
        WHERE node_id = @node_id
        
        IF @trancount = 0
            COMMIT TRAN;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF(XACT_STATE() = 1)
        BEGIN
            IF @trancount = 0
                COMMIT TRAN;
        END

        IF(XACT_STATE() = -1)
        BEGIN
            IF @trancount > 0
                ROLLBACK TRANSACTION parent_node_null_ins
            ELSE
                ROLLBACK TRAN;

            SET @node_id = NULL;
        END

        DECLARE 
            @err_nmr int = ERROR_NUMBER(),
            @err_msg nvarchar(4000) = ERROR_MESSAGE(),
            @err_ste int = ERROR_STATE();

        ;THROW @err_nmr,  @err_msg, @err_ste;
    END CATCH
END




GO
/****** Object:  StoredProcedure [dbo].[node_parents_get]    Script Date: 21.03.2017 10:48:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[node_parents_get]
    @node_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT 
        n1.* 
    FROM 
        dbo.nodes n
        CROSS APPLY STRING_SPLIT(n.path_to_top, '.') p
        INNER JOIN dbo.nodes n1 
        ON p.[value] = n1.node_id
    WHERE 
        n.node_id = @node_id
        AND 
        (
            p.[value] <> '' 
            AND n1.node_id <> n.node_id
        )
END
GO
