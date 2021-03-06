USE [master]
GO
/****** Object:  Database [test_db]    Script Date: 28.04.2017 15:08:39 ******/
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
/****** Object:  Sequence [dbo].[global_sequence]    Script Date: 28.04.2017 15:08:40 ******/
CREATE SEQUENCE [dbo].[global_sequence] 
 AS [bigint]
 START WITH 0
 INCREMENT BY 1
 MINVALUE -9223372036854775808
 MAXVALUE 9223372036854775807
 CACHE 
GO
/****** Object:  UserDefinedFunction [dbo].[udf_get_customer_type_id]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[udf_get_customer_type_id](@customer_id int)
returns int
as
begin
    declare 
        @result int = NULL;

    select 
        @result = customer_type_id
    from
        dbo.customers with (nolock)
    where
        customer_id = @customer_id

    return @result
end 
GO
/****** Object:  UserDefinedFunction [dbo].[udf_get_node_childs]    Script Date: 28.04.2017 15:08:40 ******/
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
/****** Object:  UserDefinedFunction [dbo].[udf_split_string]    Script Date: 28.04.2017 15:08:40 ******/
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
/****** Object:  Table [dbo].[nodes]    Script Date: 28.04.2017 15:08:40 ******/
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
/****** Object:  UserDefinedFunction [dbo].[udf_get_node_all_leafs]    Script Date: 28.04.2017 15:08:40 ******/
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
    SELECT 
        n.node_id,
        n.parent_node_id,
        n.[level],
        n.path_to_top
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
/****** Object:  UserDefinedFunction [dbo].[udf_get_node_parents]    Script Date: 28.04.2017 15:08:40 ******/
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
        n1.node_id,
        n1.parent_node_id,
        n1.[level],
        n1.path_to_top
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
/****** Object:  Table [dbo].[customers]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[customers](
	[customer_id] [int] IDENTITY(1,1) NOT NULL,
	[object_type_id] [smallint] NOT NULL,
	[customer_type_id] [int] NOT NULL,
 CONSTRAINT [pk_customers] PRIMARY KEY CLUSTERED 
(
	[customer_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[customers_hist]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[customers_hist](
	[customer_hist_id] [int] IDENTITY(1,1) NOT NULL,
	[customer_id] [int] NOT NULL,
	[state_id] [int] NOT NULL,
	[state_time] [datetime] NOT NULL,
	[state_user_id] [int] NOT NULL,
 CONSTRAINT [pk_customers_hist] PRIMARY KEY CLUSTERED 
(
	[customer_hist_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[customers_nodes]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[customers_nodes](
	[customer_id] [int] NOT NULL,
	[node_id] [int] NOT NULL,
 CONSTRAINT [pk_customers_nodes] PRIMARY KEY CLUSTERED 
(
	[customer_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [ak_customers_nodes] UNIQUE NONCLUSTERED 
(
	[node_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[customers_persons]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[customers_persons](
	[customer_id] [int] NOT NULL,
	[person_id] [int] NOT NULL,
 CONSTRAINT [pk_customers_persons] PRIMARY KEY CLUSTERED 
(
	[customer_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [ak_customers_persons] UNIQUE NONCLUSTERED 
(
	[person_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[customers_types]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[customers_types](
	[customer_type_id] [int] NOT NULL,
	[object_type_id] [smallint] NOT NULL,
	[code] [nvarchar](3) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
 CONSTRAINT [pk_customers_types] PRIMARY KEY CLUSTERED 
(
	[customer_type_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [ak_customers_types] UNIQUE NONCLUSTERED 
(
	[code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[customers_types_hist]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[customers_types_hist](
	[customer_type_hist_id] [int] IDENTITY(1,1) NOT NULL,
	[customer_type_id] [int] NOT NULL,
	[state_id] [int] NOT NULL,
	[state_time] [datetime] NOT NULL,
	[state_user_id] [int] NOT NULL,
 CONSTRAINT [pk_customers_types_hist] PRIMARY KEY CLUSTERED 
(
	[customer_type_hist_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[delivery_notes]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[delivery_notes](
	[delivery_note_id] [int] IDENTITY(1,1) NOT NULL,
	[object_type_id] [smallint] NOT NULL,
	[order_id] [int] NULL,
	[customer_id] [int] NOT NULL,
	[delivery_note_date] [date] NOT NULL,
 CONSTRAINT [pk_delivery_notes] PRIMARY KEY CLUSTERED 
(
	[delivery_note_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[delivery_notes_hist]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[delivery_notes_hist](
	[delivery_note_hist_id] [int] IDENTITY(1,1) NOT NULL,
	[delivery_note_id] [int] NOT NULL,
	[state_id] [int] NOT NULL,
	[state_time] [datetime] NOT NULL,
	[state_user_id] [int] NOT NULL,
 CONSTRAINT [pk_delivery_notes_hist] PRIMARY KEY CLUSTERED 
(
	[delivery_note_hist_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[delivery_notes_items]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[delivery_notes_items](
	[delivery_note_item_id] [int] IDENTITY(1,1) NOT NULL,
	[object_type_id] [smallint] NOT NULL,
	[delivery_note_id] [int] NOT NULL,
	[product_id] [int] NOT NULL,
	[quantity] [decimal](12, 4) NOT NULL,
 CONSTRAINT [pk_delivery_notes_items] PRIMARY KEY CLUSTERED 
(
	[delivery_note_item_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [ak_delivery_notes_items] UNIQUE NONCLUSTERED 
(
	[delivery_note_id] ASC,
	[product_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[objects_graph_states]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[objects_graph_states](
	[objects_graph_state_id] [int] IDENTITY(1,1) NOT NULL,
	[object_type_id] [smallint] NOT NULL,
	[out_state_id] [int] NOT NULL,
	[into_state_id] [int] NOT NULL,
	[action_id] [int] NOT NULL,
 CONSTRAINT [pk_objects_graph_states] PRIMARY KEY CLUSTERED 
(
	[objects_graph_state_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[objects_types]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[objects_types](
	[object_type_id] [smallint] NOT NULL,
	[name] [nvarchar](128) NULL,
	[table_name] [nvarchar](64) NOT NULL,
 CONSTRAINT [pk_objects_types] PRIMARY KEY CLUSTERED 
(
	[object_type_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [ak_objects_types] UNIQUE NONCLUSTERED 
(
	[table_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[orders]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[orders](
	[order_id] [int] IDENTITY(1,1) NOT NULL,
	[object_type_id] [smallint] NOT NULL,
	[customer_id] [int] NOT NULL,
	[order_date] [date] NOT NULL,
 CONSTRAINT [pk_orders] PRIMARY KEY CLUSTERED 
(
	[order_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[orders_items]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[orders_items](
	[order_item_id] [int] IDENTITY(1,1) NOT NULL,
	[order_id] [int] NOT NULL,
	[product_id] [int] NOT NULL,
	[quantity] [decimal](12, 4) NOT NULL,
 CONSTRAINT [pk_orders_items] PRIMARY KEY CLUSTERED 
(
	[order_item_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [ak_orders_items] UNIQUE NONCLUSTERED 
(
	[order_id] ASC,
	[product_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[persons]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[persons](
	[person_id] [int] IDENTITY(1,1) NOT NULL,
	[object_type_id] [smallint] NOT NULL,
	[surname] [nvarchar](50) NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[patronymic] [nvarchar](50) NOT NULL,
 CONSTRAINT [pk_persons] PRIMARY KEY CLUSTERED 
(
	[person_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[products]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[products](
	[product_id] [int] IDENTITY(1,1) NOT NULL,
	[object_type_id] [smallint] NOT NULL,
	[article] [nvarchar](64) NOT NULL,
 CONSTRAINT [pk_products] PRIMARY KEY CLUSTERED 
(
	[product_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [ak_products] UNIQUE NONCLUSTERED 
(
	[article] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[products_hist]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[products_hist](
	[product_hist_id] [int] IDENTITY(1,1) NOT NULL,
	[product_id] [int] NOT NULL,
	[state_id] [int] NOT NULL,
	[state_time] [datetime] NOT NULL,
	[state_user_id] [int] NOT NULL,
 CONSTRAINT [pk_products_hist] PRIMARY KEY CLUSTERED 
(
	[product_hist_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[states]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[states](
	[state_id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](128) NOT NULL,
	[direction] [smallint] NOT NULL,
 CONSTRAINT [pk_states] PRIMARY KEY CLUSTERED 
(
	[state_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [ak_states] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[users]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[users](
	[user_id] [int] IDENTITY(0,1) NOT NULL,
	[object_type_id] [smallint] NOT NULL,
	[email] [nvarchar](254) NOT NULL,
	[email_confirmed] [bit] NOT NULL,
	[hash] [nvarchar](128) NOT NULL,
	[modifier] [nvarchar](12) NOT NULL,
	[last_login_time] [datetime] NULL,
 CONSTRAINT [pk_users] PRIMARY KEY CLUSTERED 
(
	[user_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [ak_users] UNIQUE NONCLUSTERED 
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[users_hist]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[users_hist](
	[user_hist_id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NOT NULL,
	[state_id] [int] NOT NULL,
	[state_time] [datetime] NOT NULL,
	[state_user_id] [int] NOT NULL,
 CONSTRAINT [pk_users_hist] PRIMARY KEY CLUSTERED 
(
	[user_hist_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[users_persons]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[users_persons](
	[user_id] [int] NOT NULL,
	[person_id] [int] NOT NULL,
 CONSTRAINT [pk_users_persons] PRIMARY KEY CLUSTERED 
(
	[user_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [ak_users_persons] UNIQUE NONCLUSTERED 
(
	[person_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [uix_customers_types_code]    Script Date: 28.04.2017 15:08:40 ******/
