"""
RideSync - Database Connection Manager
Utility Layer: util/db_connection.py
Provides robust, context-managed connections to Microsoft SQL Server 2025 and MongoDB 8.0.
"""
import os
from contextlib import contextmanager
from typing import Generator, Any
from exception.custom_exceptions import DatabaseConnectionError

try:
    import pyodbc
except ImportError:
    pyodbc = None

try:
    import pymongo
except ImportError:
    pymongo = None


class DBConnection:
    """
    Singleton connection provider for SQL Server and MongoDB.
    """
    # SQL Server configuration
    SQL_SERVER = os.getenv("RIDESYNC_SQL_SERVER", r".\SQLEXPRESS")
    SQL_DATABASE = os.getenv("RIDESYNC_SQL_DATABASE", "RideSyncDB")
    SQL_DRIVER = os.getenv("RIDESYNC_SQL_DRIVER", "ODBC Driver 18 for SQL Server")
    SQL_TRUSTED = os.getenv("RIDESYNC_SQL_TRUSTED", "yes")

    # MongoDB configuration
    MONGO_URI = os.getenv("RIDESYNC_MONGO_URI", "mongodb://localhost:27017/")
    MONGO_DATABASE = os.getenv("RIDESYNC_MONGO_DATABASE", "ridesync_events")

    @classmethod
    def get_sql_connection_string(cls) -> str:
        """Builds ODBC connection string for SQL Server."""
        return (
            f"DRIVER={{{cls.SQL_DRIVER}}};"
            f"SERVER={cls.SQL_SERVER};"
            f"DATABASE={cls.SQL_DATABASE};"
            f"Trusted_Connection={cls.SQL_TRUSTED};"
            f"TrustServerCertificate=yes;"
        )

    @classmethod
    def get_sql_connection(cls):
        """Creates and returns a raw pyodbc connection."""
        if pyodbc is None:
            raise DatabaseConnectionError("pyodbc package is not installed. Run: pip install pyodbc")
        try:
            conn_str = cls.get_sql_connection_string()
            return pyodbc.connect(conn_str)
        except Exception as e:
            raise DatabaseConnectionError(f"Failed to connect to SQL Server ({cls.SQL_SERVER}): {e}") from e

    @classmethod
    @contextmanager
    def get_sql_cursor(cls) -> Generator[Any, None, None]:
        """
        Context manager for SQL operations with automatic transaction commit/rollback.
        Usage:
            with DBConnection.get_sql_cursor() as cursor:
                cursor.execute("SELECT * FROM dbo.Riders")
        """
        conn = cls.get_sql_connection()
        cursor = conn.cursor()
        try:
            yield cursor
            conn.commit()
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            cursor.close()
            conn.close()

    @classmethod
    def get_mongo_db(cls):
        """Returns MongoDB database handle."""
        if pymongo is None:
            raise DatabaseConnectionError("pymongo package is not installed. Run: pip install pymongo")
        try:
            client = pymongo.MongoClient(cls.MONGO_URI, serverSelectionTimeoutMS=3000)
            return client[cls.MONGO_DATABASE]
        except Exception as e:
            raise DatabaseConnectionError(f"Failed to connect to MongoDB ({cls.MONGO_URI}): {e}") from e
