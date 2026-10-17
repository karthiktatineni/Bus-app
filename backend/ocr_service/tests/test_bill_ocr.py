import asyncio
import io

import httpx
from PIL import Image

import main


def test_authenticated_bill_ocr_endpoint_returns_reviewable_fields(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setenv("SUPABASE_ANON_KEY", "public-test-key")
    monkeypatch.setattr(main.app.state, "redis", None)

    async def verify_user(_client, _url, _key, token):
        assert token == "signed-in-test-token"
        return {"id": "test-user"}

    monkeypatch.setattr(main, "verify_supabase_user", verify_user)
    monkeypatch.setattr(
        main.pytesseract,
        "image_to_string",
        lambda *_args, **_kwargs: (
            "Northside Bus Workshop\n"
            "Tax Invoice\nInvoice No: INV-2026-048\n"
            "Date: 17/10/2026\nGrand Total Rs. 12,450.00"
        ),
    )

    image_buffer = io.BytesIO()
    Image.new("RGB", (32, 32), "white").save(image_buffer, format="JPEG")

    async def run_request():
        transport = httpx.ASGITransport(app=main.app)
        async with httpx.AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            return await client.post(
                "/ocr/scan-bill",
                headers={"Authorization": "Bearer signed-in-test-token"},
                files={"file": ("invoice.jpg", image_buffer.getvalue(), "image/jpeg")},
            )

    response = asyncio.run(run_request())

    assert response.status_code == 200
    payload = response.json()
    assert payload["vendor"] == "Northside Bus Workshop"
    assert payload["invoice_number"] == "INV-2026-048"
    assert payload["bill_date"] == "2026-10-17"
    assert payload["grand_total"] == 12450.0
    assert payload["confidence"] == 1.0


def test_bill_ocr_endpoint_rejects_missing_session():
    image_buffer = io.BytesIO()
    Image.new("RGB", (32, 32), "white").save(image_buffer, format="JPEG")

    async def run_request():
        transport = httpx.ASGITransport(app=main.app)
        async with httpx.AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            return await client.post(
                "/ocr/scan-bill",
                files={"file": ("invoice.jpg", image_buffer.getvalue(), "image/jpeg")},
            )

    response = asyncio.run(run_request())
    assert response.status_code == 401
