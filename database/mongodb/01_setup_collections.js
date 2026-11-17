// ============================================================================
// SCRIPT: 01_setup_collections.js
// System: RideSync (UrbanGo Mobility)
// Database: ridesync_events
// Technology: MongoDB 8.0 (mongosh / MongoDB Compass)
// Author: Senior Database Architect
// Date: 2026-11-17
// Description: Initializes operational event collections with JSON Schema validation,
//              2dsphere & compound indexes, TTL expiration, sample seed documents,
//              and saved aggregation views (db.createView()).
// ============================================================================

// Connect to ridesync_events database
db = db.getSiblingDB("ridesync_events");

print("==============================================================");
print("STARTING MONGODB COLLECTION SETUP FOR RIDESYNC OPERATIONAL DATA");
print("==============================================================");

// ----------------------------------------------------------------------------
// 1. COLLECTION: driver_location_events
// Telemetry stream receiving continuous GPS pings every 2-3 seconds.
// Features GeoJSON 2dsphere index and TTL automatic cleanup (7 days).
// ----------------------------------------------------------------------------
db.driver_location_events.drop(); // Clean reset for development

db.createCollection("driver_location_events", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["driver_id", "location", "speed_kmh", "timestamp"],
            properties: {
                driver_id: {
                    bsonType: "int",
                    description: "Driver ID corresponding to SQL Server Drivers.DriverID"
                },
                location: {
                    bsonType: "object",
                    required: ["type", "coordinates"],
                    properties: {
                        type: {
                            enum: ["Point"],
                            description: "GeoJSON point type"
                        },
                        coordinates: {
                            bsonType: "array",
                            minItems: 2,
                            maxItems: 2,
                            items: { bsonType: "double" },
                            description: "[longitude, latitude] in decimal degrees"
                        }
                    }
                },
                speed_kmh: {
                    bsonType: ["double", "int"],
                    minimum: 0,
                    maximum: 250,
                    description: "Current driving speed"
                },
                bearing_degrees: {
                    bsonType: ["double", "int"],
                    minimum: 0,
                    maximum: 360,
                    description: "Heading direction (0-360 degrees)"
                },
                timestamp: {
                    bsonType: "date",
                    description: "UTC timestamp when location was recorded"
                }
            }
        }
    }
});

// Indexes for Geospatial proximity and auto-expiration
db.driver_location_events.createIndex({ "location": "2dsphere" });
db.driver_location_events.createIndex({ "driver_id": 1, "timestamp": -1 });
db.driver_location_events.createIndex({ "timestamp": 1 }, { expireAfterSeconds: 604800 }); // TTL 7 Days

print("Collection created: driver_location_events with 2dsphere & TTL indexes.");

// ----------------------------------------------------------------------------
// 2. COLLECTION: dispatch_events
// Records matching and allocation metadata when rides are dispatched.
// ----------------------------------------------------------------------------
db.dispatch_events.drop();

db.createCollection("dispatch_events", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["trip_id", "rider_id", "assigned_driver_id", "zone_name", "matched_at"],
            properties: {
                trip_id: { bsonType: "int" },
                rider_id: { bsonType: "int" },
                assigned_driver_id: { bsonType: "int" },
                zone_name: { bsonType: "string" },
                matched_at: { bsonType: "date" },
                distance_to_pickup_km: { bsonType: ["double", "int"], minimum: 0 },
                dispatch_latency_ms: { bsonType: "int", minimum: 0 }
            }
        }
    }
});

db.dispatch_events.createIndex({ "trip_id": 1 }, { unique: true });
db.dispatch_events.createIndex({ "zone_name": 1, "matched_at": -1 });

print("Collection created: dispatch_events with zone & trip indexes.");

// ----------------------------------------------------------------------------
// 3. COLLECTION: ride_activity_logs
// Audit trail capturing full event history for every ride lifecycle transition.
// ----------------------------------------------------------------------------
db.ride_activity_logs.drop();

db.createCollection("ride_activity_logs", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["trip_id", "event_type", "recorded_at"],
            properties: {
                trip_id: { bsonType: "int" },
                event_type: { 
                    enum: ["REQUESTED", "DISPATCH_ATTEMPTED", "MATCHED", "DRIVER_ARRIVED", "TRIP_STARTED", "TRIP_COMPLETED", "TRIP_CANCELLED"] 
                },
                actor: { bsonType: "string" },
                payload: { bsonType: "object" },
                recorded_at: { bsonType: "date" }
            }
        }
    }
});

db.ride_activity_logs.createIndex({ "trip_id": 1, "recorded_at": 1 });

