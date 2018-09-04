--Using INSERT / OUTPUT in a SQL Server Transaction

/*
INSERT INTO <SOME_TABLE>
    (
        <column_list>
    )
OUTPUT INSERTED.<identity_column> --and other columns from SOME_TABLE if need be
INTO <SOME_OTHER_TABLE>
    (
        <column_list>
    )
SELECT
    (
        <column_list>
    )
FROM <source_table_OR_JOIN_of_multiple_tables>
WHERE <filtering_criteria>
*/
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
USE AdventureWorks;
GO

---Create Example Tables
/*
Note, this is not fully-normalized.  I would have included another table
for Notification Types if this was an actual solution.
I would also use an int NotificationTypeID column in Notifications table
instead of a varchar(xx) NotificationType column.
*/

CREATE SCHEMA [HR] AUTHORIZATION dbo;
GO

CREATE TABLE [HR].[Staff]
(
   [StaffID] [int] IDENTITY(1,1) NOT NULL,
   [FirstName] VARCHAR(30) NOT NULL,
   [LastName] VARCHAR(30) NOT NULL,

    CONSTRAINT [PK_StaffID] PRIMARY KEY CLUSTERED
        (
           [StaffID] ASC
        )ON [PRIMARY]
) ON [PRIMARY];

CREATE TABLE [HR].[Notification]
(
    [NotificationID] [int] IDENTITY(1,1) NOT NULL,
   [StaffID] [int] NOT NULL,
   [NotificationDate] DATETIME NOT NULL,
   [NotificationType] VARCHAR(30) NOT NULL,

    CONSTRAINT [PK_NotificationID] PRIMARY KEY CLUSTERED
        (
           [NotificationID] ASC
        )ON [PRIMARY]
) ON [PRIMARY]; 
    

/*
Demonstrate how you can insert the key values added to Staff.StaffID
into Notifications.StaffID in single transaction
*/

INSERT INTO HR.Staff ( FirstName, LastName )
OUTPUT INSERTED.StaffID, DATEADD(d,90,GETDATE()),'90-Day Review'
INTO HR.Notification
    (
        StaffID,
        NotificationDate,
        NotificationType
    )
VALUES  ( 'Santa','Claus'); 