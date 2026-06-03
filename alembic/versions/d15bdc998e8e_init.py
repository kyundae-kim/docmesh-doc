"""init

Revision ID: d15bdc998e8e
Revises: 
Create Date: 2026-05-28 21:27:55.967097

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB, UUID


# revision identifiers, used by Alembic.
revision: str = 'd15bdc998e8e'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # documents 테이블 생성
    op.create_table(
        "documents",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("owner_username", sa.String(), nullable=False),
        sa.Column("object_key", sa.Text(), nullable=False, unique=True),
        sa.Column("original_filename", sa.Text(), nullable=False),
        sa.Column("content_type", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index("ix_documents_owner_username", "documents", ["owner_username"])

    # document_metadata 테이블 생성
    op.create_table(
        "document_metadata",
        sa.Column("document_id", UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("owner_username", sa.String(), nullable=False),
        sa.Column("metadata_value", JSONB(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index(
        "ix_document_metadata_owner_username", "document_metadata", ["owner_username"]
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index("ix_document_metadata_owner_username", table_name="document_metadata")
    op.drop_table("document_metadata")

    op.drop_index("ix_documents_owner_username", table_name="documents")
    op.drop_table("documents")
