# RideSync — Requirements Traceability Matrix (RTM)

**Document Reference:** `DOC-03-RTM`  
**System:** RideSync (UrbanGo Mobility)  
**Standard:** IEEE 830 / Agile Traceability  

---

## 1. Traceability Matrix: User Stories to Implementation

| Story ID | Epic ID | User Story Title & Goal | Relational Table / Object | MongoDB Collection | Unit / Database Test | Status |
| :---: | :---: | :--- | :--- | :--- | :--- | :---: |
| **RS-01** | `RS-E02` | **Driver Registration:** Onboard driver and associate vehicle. | `dbo.Drivers`, `dbo.Vehicles`, `sp_register_driver` | `driver_location_events` | `TEST 3` (1:1 Vehicle check) | **COMPLETED** |
| **RS-02** | `RS-E02` | **Driver Availability:** Update status to ONLINE or OFFLINE. | `dbo.Drivers`, `sp_update_driver_status`, `vw_online_drivers_updatable` | N/A | `TEST 8` (`WITH CHECK OPTION`) | **COMPLETED** |
| **RS-03** | `RS-E04` | **Location Streaming:** Send GPS coordinates every 2–3 seconds. | `dbo.LocationPings` | `driver_location_events` (2dsphere index) | `test_location_ping_bounds` | **COMPLETED** |
| **RS-04** | `RS-E04` | **Stale Driver Detection:** Detect drivers inactive for >60s. | `dbo.vw_driver_location_history`, `sp_process_stale_drivers` | N/A | `TEST 10` (Cursor execution) | **COMPLETED** |
| **RS-05** | `RS-E05` | **Ride Request:** Rider books point-to-point ride. | `dbo.Trips`, `sp_request_ride` | `ride_activity_logs` | `TEST 6` (FK check) | **COMPLETED** |
| **RS-06** | `RS-E06` | **Zone-Based Matching:** Match rides within designated zone. | `dbo.vw_zone_supply_summary` | `dispatch_events`, `view_zone_dispatch_metrics` | Analytical Query | **COMPLETED** |
| **RS-07** | `RS-E06` | **Nearest Driver Matching:** Find nearest online driver. | `fn_calculate_distance`, `fn_get_nearby_available_drivers` | `driver_location_events` ($nearSphere) | `TEST 9` (Haversine formula) | **COMPLETED** |
| **RS-08** | `RS-E06` | **Atomic Driver Claim:** Prevent double-booking via atomic claim. | `sp_assign_driver` (UPDLOCK, HOLDLOCK) | `dispatch_events` | `TEST 7` (Concurrency claim test) | **COMPLETED** |
| **RS-09** | `RS-E05` | **Trip Cancellation:** Cancel ride and release driver. | `dbo.Trips`, `dbo.Drivers` | `ride_activity_logs` | Lifecycle test | **COMPLETED** |
| **RS-10** | `RS-E05` | **Fare Calculation:** Calculate base, per-km, and surge fares. | `fn_estimate_fare`, `sp_complete_trip` | `ride_activity_logs` | `TEST 9` (Pricing function) | **COMPLETED** |
| **RS-11** | `RS-E05` | **Rating & Feedback:** Rider rates completed trip (1–5 stars). | `dbo.Ratings` | N/A | `TEST 5` (1–5 star bounds), `test_rating_bounds` | **COMPLETED** |
| **RS-12** | `RS-E06` | **Supply-Demand Monitoring:** Operations zone monitoring. | `dbo.vw_zone_supply_summary` | `view_zone_dispatch_metrics` | Dashboard query | **COMPLETED** |