CREATE UNIQUE NONCLUSTERED INDEX [uix_customers_types_code] ON [dbo].[customers_types]
(
	[code] ASC
)
INCLUDE ( 	[customer_type_id],
	[name]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [uix_nodes_node_id]    Script Date: 28.04.2017 15:08:40 ******/
CREATE UNIQUE NONCLUSTERED INDEX [uix_nodes_node_id] ON [dbo].[nodes]
(
	[node_id] ASC
)
INCLUDE ( 	[parent_node_id],
	[level],
	[path_to_top]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [ix_products_hist_state_time]    Script Date: 28.04.2017 15:08:40 ******/
CREATE NONCLUSTERED INDEX [ix_products_hist_state_time] ON [dbo].[products_hist]
(
	[state_time] DESC
)
INCLUDE ( 	[product_hist_id],
	[product_id],
	[state_id],
	[state_user_id]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_states_name]    Script Date: 28.04.2017 15:08:40 ******/
CREATE NONCLUSTERED INDEX [ix_states_name] ON [dbo].[states]
(
	[name] ASC
)
INCLUDE ( 	[state_id],
	[direction]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[customers_hist] ADD  CONSTRAINT [df_customers_hist_state_time]  DEFAULT (getdate()) FOR [state_time]
GO
ALTER TABLE [dbo].[customers_types_hist] ADD  CONSTRAINT [df_customers_types_hist_state_time]  DEFAULT (getdate()) FOR [state_time]
GO
ALTER TABLE [dbo].[delivery_notes] ADD  CONSTRAINT [df_delivery_notes_delivery_note_date]  DEFAULT (getdate()) FOR [delivery_note_date]
GO
ALTER TABLE [dbo].[delivery_notes_hist] ADD  CONSTRAINT [df_delivery_notes_hist_state_time]  DEFAULT (getdate()) FOR [state_time]
GO
ALTER TABLE [dbo].[orders] ADD  CONSTRAINT [df_orders_order_date]  DEFAULT (getdate()) FOR [order_date]
GO
ALTER TABLE [dbo].[persons] ADD  CONSTRAINT [df_persons_object_type_id]  DEFAULT ((1)) FOR [object_type_id]
GO
ALTER TABLE [dbo].[products_hist] ADD  CONSTRAINT [df_products_hist_state_time]  DEFAULT (getdate()) FOR [state_time]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [df_users_email_confirmed]  DEFAULT ((0)) FOR [email_confirmed]
GO
ALTER TABLE [dbo].[users_hist] ADD  CONSTRAINT [df_users_hist_state_time]  DEFAULT (getdate()) FOR [state_time]
GO
ALTER TABLE [dbo].[customers]  WITH CHECK ADD  CONSTRAINT [fk_customers_ref_customers_types] FOREIGN KEY([customer_type_id])
REFERENCES [dbo].[customers_types] ([customer_type_id])
GO
ALTER TABLE [dbo].[customers] CHECK CONSTRAINT [fk_customers_ref_customers_types]
GO
ALTER TABLE [dbo].[customers]  WITH CHECK ADD  CONSTRAINT [fk_customers_ref_objects_types] FOREIGN KEY([object_type_id])
REFERENCES [dbo].[objects_types] ([object_type_id])
GO
ALTER TABLE [dbo].[customers] CHECK CONSTRAINT [fk_customers_ref_objects_types]
GO
ALTER TABLE [dbo].[customers_hist]  WITH NOCHECK ADD  CONSTRAINT [fk_customers_hist_ref_customers] FOREIGN KEY([customer_id])
REFERENCES [dbo].[customers] ([customer_id])
GO
ALTER TABLE [dbo].[customers_hist] CHECK CONSTRAINT [fk_customers_hist_ref_customers]
GO
ALTER TABLE [dbo].[customers_hist]  WITH NOCHECK ADD  CONSTRAINT [fk_customers_hist_ref_states] FOREIGN KEY([state_id])
REFERENCES [dbo].[states] ([state_id])
GO
ALTER TABLE [dbo].[customers_hist] CHECK CONSTRAINT [fk_customers_hist_ref_states]
GO
ALTER TABLE [dbo].[customers_hist]  WITH NOCHECK ADD  CONSTRAINT [fk_customers_hist_ref_users] FOREIGN KEY([state_user_id])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[customers_hist] CHECK CONSTRAINT [fk_customers_hist_ref_users]
GO
ALTER TABLE [dbo].[customers_nodes]  WITH CHECK ADD  CONSTRAINT [fk_customers_nodes_ref_nodes] FOREIGN KEY([node_id])
REFERENCES [dbo].[nodes] ([node_id])
GO
ALTER TABLE [dbo].[customers_nodes] CHECK CONSTRAINT [fk_customers_nodes_ref_nodes]
GO
ALTER TABLE [dbo].[customers_persons]  WITH CHECK ADD  CONSTRAINT [fk_customers_persons_ref_customers] FOREIGN KEY([customer_id])
REFERENCES [dbo].[customers] ([customer_id])
GO
ALTER TABLE [dbo].[customers_persons] CHECK CONSTRAINT [fk_customers_persons_ref_customers]
GO
ALTER TABLE [dbo].[customers_persons]  WITH CHECK ADD  CONSTRAINT [fk_customers_persons_ref_persons] FOREIGN KEY([person_id])
REFERENCES [dbo].[persons] ([person_id])
GO
ALTER TABLE [dbo].[customers_persons] CHECK CONSTRAINT [fk_customers_persons_ref_persons]
GO
ALTER TABLE [dbo].[customers_types]  WITH CHECK ADD  CONSTRAINT [fk_customers_types_ref_objects_types] FOREIGN KEY([object_type_id])
REFERENCES [dbo].[objects_types] ([object_type_id])
GO
ALTER TABLE [dbo].[customers_types] CHECK CONSTRAINT [fk_customers_types_ref_objects_types]
GO
ALTER TABLE [dbo].[customers_types_hist]  WITH CHECK ADD  CONSTRAINT [fk_customers_types_hist_ref_delivery_notes] FOREIGN KEY([customer_type_id])
REFERENCES [dbo].[customers_types] ([customer_type_id])
GO
ALTER TABLE [dbo].[customers_types_hist] CHECK CONSTRAINT [fk_customers_types_hist_ref_delivery_notes]
GO
ALTER TABLE [dbo].[customers_types_hist]  WITH CHECK ADD  CONSTRAINT [fk_customers_types_hist_ref_states] FOREIGN KEY([state_id])
REFERENCES [dbo].[states] ([state_id])
GO
ALTER TABLE [dbo].[customers_types_hist] CHECK CONSTRAINT [fk_customers_types_hist_ref_states]
GO
ALTER TABLE [dbo].[customers_types_hist]  WITH CHECK ADD  CONSTRAINT [fk_customers_types_hist_ref_users] FOREIGN KEY([state_user_id])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[customers_types_hist] CHECK CONSTRAINT [fk_customers_types_hist_ref_users]
GO
ALTER TABLE [dbo].[delivery_notes]  WITH CHECK ADD  CONSTRAINT [fk_delivery_notes_ref_customers] FOREIGN KEY([customer_id])
REFERENCES [dbo].[customers] ([customer_id])
GO
ALTER TABLE [dbo].[delivery_notes] CHECK CONSTRAINT [fk_delivery_notes_ref_customers]
GO
ALTER TABLE [dbo].[delivery_notes]  WITH CHECK ADD  CONSTRAINT [fk_delivery_notes_ref_objects_types] FOREIGN KEY([object_type_id])
REFERENCES [dbo].[objects_types] ([object_type_id])
GO
ALTER TABLE [dbo].[delivery_notes] CHECK CONSTRAINT [fk_delivery_notes_ref_objects_types]
GO
ALTER TABLE [dbo].[delivery_notes]  WITH CHECK ADD  CONSTRAINT [fk_delivery_notes_ref_orders] FOREIGN KEY([order_id])
REFERENCES [dbo].[orders] ([order_id])
GO
ALTER TABLE [dbo].[delivery_notes] CHECK CONSTRAINT [fk_delivery_notes_ref_orders]
GO
ALTER TABLE [dbo].[delivery_notes_hist]  WITH NOCHECK ADD  CONSTRAINT [fk_delivery_notes_hist_ref_delivery_notes] FOREIGN KEY([delivery_note_id])
REFERENCES [dbo].[delivery_notes] ([delivery_note_id])
GO
ALTER TABLE [dbo].[delivery_notes_hist] CHECK CONSTRAINT [fk_delivery_notes_hist_ref_delivery_notes]
GO
ALTER TABLE [dbo].[delivery_notes_hist]  WITH NOCHECK ADD  CONSTRAINT [fk_delivery_notes_hist_ref_states] FOREIGN KEY([state_id])
REFERENCES [dbo].[states] ([state_id])
GO
ALTER TABLE [dbo].[delivery_notes_hist] CHECK CONSTRAINT [fk_delivery_notes_hist_ref_states]
GO
ALTER TABLE [dbo].[delivery_notes_hist]  WITH NOCHECK ADD  CONSTRAINT [fk_delivery_notes_hist_ref_users] FOREIGN KEY([state_user_id])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[delivery_notes_hist] CHECK CONSTRAINT [fk_delivery_notes_hist_ref_users]
GO
ALTER TABLE [dbo].[delivery_notes_items]  WITH CHECK ADD  CONSTRAINT [fk_delivery_notes_items_ref_delivery_notes] FOREIGN KEY([delivery_note_id])
REFERENCES [dbo].[delivery_notes] ([delivery_note_id])
GO
ALTER TABLE [dbo].[delivery_notes_items] CHECK CONSTRAINT [fk_delivery_notes_items_ref_delivery_notes]
GO
ALTER TABLE [dbo].[delivery_notes_items]  WITH CHECK ADD  CONSTRAINT [fk_delivery_notes_items_ref_objects_types] FOREIGN KEY([object_type_id])
REFERENCES [dbo].[objects_types] ([object_type_id])
GO
ALTER TABLE [dbo].[delivery_notes_items] CHECK CONSTRAINT [fk_delivery_notes_items_ref_objects_types]
GO
ALTER TABLE [dbo].[delivery_notes_items]  WITH CHECK ADD  CONSTRAINT [fk_delivery_notes_items_ref_products] FOREIGN KEY([product_id])
REFERENCES [dbo].[products] ([product_id])
GO
ALTER TABLE [dbo].[delivery_notes_items] CHECK CONSTRAINT [fk_delivery_notes_items_ref_products]
GO
ALTER TABLE [dbo].[nodes]  WITH NOCHECK ADD  CONSTRAINT [fk_nodes_ref_nodes] FOREIGN KEY([parent_node_id])
REFERENCES [dbo].[nodes] ([node_id])
GO
ALTER TABLE [dbo].[nodes] CHECK CONSTRAINT [fk_nodes_ref_nodes]
GO
ALTER TABLE [dbo].[orders]  WITH CHECK ADD  CONSTRAINT [fk_orders_ref_customers] FOREIGN KEY([customer_id])
REFERENCES [dbo].[customers] ([customer_id])
GO
ALTER TABLE [dbo].[orders] CHECK CONSTRAINT [fk_orders_ref_customers]
GO
ALTER TABLE [dbo].[orders]  WITH NOCHECK ADD  CONSTRAINT [fk_orders_ref_objects_types] FOREIGN KEY([object_type_id])
REFERENCES [dbo].[objects_types] ([object_type_id])
GO
ALTER TABLE [dbo].[orders] CHECK CONSTRAINT [fk_orders_ref_objects_types]
GO
ALTER TABLE [dbo].[orders_items]  WITH CHECK ADD  CONSTRAINT [fk_orders_items_ref_orders] FOREIGN KEY([order_id])
REFERENCES [dbo].[orders] ([order_id])
GO
ALTER TABLE [dbo].[orders_items] CHECK CONSTRAINT [fk_orders_items_ref_orders]
GO
ALTER TABLE [dbo].[orders_items]  WITH CHECK ADD  CONSTRAINT [fk_orders_items_ref_products] FOREIGN KEY([product_id])
REFERENCES [dbo].[products] ([product_id])
GO
ALTER TABLE [dbo].[orders_items] CHECK CONSTRAINT [fk_orders_items_ref_products]
GO
ALTER TABLE [dbo].[persons]  WITH CHECK ADD  CONSTRAINT [fk_persons_ref_objects_types] FOREIGN KEY([object_type_id])
REFERENCES [dbo].[objects_types] ([object_type_id])
GO
ALTER TABLE [dbo].[persons] CHECK CONSTRAINT [fk_persons_ref_objects_types]
GO
ALTER TABLE [dbo].[products]  WITH CHECK ADD  CONSTRAINT [fk_products_ref_objects_types] FOREIGN KEY([object_type_id])
REFERENCES [dbo].[objects_types] ([object_type_id])
GO
ALTER TABLE [dbo].[products] CHECK CONSTRAINT [fk_products_ref_objects_types]
GO
ALTER TABLE [dbo].[products_hist]  WITH CHECK ADD  CONSTRAINT [fk_products_hist_ref_products] FOREIGN KEY([product_id])
REFERENCES [dbo].[products] ([product_id])
GO
ALTER TABLE [dbo].[products_hist] CHECK CONSTRAINT [fk_products_hist_ref_products]
GO
ALTER TABLE [dbo].[products_hist]  WITH CHECK ADD  CONSTRAINT [fk_products_hist_ref_states] FOREIGN KEY([state_id])
REFERENCES [dbo].[states] ([state_id])
GO
ALTER TABLE [dbo].[products_hist] CHECK CONSTRAINT [fk_products_hist_ref_states]
GO
ALTER TABLE [dbo].[products_hist]  WITH CHECK ADD  CONSTRAINT [fk_products_hist_ref_users] FOREIGN KEY([state_user_id])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[products_hist] CHECK CONSTRAINT [fk_products_hist_ref_users]
GO
ALTER TABLE [dbo].[users]  WITH CHECK ADD  CONSTRAINT [fk_users_ref_objects_types] FOREIGN KEY([object_type_id])
REFERENCES [dbo].[objects_types] ([object_type_id])
GO
ALTER TABLE [dbo].[users] CHECK CONSTRAINT [fk_users_ref_objects_types]
GO
ALTER TABLE [dbo].[users_hist]  WITH CHECK ADD  CONSTRAINT [fk_users_hist_ref_states] FOREIGN KEY([state_id])
REFERENCES [dbo].[states] ([state_id])
GO
ALTER TABLE [dbo].[users_hist] CHECK CONSTRAINT [fk_users_hist_ref_states]
GO
ALTER TABLE [dbo].[users_hist]  WITH CHECK ADD  CONSTRAINT [fk1_users_hist_ref_users] FOREIGN KEY([user_id])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[users_hist] CHECK CONSTRAINT [fk1_users_hist_ref_users]
GO
ALTER TABLE [dbo].[users_hist]  WITH CHECK ADD  CONSTRAINT [fk2_users_hist_ref_users] FOREIGN KEY([state_user_id])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[users_hist] CHECK CONSTRAINT [fk2_users_hist_ref_users]
GO
ALTER TABLE [dbo].[users_persons]  WITH CHECK ADD  CONSTRAINT [fk_users_persons_ref_persons] FOREIGN KEY([person_id])
REFERENCES [dbo].[persons] ([person_id])
GO
ALTER TABLE [dbo].[users_persons] CHECK CONSTRAINT [fk_users_persons_ref_persons]
GO
ALTER TABLE [dbo].[users_persons]  WITH CHECK ADD  CONSTRAINT [fk_users_persons_ref_users] FOREIGN KEY([user_id])
REFERENCES [dbo].[users] ([user_id])
GO
ALTER TABLE [dbo].[users_persons] CHECK CONSTRAINT [fk_users_persons_ref_users]
GO
ALTER TABLE [dbo].[customers_persons]  WITH CHECK ADD  CONSTRAINT [ck_customers_persons_customer_type] CHECK  (([dbo].[udf_get_customer_type_id]([customer_id])=(1)))
GO
ALTER TABLE [dbo].[customers_persons] CHECK CONSTRAINT [ck_customers_persons_customer_type]
GO
ALTER TABLE [dbo].[states]  WITH NOCHECK ADD  CONSTRAINT [ck_states_direction] CHECK  (([direction]=(1) OR [direction]=(-1)))
GO
ALTER TABLE [dbo].[states] CHECK CONSTRAINT [ck_states_direction]
GO
/****** Object:  StoredProcedure [dbo].[usp_del_node]    Script Date: 28.04.2017 15:08:40 ******/
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

        SET @trancount = @@TRANCOUNT;
        
        IF @trancount > 0
            SAVE TRANSACTION usp_del_node_tran;
        ELSE
            BEGIN TRAN;
        
        UPDATE n
        SET n.parent_node_id = IIF(n.parent_node_id = @node_id, @parent_node_id, n.parent_node_id), 
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
                    dbo.udf_get_node_childs(@node_id)
            ) c
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
                ROLLBACK TRANSACTION usp_del_node_tran
            ELSE
                ROLLBACK TRAN;
        END

        DECLARE 
            @err_msg nvarchar(4000) = CAST(ERROR_NUMBER() AS nvarchar(10)) + ', ' + ERROR_MESSAGE(),
            @err_ste int = ERROR_STATE();

        ;THROW 50000, @err_msg, @err_ste;
    END CATCH
END




GO
/****** Object:  StoredProcedure [dbo].[usp_get_node_all_leafs]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_node_all_leafs]
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT 
		n.node_id,
		n.parent_node_id,
		n.[level],
		n.path_to_top
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
/****** Object:  StoredProcedure [dbo].[usp_get_node_childs]    Script Date: 28.04.2017 15:08:40 ******/
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
END

GO
/****** Object:  StoredProcedure [dbo].[usp_get_node_parents]    Script Date: 28.04.2017 15:08:40 ******/
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
        n1.node_id,
        n1.parent_node_id,
        n1.[level],
        n1.path_to_top
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
END

GO
/****** Object:  StoredProcedure [dbo].[usp_ins_customer]    Script Date: 28.04.2017 15:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE PROCEDURE [dbo].[usp_ins_customer]
    @customer_id int OUTPUT,
    @parent_customer_id int,
    @customer_type_id int 
AS
BEGIN
	SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @trancount int,
        @parent_node_id int,
        @node_id int

    BEGIN TRY

        SELECT
            @parent_node_id = node_id
        FROM
            dbo.customers_nodes
        WHERE
            customer_id = @parent_customer_id 

        SET @trancount = @@TRANCOUNT;

        IF @trancount > 0
            SAVE TRANSACTION usp_ins_customer_tran;
        ELSE
            BEGIN TRAN;

        EXEC dbo.usp_ins_node
            @parent_node_id,
            @node_id OUTPUT

        INSERT INTO dbo.customers 
        (object_type_id, customer_type_id)
        VALUES
        (0, @customer_type_id);

        SET @customer_id = SCOPE_IDENTITY();

        INSERT INTO dbo.customers_nodes
        (customer_id, node_id)
        VALUES
        (@customer_id, @node_id);


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
                ROLLBACK TRANSACTION usp_ins_customer_tran
            ELSE
                ROLLBACK TRAN;

            SET @customer_id = NULL;
        END
        
        DECLARE 
            @err_msg nvarchar(4000) = CAST(ERROR_NUMBER() AS nvarchar(10)) + ', ' + ERROR_MESSAGE(),
            @err_ste int = ERROR_STATE();

        ;THROW 50000,  @err_msg, @err_ste;
    END CATCH
END

GO
/****** Object:  StoredProcedure [dbo].[usp_ins_node]    Script Date: 28.04.2017 15:08:40 ******/
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
            SAVE TRANSACTION usp_ins_node;
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
                ROLLBACK TRANSACTION usp_ins_node
            ELSE
                ROLLBACK TRAN;

            SET @node_id = NULL;
        END
        
        DECLARE 
            @err_msg nvarchar(4000) = CAST(ERROR_NUMBER() AS nvarchar(10)) + ', ' + ERROR_MESSAGE(),
            @err_ste int = ERROR_STATE();

        ;THROW 50000,  @err_msg, @err_ste;
    END CATCH
END

GO
/****** Object:  StoredProcedure [dbo].[usp_move_node]    Script Date: 28.04.2017 15:08:40 ******/
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
        @old_path_to_top nvarchar(4000),
        @new_path_to_top nvarchar(4000),
        @err_msg nvarchar(4000);

    BEGIN TRY
        SELECT
            @old_path_to_top = n.path_to_top,
            @new_path_to_top = np.path_to_top + CAST(n.node_id AS nvarchar(4000)) + N'.'
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
            [level]     = LEN(REPLACE(n.path_to_top, @old_path_to_top, @new_path_to_top)) 
                          - LEN(REPLACE(REPLACE(n.path_to_top, @old_path_to_top, @new_path_to_top), '.', ''))
        FROM 
            dbo.nodes n
            INNER JOIN dbo.udf_get_node_childs(@node_id) c
            ON n.node_id = c.node_id

        UPDATE dbo.nodes
        SET 
            parent_node_id  = @new_parent_node_id,
            path_to_top     = REPLACE(path_to_top, @old_path_to_top, @new_path_to_top),
            [level]         = LEN(REPLACE(path_to_top, @old_path_to_top, @new_path_to_top)) 
                              - LEN(REPLACE(REPLACE(path_to_top, @old_path_to_top, @new_path_to_top), '.', ''))
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
            @err_ste int = ERROR_STATE();
         
        SET @err_msg = CAST(ERROR_NUMBER() AS nvarchar(10)) + ', ' + ERROR_MESSAGE();

        ;THROW 50000,  @err_msg, @err_ste;
    END CATCH
END

GO
USE [master]
GO
ALTER DATABASE [test_db] SET  READ_WRITE 
GO