print("Collection created: ride_activity_logs with audit trail indexes.");

// ----------------------------------------------------------------------------
// 4. SAMPLE DATA INSERTION
// ----------------------------------------------------------------------------
print("Inserting sample operational event documents...");

// Sample driver location events (Hyderabad Coordinates: Lon 78.37~78.39, Lat 17.43~17.45)
db.driver_location_events.insertMany([
    {
        driver_id: NumberInt(1),
        location: { type: "Point", coordinates: [78.374100, 17.448200] },
        speed_kmh: 32.5,
        bearing_degrees: 145.0,
        timestamp: new Date()
    },
    {
        driver_id: NumberInt(2),
        location: { type: "Point", coordinates: [78.348900, 17.440000] },
        speed_kmh: 0.0,
        bearing_degrees: 0.0,
        timestamp: new Date()
    },
    {
        driver_id: NumberInt(3),
        location: { type: "Point", coordinates: [78.390000, 17.445000] },
        speed_kmh: 45.2,
        bearing_degrees: 270.5,
        timestamp: new Date()
    }
]);

// Sample dispatch events
db.dispatch_events.insertMany([
    {
        trip_id: NumberInt(1),
        rider_id: NumberInt(1),
        assigned_driver_id: NumberInt(1),
        zone_name: "HITEC City Corridor",
        matched_at: new Date(Date.now() - 24 * 3600 * 1000),
        distance_to_pickup_km: 1.45,
        dispatch_latency_ms: NumberInt(840)
    },
    {
        trip_id: NumberInt(2),
        rider_id: NumberInt(2),
        assigned_driver_id: NumberInt(2),
        zone_name: "Gachibowli Financial District",
        matched_at: new Date(Date.now() - 20 * 3600 * 1000),
        distance_to_pickup_km: 2.10,
        dispatch_latency_ms: NumberInt(1250)
    },
    {
        trip_id: NumberInt(3),
        rider_id: NumberInt(3),
        assigned_driver_id: NumberInt(3),
        zone_name: "Madhapur Tech Corridor",
        matched_at: new Date(Date.now() - 18 * 3600 * 1000),
        distance_to_pickup_km: 0.85,
        dispatch_latency_ms: NumberInt(620)
    }
]);

// Sample ride activity logs
db.ride_activity_logs.insertMany([
    {
        trip_id: NumberInt(1),
        event_type: "REQUESTED",
        actor: "Rider",
        payload: { pickup: "Cyber Towers", drop: "Inorbit Mall" },
        recorded_at: new Date(Date.now() - 24 * 3600 * 1000 - 30000)
    },
    {
        trip_id: NumberInt(1),
        event_type: "MATCHED",
        actor: "DispatchService",
        payload: { driver_id: NumberInt(1), eta_seconds: 180 },
        recorded_at: new Date(Date.now() - 24 * 3600 * 1000)
    },
    {
        trip_id: NumberInt(1),
        event_type: "TRIP_COMPLETED",
        actor: "Driver",
        payload: { fare_inr: 245.50, trip_duration_min: 24.5 },
        recorded_at: new Date(Date.now() - 23 * 3600 * 1000)
    }
]);

print("Sample documents inserted successfully.");

// ----------------------------------------------------------------------------
// 5. SAVED AGGREGATION VIEW (db.createView())
// Business Purpose: Real-time operational metric dashboard computing average
//                   dispatch latency and distance per urban zone.
// ----------------------------------------------------------------------------
try {
    db.view_zone_dispatch_metrics.drop();
} catch (e) {}

db.createView(
    "view_zone_dispatch_metrics",
    "dispatch_events",
    [
        {
            $group: {
                _id: "$zone_name",
                total_dispatches: { $sum: 1 },
                avg_pickup_distance_km: { $avg: "$distance_to_pickup_km" },
                avg_dispatch_latency_ms: { $avg: "$dispatch_latency_ms" },
                last_dispatch_at: { $max: "$matched_at" }
            }
        },
        {
            $project: {
                zone_name: "$_id",
                total_dispatches: 1,
                avg_pickup_distance_km: { $round: ["$avg_pickup_distance_km", 2] },
                avg_dispatch_latency_ms: { $round: ["$avg_dispatch_latency_ms", 0] },
                last_dispatch_at: 1,
                _id: 0
            }
        },
        { $sort: { total_dispatches: -1 } }
    ]
);

print("Created MongoDB Saved Aggregation View: view_zone_dispatch_metrics.");
print("==============================================================");
print("MONGODB SETUP FOR RIDESYNC COMPLETED SUCCESSFULLY.");
print("==============================================================");
