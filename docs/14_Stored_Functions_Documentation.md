# RideSync — Day 9 Stored Functions Documentation

**Document Reference:** `DOC-14-FUNCTIONS`  
**Database:** `RideSyncDB`  
**Day 9 Topic:** User-Defined Functions (Scalar & Table-Valued)  

---

## 1. Summary of Functions

| Function Name | Type | Deterministic? | Return Type | Purpose |
| :--- | :---: | :---: | :--- | :--- |
| `fn_calculate_distance` | Scalar | Yes (`SCHEMABINDING`) | `DECIMAL(10,3)` | Great-circle distance between two GPS coordinates in KM. |
| `fn_estimate_fare` | Scalar | Yes (`SCHEMABINDING`) | `DECIMAL(10,2)` | Pricing formula based on distance and surge factor. |
| `fn_get_nearby_available_drivers` | Inline TVF | No (Queries tables) | `TABLE` | Returns available drivers within a radius, ranked nearest first. |

---

## 2. In-Depth Mathematical Breakdown: Haversine Distance Formula

The great-circle distance between two points on a spherical Earth of radius $R = 6371.0\text{ km}$ is given by:

$$\Delta\text{lat} = \text{lat}_2 - \text{lat}_1, \quad \Delta\text{lon} = \text{lon}_2 - \text{lon}_1$$

$$a = \sin^2\left(\frac{\Delta\text{lat}}{2}\right) + \cos(\text{lat}_1) \cdot \cos(\text{lat}_2) \cdot \sin^2\left(\frac{\Delta\text{lon}}{2}\right)$$

$$c = 2 \cdot \text{atan2}\left(\sqrt{a}, \sqrt{1-a}\right)$$

$$d = R \cdot c$$

In `dbo.fn_calculate_distance`, this formulation is implemented in native T-SQL using `RADIANS()`, `SIN()`, `COS()`, `SQRT()`, and `ATN2()`. Clamping safeguards (`IF @a > 1.0 SET @a = 1.0`) eliminate floating-point precision domain exceptions.

---

## 3. Inline Table-Valued Function (iTVF) vs Multi-Statement TVF (mTVF)

In Day 9 curriculum, understanding the performance difference between Inline TVFs and Multi-Statement TVFs is an evaluated topic:
- **`fn_get_nearby_available_drivers` is an Inline TVF:** It contains a single `RETURN (SELECT ...)` statement without a `BEGIN ... END` block.
- **Why it matters:** SQL Server treats inline TVFs as parameterized views. The query optimizer directly **inlines** the logic into the calling query's execution plan, generating optimal index seeks and accurate cardinality estimates.
- Multi-statement TVFs (mTVFs), by contrast, create hidden internal table variables in `tempdb` with fixed cardinality guesses (often 1 or 100 rows), causing poor execution plans.
