-- ============================================================================
-- SCRIPT 06: DAY 9 STORED FUNCTIONS IMPLEMENTATION
-- System: RideSync (UrbanGo Mobility)
-- Database: RideSyncDB
-- Technology: Microsoft SQL Server 2025 (v17)
-- Author: Senior Database Architect
-- Date: 2026-11-17
-- Description: Implements Day 9 Stored Functions:
--              1. Scalar Function: fn_calculate_distance (Haversine formula in KM)
--              2. Scalar Function: fn_estimate_fare (Pricing algorithm)
--              3. Inline Table-Valued Function (iTVF): fn_get_nearby_available_drivers
-- ============================================================================

USE RideSyncDB;
GO

-- ============================================================================
-- FUNCTION 1: fn_calculate_distance (Scalar Function)
-- Business Purpose: Calculates great-circle distance between two GPS coordinates
--                   on Earth using the spherical Haversine formula (Mean Earth Radius = 6371.0 km).
-- Note: Deterministic function, safe for index computations and WHERE filtering.
-- ============================================================================
CREATE OR ALTER FUNCTION dbo.fn_calculate_distance (
    @Lat1 DECIMAL(9,6),
    @Lon1 DECIMAL(9,6),
    @Lat2 DECIMAL(9,6),
    @Lon2 DECIMAL(9,6)
)
RETURNS DECIMAL(10,3)
WITH SCHEMABINDING
AS
BEGIN
    -- Return 0.000 if origin equals destination
    IF (@Lat1 = @Lat2 AND @Lon1 = @Lon2)
        RETURN 0.000;

    -- Earth mean radius in kilometers
    DECLARE @R FLOAT = 6371.0;

    -- Convert degrees to radians
    DECLARE @dLat FLOAT = RADIANS(CAST(@Lat2 - @Lat1 AS FLOAT));
    DECLARE @dLon FLOAT = RADIANS(CAST(@Lon2 - @Lon1 AS FLOAT));
    DECLARE @rLat1 FLOAT = RADIANS(CAST(@Lat1 AS FLOAT));
    DECLARE @rLat2 FLOAT = RADIANS(CAST(@Lat2 AS FLOAT));

    -- Haversine trigonometric formulation:
    -- a = sin^2(dLat/2) + cos(Lat1) * cos(Lat2) * sin^2(dLon/2)
    -- c = 2 * atan2(sqrt(a), sqrt(1-a))
    -- d = R * c
    DECLARE @a FLOAT = SIN(@dLat / 2.0) * SIN(@dLat / 2.0) +
                       COS(@rLat1) * COS(@rLat2) *
                       SIN(@dLon / 2.0) * SIN(@dLon / 2.0);

    -- Clamp 'a' to avoid floating point domain errors in SQRT
    IF @a > 1.0 SET @a = 1.0;
    IF @a < 0.0 SET @a = 0.0;

    DECLARE @c FLOAT = 2.0 * ATN2(SQRT(@a), SQRT(1.0 - @a));
    DECLARE @Distance FLOAT = @R * @c;

    RETURN CAST(@Distance AS DECIMAL(10,3));
END;
GO

PRINT 'Created scalar function: dbo.fn_calculate_distance';
GO

-- ============================================================================
-- FUNCTION 2: fn_estimate_fare (Scalar Function)
-- Business Purpose: Estimates trip fare based on UrbanGo's commercial rate card:
--                   Base Fare (₹50.00) + Per-KM Rate (₹14.00) * Distance * SurgeMultiplier
-- ============================================================================
CREATE OR ALTER FUNCTION dbo.fn_estimate_fare (
    @DistanceKM         DECIMAL(10,3),
    @SurgeMultiplier    DECIMAL(3,2) = 1.00
)
RETURNS DECIMAL(10,2)
WITH SCHEMABINDING
AS
BEGIN
    IF @DistanceKM IS NULL OR @DistanceKM < 0.0
        RETURN 0.00;

    IF @SurgeMultiplier IS NULL OR @SurgeMultiplier < 1.00
        SET @SurgeMultiplier = 1.00;

    DECLARE @BaseFare DECIMAL(10,2) = 50.00;
    DECLARE @PerKmRate DECIMAL(10,2) = 14.00;

    DECLARE @TotalFare DECIMAL(10,2) = (@BaseFare + (@DistanceKM * @PerKmRate)) * @SurgeMultiplier;

    -- Return rounded to nearest rupee
    RETURN ROUND(@TotalFare, 2);
END;
GO

PRINT 'Created scalar function: dbo.fn_estimate_fare';
GO

-- ============================================================================
-- FUNCTION 3: fn_get_nearby_available_drivers (Inline Table-Valued Function)
-- Business Purpose: Returns all ONLINE drivers within @MaxRadiusKM of a pickup
--                   point, sorted nearest-first for dispatch evaluation.
-- Performance: Inline TVFs are treated like views and inlined directly into
--              the execution plan by the SQL Server Query Optimizer.
-- ============================================================================
CREATE OR ALTER FUNCTION dbo.fn_get_nearby_available_drivers (
    @PickupLat      DECIMAL(9,6),
    @PickupLon      DECIMAL(9,6),
    @MaxRadiusKM    DECIMAL(10,2) = 5.00
)
RETURNS TABLE
AS
RETURN (
    WITH LatestDriverPings AS (
        SELECT 
            lp.DriverID,
            lp.Latitude,
            lp.Longitude,
            lp.RecordedAt,
            ROW_NUMBER() OVER (PARTITION BY lp.DriverID ORDER BY lp.RecordedAt DESC) AS Seq
        FROM dbo.LocationPings lp
    )
    SELECT 
        d.DriverID,
        d.FirstName + ' ' + d.LastName AS DriverName,
        v.PlateNumber,
        v.Model AS VehicleModel,
        p.Latitude AS DriverLatitude,
        p.Longitude AS DriverLongitude,
        p.RecordedAt AS LastPingAt,
        dbo.fn_calculate_distance(@PickupLat, @PickupLon, p.Latitude, p.Longitude) AS DistanceKM
    FROM dbo.Drivers d
    INNER JOIN dbo.Vehicles v ON d.VehicleID = v.VehicleID
    INNER JOIN LatestDriverPings p ON d.DriverID = p.DriverID AND p.Seq = 1
    WHERE d.Status = 'ONLINE'
      AND dbo.fn_calculate_distance(@PickupLat, @PickupLon, p.Latitude, p.Longitude) <= @MaxRadiusKM
);
GO

PRINT 'Created table-valued function: dbo.fn_get_nearby_available_drivers';
GO

PRINT 'All Day 9 Stored Functions created successfully.';
GO
