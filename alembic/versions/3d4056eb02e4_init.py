"""init document metadata schema

Revision ID: 3d4056eb02e4
Revises:
Create Date: 2026-06-19 08:26:43.236097

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "3d4056eb02e4"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        "document_metadata",
        sa.Column("document_id", sa.String(length=255), nullable=False),
        sa.Column("original_filename", sa.String(length=1024), nullable=False),
        sa.Column("content_type", sa.String(length=255), nullable=False),
        sa.Column("file_size", sa.Integer(), nullable=False),
        sa.Column("storage_key", sa.String(length=2048), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("checksum", sa.String(length=128), nullable=True),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_by", sa.String(length=255), nullable=True),
        sa.Column("extra_metadata", sa.JSON(), nullable=False),
        sa.PrimaryKeyConstraint("document_id"),
    )
    op.create_index(
        "ix_document_metadata_storage_key",
        "document_metadata",
        ["storage_key"],
        unique=False,
    )
    op.create_index(
        "ix_document_metadata_status",
        "document_metadata",
        ["status"],
        unique=False,
    )
    op.create_index(
        "ix_document_metadata_created_at",
        "document_metadata",
        ["created_at"],
        unique=False,
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index("ix_document_metadata_created_at", table_name="document_metadata")
    op.drop_index("ix_document_metadata_status", table_name="document_metadata")
    op.drop_index("ix_document_metadata_storage_key", table_name="document_metadata")
    op.drop_table("document_metadata")
