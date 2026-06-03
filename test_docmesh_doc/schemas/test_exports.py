from docmesh_doc import schemas


def test_health_schema_is_not_exported_from_docmesh_doc_schemas():
    assert not hasattr(schemas, "HealthCheckResponse")
