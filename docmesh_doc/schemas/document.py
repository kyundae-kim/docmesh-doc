from pydantic import BaseModel, Field


class DocumentUploadResponse(BaseModel):
    file_path: str = Field(..., description="The file path where the document was uploaded")
