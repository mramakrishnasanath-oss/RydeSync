"""
RideSync - Custom Domain Exceptions
Domain Layer: exception/custom_exceptions.py
"""


class RideSyncException(Exception):
    """Base exception for all domain errors within RideSync."""
    pass


class DatabaseConnectionError(RideSyncException):
    """Raised when connecting to SQL Server or MongoDB fails."""
    pass


class EntityNotFoundError(RideSyncException):
    """Raised when a requested entity does not exist in the database."""
    pass


class DuplicateEntityError(RideSyncException):
    """Raised when attempting to insert duplicate unique attributes (e.g. phone, plate)."""
    pass


class DriverUnavailableError(RideSyncException):
    """Raised when attempting to match or assign a driver who is not ONLINE."""
    pass


class InvalidTripStateTransitionError(RideSyncException):
    """Raised when an illegal status change is attempted on a Trip."""
    pass


class AtomicDispatchConflictError(RideSyncException):
    """Raised when concurrent dispatch requests attempt to claim the same driver."""
    pass
