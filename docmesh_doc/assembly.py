from __future__ import annotations

from dataclasses import dataclass
from typing import Callable

from dms.infrastructure.metadata.postgres import PostgresMetadataStore
from dms.infrastructure.metadata.sqlite import SqliteMetadataStore
from dms.infrastructure.storage.minio import MinioObjectStore
from dms.sdk import DocumentManagementSDK, create_sdk
from fastapi import FastAPI
from fastapi_core import EnvConfig

from .auth_adapter import FastapiCoreAuthAdapter


@dataclass(frozen=True)
class DmsAssembly:
    sdk: DocumentManagementSDK


SdkFactory = Callable[[FastAPI, EnvConfig], DocumentManagementSDK]


def build_dms_sdk(app: FastAPI, config: EnvConfig) -> DocumentManagementSDK:
    engine = app.state.db_engine
    minio_client = app.state.minio_client
    auth_provider = getattr(app.state, "auth_provider", None)

    database_url = getattr(config.db, "url", None) or ""
    if database_url.startswith("sqlite"):
        metadata_store = SqliteMetadataStore(engine)
    else:
        metadata_store = PostgresMetadataStore(engine)

    object_store = MinioObjectStore(client=minio_client, bucket_name=config.minio.bucket)
    auth_service = FastapiCoreAuthAdapter(auth_provider) if auth_provider else None

    return create_sdk(
        metadata_store=metadata_store,
        object_store=object_store,
        auth_service=auth_service,
    )
