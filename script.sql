USE [master]
GO
/****** Object:  Database [test_db]    Script Date: 21.03.2017 17:15:25 ******/
CREATE DATABASE [test_db]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'test_db', FILENAME = N'C:\test_db\test_db.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'test_db_log', FILENAME = N'C:\test_db\test_db_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [test_db] SET COMPATIBILITY_LEVEL = 130
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [test_db].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [test_db] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [test_db] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [test_db] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [test_db] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [test_db] SET ARITHABORT OFF 
GO
ALTER DATABASE [test_db] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [test_db] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [test_db] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [test_db] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [test_db] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [test_db] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [test_db] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [test_db] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [test_db] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [test_db] SET  DISABLE_BROKER 
GO
ALTER DATABASE [test_db] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [test_db] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [test_db] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [test_db] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [test_db] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [test_db] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [test_db] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [test_db] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [test_db] SET  MULTI_USER 
GO
ALTER DATABASE [test_db] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [test_db] SET DB_CHAINING OFF 
GO
ALTER DATABASE [test_db] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [test_db] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [test_db] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [test_db] SET QUERY_STORE = OFF
GO
USE [test_db]
GO
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = PRIMARY;
GO
USE [test_db]
GO
USE [test_db]
GO
/****** Object:  Sequence [dbo].[global_sequence]    Script Date: 21.03.2017 17:15:25 ******/
CREATE SEQUENCE [dbo].[global_sequence] 
 AS [bigint]
 START WITH 0
 INCREMENT BY 1
 MINVALUE -9223372036854775808
 MAXVALUE 9223372036854775807
 CACHE 
GO
/****** Object:  UserDefinedFunction [dbo].[udf_get_node_childs]    Script Date: 21.03.2017 17:15:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_get_node_childs]
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
/****** Object:  UserDefinedFunction [dbo].[udf_split_string]    Script Date: 21.03.2017 17:15:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_split_string]
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
/****** Object:  Table [dbo].[nodes]    Script Date: 21.03.2017 17:15:25 ******/
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
/****** Object:  View [dbo].[v_nodes_list]    Script Date: 21.03.2017 17:15:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[v_nodes_list]
WITH SCHEMABINDING 
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
/****** Object:  Index [ucix_v_nodes_list_node_id]    Script Date: 21.03.2017 17:15:25 ******/
CREATE UNIQUE CLUSTERED INDEX [ucix_v_nodes_list_node_id] ON [dbo].[v_nodes_list]
(
	[node_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_get_node_all_leafs]    Script Date: 21.03.2017 17:15:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[udf_get_node_all_leafs]
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
/****** Object:  UserDefinedFunction [dbo].[udf_get_node_parents]    Script Date: 21.03.2017 17:15:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[udf_get_node_parents]
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
        CROSS APPLY dbo.udf_split_string(n.path_to_top, '.') p
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
/****** Object:  Index [uix_nodes_node_id]    Script Date: 21.03.2017 17:15:25 ******/
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
/****** Object:  Index [uix_v_nodes_list_node_id]    Script Date: 21.03.2017 17:15:25 ******/
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
/****** Object:  StoredProcedure [dbo].[usp_del_node]    Script Date: 21.03.2017 17:15:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_del_node]
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
        END

        DECLARE 
            @err_nmr int = ERROR_NUMBER(),
            @err_msg nvarchar(4000) = ERROR_MESSAGE(),
            @err_ste int = ERROR_STATE();

        ;THROW @err_nmr,  @err_msg, @err_ste;
    END CATCH
END




GO
/****** Object:  StoredProcedure [dbo].[usp_get_node_all_leafs]    Script Date: 21.03.2017 17:15:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_get_node_all_leafs]
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
/****** Object:  StoredProcedure [dbo].[usp_get_node_childs]    Script Date: 21.03.2017 17:15:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_get_node_childs]
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
/****** Object:  StoredProcedure [dbo].[usp_get_node_parents]    Script Date: 21.03.2017 17:15:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_get_node_parents]
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
/****** Object:  StoredProcedure [dbo].[usp_ins_node]    Script Date: 21.03.2017 17:15:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_ins_node]
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
/****** Object:  StoredProcedure [dbo].[usp_move_node]    Script Date: 21.03.2017 17:15:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[usp_move_node]
    @node_id int,
    @new_parent_node_id int
AS
BEGIN
	SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @trancount int,
        @level_move_step int,
        @old_path_to_top nvarchar(4000),
        @new_path_to_top nvarchar(4000),
        @err_msg nvarchar(4000);

    BEGIN TRY
        SELECT
            @old_path_to_top = n.path_to_top,
            @new_path_to_top = np.path_to_top + CAST(n.node_id AS nvarchar(4000)) + N'.',
            @level_move_step = IIF(
                                    CAST(np.[level] AS int) - CAST(n.[level] AS int) = 0, 
                                    1, 
                                    IIF(
                                            CAST(np.[level] AS int) - CAST(n.[level] AS int) < 0, 
                                            CAST(np.[level] AS int) - CAST(n.[level] AS int) + 1, 
                                            CAST(np.[level] AS int) - CAST(n.[level] AS int)
                                        )
                                  )
        FROM 
            dbo.nodes n
            OUTER APPLY
            (
                SELECT 
                    path_to_top,
                    [level]
                FROM 
                    dbo.nodes
                WHERE 
                    node_id = @new_parent_node_id
            ) np
        WHERE
            n.node_id = @node_id

        IF @old_path_to_top IS NULL
        BEGIN
            SET @err_msg = N'@node_id = ' + CAST(@node_id AS nvarchar(11)) + N' not exists'
            ;THROW 50002, @err_msg, 1
        END

        IF @new_path_to_top IS NULL
        BEGIN
            SET @err_msg = N'@new_parent_node_id = ' + CAST(@new_parent_node_id AS nvarchar(11)) + N' not exists'
            ;THROW 50003, @err_msg, 1
        END

        SET @trancount = @@TRANCOUNT;
        
        IF @trancount > 0
            SAVE TRANSACTION usp_move_node_tran;
        ELSE
            BEGIN TRAN;
        
        UPDATE n
        SET
            path_to_top = REPLACE(n.path_to_top, @old_path_to_top, @new_path_to_top),
            [level] = n.[level] + @level_move_step
        FROM 
            dbo.nodes n
            INNER JOIN dbo.udf_get_node_childs(@node_id) c
            ON n.node_id = c.node_id

        UPDATE dbo.nodes
        SET 
            parent_node_id = @new_parent_node_id,
            path_to_top = REPLACE(path_to_top, @old_path_to_top, @new_path_to_top),
            [level] = [level] + @level_move_step
        WHERE
            node_id = @node_id
        
        IF @trancount = 0
            COMMIT TRAN;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF (XACT_STATE() = 1)
        BEGIN
            IF @trancount = 0
                COMMIT TRAN;
        END;

        IF(XACT_STATE() = -1)
        BEGIN
            IF @trancount > 0
                ROLLBACK TRANSACTION usp_move_node_tran
            ELSE
                ROLLBACK TRAN;
        END;

        DECLARE 
            @err_nmr int = ERROR_NUMBER(),
            @err_ste int = ERROR_STATE();
         
        SET @err_msg = ERROR_MESSAGE();

        ;THROW @err_nmr,  @err_msg, @err_ste;
    END CATCH
END








GO
USE [master]
GO
ALTER DATABASE [test_db] SET  READ_WRITE 
GO
