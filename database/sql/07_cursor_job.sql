-- ============================================================================
-- SCRIPT 07: DAY 9 CURSOR IMPLEMENTATION & SET-BASED COMPARISON
-- System: RideSync (UrbanGo Mobility)
-- Database: RideSyncDB
-- Technology: Microsoft SQL Server 2025 (v17)
-- Author: Senior Database Architect
-- Date: 2026-11-17
-- Description: Demonstrates T-SQL CURSOR syntax, lifecycle management, and
--              error recovery to satisfy Day 9 training requirements.
--              Processes 'ONLINE' drivers whose last telemetry ping is older than
--              60 seconds, marking them 'OFFLINE' and printing diagnostic logs.
--              Includes a side-by-side performance contrast with set-based SQL.
-- ============================================================================

USE RideSyncDB;
GO

-- ============================================================================
-- AUDIT TABLE FOR STALE DRIVER ACTIONS
-- ============================================================================
IF OBJECT_ID(N'dbo.StaleDriverAudit', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.StaleDriverAudit (
        AuditID         INT IDENTITY(1,1) PRIMARY KEY,
        DriverID        INT NOT NULL,
        PreviousStatus  VARCHAR(20) NOT NULL,
        SecondsStale    INT NOT NULL,
        MarkedOfflineAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
        Reason          NVARCHAR(200) NOT NULL
    );
    PRINT 'Created table: dbo.StaleDriverAudit';
END
GO

-- ============================================================================
-- STORED PROCEDURE WITH CURSOR: sp_process_stale_drivers
-- Demonstrates: DECLARE CURSOR, OPEN, FETCH NEXT, @@FETCH_STATUS, CLOSE, DEALLOCATE
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_process_stale_drivers
    @StaleThresholdSeconds INT = 60
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '------------------------------------------------------------';
    PRINT 'BEGINNING STALE DRIVER CURSOR BATCH JOB';
    PRINT 'Stale Threshold: ' + CAST(@StaleThresholdSeconds AS VARCHAR(10)) + ' seconds';
    PRINT '------------------------------------------------------------';

    -- Declare local variables for cursor processing
    DECLARE @DriverID INT;
    DECLARE @FirstName NVARCHAR(50);
    DECLARE @LastName NVARCHAR(50);
    DECLARE @LastPingTime DATETIME2(3);
    DECLARE @SecondsElapsed INT;
    DECLARE @ProcessedCount INT = 0;

    -- 1. DECLARE CURSOR
    -- Explicitly declare as FAST_FORWARD (Read-only, forward-only optimized cursor)
    DECLARE cur_stale_drivers CURSOR FAST_FORWARD FOR
    WITH LatestPings AS (
        SELECT 
            lp.DriverID,
            MAX(lp.RecordedAt) AS MaxRecordedAt
        FROM dbo.LocationPings lp
        GROUP BY lp.DriverID
    )
    SELECT 
        d.DriverID,
        d.FirstName,
        d.LastName,
        lp.MaxRecordedAt,
        ISNULL(DATEDIFF(SECOND, lp.MaxRecordedAt, SYSUTCDATETIME()), 999999) AS SecondsElapsed
    FROM dbo.Drivers d
    LEFT JOIN LatestPings lp ON d.DriverID = lp.DriverID
    WHERE d.Status = 'ONLINE'
      AND (lp.MaxRecordedAt IS NULL OR DATEDIFF(SECOND, lp.MaxRecordedAt, SYSUTCDATETIME()) > @StaleThresholdSeconds);

    -- 2. OPEN CURSOR
    OPEN cur_stale_drivers;

    -- 3. INITIAL FETCH (Prime the @@FETCH_STATUS loop)
    FETCH NEXT FROM cur_stale_drivers INTO @DriverID, @FirstName, @LastName, @LastPingTime, @SecondsElapsed;

    -- 4. PROCESS LOOP
    -- @@FETCH_STATUS = 0 indicates successful retrieval
    -- @@FETCH_STATUS = -1 indicates fetch failed or reached beyond result set
    -- @@FETCH_STATUS = -2 indicates fetched row is missing
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Processing Stale Driver #' + CAST(@DriverID AS VARCHAR(10)) + 
              ' (' + @FirstName + ' ' + @LastName + ') - Inactive for ' + 
              CAST(@SecondsElapsed AS VARCHAR(10)) + 's';

        -- Perform individual row transition
        UPDATE dbo.Drivers
        SET Status = 'OFFLINE'
        WHERE DriverID = @DriverID;

        -- Record audit entry
        INSERT INTO dbo.StaleDriverAudit (DriverID, PreviousStatus, SecondsStale, Reason)
        VALUES (@DriverID, 'ONLINE', @SecondsElapsed, N'Automatically transitioned due to telemetry timeout (> ' + CAST(@StaleThresholdSeconds AS VARCHAR(10)) + 's)');

        SET @ProcessedCount = @ProcessedCount + 1;

        -- Fetch next row
        FETCH NEXT FROM cur_stale_drivers INTO @DriverID, @FirstName, @LastName, @LastPingTime, @SecondsElapsed;
    END

    -- 5. CLOSE CURSOR (Release row locks and result cursor memory)
    CLOSE cur_stale_drivers;

    -- 6. DEALLOCATE CURSOR (Remove cursor reference from server memory)
    DEALLOCATE cur_stale_drivers;

    PRINT '------------------------------------------------------------';
    PRINT 'CURSOR PROCESSING COMPLETE: ' + CAST(@ProcessedCount AS VARCHAR(10)) + ' stale drivers deactivated.';
    PRINT '------------------------------------------------------------';
END;
GO

PRINT 'Created cursor procedure: dbo.sp_process_stale_drivers';
GO

-- ============================================================================
-- ARCHITECTURAL COMPARISON: CURSOR vs SET-BASED SQL
-- ============================================================================
/*
THEORY & VIVA DEFENSE:
1. Why was a CURSOR used here?
   In Day 9 of the Hexaware curriculum, cursors are evaluated to demonstrate row-by-row
   lifecycle management (DECLARE -> OPEN -> FETCH -> CLOSE -> DEALLOCATE) and fine-grained
   logging/external messaging for individual records.

2. What is the production-grade SET-BASED ALTERNATIVE?
   Set-based SQL updates all matching rows in a single relational operation, eliminating
   cursor overhead, context switches, and iterative row locks.

   -- SET-BASED ALTERNATIVE:
   BEGIN TRANSACTION;
   
   WITH LatestPings AS (
       SELECT DriverID, MAX(RecordedAt) AS MaxRecordedAt
       FROM dbo.LocationPings
       GROUP BY DriverID
   )
   UPDATE d
   SET d.Status = 'OFFLINE'
   OUTPUT inserted.DriverID, 'ONLINE', DATEDIFF(SECOND, lp.MaxRecordedAt, SYSUTCDATETIME()), SYSUTCDATETIME(), 'Set-based batch timeout'
   INTO dbo.StaleDriverAudit (DriverID, PreviousStatus, SecondsStale, MarkedOfflineAt, Reason)
   FROM dbo.Drivers d
   LEFT JOIN LatestPings lp ON d.DriverID = lp.DriverID
   WHERE d.Status = 'ONLINE'
     AND (lp.MaxRecordedAt IS NULL OR DATEDIFF(SECOND, lp.MaxRecordedAt, SYSUTCDATETIME()) > 60);

   COMMIT TRANSACTION;

3. Comparison Summary:
   - Cursor Complexity: O(N) context switches; high overhead on large driver tables.
   - Set-Based Complexity: Optimized single-pass execution plan with batch I/O.
   - Recommendation: Use Set-Based SQL for high-volume production operations; use Cursors
     only when invoking sequential external APIs or complex conditional procedural logic per row.
*/
GO
