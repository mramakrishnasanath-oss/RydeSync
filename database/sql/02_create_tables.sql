-- ============================================================================
-- SCRIPT 02: DDL TABLE DEFINITIONS & CONSTRAINTS
-- System: RideSync (UrbanGo Mobility)
-- Database: RideSyncDB
-- Technology: Microsoft SQL Server 2025 (v17)
-- Author: Senior Database Architect
-- Date: 2026-11-17
-- Description: Creates all six core relational tables in correct dependency order,
--              enforcing Primary Keys, Foreign Keys, Unique constraints, 
--              Check constraints, Defaults, and performance Indexes.
-- ============================================================================

USE RideSyncDB;
GO

-- ============================================================================
-- TABLE 1: Riders (Entity 1: Rider)
-- Description: Master repository of passenger accounts using UrbanGo Mobility.
-- ============================================================================
IF OBJECT_ID(N'dbo.Riders', N'U') IS NULL
BEGIN
    PRINT 'Creating table: dbo.Riders...';
    CREATE TABLE dbo.Riders (
        RiderID         INT IDENTITY(1,1)   NOT NULL,
        FirstName       NVARCHAR(50)        NOT NULL,
        LastName        NVARCHAR(50)        NOT NULL,
        Phone           VARCHAR(15)         NOT NULL,
        CreatedAt       DATETIME2(3)        NOT NULL CONSTRAINT DF_Riders_CreatedAt DEFAULT SYSUTCDATETIME(),

        -- Primary Key
        CONSTRAINT PK_Riders PRIMARY KEY CLUSTERED (RiderID),

        -- Unique phone constraint (one account per phone number)
        CONSTRAINT UQ_Riders_Phone UNIQUE NONCLUSTERED (Phone),

        -- Phone format validation constraint (E.164 international format or 10-15 digits)
        CONSTRAINT CK_Riders_Phone CHECK (LEN(Phone) >= 10 AND Phone NOT LIKE '%[^0-9+]%')
    );
    PRINT 'Table dbo.Riders created successfully.';
END
ELSE
    PRINT 'Table dbo.Riders already exists.';
GO

-- ============================================================================
-- TABLE 2: Vehicles (Entity 3: Vehicle)
-- Description: Master fleet repository of verified automobiles.
-- Created before Drivers because Drivers references Vehicles via VehicleID.
-- ============================================================================
IF OBJECT_ID(N'dbo.Vehicles', N'U') IS NULL
BEGIN
    PRINT 'Creating table: dbo.Vehicles...';
    CREATE TABLE dbo.Vehicles (
        VehicleID       INT IDENTITY(1,1)   NOT NULL,
        PlateNumber     VARCHAR(20)         NOT NULL,
        Model           NVARCHAR(50)        NOT NULL,
        RegisteredAt    DATETIME2(3)        NOT NULL CONSTRAINT DF_Vehicles_RegisteredAt DEFAULT SYSUTCDATETIME(),

        -- Primary Key
        CONSTRAINT PK_Vehicles PRIMARY KEY CLUSTERED (VehicleID),

        -- Unique license plate constraint (prevents duplicate vehicle entries)
        CONSTRAINT UQ_Vehicles_PlateNumber UNIQUE NONCLUSTERED (PlateNumber)
    );
    PRINT 'Table dbo.Vehicles created successfully.';
END
ELSE
    PRINT 'Table dbo.Vehicles already exists.';
GO

