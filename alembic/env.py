import os
from logging.config import fileConfig

from sqlalchemy import engine_from_config
from sqlalchemy import pool

from alembic import context

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Import Base and models for autogenerate support
from docmesh_doc.models.base import Base
from docmesh_doc.models import metadata  # noqa: F401 (모델 임포트로 Base에 등록)

target_metadata = Base.metadata


def _get_db_url() -> str:
    """환경변수에서 DB URL을 구성한다."""
    host = os.environ.get("DB__HOST", "localhost")
    port = os.environ.get("DB__PORT", "5432")
    name = os.environ.get("DB__NAME", "docmesh")
    user = os.environ.get("DB__USER", "postgres")
    password = os.environ.get("DB__PASSWORD", "postgres")
    return f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{name}"


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url") or _get_db_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    ini_section = config.get_section(config.config_ini_section, {})

    # 환경변수로 sqlalchemy.url 오버라이드
    if not ini_section.get("sqlalchemy.url"):
        ini_section["sqlalchemy.url"] = _get_db_url()

    connectable = engine_from_config(
        ini_section,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
