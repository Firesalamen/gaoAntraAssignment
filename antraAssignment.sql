--1.	List of Persons¡¯ full name, all their fax and phone numbers, as well as the phone number and fax of the company they are working for (if any). 
use WideWorldImporters;
Select CustomerName, FaxNumber, PhoneNumber
from sales.customers

--2.	If the customer's primary contact person has the same phone number as the customer¡¯s phone number, list the customer companies. 
use WideWorldImporters;
Select CustomerName
from sales.customers as sc
inner join Application.People as ap on ap.PersonID= sc.PrimaryContactPersonID
where ap.PhoneNumber=sc.PhoneNumber

--3.	List of customers to whom we made a sale prior to 2016 but no sale since 2016-01-01.

use WideWorldImporters;
Select distinct CustomerName
From Sales.invoices as si
Inner join Sales.Customers as c on c.CustomerID=si.CustomerID
Except 
Select distinct CustomerName
From Sales.Invoices as si
Inner join Sales.Customers as c on c.CustomerID=si.CustomerID
Where InvoiceDate > '2016-01-01'  

--4.	List of Stock Items and total quantity for each stock item in Purchase Orders in Year 2013.

Use WideWorldImporters;
With cte as(
Select pol.StockItemID , sum(Orderedouters) as total_quantity
From Purchasing.PurchaseOrderLines as pol
Join Purchasing.PurchaseOrders as po on po.PurchaseOrderID = pol.PurchaseOrderID and year(OrderDate)=2013 
Group by pol.StockItemID
)
Select cte.StockItemID, si.StockItemName, cte.total_quantity
From cte
Inner join warehouse.StockItems as si on si. StockItemID =cte.StockItemID

--5.	List of stock items that have at least 10 characters in description.
use WideWorldImporters;
Select distinct StockItemName
From Purchasing.PurchaseOrderLines as pol
inner join Warehouse.StockItems as wsi on wsi.StockItemID=pol.StockItemID and len(pol.Description) >=10
;

--6.	List of stock items that are not sold to the state of Alabama and Georgia in 2014.
Select distinct StockItemName
From Sales.Invoices as i
Inner join Sales.InvoiceLines as il on il.InvoiceID=i.invoiceID
Inner join Sales.Customers as c on c. CustomerID= i.CustomerID
Inner join Application.Cities as ac on ac. CityID = c. PostalCityID
Inner join Application.StateProvinces as sp on sp.StateProvinceID= ac. StateProvinceID
inner join Warehouse.StockItems as wsi on wsi.StockItemID=il.StockItemID
Where year(i.InvoiceDate) = 2014 and sp.StateProvinceName not in ('Alabama','Georgia')

--7.	List of States and Avg dates for processing (confirmed delivery date ¨C order date).
Select sp.StateProvinceName as States, avg(DATEDIFF(day, o.OrderDate, i.ConfirmedDeliveryTime))
From Sales.Invoices as i
Inner join Sales.InvoiceLines as il on il.InvoiceID=i.invoiceID
Inner join Sales.Customers as c on c. CustomerID= i.CustomerID
Inner join Application.Cities as ac on ac. CityID = c. PostalCityID
Inner join Application.StateProvinces as sp on sp.StateProvinceID= ac. StateProvinceID
Inner join Sales.Orders as o on o.OrderID = i.OrderID
Group by sp.StateProvinceName

--8.	List of States and Avg dates for processing (confirmed delivery date ¨C order date) by month.
Select sp.StateProvinceName as States,month(o.OrderDate) as Months, avg(DATEDIFF(day, o.OrderDate, i.ConfirmedDeliveryTime)) as avg_day
From Sales.Invoices as i
Inner join Sales.InvoiceLines as il on il.InvoiceID=i.invoiceID
Inner join Sales.Customers as c on c. CustomerID= i.CustomerID
Inner join Application.Cities as ac on ac. CityID = c. PostalCityID
Inner join Application.StateProvinces as sp on sp.StateProvinceID= ac. StateProvinceID
Inner join Sales.Orders as o on o.OrderID = i.OrderID
Group by sp.StateProvinceName, MONTH(o.OrderDate)
Order by sp.StateProvinceName, Months

