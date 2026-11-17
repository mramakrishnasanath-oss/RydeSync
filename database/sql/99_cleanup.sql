-- ============================================================================
-- SCRIPT 99: REVERSE-DEPENDENCY TEARDOWN & CLEANUP
-- System: RideSync (UrbanGo Mobility)
-- Database: RideSyncDB
-- Technology: Microsoft SQL Server 2025 (v17)
-- Author: Senior Database Architect
-- Date: 2026-11-17
-- Description: Safely drops all database objects in strict reverse dependency order.
--              Use ONLY in development/sandbox environments for clean resets.
-- ============================================================================

USE RideSyncDB;
GO

PRINT 'Starting reverse-dependency cleanup in RideSyncDB...';

-- 1. Drop Views
DROP VIEW IF EXISTS dbo.vw_online_drivers_updatable;
DROP VIEW IF EXISTS dbo.vw_zone_supply_summary;
DROP VIEW IF EXISTS dbo.vw_driver_location_history;
DROP VIEW IF EXISTS dbo.vw_trip_summary;
DROP VIEW IF EXISTS dbo.vw_driver_availability;
PRINT 'Views dropped.';

-- 2. Drop Stored Procedures
DROP PROCEDURE IF EXISTS dbo.sp_process_stale_drivers;
DROP PROCEDURE IF EXISTS dbo.sp_complete_trip;
DROP PROCEDURE IF EXISTS dbo.sp_assign_driver;
DROP PROCEDURE IF EXISTS dbo.sp_request_ride;
DROP PROCEDURE IF EXISTS dbo.sp_update_driver_status;
DROP PROCEDURE IF EXISTS dbo.sp_register_driver;
DROP PROCEDURE IF EXISTS dbo.sp_register_rider;
PRINT 'Stored procedures dropped.';

-- 3. Drop Stored Functions
DROP FUNCTION IF EXISTS dbo.fn_get_nearby_available_drivers;
DROP FUNCTION IF EXISTS dbo.fn_estimate_fare;
DROP FUNCTION IF EXISTS dbo.fn_calculate_distance;
PRINT 'Stored functions dropped.';

-- 4. Drop Tables in Reverse Dependency Order
-- Child tables with foreign keys must be dropped before referenced parent tables

-- Drop Ratings (Child of Trips)
IF OBJECT_ID(N'dbo.Ratings', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Ratings;
    PRINT 'Dropped table: dbo.Ratings';
END;

-- Drop LocationPings (Child of Drivers)
IF OBJECT_ID(N'dbo.LocationPings', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.LocationPings;
    PRINT 'Dropped table: dbo.LocationPings';
END;

-- Drop Trips (Child of Riders and Drivers)
IF OBJECT_ID(N'dbo.Trips', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Trips;
    PRINT 'Dropped table: dbo.Trips';
END;

-- Drop Drivers (Child of Vehicles)
IF OBJECT_ID(N'dbo.Drivers', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Drivers;
    PRINT 'Dropped table: dbo.Drivers';
END;

-- Drop Vehicles (Parent of Drivers)
IF OBJECT_ID(N'dbo.Vehicles', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Vehicles;
    PRINT 'Dropped table: dbo.Vehicles';
END;

-- Drop Riders (Parent of Trips)
IF OBJECT_ID(N'dbo.Riders', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Riders;
    PRINT 'Dropped table: dbo.Riders';
END;

PRINT 'Reverse-dependency cleanup completed successfully.';
GO
