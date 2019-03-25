CREATE TABLE [dbo].[Locations] (
[LocationID] int NOT NULL,
[Intersection] nvarchar(255) NOT NULL,
[TrafficClass] nvarchar(255),
[Latitude] float,
[Longitude] float,
PRIMARY KEY ([LocationID])
)

CREATE TABLE [dbo].[Counts] (
[LocationID] int NOT NULL FOREIGN KEY REFERENCES dbo.Locations(LocationID),
[Volunteer] nvarchar(255),
[Date] datetime NOT NULL,
[Weather] nvarchar(255),
[TimePeriod] nvarchar(255),
[NorthBoundLeft] float,
[NorthBoundRight] float,
[NorthBoundThrough] float,
[SouthBoundLeft] float,
[SouthBoundRight] float,
[SouthBoundThrough] float,
[EastBoundLeft] float,
[EastBoundRight] float,
[EastBoundThrough] float,
[WestBoundLeft] float,
[WestBoundRight] float,
[WestBoundThrough] float,
[HelmetMale] float,
[HelmetFemale] float,
[NoHelmetMale] float,
[NoHelmetFemale] float,
PRIMARY KEY ([LocationID], [Date])
)

CREATE TABLE [dbo].[Survey] (
[DateTime] datetime NOT NULL,
[VolunteerName] nvarchar(255) NOT NULL,
[LocationName] nvarchar(255) NOT NULL,
[TripPurpose] nvarchar(255),
[TripOrigin] nvarchar(255),
[TripDestination] nvarchar(255),
[BicycleFrequency] nvarchar(255),
PRIMARY KEY ([DateTime], [VolunteerName], [LocationName])
)

INSERT INTO dbo.Survey
VALUES ('20150416', 'Someone', 'A park', 'a', 'b', 'c', 'd');