--9.	List of StockItems that the company purchased more than sold in the year of 2015.
use WideWorldImporters;
with purchase as(
	select StockItemID, sum(OrderedOuters) as purchased
	from Purchasing.PurchaseOrderLines as pol
	inner join Purchasing.PurchaseOrders as ppo on ppo.PurchaseOrderID=pol.PurchaseOrderID and year(OrderDate)=2015
	group by StockItemID),
sold as (
	select StockItemID, sum(Quantity) as sold
	from Sales.InvoiceLines as sol
	inner join Sales.Invoices as si on si.InvoiceID = sol.InvoiceID and YEAR(si.InvoiceDate)=2015
	group by StockItemID)
select purchase.StockItemID from purchase
inner join sold on sold.StockItemID=purchase.StockItemID
where purchased>sold

--10.	List of Customers and their phone number, together with the primary contact person¡¯s name, to whom we did not sell more than 10  mugs (search by name) in the year 2016.
use WideWorldImporters;
with cte as(
	select si.CustomerID, sum(Quantity) as mug_sold
	from Sales.InvoiceLines as sil
	inner join Sales.Invoices as si on si.InvoiceID=sil.InvoiceID and year(InvoiceDate)=2016
	inner join Warehouse.StockItems as wsi on wsi.StockItemID=sil.StockItemID and StockItemName like '%mug%'
	group by si.CustomerID
	having sum(Quantity) <=10
)
select 
	sc.CustomerName,
	sc.PhoneNumber,
	sc2.CustomerName,
	mug_sold
from cte
left join Sales.Customers as sc on sc.CustomerID=cte.CustomerID
left join Sales.Customers as sc2 on sc2. CustomerID=sc.PrimaryContactPersonID

--11.	List all the cities that were updated after 2015-01-01.
select CityName, ValidFrom
from Application.Cities
where ValidFrom > '2015-01-01'

--12.	List all the Order Detail n name, customer phone, quantity) for the date of 2014-07-01. Info should be relevant to that date.
with cte as
( select OrderID, count(StockItemID) as quantity 
from Sales.OrderLines
group by OrderID),

roll as ( 
	select t.OrderID,
		t.quantity,
		stuff((select ', ' + StockItemName
			from Sales.OrderLines as sol
			inner join Warehouse.StockItems as wsi on wsi.StockItemID=sol.StockItemID
			where sol.OrderID=t.OrderID
			for xml path ('')),1,1,'') as items
	from cte as t)
select * from roll
go
-- the difficulty is over here to rollup columns, others just join order tables omitted.

--13.	List of stock item groups uantity sold)
with buy as (
	select StockGroupName, sum(OrderedOuters) as total_buy

	from Purchasing.PurchaseOrderLines as pol
	inner join Warehouse.StockItemStockGroups as sisg on sisg.StockItemID=pol.StockItemID
	inner join Warehouse.StockGroups as wsg on wsg.StockGroupID= sisg.StockGroupID
	group by StockGroupName
),

sell as (
	select StockGroupName, SUM(Quantity) as total_sell
	from Sales.InvoiceLines as sil
	inner join Warehouse.StockItemStockGroups as sisg on sisg.StockItemID=sil.StockItemID
	inner join Warehouse.StockGroups as wsg on wsg.StockGroupID= sisg.StockGroupID
	group by StockGroupName
)

select buy.StockGroupName, total_buy, total_sell, total_buy-total_sell as remain
from buy
inner join sell on sell.StockGroupName=buy.StockGroupName
go

--14.	List of Cities in the US and the stock item 
--## one of the toughest one, require multiple joins and logics 
use WideWorldImporters;
with cte as ( --to get invoice total quantity.
	select InvoiceID, StockItemID, sum(Quantity) as qnt
	from Sales.InvoiceLines
	group by InvoiceID, StockItemID
),

cte2 as ( --to get invoice ship to which city
	select
		si.InvoiceID,
		ac.CityName
	from Sales.Invoices as si
	inner join Sales.Customers as sc on sc.CustomerID= si.CustomerID
	inner join Application.Cities as ac on ac.CityID=sc.PostalCityID
	where year(InvoiceDate)=2016
),

