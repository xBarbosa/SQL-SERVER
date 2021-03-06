USE [SQL_Audit]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BlackList](
    [SRV_Rule] [int] IDENTITY(1,1) NOT NULL,
    [HostName] [varchar](64) NULL,
    [IP_Address] [varchar](15) NULL,
    [LoginName] [varchar](128) NULL,
    [AppName] [varchar](256) NULL,
    [RestrictionEnabled] [bit] NULL,
    [Description] [varchar](2048) NULL,
CONSTRAINT [PK_BlackList] PRIMARY KEY CLUSTERED 
(
    [SRV_Rule] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[BlackList] ADD CONSTRAINT [DF_BlackList_RestrictionEnabled] DEFAULT ((0)) FOR [RestrictionEnabled]
GO

---------------------------------------------------------------------
---------------------------------------------------------------------
USE [SQL_Audit]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Violations](
    [ViolationNum] [int] IDENTITY(1,1) NOT NULL,
    [PostDate] [datetime] NOT NULL,
    [LoginName] [varchar](128) NULL,
    [IPAddress] [varchar](15) NULL,
    [HostName] [nvarchar](64) NULL,
    [ServerName] [varchar](96) NULL,
    [AppName] [nvarchar](256) NULL,
    [ViolationType] [varchar](512) NULL,
CONSTRAINT [PK_Violations] PRIMARY KEY CLUSTERED 
(
    [ViolationNum] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[Violations] ADD CONSTRAINT [DF_Violations_PostDate] DEFAULT (getdate()) FOR [PostDate]
GO
---------------------------------------------------------------------
---------------------------------------------------------------------
--(c) Gregory A. Ferdinandsen
--greg@ferdinandsen.com
--Revision 1.0, 8 Feb 10
--Requires SQL 2005 SP2 or higher

--
--Change with <<Execute as 'Domain\SQL'>> for a valid service account that has sa rights
--
--Information on Logon Triggers: http://msdn.microsoft.com/en-us/library/bb326598.aspx
--
USE Master
go
CREATE Trigger [trg_LoginBlackList]
 on all Server 
AS
begin
 
 declare @data XML
    declare @User as varchar(128)
    declare @HostName as varchar(64)
    declare @IPAddress as varchar(15)
    declare @AppName as nvarchar(256)
    declare @SPID as int
    declare @SrvName as nvarchar(96)
    declare @PostTime as datetime
    declare @LogMsg as varchar(1024)
    
    set @data = EVENTDATA()
    set @User = @data.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(128)')
    set @IPAddress = @data.value('(/EVENT_INSTANCE/ClientHost)[1]', 'nvarchar(15)')
    set @SPID = @data.value('(/EVENT_INSTANCE/SPID)[1]', 'int')
    set @SrvName = @data.value('(/EVENT_INSTANCE/ServerName)[1]', 'nvarchar(96)')
    set @PostTime = @data.value('(/EVENT_INSTANCE/PostTime)[1]', 'datetime')
    set @HostName = Cast(Host_Name() as nvarchar(64))
    set @AppName = Cast(App_Name() as nvarchar(256))
    
    --Check to see if the blacklist table exists, if the table does not exist, exit the Trigger, as otherwise all user would be locked out.
    
    if Not Exists (select * from SQL_Audit.INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'BlackList')
        begin
            return;
        end
    
    
    --#1
    --If a user connects from a given work station and with a given UserName, they will be dissconected
    --This user need to be set up in SQL_Audit..Blacklist with a user name and a host name, no IP Address is necesary
    --This is the prefered method of blacklisting, as DHCP could reak havoc on any IP restrictions
    If(Exists(Select * from SQL_Audit.dbo.BlackList where LoginName = @User and HostName = @HostName and RestrictionEnabled = 1))
        begin
            --Any data modifications made up to the point of ROLLBACK TRANSACTION are rolled back
            --The current trigger continues to execute any remaining statements that appear after the ROLLBACK statement. 
            --If any of these statements modify data, the modifications are not rolled back.
            --http://technet.microsoft.com/en-us/library/bb153915.aspx
            rollback
                
            insert into SQL_Audit..Violations
                (PostDate, LoginName, IPAddress, HostName, ServerName, AppName, ViolationType)
                values (@PostTime, @User, @IPAddress, @HostName, @SrvName, @AppName, 'LoginName, HostName')
                
            --Exit trigger without evaluating any further conditions
            return;
        end
    
    --#2
    --If a user connects from a given IP Address and with a given UserName, they will be dissconected
    --This user need to be set up in SQL_Audit..Blacklist with a user name and a IP Address, no HostName is necesary
    If(Exists(Select * from SQL_Audit.dbo.BlackList where LoginName = @User and IP_Address = @IPAddress and RestrictionEnabled = 1))
        begin
            --Any data modifications made up to the point of ROLLBACK TRANSACTION are rolled back
            --The current trigger continues to execute any remaining statements that appear after the ROLLBACK statement. 
            --If any of these statements modify data, the modifications are not rolled back.
            --http://technet.microsoft.com/en-us/library/bb153915.aspx
            rollback
                
            insert into SQL_Audit..Violations
                (PostDate, LoginName, IPAddress, HostName, ServerName, AppName, ViolationType)
                values (@PostTime, @User, @IPAddress, @HostName, @SrvName, @AppName, 'LoginName, IP Address')
                
            --Exit trigger without evaluating any further conditions
            return;
        end
    
    --#3
    --If a user connects from a given Blacklisted IP Address, regardless of the host name or SQL Server User
    --This IPAddress need to be set up in SQL_Audit..Blacklist with only an IP Address, no other information is needed
    --This will block all connections from the designated IP Address
    If(Exists(Select * from SQL_Audit.dbo.BlackList where IP_Address = @IPAddress and LoginName is NULL and HostName is NULL and RestrictionEnabled = 1))
        begin
            --Any data modifications made up to the point of ROLLBACK TRANSACTION are rolled back
            --The current trigger continues to execute any remaining statements that appear after the ROLLBACK statement. 
            --If any of these statements modify data, the modifications are not rolled back.
            --http://technet.microsoft.com/en-us/library/bb153915.aspx
            rollback
                
            insert into SQL_Audit..Violations
                (PostDate, LoginName, IPAddress, HostName, ServerName, AppName, ViolationType)
                values (@PostTime, @User, @IPAddress, @HostName, @SrvName, @AppName, 'IP Address')
                
            --Exit trigger without evaluating any further conditions
            return;
        end
    
    --#4
    --If a user connects from a given Blacklisted Workstation, regardless of the IP Address or SQL Server User
    --This Client need to be set up in SQL_Audit..Blacklist with only a value for HostName, no other information is needed
    --This will block all connections from the designated Host
    If(Exists(Select * from SQL_Audit.dbo.BlackList where HostName = @HostName and LoginName is NULL and IP_Address is NULL and RestrictionEnabled = 1))
        begin
            --Any data modifications made up to the point of ROLLBACK TRANSACTION are rolled back
            --The current trigger continues to execute any remaining statements that appear after the ROLLBACK statement. 
            --If any of these statements modify data, the modifications are not rolled back.
            --http://technet.microsoft.com/en-us/library/bb153915.aspx
            rollback
                
            insert into SQL_Audit..Violations
                (PostDate, LoginName, IPAddress, HostName, ServerName, AppName, ViolationType)
                values (@PostTime, @User, @IPAddress, @HostName, @SrvName, @AppName, 'HostName')
                
            --Exit trigger without evaluating any further conditions
            return;
        end
    
    --#5
    --If a particular application connects to SQL Server, regardless of IP Address, UserName, or HostName, the session is terminated
    If(Exists(Select * from SQL_Audit.dbo.BlackList where AppName = @AppName and HostName is NULL and LoginName is NULL and IP_Address is NULL and RestrictionEnabled = 1))
        begin
            --Any data modifications made up to the point of ROLLBACK TRANSACTION are rolled back
            --The current trigger continues to execute any remaining statements that appear after the ROLLBACK statement. 
            --If any of these statements modify data, the modifications are not rolled back.
            --http://technet.microsoft.com/en-us/library/bb153915.aspx
            rollback
                
            insert into SQL_Audit..Violations
                (PostDate, LoginName, IPAddress, HostName, ServerName, AppName, ViolationType)
                values (@PostTime, @User, @IPAddress, @HostName, @SrvName, @AppName, 'ApplicationName')
                
            --Exit trigger without evaluating any further conditions
            return;
        end

    --#6
    --If a particular application connects to SQL Server, with a given UserName (i.e. service account cannot connect with SSMS)
    If(Exists(Select * from SQL_Audit.dbo.BlackList where AppName = @AppName and LoginName = @User and RestrictionEnabled = 1))
        begin
            --Any data modifications made up to the point of ROLLBACK TRANSACTION are rolled back
            --The current trigger continues to execute any remaining statements that appear after the ROLLBACK statement. 
            --If any of these statements modify data, the modifications are not rolled back.
            --http://technet.microsoft.com/en-us/library/bb153915.aspx
            rollback
                
            insert into SQL_Audit..Violations
                (PostDate, LoginName, IPAddress, HostName, ServerName, AppName, ViolationType)
                values (@PostTime, @User, @IPAddress, @HostName, @SrvName, @AppName, 'ApplicationName, UserName')
                
            --Exit trigger without evaluating any further conditions
            return;
        end
end;

GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

ENABLE TRIGGER [trg_LoginBlackList] ON ALL SERVER
GO












