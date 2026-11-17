"""
RideSync - Rating Entity Model
Domain Layer: entity/rating.py
Represents a rider's review and satisfaction score for a completed trip.
"""
from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class Rating:
    """
    Rating Domain Entity
    Corresponds to SQL Server table dbo.Ratings
    """
    rating_id: Optional[int]
    trip_id: int
    stars: int
    comment: Optional[str] = None
    created_at: Optional[datetime] = None

    def __post_init__(self):
        if not (1 <= self.stars <= 5):
            raise ValueError(f"Stars must be between 1 and 5 (got {self.stars}).")

    def __repr__(self) -> str:
        return f"<Rating ID={self.rating_id} TripID={self.trip_id} Stars={self.stars} Comment='{self.comment}'>"