cte3 as( --rank each item amount to each city
	select CityName, StockItemID, sum(qnt) as amt,
		ROW_NUMBER() over(partition by CityName order by sum(qnt) desc) as rnk	
	from cte
	inner join cte2 on cte2.InvoiceID=cte.InvoiceID
	group by CityName, StockItemID
),

cte4 as( -- get the first rank of last cte and get the item name
	select CityName, StockItemName
	from cte3
	inner join Warehouse.StockItems as wsi on wsi.StockItemID=cte3.StockItemID
	where rnk=1)

select ac.CityName, --now i need to get the case when theres no value, and left join city table, and constrain to the US
case when cte4.StockItemName is null then 'No Sales'
	else  cte4.StockItemName end as StockItem
from Application.Cities as ac
inner join Application.StateProvinces as asp on asp.StateProvinceID=ac.StateProvinceID and CountryID=230
left join cte4 on cte4.CityName=ac.CityName
order by ac.CityName
--15.	List any orders that had more than one delivery attempt (located in invoice table).
with cte as (
	select JSON_value(si.ReturnedDeliveryData,'$.Events[1].EventTime') as attemp,
		JSON_VALUE(si.ReturnedDeliveryData,'$.DeliveredWhen') as delivery
	from Sales.Invoices as si
)
select * from cte
where attemp<>delivery
go

--16.	List all stock items that are manufactured in China. (Country of Manufacture)
select StockItemName
from Warehouse.StockItems as wsi
where JSON_value (wsi.CustomFields, '$.CountryOfManufacture') = 'China'
go


--17.	Total quantity of stock items sold in 2015, group by country of manufacturing.
with cte as (
	select StockItemID,StockItemName, JSON_value (wsi.CustomFields, '$.CountryOfManufacture') as country
	from Warehouse.StockItems as wsi
)

select 
	country,
	sum(sil.Quantity) as total_quantity
from Sales.InvoiceLines as sil
left join cte on cte.StockItemID= sil.StockItemID
left join Sales.Invoices as si on si.InvoiceID=sil.InvoiceID and year(InvoiceDate)=2015
group by country
go


--18.	Create a view that shows the
drop view if exists performance2013_2017;
go
create view performance2013_2017 as 
	with cte as(
		select StockGroupName, Quantity, YEAR(InvoiceDate) as yr
		from Sales.InvoiceLines as sil
		inner join Warehouse.StockItemStockGroups as sisg on sisg.StockItemID= sil.StockItemID
		inner join Warehouse.StockGroups as wsg on wsg.StockGroupID=sisg.StockGroupID
		inner join Sales.Invoices as si on si.InvoiceID=sil.InvoiceID
	),
	cte2013 as (
		select StockGroupName, sum(Quantity) as q2013
		from cte where yr=2013
		group by StockGroupName),

	cte2014 as (
		select StockGroupName, sum(Quantity) as q2014
		from cte where yr=2014
		group by StockGroupName),
	cte2015 as (
		select StockGroupName, sum(Quantity) as q2015
		from cte where yr=2015
		group by StockGroupName),
	cte2016 as (
		select StockGroupName, sum(Quantity) as q2016
		from cte where yr=2016
		group by StockGroupName),
	cte2017 as (
		select StockGroupName, sum(Quantity) as q2017
		from cte where yr=2017
		group by StockGroupName)

	select cte2013.StockGroupName, q2013,q2014,q2015, q2016, q2017
	from cte2013
	inner join cte2014 on cte2014.StockGroupName=cte2013.StockGroupName
	inner join cte2015 on cte2015.StockGroupName=cte2013.StockGroupName
	inner join cte2016 on cte2016.StockGroupName=cte2013.StockGroupName
	left join cte2017 on cte2017.StockGroupName=cte2013.StockGroupName
go
select * from performance2013_2017 
order by StockGroupName
go

