-- ============================================================================
-- SCRIPT 04: DAY 9 SQL SERVER VIEWS IMPLEMENTATION
-- System: RideSync (UrbanGo Mobility)
-- Database: RideSyncDB
-- Technology: Microsoft SQL Server 2025 (v17)
-- Author: Senior Database Architect
-- Date: 2026-11-17
-- Description: Implements Day 9 training requirements for Views:
--              1. Simple View: vw_driver_availability
--              2. Complex Reporting View: vw_trip_summary
--              3. Analytical Telemetry View: vw_driver_location_history (Window functions)
--              4. Zone Aggregate View: vw_zone_supply_summary
--              5. Updatable View with WITH CHECK OPTION: vw_online_drivers_updatable
-- ============================================================================

USE RideSyncDB;
GO

-- ============================================================================
-- VIEW 1: vw_driver_availability (Simple View)
-- Business Purpose: Exposes currently active (ONLINE) drivers and their assigned
--                   vehicle specifications for dispatch routing.
-- Security Purpose: Hides internal driver timestamps and registration dates.
-- ============================================================================
CREATE OR ALTER VIEW dbo.vw_driver_availability
AS
SELECT 
    d.DriverID,
    d.FirstName + ' ' + d.LastName AS DriverFullName,
    d.Status AS DriverStatus,
    v.VehicleID,
    v.PlateNumber,
    v.Model AS VehicleModel
FROM dbo.Drivers d
INNER JOIN dbo.Vehicles v ON d.VehicleID = v.VehicleID
WHERE d.Status = 'ONLINE';
GO

PRINT 'Created view: dbo.vw_driver_availability';
GO

-- ============================================================================
-- VIEW 2: vw_trip_summary (Complex Multi-Table Reporting View)
-- Business Purpose: Executive dashboard view consolidating Rider, Driver, 
--                   Vehicle, Trip lifecycle timestamps, Fares, and Star Ratings.
-- Joins: Riders (1:M), Drivers (1:M), Vehicles (1:1), Trips (Core), Ratings (1:0..1)
-- ============================================================================
CREATE OR ALTER VIEW dbo.vw_trip_summary
AS
SELECT 
    t.TripID,
    t.Status AS TripStatus,
    t.RequestedAt,
    t.MatchedAt,
    DATEDIFF(SECOND, t.RequestedAt, t.MatchedAt) AS DispatchLatencySeconds,
    t.Fare AS TotalFareINR,
    -- Rider Info
    r.RiderID,
    r.FirstName + ' ' + r.LastName AS RiderName,
    r.Phone AS RiderPhone,
    -- Driver Info
    d.DriverID,
    ISNULL(d.FirstName + ' ' + d.LastName, 'Unassigned') AS DriverName,
    d.Status AS DriverCurrentStatus,
    -- Vehicle Info
    v.PlateNumber,
    v.Model AS VehicleModel,
    -- Feedback Info
    rt.Stars AS RatingStars,
    rt.Comment AS RiderComment
FROM dbo.Trips t
INNER JOIN dbo.Riders r ON t.RiderID = r.RiderID
LEFT JOIN dbo.Drivers d ON t.DriverID = d.DriverID
LEFT JOIN dbo.Vehicles v ON d.VehicleID = v.VehicleID
LEFT JOIN dbo.Ratings rt ON t.TripID = rt.TripID;
GO

PRINT 'Created view: dbo.vw_trip_summary';
GO

