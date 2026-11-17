-- ============================================================================
-- SCRIPT 01: DATABASE CREATION
-- System: RideSync (UrbanGo Mobility)
-- Technology: Microsoft SQL Server 2025 (v17) / Azure SQL Database compatible
-- Author: Senior Database Architect
-- Date: 2026-11-17
-- Description: Safely creates the RideSyncDB database if it does not already exist.
-- ============================================================================

USE master;
GO

-- Check if RideSyncDB already exists before attempting creation
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'RideSyncDB')
BEGIN
    PRINT 'Creating database RideSyncDB...';
    CREATE DATABASE RideSyncDB
    COLLATE Latin1_General_100_CI_AS_SC_UTF8; -- Modern UTF-8 collation supported in SQL Server 2019+
    PRINT 'Database RideSyncDB created successfully.';
END
ELSE
BEGIN
    PRINT 'Database RideSyncDB already exists. Skipping creation.';
END
GO

-- Set database configuration options for optimal concurrency and ACID safety
ALTER DATABASE RideSyncDB SET RECOVERY SIMPLE;
ALTER DATABASE RideSyncDB SET AUTO_UPDATE_STATISTICS ON;
ALTER DATABASE RideSyncDB SET READ_COMMITTED_SNAPSHOT ON; -- Optimistic concurrency: reads don't block writes
GO

PRINT 'RideSyncDB configuration completed.';
GO
