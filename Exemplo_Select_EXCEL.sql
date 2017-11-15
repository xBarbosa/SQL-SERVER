-- A few basic approaches... Dynamically using openrowset through to more formally with Linked Server. Could even go to Office Automation procedures - but we won't go that far if not needed.
 
-- the common way is to use "dynamic" linking to the datasource using a data provider when used in an ad-hoc kind of way
-- and by using providers directly as a "dynamic" linked server - opens Excel directly, then there are a couple of choices...
SELECT ID FROM OPENROWSET('Microsoft.Jet.OLEDB.4.0','Excel 8.0;database=c:\ID_NAO_ENCONTRADO.xls;hdr=yes',' select * from [Plan1$]') as a
 
 
-- and just to show you the ACE version of openrowset
Select * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;Database=c:\order_worksheet.xlsx;HDR=Yes', 'SELECT * FROM [order_worksheet$]') as a         -- just to show office 2007 syntax