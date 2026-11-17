# RideSync — MongoDB Operational Event Storage Design

**Document Reference:** `DOC-16-MONGODB`  
**Database:** `ridesync_events`  
**Technology:** MongoDB 8.0 (mongosh / MongoDB Compass)  
**Topic:** Polyglot Persistence, Event Streaming, Schema Validation & Aggregation Views  

---

## 1. Architectural Role of MongoDB in RideSync

While SQL Server 2025 manages ACID master records (Riders, Drivers, Vehicles, Trips, Fares), **MongoDB 8.0** is utilized as a high-velocity event store for:
1. **Continuous Telemetry Streaming:** Active drivers emitting GPS breadcrumbs every 2–3 seconds.
2. **Dispatch Event Telemetry:** Dispatch latency metrics and pickup distance records.
3. **Audit Trails:** Immutable event-sourced logs of trip state transitions.

---

## 2. Collection Schemas & JSON Schema Validation

### 2.1 Collection: `driver_location_events`
Receives high-frequency GPS breadcrumbs.
- **Validation Schema:**
  ```javascript
  {
      bsonType: "object",
      required: ["driver_id", "location", "speed_kmh", "timestamp"],
      properties: {
          driver_id: { bsonType: "int" },
          location: {
              bsonType: "object",
              required: ["type", "coordinates"],
              properties: {
                  type: { enum: ["Point"] },
                  coordinates: {
                      bsonType: "array",
                      minItems: 2,
                      maxItems: 2,
                      items: { bsonType: "double" }
                  }
              }
          },
          speed_kmh: { bsonType: ["double", "int"], minimum: 0, maximum: 250 },
          bearing_degrees: { bsonType: ["double", "int"], minimum: 0, maximum: 360 },
          timestamp: { bsonType: "date" }
      }
  }
  ```
- **Indexes:**
  - `location`: `"2dsphere"` (Enables `$nearSphere` proximity searches).
  - `{ driver_id: 1, timestamp: -1 }`: Fast driver history retrieval.
  - `{ timestamp: 1 }`, `{ expireAfterSeconds: 604800 }`: **TTL index** that automatically purges telemetry older than 7 days, preventing runaway disk consumption.

---

### 2.2 Collection: `dispatch_events`
Captures matching performance metadata for each completed dispatch.
- **Fields:** `trip_id` (int, Unique), `rider_id` (int), `assigned_driver_id` (int), `zone_name` (string), `matched_at` (date), `distance_to_pickup_km` (double), `dispatch_latency_ms` (int).

---

### 2.3 Collection: `ride_activity_logs`
Immutable event stream capturing all lifecycle events: `REQUESTED`, `MATCHED`, `DRIVER_ARRIVED`, `TRIP_STARTED`, `TRIP_COMPLETED`, `TRIP_CANCELLED`.

---

## 3. MongoDB Saved Aggregation View (`db.createView()`)

In Day 9 curriculum, saved views in MongoDB are built using `db.createView()` to expose aggregation pipelines as read-only virtual collections:

```javascript
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
```

### How to Query the View:
```javascript
// Querying the MongoDB view just like a regular collection:
db.view_zone_dispatch_metrics.find();
```
