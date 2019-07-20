SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_getIata3Hash] 
(
	@iata3 varchar(3)
)
RETURNS int
AS
BEGIN
	-- Creates hash sum of the iata3 code as a consecutive number of the letter plus 100, concatenated into a single string and converted to an Integer.

	DECLARE @iata3hash int = 0

	DECLARE @alphabet TABLE (
	num INT,
	letter VARCHAR(1)
	)
	INSERT INTO @alphabet VALUES (0,'A'),(1,'B'),(2,'C'),(3,'D'),(4,'E'),(5,'F'),(6,'G'),(7,'H'),(8,'I'),(9,'J'),(10,'K'),(11,'L'),(12,'M'),(13,'N'),(14,'O'),(15,'P'),(16,'Q'),(17,'R'),(18,'S'),(19,'T'),(20,'U'),(21,'V'),(22,'W'),(23,'X'),(24,'Y'),(25,'Z')

	DECLARE @counter INT = 1
	DECLARE @currentLetter VARCHAR(1) = ''
	DECLARE @code VARCHAR(50) = ''

	WHILE @counter < 4
	BEGIN
		SET @currentLetter = SUBSTRING(@iata3,@counter,1)
		SET @code = @code + CAST((SELECT T.num + 100 FROM @alphabet T WHERE T.letter = @currentLetter) AS VARCHAr(20))	

		SET @counter = @counter + 1
	END
	SET @iata3hash = CAST(@code AS INTEGER)

	RETURN @iata3hash

END
GO

-- ###############################
-- ############ STAGING ##########
-- ###############################


-- Load Routes
CREATE TABLE [Routes](
	r_airlineID NVARCHAR(10),
	r_origin VARCHAR(3),
	r_destination VARCHAR(3)
)

BULK INSERT [Routes]
    FROM 'D:\routes.csv'
    WITH
    (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',  --CSV field delimiter
    ROWTERMINATOR = '\n',   --Use to shift the control to next row
    ERRORFILE = 'd:\routesErrorRows.csv',
    TABLOCK
    )
	GO

	-- Remove "AirlineID column for performance and delete duplicates.
ALTER TABLE [dbo].[Routes] DROP COLUMN [r_airlineID]
GO
SELECT DISTINCT * INTO Routes_tmp from Routes
GO
DROP TABLE Routes
GO
SELECT * INTO Routes from Routes_tmp
GO
DROP TABLE Routes_tmp
GO
-- Add hash columns for both origin and destination.
ALTER TABLE Routes
ADD r_originHash int
GO
ALTER TABLE Routes
add r_destinationHash int
GO
-- Set hash values
UPDATE T
	SET T.r_originHash = dbo.fn_getIata3Hash(T.r_origin), T.r_destinationHash = dbo.fn_getIata3Hash(T.r_destination)
FROM Routes t 
GO

-- Create unique index on Routes
CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20190720-114016] ON [dbo].[Routes]
(
	[r_originHash] ASC,
	[r_destinationHash] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO







-- Load Airports
create table Airports
(
	a_airportname nvarchar(255),
	a_airportcity nvarchar(255),
	a_airportcountry nvarchar(255),
	a_iata3 varchar(3),
	a_latitude decimal(9,6),
	a_longitude decimal(9,6)
)
GO
	
BULK INSERT [airports]
    FROM 'D:\airports-preprocessed.csv'
    WITH
    (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',  --CSV field delimiter
    ROWTERMINATOR = '\n',   --Use to shift the control to next row
    ERRORFILE = 'd:\airportsErrorRows.csv',
    TABLOCK
    )
	GO
	update T
		SET t.a_airportname = replace(T.a_airportname, '#',',')
	from Airports t where T.a_airportname like '%#%'
	update T
		SET t.a_airportname = replace(T.a_airportname, '"','')
	from Airports t where T.a_airportname like '%"%'
	update T
		SET t.a_airportcity = replace(T.a_airportcity, '#',',')
	from Airports t where T.a_airportcity like '%#%'
	update T
		SET t.a_airportcity = replace(T.a_airportcity, '"','')
	from Airports t where T.a_airportcity like '%"%'


	/****** Object:  Index [NonClusteredIndex-20190720-143248]    Script Date: 7/20/2019 4:29:15 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20190720-143248] ON [dbo].[Airports]
(
	[a_iata3] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO









