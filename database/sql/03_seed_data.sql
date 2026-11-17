-- ============================================================================
-- SCRIPT 03: REALISTIC SAMPLE DATA INSERTION
-- System: RideSync (UrbanGo Mobility)
-- Database: RideSyncDB
-- Technology: Microsoft SQL Server 2025 (v17)
-- Author: Senior Database Architect
-- Date: 2026-11-17
-- Description: Inserts production-grade realistic test data:
--              - 15 Riders (Valid unique phone numbers)
--              - 12 Vehicles (Realistic commercial plates & models)
--              - 12 Drivers (1:1 Vehicle allocation; distributed statuses)
--              - 15 Trips (Requested, Matched, In-Progress, Completed, Cancelled)
--              - 10 Ratings (1:1 with completed trips; stars 1-5 with comments)
--              - 250+ LocationPings (High-frequency 2-3s GPS breadcrumbs)
-- ============================================================================

USE RideSyncDB;
GO

SET NOCOUNT ON;
PRINT 'Beginning sample data insertion for RideSyncDB...';

-- ============================================================================
-- 1. SEED DATA: dbo.Riders (15 Records)
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.Riders)
BEGIN
    PRINT 'Inserting 15 sample Riders...';
    INSERT INTO dbo.Riders (FirstName, LastName, Phone, CreatedAt) VALUES
    (N'Aarav',     N'Sharma',    '+919876543210', DATEADD(DAY, -30, SYSUTCDATETIME())),
    (N'Diya',      N'Patel',     '+919876543211', DATEADD(DAY, -28, SYSUTCDATETIME())),
    (N'Rohan',     N'Verma',     '+919876543212', DATEADD(DAY, -25, SYSUTCDATETIME())),
    (N'Ananya',    N'Iyer',      '+919876543213', DATEADD(DAY, -22, SYSUTCDATETIME())),
    (N'Vikram',    N'Reddy',     '+919876543214', DATEADD(DAY, -20, SYSUTCDATETIME())),
    (N'Pooja',     N'Nair',      '+919876543215', DATEADD(DAY, -18, SYSUTCDATETIME())),
    (N'Karthik',   N'Rao',       '+919876543216', DATEADD(DAY, -15, SYSUTCDATETIME())),
    (N'Sneha',     N'Kulkarni',  '+919876543217', DATEADD(DAY, -12, SYSUTCDATETIME())),
    (N'Aditya',    N'Mehta',     '+919876543218', DATEADD(DAY, -10, SYSUTCDATETIME())),
    (N'Meera',     N'Deshmukh',  '+919876543219', DATEADD(DAY, -8,  SYSUTCDATETIME())),
    (N'Siddharth', N'Chopra',    '+919876543220', DATEADD(DAY, -6,  SYSUTCDATETIME())),
    (N'Neha',      N'Gupta',     '+919876543221', DATEADD(DAY, -5,  SYSUTCDATETIME())),
    (N'Rahul',     N'Joshi',     '+919876543222', DATEADD(DAY, -3,  SYSUTCDATETIME())),
    (N'Kavya',     N'Menon',     '+919876543223', DATEADD(DAY, -2,  SYSUTCDATETIME())),
    (N'Varun',     N'Bhat',      '+919876543224', DATEADD(DAY, -1,  SYSUTCDATETIME()));
    PRINT 'Inserted 15 Riders successfully.';
END
ELSE
    PRINT 'Riders table already populated.';
GO

-- ============================================================================
-- 2. SEED DATA: dbo.Vehicles (12 Records)
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.Vehicles)
BEGIN
    PRINT 'Inserting 12 sample Vehicles...';
    INSERT INTO dbo.Vehicles (PlateNumber, Model, RegisteredAt) VALUES
    ('TS09UB1001', N'Maruti Suzuki Dzire VXi',    DATEADD(DAY, -60, SYSUTCDATETIME())),
    ('TS09UB1002', N'Hyundai Aura S CNG',         DATEADD(DAY, -55, SYSUTCDATETIME())),
    ('TS09UB1003', N'Tata Tigor EV XZ+',          DATEADD(DAY, -50, SYSUTCDATETIME())),
    ('TS09UB1004', N'Toyota Etios GD',            DATEADD(DAY, -45, SYSUTCDATETIME())),
    ('TS09UB1005', N'Maruti Suzuki WagonR LXi',   DATEADD(DAY, -40, SYSUTCDATETIME())),
    ('TS09UB1006', N'Honda Amaze VX',             DATEADD(DAY, -35, SYSUTCDATETIME())),
    ('TS09UB1007', N'Maruti Suzuki Ertiga ZXi',   DATEADD(DAY, -30, SYSUTCDATETIME())),
    ('TS09UB1008', N'Toyota Innova Crysta 2.4G',  DATEADD(DAY, -25, SYSUTCDATETIME())),
    ('TS09UB1009', N'Hyundai Grand i10 Nios',     DATEADD(DAY, -20, SYSUTCDATETIME())),
    ('TS09UB1010', N'Tata Nexon EV Max',          DATEADD(DAY, -15, SYSUTCDATETIME())),
    ('TS09UB1011', N'Mahindra Marazzo M6',        DATEADD(DAY, -10, SYSUTCDATETIME())),
    ('TS09UB1012', N'Maruti Suzuki Baleno Alpha', DATEADD(DAY, -5,  SYSUTCDATETIME()));
    PRINT 'Inserted 12 Vehicles successfully.';
