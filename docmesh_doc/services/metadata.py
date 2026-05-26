from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from fastapi_core.core.config import DatabaseConfig
from sqlalchemy import JSON, DateTime, String, create_engine, select
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column
from sqlalchemy.sql import func


@dataclass(slots=True)
class MetadataRecord:
    document_id: UUID
    metadata_value: dict
    created_at: datetime
    updated_at: datetime


class MetadataConflictError(Exception):
    pass


class Base(DeclarativeBase):
    pass


class DocumentMetadataModel(Base):
    __tablename__ = "document_metadata"

    document_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    owner_username: Mapped[str] = mapped_column(String, nullable=False, index=True)
    metadata_value: Mapped[dict] = mapped_column(JSON, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )


class MetadataService:
    def __init__(self, db_config: DatabaseConfig) -> None:
        self._engine = create_engine(
            db_config.sqlalchemy_database_url,
            echo=db_config.echo,
            future=True,
        )
        Base.metadata.create_all(self._engine)

    def _normalize_username(self, username: str) -> str:
        normalized_username = username.strip().strip("/")
        if not normalized_username:
            raise ValueError("username must not be empty")
        return normalized_username

    @staticmethod
    def _to_record(model: DocumentMetadataModel) -> MetadataRecord:
        return MetadataRecord(
            document_id=model.document_id,
            metadata_value=model.metadata_value,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    def create(self, *, username: str, document_id: UUID, metadata_value: dict) -> MetadataRecord:
        normalized_username = self._normalize_username(username)

        model = DocumentMetadataModel(
            document_id=document_id,
            owner_username=normalized_username,
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
