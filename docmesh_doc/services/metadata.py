from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from fastapi_core.core.config import DatabaseConfig
from fastapi_core.core.database import create_db_engine
from sqlalchemy import inspect, select, text
from sqlalchemy.engine import Engine
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from docmesh_doc.models.base import Base
from docmesh_doc.models.metadata import DocumentMetadataModel


@dataclass(slots=True)
class MetadataRecord:
    document_id: UUID
    filename: str
    uploaded_by: str
    metadata_value: dict
    created_at: datetime
    updated_at: datetime


class MetadataConflictError(Exception):
    pass


class MetadataService:
    def __init__(
        self,
        db_config: DatabaseConfig | None = None,
        *,
        engine: Engine | None = None,
    ) -> None:
        if engine is None:
            if db_config is None:
                raise ValueError("db_config or engine must be provided")
            engine = create_db_engine(db_config)

        self._engine = engine
        Base.metadata.create_all(self._engine)
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        inspector = inspect(self._engine)
        try:
            columns = {column["name"] for column in inspector.get_columns("document_metadata")}
        except Exception:
            return

        if "filename" not in columns:
            with self._engine.begin() as conn:
                conn.execute(
                    text(
                        "ALTER TABLE document_metadata "
                        "ADD COLUMN filename TEXT NOT NULL DEFAULT ''"
                    )
                )

    def _normalize_username(self, username: str) -> str:
        normalized_username = username.strip().strip("/")
        if not normalized_username:
            raise ValueError("username must not be empty")
        return normalized_username

    @staticmethod
    def _to_record(model: DocumentMetadataModel) -> MetadataRecord:
        return MetadataRecord(
            document_id=model.document_id,
            filename=model.filename,
            uploaded_by=model.owner_username,
            metadata_value=model.metadata_value,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    def create(
        self,
        *,
        username: str,
        document_id: UUID,
        filename: str,
        metadata_value: dict,
    ) -> MetadataRecord:
        normalized_username = self._normalize_username(username)

        model = DocumentMetadataModel(
            document_id=document_id,
            owner_username=normalized_username,
            filename=filename,
            metadata_value=metadata_value,
        )

        with Session(self._engine) as session:
            session.add(model)
            try:
                session.commit()
            except IntegrityError as exc:
                session.rollback()
                raise MetadataConflictError("Metadata already exists") from exc
            session.refresh(model)
            return self._to_record(model)

    def get(self, *, username: str, document_id: UUID) -> MetadataRecord | None:
        normalized_username = self._normalize_username(username)

        with Session(self._engine) as session:
            stmt = select(DocumentMetadataModel).where(
                DocumentMetadataModel.owner_username == normalized_username,
                DocumentMetadataModel.document_id == document_id,
            )
            model = session.scalar(stmt)
            if model is None:
                return None
            return self._to_record(model)

    def update(self, *, username: str, document_id: UUID, metadata_value: dict) -> MetadataRecord | None:
        normalized_username = self._normalize_username(username)

        with Session(self._engine) as session:
            stmt = select(DocumentMetadataModel).where(
                DocumentMetadataModel.owner_username == normalized_username,
                DocumentMetadataModel.document_id == document_id,
            )
            model = session.scalar(stmt)
            if model is None:
                return None

            model.metadata_value = metadata_value
            session.commit()
            session.refresh(model)
            return self._to_record(model)

    def delete(self, *, username: str, document_id: UUID) -> bool:
        normalized_username = self._normalize_username(username)

        with Session(self._engine) as session:
            stmt = select(DocumentMetadataModel).where(
                DocumentMetadataModel.owner_username == normalized_username,
                DocumentMetadataModel.document_id == document_id,
            )
            model = session.scalar(stmt)
            if model is None:
                return False

            session.delete(model)
            session.commit()
            return True