END
ELSE
    PRINT 'Vehicles table already populated.';
GO

-- ============================================================================
-- 3. SEED DATA: dbo.Drivers (12 Records)
-- 1:1 mapped to Vehicles. Status distributed: ONLINE, OFFLINE, ON_TRIP, SUSPENDED
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.Drivers)
BEGIN
    PRINT 'Inserting 12 sample Drivers...';
    INSERT INTO dbo.Drivers (FirstName, LastName, VehicleID, Status, RegisteredAt) VALUES
    (N'Rajesh',    N'Kumar',    1,    'ONLINE',    DATEADD(DAY, -60, SYSUTCDATETIME())),
    (N'Suresh',    N'Babu',     2,    'ONLINE',    DATEADD(DAY, -55, SYSUTCDATETIME())),
    (N'Mahesh',    N'Yadav',    3,    'ONLINE',    DATEADD(DAY, -50, SYSUTCDATETIME())),
    (N'Ganesh',    N'Reddy',    4,    'ON_TRIP',   DATEADD(DAY, -45, SYSUTCDATETIME())),
    (N'Ramesh',    N'Goud',     5,    'ON_TRIP',   DATEADD(DAY, -40, SYSUTCDATETIME())),
    (N'Venkat',    N'Rao',      6,    'ONLINE',    DATEADD(DAY, -35, SYSUTCDATETIME())),
    (N'Naresh',    N'Chary',    7,    'OFFLINE',   DATEADD(DAY, -30, SYSUTCDATETIME())),
    (N'Prasad',    N'Vara',     8,    'ONLINE',    DATEADD(DAY, -25, SYSUTCDATETIME())),
    (N'Srinivas',  N'Murthy',   9,    'OFFLINE',   DATEADD(DAY, -20, SYSUTCDATETIME())),
    (N'Chandrashekhar', N'M',   10,   'ONLINE',    DATEADD(DAY, -15, SYSUTCDATETIME())),
    (N'Dhanush',   N'Shetty',   11,   'SUSPENDED', DATEADD(DAY, -10, SYSUTCDATETIME())),
    (N'Harish',    N'Gowda',    NULL, 'OFFLINE',   DATEADD(DAY, -5,  SYSUTCDATETIME())); -- Unassigned vehicle
    PRINT 'Inserted 12 Drivers successfully.';
END
ELSE
    PRINT 'Drivers table already populated.';
GO