-- ============================================================================
-- VIEW 3: vw_driver_location_history (Complex Window-Function View)
-- Business Purpose: Resolves the "latest known position" for every driver
--                   without expensive correlated subqueries by leveraging
--                   the T-SQL ROW_NUMBER() window function.
-- ============================================================================
CREATE OR ALTER VIEW dbo.vw_driver_location_history
AS
WITH RankedPings AS (
    SELECT 
        lp.PingID,
        lp.DriverID,
        lp.Latitude,
        lp.Longitude,
        lp.RecordedAt,
        ROW_NUMBER() OVER (
            PARTITION BY lp.DriverID 
            ORDER BY lp.RecordedAt DESC
        ) AS PingRecencyRank
    FROM dbo.LocationPings lp
)
SELECT 
    rp.DriverID,
    d.FirstName + ' ' + d.LastName AS DriverName,
    d.Status AS CurrentStatus,
    rp.Latitude AS LatestLatitude,
    rp.Longitude AS LatestLongitude,
    rp.RecordedAt AS LastPingTime,
    DATEDIFF(SECOND, rp.RecordedAt, SYSUTCDATETIME()) AS SecondsSinceLastPing,
    CASE 
        WHEN DATEDIFF(SECOND, rp.RecordedAt, SYSUTCDATETIME()) > 60 THEN 'STALE'
        ELSE 'FRESH'
    END AS TelemetryFreshness
FROM RankedPings rp
INNER JOIN dbo.Drivers d ON rp.DriverID = d.DriverID
WHERE rp.PingRecencyRank = 1;
GO

PRINT 'Created view: dbo.vw_driver_location_history';
GO

-- ============================================================================
-- VIEW 4: vw_zone_supply_summary (Analytical Aggregation View)
-- Business Purpose: Evaluates supply-demand metrics across urban coordinates
--                   to detect shortage zones.
-- ============================================================================
CREATE OR ALTER VIEW dbo.vw_zone_supply_summary
AS
SELECT 
    CASE 
        WHEN lp.Latitude >= 17.4400 AND lp.Longitude <= 78.3800 THEN 'Zone A - HITEC Corridor'
        WHEN lp.Latitude <  17.4400 AND lp.Longitude <= 78.3800 THEN 'Zone B - Gachibowli / Financial Dist'
        ELSE 'Zone C - Madhapur / Jubilee'
    END AS UrbanZone,
    COUNT(DISTINCT d.DriverID) AS TotalAssignedDrivers,
    SUM(CASE WHEN d.Status = 'ONLINE' THEN 1 ELSE 0 END) AS OnlineAvailableSupply,
    SUM(CASE WHEN d.Status = 'ON_TRIP' THEN 1 ELSE 0 END) AS OnTripDrivers
FROM dbo.Drivers d
INNER JOIN dbo.LocationPings lp ON d.DriverID = lp.DriverID
GROUP BY 
    CASE 
        WHEN lp.Latitude >= 17.4400 AND lp.Longitude <= 78.3800 THEN 'Zone A - HITEC Corridor'
        WHEN lp.Latitude <  17.4400 AND lp.Longitude <= 78.3800 THEN 'Zone B - Gachibowli / Financial Dist'
        ELSE 'Zone C - Madhapur / Jubilee'
    END;
GO

PRINT 'Created view: dbo.vw_zone_supply_summary';
GO

-- ============================================================================
-- VIEW 5: vw_online_drivers_updatable (Updatable View with WITH CHECK OPTION)
-- Business Purpose: Allows operations personnel to toggle driver availability
--                   through a restricted view without direct table access.
-- WITH CHECK OPTION: Enforces that any UPDATE or INSERT executed through this
--                    view must satisfy the WHERE clause (Status = 'ONLINE').
--                    Attempting to insert or update a driver with Status = 'OFFLINE'
--                    through this view will be blocked by SQL Server.
-- ============================================================================
CREATE OR ALTER VIEW dbo.vw_online_drivers_updatable
AS
SELECT 
    DriverID,
    FirstName,
    LastName,
    VehicleID,
    Status
FROM dbo.Drivers
WHERE Status = 'ONLINE'
WITH CHECK OPTION;
GO

PRINT 'Created view: dbo.vw_online_drivers_updatable (with WITH CHECK OPTION)';
GO

PRINT 'All Day 9 SQL Server Views created successfully.';
GO
