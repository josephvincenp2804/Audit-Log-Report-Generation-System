import json
from datetime import datetime, timezone
from typing import Optional, Dict, Any
try:
    from sqlalchemy.orm import Session  # type: ignore
except ImportError:
    Session = Any  # type: ignore
try:
    from ..models import AuditLog, User
except (ImportError, ValueError):
    from app.models import AuditLog, User

class AuditService:
    @staticmethod
    def log_activity(
        db: Session,
        action_type: str,
        table_name: str,
        record_id: str,
        username: str,
        previous_value: Optional[Dict[str, Any]] = None,
        new_value: Optional[Dict[str, Any]] = None,
        ip_address: Optional[str] = "127.0.0.1",
        user_id: Optional[int] = None,
        timestamp: Optional[datetime] = None
    ) -> AuditLog:
        """
        Creates an AuditLog record in the current session.
        Does NOT commit immediately so it participates in the outer caller's transaction.
        """
        if user_id is None and username:
            user = db.query(User).filter(User.username == username).first()
            if user:
                user_id = user.id

        prev_json = json.dumps(previous_value, default=str) if previous_value is not None else None
        new_json = json.dumps(new_value, default=str) if new_value is not None else None

        audit_entry = AuditLog(
            user_id=user_id,
            username=username or "system",
            action_type=action_type.upper(),
            table_name=table_name,
            record_id=str(record_id),
            previous_value=prev_json,
            new_value=new_json,
            ip_address=ip_address,
            timestamp=timestamp or datetime.now(timezone.utc)
        )

        db.add(audit_entry)
        db.flush()  # Ensures audit_id is populated within transaction
        return audit_entry

