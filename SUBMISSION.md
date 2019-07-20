1. The solution is oriented for performance. I've assumed that there will be no frequent updates in the airport/routes list (not every few minutes).
A call to the interfacing stored procedure takes on average less than 10 milliseconds for any number of stops, inlcuding "No Route" response on my laptop.  
	All reads are dirty for performance. It is possible to adjust the solution for frequently updated routes list.  
	a. If there is no route between two airports with maximum 6 tops, the API decides that there is no route. 
		It is possible to add further search capability for more stops.

2. The solution uses SQL server. The following are the steps to create the database and ingest required data. 
		I also provided backup TestDB_ShortestRoute.bak (MS SQL 2016) for your convenience with everything required.
		Please follow thsese steps if restoring the backup is not an option.
	a. Please create an empty database. Allow 20MB of space for full test data.
	b. Copy files airports-preporcessed.csv and routes.csv on D drive. 
		I had to preprocess original Airports.csv file to handle comma separators inside the column values.
		I probably could create a robust SQL script to ingest original airports.csv file, but focused on the algorithm instead.
	b. Run 01 - Staging.sql scripts to create two tables and load airport and route data into them.
	b. Run scripts 01 - Functionality.sql. The script will create all required 

3. To run the API just open the .NET solution and run (GetShortestRoute.zip). The following is the sample reuest: http://localhost:[port]/route/origin/YYZ/destination/JFK
	a. The solution uses connection string to the MS SQl server instance installe locally and using user name/password "newuser". 
	Please adjust these as required.

4. I'm available at idolinin@gmail.com / 416-841-1694. Ivan Dolinin