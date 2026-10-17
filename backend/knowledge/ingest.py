"""Chunk local Markdown/text maintenance references into the tenant-safe RAG corpus."""

import argparse
import json
import os
from pathlib import Path

import requests
from dotenv import load_dotenv
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

load_dotenv(override=False)
EMBEDDING_MODEL = "nvidia/nemotron-3-embed-1b"
EMBEDDING_DIMENSIONS = 2048


def chunks(text: str, size: int = 1000, overlap: int = 150):
    cleaned = " ".join(text.split())
    start = 0
    while start < len(cleaned):
        end = min(start + size, len(cleaned))
        if end < len(cleaned):
            boundary = cleaned.rfind(" ", start + size // 2, end)
            if boundary > start:
                end = boundary
        section = cleaned[start:end].strip()
        if section:
            yield section
        if end >= len(cleaned):
            break
        start = max(end - overlap, start + 1)


def embed(text: str, key: str, session: requests.Session | None = None) -> list[float]:
    requester = session or requests
    response = requester.post(
        "https://integrate.api.nvidia.com/v1/embeddings",
        headers={"Authorization": f"Bearer {key}"},
        json={
            "model": EMBEDDING_MODEL,
            "input": text,
            "input_type": "passage",
            "encoding_format": "float",
        },
        timeout=60,
    )
    response.raise_for_status()
    vector = response.json()["data"][0]["embedding"]
    if len(vector) != EMBEDDING_DIMENSIONS:
        raise ValueError(
            f"NVIDIA returned {len(vector)} embedding values; expected {EMBEDDING_DIMENSIONS}."
        )
    return vector


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("corpus", type=Path, help="Folder containing authorized .md or .txt manuals")
    args = parser.parse_args()
    base_url = os.environ["SUPABASE_URL"].rstrip("/")
    service_key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    nvidia_key = os.environ["NVIDIA_NIM_API_KEY"]
    company_id = os.getenv("FLEET_KNOWLEDGE_COMPANY_ID") or None
    headers = {
        "apikey": service_key,
        "Authorization": f"Bearer {service_key}",
        "Content-Type": "application/json",
    }
    session = requests.Session()
    session.mount(
        "https://",
        HTTPAdapter(max_retries=Retry(total=3, backoff_factor=1, status_forcelist=(429, 500, 502, 503, 504), allowed_methods=frozenset({"GET", "POST"}))),
    )

    files = sorted(path for path in args.corpus.rglob("*") if path.suffix.lower() in {".md", ".txt"})
    if not files:
        raise SystemExit("No Markdown or text manuals found. Add an authorized corpus before ingestion.")
    total = 0
    for path in files:
        source = path.relative_to(args.corpus).as_posix()
        for section in chunks(path.read_text(encoding="utf-8")):
            try:
                vector = embed(section, nvidia_key, session)
            except requests.HTTPError as exc:
                raise RuntimeError(
                    f"Embedding failed for {source}; no chunk was ingested for this section."
                ) from exc
            response = session.post(
                f"{base_url}/rest/v1/rpc/rpc_ingest_fleet_knowledge",
                headers=headers,
                json={
                    "p_company_id": company_id,
                    "p_source_name": source,
                    "p_chunk_text": section,
                    "p_embedding": json.dumps(vector),
                },
                timeout=30,
            )
            response.raise_for_status()
            total += 1
    print(f"Ingested {total} chunks from {len(files)} files.")


if __name__ == "__main__":
    main()
