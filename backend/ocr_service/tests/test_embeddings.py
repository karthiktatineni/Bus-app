import asyncio
import json

import httpx
import pytest
from fastapi import HTTPException

import main


def test_create_embedding_uses_supported_model_and_query_type():
    captured = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured.update(json.loads(request.content))
        return httpx.Response(
            200,
            json={"data": [{"embedding": [0.1] * 2048}]},
        )

    async def run():
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await main.create_embedding(client, "bus brakes", "test-key")

    vector = asyncio.run(run())
    assert len(vector) == 2048
    assert captured["model"] == "nvidia/nemotron-3-embed-1b"
    assert captured["input_type"] == "query"


def test_create_embedding_translates_retired_endpoint_410():
    def handler(_: httpx.Request) -> httpx.Response:
        return httpx.Response(410, json={"detail": "retired"})

    async def run():
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            await main.create_embedding(client, "bus brakes", "test-key")

    with pytest.raises(HTTPException) as exc:
        asyncio.run(run())
    assert exc.value.status_code == 502
    assert "retired" in exc.value.detail


def test_create_embedding_rejects_unexpected_vector_dimensions():
    def handler(_: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"data": [{"embedding": [0.1] * 1024}]})

    async def run():
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            await main.create_embedding(client, "bus brakes", "test-key")

    with pytest.raises(HTTPException) as exc:
        asyncio.run(run())
    assert exc.value.status_code == 502
    assert "invalid embedding" in exc.value.detail