-- ============================================================================
-- TABLE 3: Drivers (Entity 2: Driver)
-- Description: Master repository of service drivers and their operational status.
-- References Vehicles via VehicleID (1:0..1 Optional relationship).
-- ============================================================================
IF OBJECT_ID(N'dbo.Drivers', N'U') IS NULL
BEGIN
    PRINT 'Creating table: dbo.Drivers...';
    CREATE TABLE dbo.Drivers (
        DriverID        INT IDENTITY(1,1)   NOT NULL,
        FirstName       NVARCHAR(50)        NOT NULL,
        LastName        NVARCHAR(50)        NOT NULL,
        VehicleID       INT                 NULL,
        Status          VARCHAR(20)         NOT NULL CONSTRAINT DF_Drivers_Status DEFAULT 'OFFLINE',
        RegisteredAt    DATETIME2(3)        NOT NULL CONSTRAINT DF_Drivers_RegisteredAt DEFAULT SYSUTCDATETIME(),

        -- Primary Key
        CONSTRAINT PK_Drivers PRIMARY KEY CLUSTERED (DriverID),

        -- Foreign Key: References Vehicle table
        CONSTRAINT FK_Drivers_Vehicles FOREIGN KEY (VehicleID) 
            REFERENCES dbo.Vehicles(VehicleID)
            ON DELETE SET NULL
            ON UPDATE CASCADE,

        -- Unique constraint on VehicleID: Ensures a vehicle is assigned to AT MOST ONE driver
        CONSTRAINT UQ_Drivers_VehicleID UNIQUE NONCLUSTERED (VehicleID),

        -- Domain CHECK constraint for operational status values
        CONSTRAINT CK_Drivers_Status CHECK (Status IN ('OFFLINE', 'ONLINE', 'ON_TRIP', 'SUSPENDED'))
    );
    PRINT 'Table dbo.Drivers created successfully.';
END
ELSE
    PRINT 'Table dbo.Drivers already exists.';
GO

-- Index for searching available drivers by status
IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N'IX_Drivers_Status')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Drivers_Status ON dbo.Drivers (Status) INCLUDE (VehicleID, FirstName, LastName);
    PRINT 'Index IX_Drivers_Status created.';
END
GO

-- ============================================================================
-- TABLE 4: LocationPings (Entity 4: LocationPing)
-- Description: High-volume time-series telemetry representing continuous GPS
--              breadcrumbs emitted every 2-3 seconds by active drivers.
-- ============================================================================
IF OBJECT_ID(N'dbo.LocationPings', N'U') IS NULL
BEGIN
    PRINT 'Creating table: dbo.LocationPings...';
    CREATE TABLE dbo.LocationPings (
        PingID          BIGINT IDENTITY(1,1) NOT NULL,
        DriverID        INT                  NOT NULL,
        Latitude        DECIMAL(9,6)         NOT NULL,
        Longitude       DECIMAL(9,6)         NOT NULL,
        RecordedAt      DATETIME2(3)         NOT NULL CONSTRAINT DF_LocationPings_RecordedAt DEFAULT SYSUTCDATETIME(),

        -- Primary Key (BIGINT to support millions of high-frequency pings)
        CONSTRAINT PK_LocationPings PRIMARY KEY CLUSTERED (PingID),

        -- Foreign Key: References Driver
        CONSTRAINT FK_LocationPings_Drivers FOREIGN KEY (DriverID)
            REFERENCES dbo.Drivers(DriverID)
            ON DELETE CASCADE
            ON UPDATE CASCADE,

        -- Domain CHECK constraints for valid global geographic coordinates
        CONSTRAINT CK_LocationPings_Latitude CHECK (Latitude BETWEEN -90.000000 AND 90.000000),
        CONSTRAINT CK_LocationPings_Longitude CHECK (Longitude BETWEEN -180.000000 AND 180.000000)
    );
    PRINT 'Table dbo.LocationPings created successfully.';
END
ELSE
    PRINT 'Table dbo.LocationPings already exists.';
GO

-- Composite Index for fast driver trajectory lookup and latest location retrieval
IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N'IX_LocationPings_Driver_Time')
BEGIN
    CREATE NONCLUSTERED INDEX IX_LocationPings_Driver_Time 
    ON dbo.LocationPings (DriverID, RecordedAt DESC) 
    INCLUDE (Latitude, Longitude);
    PRINT 'Index IX_LocationPings_Driver_Time created.';
END
GO