--19.	Create a view that shows the total quantity  
select *
from performance2013_2017
unpivot (value for year in ([q2013],[q2014],[q2015],[q2016],[q2017])) as up
pivot (max(value) for StockGroupName in ([Toys],[Mugs],[T-Shirts],[Furry Footwear],[Computing Novelties],[Novelty Items],[Clothing],[USB Novelties],[Packaging Materials])) as p
order by [year] ## using pivot and unpivot
go

--20.	Create a function, input: order id; return: total of that order. 
drop function if exists dbo.total;
go
create function total(
	@orderid int)
returns float as 
begin 
	Declare @return_value float;
	select @return_value= sum(Quantity*UnitPrice)
	from Sales.OrderLines
	where OrderID=@orderid
	group by OrderID

	return @return_value
end;

go
select *,dbo.total(Sales.Invoices.OrderID) as OrderTotalAmount
from Sales.Invoicesd
go


--21.	Create a new table called ods.Orders. 
drop table if exists DB_Errors;
CREATE TABLE DB_Errors
         (ErrorID        INT IDENTITY(1, 1),
          UserName       VARCHAR(100),
          ErrorNumber    INT,
          ErrorState     INT,
          ErrorSeverity  INT,
          ErrorLine      INT,
          ErrorProcedure VARCHAR(MAX),
          ErrorMessage   VARCHAR(MAX),
          ErrorDateTime  DATETIME)
GO

--create orders table; unable to create table in ods
drop table if exists dbo.Orders;
go
create table dbo.Orders
		(
		OrderDate date,
		OrderID int,
		CustomerID int,
		total float,
		primary key (OrderDate, OrderID)
		);
go 

--create procedure that enter a date will return an insert to a table.
drop procedure if exists dbo.findyourorder;
go 
create procedure dbo.findyourorder @date Date
as
	begin try
		begin transaction
		insert into dbo.Orders
			select OrderDate, so.OrderID, CustomerID, sum(Quantity*UnitPrice) as total
			from Sales.Orders as so
			inner join Sales.OrderLines as sol on sol.OrderID=so.OrderID
			where OrderDate=@date
			group by OrderDate, so.OrderID, CustomerID
		commit transaction
	end try
	begin catch
		insert into dbo.DB_Errors
		Values
		(SUSER_SNAME(),
	   ERROR_NUMBER(),
	   ERROR_STATE(),
	   ERROR_SEVERITY(),
	   ERROR_LINE(),
	   ERROR_PROCEDURE(),
	   ERROR_MESSAGE(),
	   GETDATE());
-- Transaction uncommittable
    IF (XACT_STATE()) = -1
      ROLLBACK TRANSACTION
 
-- Transaction committable
    IF (XACT_STATE()) = 1
      COMMIT TRANSACTION  
  
  END CATCH
GO
;
--process
exec dbo.findyourorder @date = '2013-03-09'
go
exec dbo.findyourorder @date = '2013-03-09'
go
exec dbo.findyourorder @date = 'haha'
go
exec dbo.findyourorder @date = 2
go
exec dbo.findyourorder @date = '2013-03-12'

select * from dbo.Orders
go


--22.	Create a new table called ods.StockItem. 
drop table if exists ods.StockItem;
create table ods.StockItem (
StockItemID int,
StockItemName nvarchar(100),
SupplierID int, 
ColorID int,
UnitPackageID int,
OuterPackageID int,
Brand nvarchar(50),
Size nvarchar(20),
LeadTimeDays int,
QuantityPerOuter int,
IsChillerStock bit,
Barcode nvarchar(50),
TaxRate decimal(18,3),
UnitPrice decimal(18,2),
RecommendedRetailPrice decimal(18,2),
TypicalWeightPerUnit decimal(18,3),
MarketingComments nvarchar(MAX),
InternalComments nvarchar(MAX),
CountryOfManufature nvarchar(20)
);

insert into ods.StockItem
select StockItemID, StockItemName, SupplierID,ColorID,
	UnitPackageID,OuterPackageID,Brand,Size,LeadTimeDays,QuantityPerOuter,IsChillerStock,
	Barcode,TaxRate,UnitPrice,RecommendedRetailPrice,TypicalWeightPerUnit,MarketingComments,InternalComments,
	JSON_value (wsi.CustomFields, '$.CountryOfManufacture')
