SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_getHashIata3] 
(
	@iata3Hash int
)
RETURNS varchar(3)
AS
BEGIN
	-- Converts hash sum of the iata3 code into an actual iata3 code using alphabet mapping.

	DECLARE @iata3 varchar(3)

	DECLARE @alphabet TABLE (
	num INT,
	letter VARCHAR(1)
	)
	INSERT INTO @alphabet VALUES (0,'A'),(1,'B'),(2,'C'),(3,'D'),(4,'E'),(5,'F'),(6,'G'),(7,'H'),(8,'I'),(9,'J'),(10,'K'),(11,'L'),(12,'M'),(13,'N'),(14,'O'),(15,'P'),(16,'Q'),(17,'R'),(18,'S'),(19,'T'),(20,'U'),(21,'V'),(22,'W'),(23,'X'),(24,'Y'),(25,'Z')
	declare @iata3hashstring varchar(20) = CAST(@iata3hash AS VARCHAR(20))
	DECLARE @letter1Hash varchar(3) = SUBSTRING(@iata3hashstring,1,3)
	DECLARE @letter2Hash varchar(3) = SUBSTRING(@iata3hashString,4,3)
	DECLARE @letter3Hash varchar(3) = SUBSTRING(@iata3hashString,7,3)

	DECLARE @letter1 VARCHAR(1) = (SELECT letter FROM @alphabet T WHERE T.num = CAST(@letter1Hash AS INT)-100)
	DECLARE @letter2 VARCHAR(1) = (SELECT letter FROM @alphabet T WHERE T.num = CAST(@letter2Hash AS INT)-100)
	DECLARE @letter3 VARCHAR(1) = (SELECT letter FROM @alphabet T WHERE T.num = CAST(@letter3Hash AS INT)-100)

	SET @iata3 = @letter1+@letter2+@letter3

	RETURN @iata3

END