-- ============================================================================
-- 4. SEED DATA: dbo.Trips (15 Records)
-- Distributed across lifecycle: COMPLETED, IN_PROGRESS, MATCHED, REQUESTED, CANCELLED
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.Trips)
BEGIN
    PRINT 'Inserting 15 sample Trips...';
    INSERT INTO dbo.Trips (RiderID, DriverID, RequestedAt, MatchedAt, Status, Fare, PickupLat, PickupLon, DropLat, DropLon) VALUES
    -- Completed Trips (1-10) with valid fares and match timestamps
    (1,  1, DATEADD(HOUR, -24, SYSUTCDATETIME()), DATEADD(MINUTE, -1438, SYSUTCDATETIME()), 'COMPLETED', 245.50, 17.4399, 78.3800, 17.4900, 78.3900),
    (2,  2, DATEADD(HOUR, -20, SYSUTCDATETIME()), DATEADD(MINUTE, -1198, SYSUTCDATETIME()), 'COMPLETED', 180.00, 17.4410, 78.3820, 17.4200, 78.3500),
    (3,  3, DATEADD(HOUR, -18, SYSUTCDATETIME()), DATEADD(MINUTE, -1077, SYSUTCDATETIME()), 'COMPLETED', 320.75, 17.4500, 78.3700, 17.5100, 78.3400),
    (4,  4, DATEADD(HOUR, -15, SYSUTCDATETIME()), DATEADD(MINUTE, -897,  SYSUTCDATETIME()), 'COMPLETED', 150.00, 17.4350, 78.3850, 17.4100, 78.4000),
    (5,  5, DATEADD(HOUR, -12, SYSUTCDATETIME()), DATEADD(MINUTE, -718,  SYSUTCDATETIME()), 'COMPLETED', 410.20, 17.4300, 78.3900, 17.3600, 78.4700),
    (6,  6, DATEADD(HOUR, -10, SYSUTCDATETIME()), DATEADD(MINUTE, -599,  SYSUTCDATETIME()), 'COMPLETED', 125.00, 17.4450, 78.3750, 17.4600, 78.3650),
    (7,  8, DATEADD(HOUR, -8,  SYSUTCDATETIME()), DATEADD(MINUTE, -478,  SYSUTCDATETIME()), 'COMPLETED', 275.00, 17.4250, 78.3950, 17.4800, 78.4100),
    (8,  1, DATEADD(HOUR, -6,  SYSUTCDATETIME()), DATEADD(MINUTE, -357,  SYSUTCDATETIME()), 'COMPLETED', 195.50, 17.4380, 78.3830, 17.4500, 78.4200),
    (9,  2, DATEADD(HOUR, -4,  SYSUTCDATETIME()), DATEADD(MINUTE, -238,  SYSUTCDATETIME()), 'COMPLETED', 340.00, 17.4420, 78.3780, 17.3800, 78.4500),
    (10, 3, DATEADD(HOUR, -3,  SYSUTCDATETIME()), DATEADD(MINUTE, -179,  SYSUTCDATETIME()), 'COMPLETED', 110.00, 17.4480, 78.3720, 17.4600, 78.3800),

    -- In-Progress Trips (11-12)
    (11, 4, DATEADD(MINUTE, -25, SYSUTCDATETIME()), DATEADD(MINUTE, -23, SYSUTCDATETIME()), 'IN_PROGRESS', NULL, 17.4390, 78.3810, 17.5000, 78.3500),
    (12, 5, DATEADD(MINUTE, -15, SYSUTCDATETIME()), DATEADD(MINUTE, -13, SYSUTCDATETIME()), 'IN_PROGRESS', NULL, 17.4440, 78.3840, 17.4100, 78.4300),

    -- Matched Trip (13) awaiting pickup
    (13, 6, DATEADD(MINUTE, -5,  SYSUTCDATETIME()), DATEADD(MINUTE, -4,  SYSUTCDATETIME()), 'MATCHED',     NULL, 17.4470, 78.3790, 17.4900, 78.3900),

    -- Requested Trips (14) waiting for driver assignment
    (14, NULL, DATEADD(MINUTE, -2, SYSUTCDATETIME()), NULL,                             'REQUESTED',   NULL, 17.4360, 78.3860, 17.4700, 78.4000),

    -- Cancelled Trip (15)
    (15, NULL, DATEADD(HOUR, -2, SYSUTCDATETIME()),   NULL,                             'CANCELLED',   NULL, 17.4400, 78.3800, 17.4800, 78.3700);

    PRINT 'Inserted 15 Trips successfully.';
END
ELSE
    PRINT 'Trips table already populated.';
GO

-- ============================================================================
-- 5. SEED DATA: dbo.Ratings (10 Records)
-- Strictly 1:1 evaluated against completed trips (TripID 1 to 10)
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.Ratings)
BEGIN
    PRINT 'Inserting 10 sample Ratings for completed trips...';
    INSERT INTO dbo.Ratings (TripID, Stars, Comment, CreatedAt) VALUES
    (1,  5, N'Smooth and punctual ride. Very polite driver.',             DATEADD(MINUTE, -1400, SYSUTCDATETIME())),
    (2,  4, N'Clean vehicle, drove safely through heavy traffic.',        DATEADD(MINUTE, -1170, SYSUTCDATETIME())),
    (3,  5, N'Excellent EV experience, silent and comfortable ride.',     DATEADD(MINUTE, -1040, SYSUTCDATETIME())),
    (4,  3, N'Driver arrived 5 minutes late but trip was okay.',          DATEADD(MINUTE, -870,  SYSUTCDATETIME())),
    (5,  5, N'Outstanding service! Handled airport luggage carefully.',   DATEADD(MINUTE, -690,  SYSUTCDATETIME())),
    (6,  4, N'Good route choice avoiding peak congestion at HITEC City.', DATEADD(MINUTE, -580,  SYSUTCDATETIME())),
    (7,  5, N'Very clean car and pleasant air conditioning.',             DATEADD(MINUTE, -450,  SYSUTCDATETIME())),
    (8,  2, N'Driver was speaking on phone using earphones while driving.', DATEADD(MINUTE, -330, SYSUTCDATETIME())),
    (9,  5, N'Fastest dispatch ever! Driver arrived within 2 minutes.',   DATEADD(MINUTE, -210,  SYSUTCDATETIME())),
    (10, 4, N'Decent ride, fair pricing.',                                DATEADD(MINUTE, -160,  SYSUTCDATETIME()));
    PRINT 'Inserted 10 Ratings successfully.';
END
ELSE
    PRINT 'Ratings table already populated.';
