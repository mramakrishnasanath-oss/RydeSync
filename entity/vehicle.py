"""
RideSync - Vehicle Entity Model
Domain Layer: entity/vehicle.py
Represents a physical motor vehicle registered in the UrbanGo Mobility fleet.
"""
from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class Vehicle:
    """
    Vehicle Domain Entity
    Corresponds to SQL Server table dbo.Vehicles
    """
    vehicle_id: Optional[int]
    plate_number: str
    model: str
    registered_at: Optional[datetime] = None

    def __post_init__(self):
        if not self.plate_number or not self.plate_number.strip():
            raise ValueError("Vehicle plate_number cannot be empty.")
        if not self.model or not self.model.strip():
            raise ValueError("Vehicle model cannot be empty.")
        self.plate_number = self.plate_number.strip().upper()

    def __repr__(self) -> str:
        return f"<Vehicle ID={self.vehicle_id} Plate='{self.plate_number}' Model='{self.model}'>"
