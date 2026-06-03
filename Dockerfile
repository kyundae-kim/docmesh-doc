FROM python:3.10-slim

WORKDIR /app

RUN apt update && apt install -y curl git
RUN pip install uv

COPY pyproject.toml uv.lock* /app/
RUN uv sync --no-dev

COPY . /app
RUN uv pip install -e .

EXPOSE 8000

CMD ["uv", "run", "python", "-m", "fastapi", "dev", "--host", "0.0.0.0"]