from Warehouse.StockItems as wsi;

select * from ods.StockItem
go

--23.	Rewrite your stored procedure in (21). 
alter procedure dbo.findyourorder @date Date
as
	begin try
	declare @date_7 date
		begin transaction
		delete from dbo.Orders
		set @date_7= DATEADD(day,7,@date)
		insert into dbo.Orders
			select OrderDate, so.OrderID, CustomerID, sum(Quantity*UnitPrice) as total
			from Sales.Orders as so
			inner join Sales.OrderLines as sol on sol.OrderID=so.OrderID
			where OrderDate between @date and @date_7
			group by OrderDate, so.OrderID, CustomerID
		commit transaction
	end try
	begin catch
		insert into dbo.DB_Errors
		Values
		(SUSER_SNAME(),
	   ERROR_NUMBER(),
	   ERROR_STATE(),
	   ERROR_SEVERITY(),
	   ERROR_LINE(),
	   ERROR_PROCEDURE(),
	   ERROR_MESSAGE(),
	   GETDATE());
-- Transaction uncommittable
    IF (XACT_STATE()) = -1
      ROLLBACK TRANSACTION
 
-- Transaction committable
    IF (XACT_STATE()) = 1
      COMMIT TRANSACTION  
  
  END CATCH
GO

--24.	Consider the JSON file:
--Looks like that it is our missed purchase orders. Migrate these data into Stock Item, Purchase Order and Purchase Order Lines tables. Of course, save the script.
--##this question going to affect original database so ill leave it for a while, there are some columns missing, and outerpackageID is an array in the first item.
declare @json Nvarchar(Max)= N'
{
   "PurchaseOrders":[
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[
            6,
            7
         ],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-025",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }
   ]
}';

select*
from OPENJSON(@json, '$."PurchaseOrders"')
with (
		StockItemName nvarchar(100) '$.StockItemName',
		SupplierID int '$.Supplier', 
		ColorID int '$.ColorID',
		UnitPackageID int '$.UnitPackageID',
		OuterPackageID int '$.OuterPackageID',
		Brand nvarchar(50) '$.Brand',
		Size nvarchar(20) '$.Size',
		LeadTimeDays int '$.LeadTimeDays',
		QuantityPerOuter int '$.QuantityPerOuter',
		IsChillerStock bit '$.QuantityPerOuter',
		Barcode nvarchar(50) '$.Barcode',
		TaxRate decimal(18,3) '$.TaxRate',
		UnitPrice decimal(18,2) '$.UnitPrice',
		RecommendedRetailPrice decimal(18,2) '$.RecommendedRetailPrice',
		TypicalWeightPerUnit decimal(18,3) '$.TypicalWeightPerUnit',
		MarketingComments nvarchar(MAX) '$.MarketingComments',
		InternalComments nvarchar(MAX) '$.InternalComments',
		CountryOfManufacture nvarchar(20) '$.CountryOfManufacture'
)
--##the difficulty is to open json file, then one should union the information to the other original tables, omitted over here

--25.	Revisit your answer in (19). Convert the result in JSON string and save it to the server using TSQL FOR JSON PATH.
select *
from performance2013_2017
unpivot (value for year in ([q2013],[q2014],[q2015],[q2016],[q2017])) as up
pivot (max(value) for StockGroupName in ([Toys],[Mugs],[T-Shirts],[Furry Footwear],[Computing Novelties],[Novelty Items],[Clothing],[USB Novelties],[Packaging Materials])) as p
order by [year] 
for Json path
go


--26.	Revisit your answer in (19). Convert the result into an XML string and save it to the server using TSQL FOR XML PATH.
select *
from performance2013_2017
unpivot (value for year in ([q2013],[q2014],[q2015],[q2016],[q2017])) as up
pivot (max(value) for StockGroupName in ([Toys],[Mugs],[T-Shirts],[Furry Footwear],[Computing Novelties],[Novelty Items],[Clothing],[USB Novelties],[Packaging Materials])) as p
order by [year] 
for xml auto;
--##for xml path name rule is strict, doesn¡¯t allow space, so I used xml auto instead of path. Omitted renaming process.
