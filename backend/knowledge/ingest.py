"""Chunk local Markdown/text maintenance references into the tenant-safe RAG corpus."""

import argparse
import os
from pathlib import Path

import requests
from dotenv import load_dotenv

load_dotenv(override=False)


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


def embed(text: str, key: str) -> list[float]:
    response = requests.post(
        "https://integrate.api.nvidia.com/v1/embeddings",
        headers={"Authorization": f"Bearer {key}"},
        json={"model": "baai/bge-m3", "input": text, "encoding_format": "float"},
        timeout=60,
    )
    response.raise_for_status()
    return response.json()["data"][0]["embedding"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("corpus", type=Path, help="Folder containing authorized .md or .txt manuals")
    args = parser.parse_args()
    base_url = os.environ["SUPABASE_URL"].rstrip("/")
    service_key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    nvidia_key = os.environ["NVIDIA_NIM_API_KEY"]
    company_id = os.getenv("FLEET_KNOWLEDGE_COMPANY_ID") or None
    headers = {"apikey": service_key, "Authorization": f"Bearer {service_key}", "Content-Type": "application/json"}

    files = sorted(path for path in args.corpus.rglob("*") if path.suffix.lower() in {".md", ".txt"})
    if not files:
        raise SystemExit("No Markdown or text manuals found. Add an authorized corpus before ingestion.")
    total = 0
    for path in files:
        source = path.relative_to(args.corpus).as_posix()
        for section in chunks(path.read_text(encoding="utf-8")):
            vector = embed(section, nvidia_key)
            response = requests.post(
                f"{base_url}/rest/v1/rpc/rpc_ingest_fleet_knowledge",
                headers=headers,
                json={"p_company_id": company_id, "p_source_name": source, "p_chunk_text": section, "p_embedding": str(vector)},
                timeout=30,
            )
            response.raise_for_status()
            total += 1
    print(f"Ingested {total} chunks from {len(files)} files.")


if __name__ == "__main__":
    main()