GO
/****** Object:  UserDefinedFunction [dbo].[fn_getShortestPath0Stops]    Script Date: 7/20/2019 4:52:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_getShortestPath0Stops] 
(

	@OriginIata3 VARCHAR(3), @DestinationIata3 VARCHAR(3)
)
RETURNS VARCHAR(256)
AS
BEGIN
	DECLARE @directpath VARCHAR(256) = ''
	DECLARE @originHash int = dbo.fn_getIata3Hash(@OriginIata3)
	DECLARE @destinationHash int = dbo.fn_getIata3Hash(@DestinationIata3)


	SET @directpath = (SELECT dbo.fn_getHashIata3(T.r_originHash) + ' -> ' + dbo.fn_getHashIata3(T.r_destinationHash) FROM (SELECT TOP 1 R.r_originHash , R.r_destinationHash FROM Routes R (NOLOCK) WHERE R.r_originHash = @originHash and R.r_destinationHash = @destinationHash) T)

	RETURN @directPath

END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_getShortestPath1Stops]    Script Date: 7/20/2019 4:52:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_getShortestPath1Stops] 
(

	@OriginIata3 VARCHAR(3), @DestinationIata3 VARCHAR(3)
)
RETURNS VARCHAR(256)
AS
BEGIN
	DECLARE @directpath VARCHAR(256) = ''
	DECLARE @originHash INT = dbo.fn_getIata3Hash(@OriginIata3)
	DECLARE @destinationHash INT = dbo.fn_getIata3Hash(@DestinationIata3)

	SET @directpath = (
	SELECT dbo.fn_getHashIata3(S0o) + ' -> ' + dbo.fn_getHashIata3(S1o) + ' -> ' + dbo.fn_getHashIata3(S1d) FROM (
		SELECT TOP 1 
					S0.r_originHash S0o, S1.r_originHash S1o, S1.r_destinationHash S1d 
		FROM Routes S0 (NOLOCK)
		LEFT OUTER JOIN Routes S1 (NOLOCK) ON 
					S0.r_destinationHash = S1.r_originHash 
					AND NOT S0.r_originHash = S1.r_destinationHash
		WHERE
			S0.r_originHash = @originHash 
			AND S1.r_destinationHash = @destinationHash
	) T)

	RETURN @directPath

END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_getShortestPath2Stops]    Script Date: 7/20/2019 4:52:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_getShortestPath2Stops] 
(

	@OriginIata3 VARCHAR(3), @DestinationIata3 VARCHAR(3)
)
RETURNS VARCHAR(256)
AS
BEGIN
	DECLARE @directpath VARCHAR(256) = ''
	DECLARE @originHash int = dbo.fn_getIata3Hash(@OriginIata3)
	DECLARE @destinationHash int = dbo.fn_getIata3Hash(@DestinationIata3)

	DECLARE @result TABLE(
		result VARCHAR(256)
	)

	INSERT INTO @result

	SELECT 
		dbo.fn_getHashIata3(S0o) + ' -> ' + 
		dbo.fn_getHashIata3(S1o) + ' -> ' + 
		dbo.fn_getHashIata3(S2o) + ' -> ' + 
		dbo.fn_getHashIata3(S2d) 
	FROM (
		SELECT TOP 1 
					S0.r_originHash S0o, S1.r_originHash S1o, S2.r_originHash S2o, S2.r_destinationHash S2d 
		FROM Routes S0 (NOLOCK)
		LEFT OUTER JOIN Routes S1 (NOLOCK) ON 
					S0.r_destinationHash = S1.r_originHash 
					AND NOT S0.r_originHash = S1.r_destinationHash -- do not go to the original airport
		LEFT OUTER JOIN Routes S2 (NOLOCK) ON 
					S1.r_destinationHash = S2.r_originHash 
					AND NOT S1.r_originHash = S2.r_destinationHash -- do not go to the previous transit airport

		WHERE
			S0.r_originHash = @originHash 
			AND S2.r_destinationHash = @destinationHash
	) T
	OPTION(FORCE ORDER)



	SET @directpath = (SELECT TOP 1 T.result FROM @result T)

	RETURN @directPath

END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_getShortestPath3Stops]    Script Date: 7/20/2019 4:52:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_getShortestPath3Stops] 
(
	@OriginIata3 VARCHAR(3), @DestinationIata3 VARCHAR(3)
)
RETURNS VARCHAR(256)
AS
BEGIN
	DECLARE @directpath VARCHAR(256) = ''
	DECLARE @originHash int = dbo.fn_getIata3Hash(@OriginIata3)
	DECLARE @destinationHash int = dbo.fn_getIata3Hash(@DestinationIata3)
	
	DECLARE @result TABLE(
		result VARCHAR(256)
	)

	INSERT INTO @result
	SELECT 
			dbo.fn_getHashIata3(S0o) + ' ->' + 
			dbo.fn_getHashIata3(S1o) + ' ->' + 
			dbo.fn_getHashIata3(S2o) + ' ->' + 
			dbo.fn_getHashIata3(S3o) + ' ->' + 
			dbo.fn_getHashIata3(S3d) 
	FROM (
		SELECT TOP 1 
					S0.r_originHash S0o, S1.r_originHash S1o, S2.r_originHash S2o, S3.r_originHash S3o, S3.r_destinationHash S3d 
		FROM Routes S0
		LEFT OUTER JOIN Routes S1 (NOLOCK) ON 
					S0.r_destinationHash = S1.r_originHash 
					AND NOT S0.r_originHash = S1.r_destinationHash -- do not go to the original airport
		LEFT OUTER JOIN Routes S2 (NOLOCK) ON 
					S1.r_destinationHash = S2.r_originHash 
					AND NOT S1.r_originHash = S2.r_destinationHash -- do not go to the previous transit airport
		LEFT OUTER JOIN Routes S3 (NOLOCK) ON 
					S2.r_destinationHash = S3.r_originHash 
					-- do not go to the previous transit airports
					AND NOT S1.r_originHash = S3.r_destinationHash 
					AND NOT S2.r_originHash = S3.r_destinationHash

		WHERE
			S0.r_originHash = @originHash 
			AND S3.r_destinationHash = @destinationHash
	) T
	OPTION(FORCE ORDER)

	SET @directpath = (SELECT TOP 1 T.result FROM @result T)

	RETURN @directPath

END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_getShortestPath4Stops]    Script Date: 7/20/2019 4:52:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_getShortestPath4Stops] 
(
	@OriginIata3 VARCHAR(3), @DestinationIata3 VARCHAR(3)
)
RETURNS VARCHAR(256)
AS
BEGIN
	DECLARE @directpath VARCHAR(256) = ''
	DECLARE @originHash int = dbo.fn_getIata3Hash(@OriginIata3)
	DECLARE @destinationHash int = dbo.fn_getIata3Hash(@DestinationIata3)
	DECLARE @result TABLE(
		result VARCHAR(256)
	)

	INSERT INTO @result
	SELECT 
			dbo.fn_getHashIata3(S0o) + ' -> ' + 
			dbo.fn_getHashIata3(S1o) + ' -> ' + 
			dbo.fn_getHashIata3(S2o) + ' -> ' +  
			dbo.fn_getHashIata3(S3o) + ' -> ' +  
			dbo.fn_getHashIata3(S4o) + ' -> ' +  
			dbo.fn_getHashIata3(S4d)
	FROM (
		SELECT TOP 1 
					S0.r_originHash S0o, S1.r_originHash S1o, S2.r_originHash S2o, S3.r_originHash S3o, S4.r_originHash S4o, S4.r_destinationHash S4d 
		FROM Routes S0 (NOLOCK)
		LEFT OUTER JOIN Routes S1 (NOLOCK) ON 
					S0.r_destinationHash = S1.r_originHash 
					AND NOT S0.r_originHash = S1.r_destinationHash -- do not go to the original airport
		LEFT OUTER JOIN Routes S2 (NOLOCK) ON 
					S1.r_destinationHash = S2.r_originHash 
					AND NOT S1.r_originHash = S2.r_destinationHash -- do not go to the previous transit airport
		LEFT OUTER JOIN Routes S3 (NOLOCK) ON 
					S2.r_destinationHash = S3.r_originHash 
					-- do not go to the previous transit airport
					AND NOT S1.r_originHash = S3.r_destinationHash
					AND NOT S2.r_originHash = S3.r_destinationHash
		LEFT OUTER JOIN Routes S4 (NOLOCK) ON 
					S3.r_destinationHash = S4.r_originHash 
					-- do not go to the previous transit airport
					AND NOT S1.r_originHash = S4.r_destinationHash
					AND NOT S2.r_originHash = S4.r_destinationHash
					AND NOT S3.r_originHash = S4.r_destinationHash 

		WHERE
			S0.r_originHash = @originHash 
			AND S4.r_destinationHash = @destinationHash
	) T
	OPTION(FORCE ORDER)

	SET @directpath = (SELECT TOP 1 T.result FROM @result T)

	RETURN @directPath

END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_getShortestPath5Stops]    Script Date: 7/20/2019 4:52:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_getShortestPath5Stops] 
(
	@OriginIata3 VARCHAR(3), @DestinationIata3 VARCHAR(3)
)
RETURNS VARCHAR(256)
AS
BEGIN
	DECLARE @directpath VARCHAR(256) = ''
	DECLARE @originHash int = dbo.fn_getIata3Hash(@OriginIata3)
	DECLARE @destinationHash int = dbo.fn_getIata3Hash(@DestinationIata3)

	DECLARE @result TABLE(
		result VARCHAR(256)
	)

	INSERT INTO @result
	SELECT 
			dbo.fn_getHashIata3(S0o) + ' -> ' + 
			dbo.fn_getHashIata3(S1o) + ' -> ' + 
			dbo.fn_getHashIata3(S2o) + ' -> ' +  
			dbo.fn_getHashIata3(S3o) + ' -> ' +  
			dbo.fn_getHashIata3(S4o) + ' -> ' +  
			dbo.fn_getHashIata3(S4o) + ' -> ' +  
			dbo.fn_getHashIata3(S5d)
	FROM (
		SELECT TOP 1 
					S0.r_originHash S0o, S1.r_originHash S1o, S2.r_originHash S2o, S3.r_originHash S3o, S4.r_originHash S4o, S5.r_originHash S5o, S5.r_destinationHash S5d 
		FROM Routes S0 (NOLOCK)
		LEFT OUTER JOIN Routes S1 (NOLOCK) ON 
					S0.r_destinationHash = S1.r_originHash 
					AND NOT S0.r_originHash = S1.r_destinationHash -- do not go to the original airport
		LEFT OUTER JOIN Routes S2 (NOLOCK) ON 
					S1.r_destinationHash = S2.r_originHash 
					AND NOT S1.r_originHash = S2.r_destinationHash -- do not go to the previous transit airport
		LEFT OUTER JOIN Routes S3 (NOLOCK) ON 
					S2.r_destinationHash = S3.r_originHash 
					-- do not go to the previous transit airport
					AND NOT S1.r_originHash = S3.r_destinationHash
					AND NOT S2.r_originHash = S3.r_destinationHash
		LEFT OUTER JOIN Routes S4 (NOLOCK) ON 
					S3.r_destinationHash = S4.r_originHash 
					-- do not go to the previous transit airport
					AND NOT S1.r_originHash = S4.r_destinationHash
					AND NOT S2.r_originHash = S4.r_destinationHash
					AND NOT S3.r_originHash = S4.r_destinationHash 
		LEFT OUTER JOIN Routes S5 (NOLOCK) ON 
					S4.r_destinationHash = S5.r_originHash 
					-- do not go to the previous transit airport
					AND NOT S1.r_originHash = S5.r_destinationHash
					AND NOT S2.r_originHash = S5.r_destinationHash
					AND NOT S3.r_originHash = S5.r_destinationHash
					AND NOT S4.r_originHash = S5.r_destinationHash 

		WHERE
			S0.r_originHash = @originHash 
			AND S5.r_destinationHash = @destinationHash
	) T
	OPTION(FORCE ORDER)

	SET @directpath = (SELECT TOP 1 T.result from @result T)

	RETURN @directPath

END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_getShortestPath6Stops]    Script Date: 7/20/2019 4:52:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_getShortestPath6Stops] 
(
	@OriginIata3 VARCHAR(3), @DestinationIata3 VARCHAR(3)
)
RETURNS VARCHAR(256)
AS
BEGIN
	DECLARE @directpath VARCHAR(256) = ''
	DECLARE @originHash int = dbo.fn_getIata3Hash(@OriginIata3)
	DECLARE @destinationHash int = dbo.fn_getIata3Hash(@DestinationIata3)
	DECLARE @result TABLE(
		result VARCHAR(256)
	)

	INSERT INTO @result
	SELECT 
			dbo.fn_getHashIata3(S0o) + ' -> ' + 
			dbo.fn_getHashIata3(S1o) + ' -> ' + 
			dbo.fn_getHashIata3(S2o) + ' -> ' + 
			dbo.fn_getHashIata3(S3o) + ' -> ' + 
			dbo.fn_getHashIata3(S4o) + ' -> ' + 
			dbo.fn_getHashIata3(S5o) + ' -> ' + 
			dbo.fn_getHashIata3(S6o) + ' -> ' + 
			dbo.fn_getHashIata3(S6d) 
	FROM (
		SELECT TOP 1 
					S0.r_originHash S0o, S1.r_originHash S1o, S2.r_originHash S2o, S3.r_originHash S3o, S4.r_originHash S4o, S5.r_originHash S5o, S6.r_originHash S6o, S6.r_destinationHash S6d 
		FROM Routes S0 (NOLOCK)
		LEFT OUTER JOIN Routes S1 (NOLOCK) ON 
					S0.r_destinationHash = S1.r_originHash 
					AND NOT S0.r_originHash = S1.r_destinationHash -- do not go to the original airport
		LEFT OUTER JOIN Routes S2 (NOLOCK) ON 
					S1.r_destinationHash = S2.r_originHash 
					-- do not go to the previous transit airport
					AND NOT S1.r_originHash = S2.r_destinationHash 
		LEFT OUTER JOIN Routes S3 (NOLOCK) ON 
					S2.r_destinationHash = S3.r_originHash 
					-- do not go to the previous transit airports
					AND NOT S1.r_originHash = S3.r_destinationHash 
					AND NOT S2.r_originHash = S3.r_destinationHash 
		LEFT OUTER JOIN Routes S4 (NOLOCK) ON 
					S3.r_destinationHash = S4.r_originHash 
					-- do not go to the previous transit airports
					AND NOT S1.r_originHash = S4.r_destinationHash 
					AND NOT S2.r_originHash = S4.r_destinationHash 
					AND NOT S3.r_originHash = S4.r_destinationHash 
		LEFT OUTER JOIN Routes S5 (NOLOCK) ON 
					S4.r_destinationHash = S5.r_originHash
					-- do not go to the previous transit airports
					AND NOT S1.r_originHash = S5.r_destinationHash 
					AND NOT S2.r_originHash = S5.r_destinationHash 					
					AND NOT S3.r_originHash = S5.r_destinationHash 
					AND NOT S4.r_originHash = S5.r_destinationHash 
		LEFT OUTER JOIN Routes S6 (NOLOCK) ON 
					S5.r_destinationHash = S6.r_originHash 
					-- do not go to the previous transit airports
					AND NOT S1.r_originHash = S6.r_destinationHash 
					AND NOT S2.r_originHash = S6.r_destinationHash 
					AND NOT S3.r_originHash = S6.r_destinationHash 
					AND NOT S4.r_originHash = S6.r_destinationHash 
					AND NOT S5.r_originHash = S6.r_destinationHash 
		WHERE
			S0.r_originHash = @originHash 
			AND S6.r_destinationHash = @destinationHash
	) T 
	OPTION(FORCE ORDER)

	SET @directpath = ( SELECT TOP 1 T.result FROM @result T)

	RETURN @directPath

END
GO
/****** Object:  StoredProcedure [dbo].[sp_getShortestRoute]    Script Date: 7/20/2019 4:52:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_getShortestRoute] 
	@iata3CodeOrigin varchar(3)
	, @iata3CodeDestination varchar(3)
AS
BEGIN
	SET NOCOUNT ON;
	
	-- Check if the origin and destination codes are valid:
	DECLARE @count INT = (SELECT TOP 1 1 FROM Airports A WHERE A.a_iata3 = @iata3CodeOrigin)

	IF @count IS NULL
	BEGIN
		SELECT CAST('Invalid Origin' AS VARCHAR(256))  AS 'Response'
		RETURN
	END

	SET @count = (SELECT TOP 1 1 FROM Airports A WHERE A.a_iata3 = @iata3CodeDestination)

	IF @count IS NULL
	BEGIN
		SELECT CAST('Invalid Destination' AS NVARCHAR(256))  AS 'Response'
		RETURN
	END

	IF @iata3CodeOrigin = @iata3CodeDestination
	BEGIN
		SELECT CAST('Destination Reached' AS VARCHAR(256)) AS 'Response'
		RETURN
	END

	-- Start from calling the lightest statement to find the direct flight.
	DECLARE @path VARCHAR(256) = dbo.fn_getShortestPath0Stops(@iata3CodeOrigin, @iata3CodeDestination)
	IF @path IS NOT NULL
	BEGIN
		SELECT @path AS 'Response'
		RETURN
	END

	-- If direct flight was not found, look for longer flights gradually.
	SET @path = dbo.fn_getShortestPath1Stops(@iata3CodeOrigin, @iata3CodeDestination)
	IF @path IS NOT NULL
	BEGIN
		SELECT @path AS 'Response'
		RETURN
	END

	SET @path = dbo.fn_getShortestPath2Stops(@iata3CodeOrigin, @iata3CodeDestination)
	IF @path IS NOT NULL
	BEGIN
		SELECT @path AS 'Response'
		RETURN
	END

	SET @path = dbo.fn_getShortestPath3Stops(@iata3CodeOrigin, @iata3CodeDestination)
	IF @path IS NOT NULL
	BEGIN
		SELECT @path AS 'Response'
		RETURN
	END

	SET @path = dbo.fn_getShortestPath4Stops(@iata3CodeOrigin, @iata3CodeDestination)
	IF @path IS NOT NULL
	BEGIN
		SELECT @path AS 'Response'
		RETURN
	END

	SET @path = dbo.fn_getShortestPath5Stops(@iata3CodeOrigin, @iata3CodeDestination)
	IF @path IS NOT NULL
	BEGIN
		SELECT @path AS 'Response'
		RETURN
	END

	SET @path = dbo.fn_getShortestPath6Stops(@iata3CodeOrigin, @iata3CodeDestination)
	IF @path IS NOT NULL
	BEGIN
		SELECT @path AS 'Response'
		RETURN
	END
	ELSE
	BEGIN
		SELECT CAST('No Route' AS NVARCHAr(256)) AS 'Response'
		RETURN
	END

	SELECT 'Unknown response' AS 'Response'
END
GO