GO

-- ============================================================================
-- 6. SEED DATA: dbo.LocationPings (260 Records)
-- High-volume time-series telemetry simulating active drivers streaming GPS 
-- coordinates every 2 to 3 seconds along Hyderabad tech corridors.
-- ============================================================================
IF (SELECT COUNT(*) FROM dbo.LocationPings) < 200
BEGIN
    PRINT 'Generating 260 high-frequency telemetry LocationPings (2-3 second intervals)...';

    -- Use an in-memory table variable with CTE cross-join to generate sequential telemetry
    DECLARE @BaseTime DATETIME2(3) = SYSUTCDATETIME();

    -- Generate pings for Driver 1 (Rajesh Kumar - active near HITEC City / Cyber Towers)
    ;WITH Tally AS (
        SELECT TOP (65) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS Seq
        FROM sys.all_columns a CROSS JOIN sys.all_columns b
    )
    INSERT INTO dbo.LocationPings (DriverID, Latitude, Longitude, RecordedAt)
    SELECT 
        1 AS DriverID,
        CAST(17.448200 + (Seq * 0.000085) AS DECIMAL(9,6)) AS Latitude,
        CAST(78.374100 + (Seq * 0.000095) AS DECIMAL(9,6)) AS Longitude,
        DATEADD(SECOND, - (65 - Seq) * 3, @BaseTime) AS RecordedAt
    FROM Tally;

    -- Generate pings for Driver 2 (Suresh Babu - active near Gachibowli Stadium)
    ;WITH Tally AS (
        SELECT TOP (65) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS Seq
        FROM sys.all_columns a CROSS JOIN sys.all_columns b
    )
    INSERT INTO dbo.LocationPings (DriverID, Latitude, Longitude, RecordedAt)
    SELECT 
        2 AS DriverID,
        CAST(17.440000 + (Seq * 0.000070) AS DECIMAL(9,6)) AS Latitude,
        CAST(78.348900 + (Seq * 0.000110) AS DECIMAL(9,6)) AS Longitude,
        DATEADD(SECOND, - (65 - Seq) * 3, @BaseTime) AS RecordedAt
    FROM Tally;

    -- Generate pings for Driver 3 (Mahesh Yadav - active near Madhapur Police Station)
    ;WITH Tally AS (
        SELECT TOP (65) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS Seq
        FROM sys.all_columns a CROSS JOIN sys.all_columns b
    )
    INSERT INTO dbo.LocationPings (DriverID, Latitude, Longitude, RecordedAt)
    SELECT 
        3 AS DriverID,
        CAST(17.445000 + (Seq * 0.000090) AS DECIMAL(9,6)) AS Latitude,
        CAST(78.390000 + (Seq * 0.000060) AS DECIMAL(9,6)) AS Longitude,
        DATEADD(SECOND, - (65 - Seq) * 3, @BaseTime) AS RecordedAt
    FROM Tally;

    -- Generate pings for Driver 4 & 5 (Ganesh & Ramesh - currently ON_TRIP moving along Financial District)
    ;WITH Tally AS (
        SELECT TOP (65) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS Seq
        FROM sys.all_columns a CROSS JOIN sys.all_columns b
    )
    INSERT INTO dbo.LocationPings (DriverID, Latitude, Longitude, RecordedAt)
    SELECT 
        4 AS DriverID,
        CAST(17.418000 + (Seq * 0.000120) AS DECIMAL(9,6)) AS Latitude,
        CAST(78.339000 + (Seq * 0.000080) AS DECIMAL(9,6)) AS Longitude,
        DATEADD(SECOND, - (65 - Seq) * 2, @BaseTime) AS RecordedAt
    FROM Tally;

    DECLARE @TotalPings INT;
    SELECT @TotalPings = COUNT(*) FROM dbo.LocationPings;
    PRINT 'Inserted ' + CAST(@TotalPings AS VARCHAR(10)) + ' LocationPings successfully.';
END
ELSE
    PRINT 'LocationPings table already populated with >= 200 records.';
GO

-- Verification summary
PRINT '==================================================';
PRINT 'SAMPLE DATA VERIFICATION SUMMARY:';
PRINT '==================================================';
SELECT 'Riders' AS TableName, COUNT(*) AS RecordCount FROM dbo.Riders
UNION ALL
SELECT 'Vehicles', COUNT(*) FROM dbo.Vehicles
UNION ALL
SELECT 'Drivers', COUNT(*) FROM dbo.Drivers
UNION ALL
SELECT 'Trips', COUNT(*) FROM dbo.Trips
UNION ALL
SELECT 'Ratings', COUNT(*) FROM dbo.Ratings
UNION ALL
SELECT 'LocationPings (Telemetry)', COUNT(*) FROM dbo.LocationPings;
PRINT '==================================================';
GO