-- ============================================================================
-- TABLE 5: Trips (Entity 5: Trip)
-- Description: Core ride-hailing contract tracking lifecycle from request to completion.
-- ============================================================================
IF OBJECT_ID(N'dbo.Trips', N'U') IS NULL
BEGIN
    PRINT 'Creating table: dbo.Trips...';
    CREATE TABLE dbo.Trips (
        TripID          INT IDENTITY(1,1)   NOT NULL,
        RiderID         INT                 NOT NULL,
        DriverID        INT                 NULL, -- Nullable until matched with a driver
        RequestedAt     DATETIME2(3)        NOT NULL CONSTRAINT DF_Trips_RequestedAt DEFAULT SYSUTCDATETIME(),
        MatchedAt       DATETIME2(3)        NULL, -- Populated atomically upon driver dispatch
        Status          VARCHAR(20)         NOT NULL CONSTRAINT DF_Trips_Status DEFAULT 'REQUESTED',
        Fare            DECIMAL(10,2)       NULL, -- Populated upon trip completion
        
        -- Technical extension attributes for physical dispatching and pricing (fully documented)
        PickupLat       DECIMAL(9,6)        NULL,
        PickupLon       DECIMAL(9,6)        NULL,
        DropLat         DECIMAL(9,6)        NULL,
        DropLon         DECIMAL(9,6)        NULL,

        -- Primary Key
        CONSTRAINT PK_Trips PRIMARY KEY CLUSTERED (TripID),

        -- Foreign Key: References Rider
        CONSTRAINT FK_Trips_Riders FOREIGN KEY (RiderID)
            REFERENCES dbo.Riders(RiderID)
            ON DELETE NO ACTION
            ON UPDATE CASCADE,

        -- Foreign Key: References Driver
        CONSTRAINT FK_Trips_Drivers FOREIGN KEY (DriverID)
            REFERENCES dbo.Drivers(DriverID)
            ON DELETE NO ACTION
            ON UPDATE CASCADE,

        -- Domain CHECK constraints
        CONSTRAINT CK_Trips_Status CHECK (Status IN ('REQUESTED', 'MATCHED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
        CONSTRAINT CK_Trips_Fare CHECK (Fare IS NULL OR Fare >= 0.00),
        CONSTRAINT CK_Trips_MatchSequence CHECK (MatchedAt IS NULL OR MatchedAt >= RequestedAt),
        CONSTRAINT CK_Trips_PickupLat CHECK (PickupLat IS NULL OR (PickupLat BETWEEN -90.000000 AND 90.000000)),
        CONSTRAINT CK_Trips_PickupLon CHECK (PickupLon IS NULL OR (PickupLon BETWEEN -180.000000 AND 180.000000))
    );
    PRINT 'Table dbo.Trips created successfully.';
END
ELSE
    PRINT 'Table dbo.Trips already exists.';
GO

-- Index for querying active trips by status and rider
IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N'IX_Trips_Status_Rider')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Trips_Status_Rider ON dbo.Trips (Status, RiderID) INCLUDE (DriverID, RequestedAt);
    PRINT 'Index IX_Trips_Status_Rider created.';
END
GO

-- Index for driver's trip history
IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = N'IX_Trips_DriverID')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Trips_DriverID ON dbo.Trips (DriverID, Status) INCLUDE (Fare, RequestedAt, MatchedAt);
    PRINT 'Index IX_Trips_DriverID created.';
END
GO

-- ============================================================================
-- TABLE 6: Ratings (Entity 6: Rating)
-- Description: Post-trip feedback and evaluation submitted by riders.
-- ============================================================================
IF OBJECT_ID(N'dbo.Ratings', N'U') IS NULL
BEGIN
    PRINT 'Creating table: dbo.Ratings...';
    CREATE TABLE dbo.Ratings (
        RatingID        INT IDENTITY(1,1)   NOT NULL,
        TripID          INT                 NOT NULL,
        Stars           TINYINT             NOT NULL,
        Comment         NVARCHAR(500)       NULL,
        CreatedAt       DATETIME2(3)        NOT NULL CONSTRAINT DF_Ratings_CreatedAt DEFAULT SYSUTCDATETIME(),

        -- Primary Key
        CONSTRAINT PK_Ratings PRIMARY KEY CLUSTERED (RatingID),

        -- Foreign Key: References Trip table
        CONSTRAINT FK_Ratings_Trips FOREIGN KEY (TripID)
            REFERENCES dbo.Trips(TripID)
            ON DELETE CASCADE
            ON UPDATE CASCADE,

        -- Unique Constraint: Strictly enforces 1:1 relationship between Trip and Rating
        CONSTRAINT UQ_Ratings_TripID UNIQUE NONCLUSTERED (TripID),

        -- Domain CHECK constraint for star rating (1 to 5 inclusive)
        CONSTRAINT CK_Ratings_Stars CHECK (Stars BETWEEN 1 AND 5)
    );
    PRINT 'Table dbo.Ratings created successfully.';
END
ELSE
    PRINT 'Table dbo.Ratings already exists.';
GO

PRINT 'All six RideSync relational tables created and indexed successfully.';
GO
