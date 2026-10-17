import asyncio
import io
import shutil
from pathlib import Path

import pytest

import httpx
from PIL import Image, ImageDraw, ImageFont

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
            "Date: 17/10/2026\n"
            "Brake pad replacement 1 8,450.00\n"
            "Labour charge 1 4,000.00\nGrand Total Rs. 12,450.00"
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
    assert payload["items"] == [
        {"name": "Brake pad replacement", "quantity": 1, "total": 8450.0},
        {"name": "Labour charge", "quantity": 1, "total": 4000.0},
    ]


def test_real_tesseract_reads_synthetic_invoice_through_scan_endpoint(monkeypatch):
    tesseract = shutil.which("tesseract")
    if not tesseract:
        candidate = Path(r"C:\Program Files\Tesseract-OCR\tesseract.exe")
        if candidate.is_file():
            tesseract = str(candidate)
    if not tesseract:
        pytest.skip("Tesseract is not installed on this test host.")

    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setenv("SUPABASE_ANON_KEY", "public-test-key")
    monkeypatch.setattr(main.app.state, "redis", None)
    monkeypatch.setattr(main.pytesseract.pytesseract, "tesseract_cmd", tesseract)

    async def verify_user(_client, _url, _key, _token):
        return {"id": "local-ocr-integration-user"}

    monkeypatch.setattr(main, "verify_supabase_user", verify_user)
    image = Image.new("RGB", (1600, 2000), "white")
    draw = ImageDraw.Draw(image)
    font_path = Path(r"C:\Windows\Fonts\arial.ttf")
    if not font_path.is_file():
        font_path = Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
    font = ImageFont.truetype(str(font_path), 52) if font_path.is_file() else ImageFont.load_default()
    small = ImageFont.truetype(str(font_path), 42) if font_path.is_file() else font
    invoice_lines = [
        (100, "NORTHSIDE BUS WORKSHOP", font),
        (220, "TAX INVOICE", font),
        (330, "Invoice No: INV-2026-048", small),
        (410, "Date: 17/10/2026", small),
        (620, "Description             Qty      Amount", small),
        (730, "Brake pad replacement    1       8,450.00", small),
        (820, "Labour charge            1       4,000.00", small),
        (1100, "Grand Total Rs. 12,450.00", font),
    ]
    for y, text, face in invoice_lines:
        draw.text((100, y), text, fill="black", font=face)
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=95)

    async def run_request():
        transport = httpx.ASGITransport(app=main.app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            return await client.post(
                "/ocr/scan-bill",
                headers={"Authorization": "Bearer local-ocr-test-token"},
                files={"file": ("synthetic-invoice.jpg", buffer.getvalue(), "image/jpeg")},
            )

    response = asyncio.run(run_request())
    assert response.status_code == 200, response.text
    payload = response.json()
    assert payload["vendor"] == "NORTHSIDE BUS WORKSHOP", payload
    assert payload["invoice_number"] == "INV-2026-048", payload
    assert payload["bill_date"] == "2026-10-17", payload
    assert payload["grand_total"] == 12450.0, payload
    assert payload["items"] == [
        {"name": "Brake pad replacement", "quantity": 1, "total": 8450.0},
        {"name": "Labour charge", "quantity": 1, "total": 4000.0},
    ], payload


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


def test_bill_ocr_retries_sparse_receipt_layout_when_first_pass_finds_no_text(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setenv("SUPABASE_ANON_KEY", "public-test-key")
    monkeypatch.setattr(main.app.state, "redis", None)

    async def verify_user(_client, _url, _key, _token):
        return {"id": "test-user"}

    calls = []

    def recognize(_image, *, config, timeout):
        calls.append(config)
        if len(calls) == 1:
            return ""
        return "Workshop Invoice\nInvoice No: RCP-2801\nGrand Total Rs. 2,850.00"

    monkeypatch.setattr(main, "verify_supabase_user", verify_user)
    monkeypatch.setattr(main.pytesseract, "image_to_string", recognize)
    image_buffer = io.BytesIO()
    Image.new("RGB", (80, 80), "white").save(image_buffer, format="JPEG")

    async def run_request():
        transport = httpx.ASGITransport(app=main.app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            return await client.post(
                "/ocr/scan-bill",
                headers={"Authorization": "Bearer signed-in-test-token"},
                files={"file": ("invoice.jpg", image_buffer.getvalue(), "image/jpeg")},
            )

    response = asyncio.run(run_request())

    assert response.status_code == 200
    assert response.json()["grand_total"] == 2850.0
    assert calls == ["--oem 3 --psm 6", "--oem 3 --psm 11"]


def test_bill_ocr_tries_alternate_invoice_layout_before_rejecting(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setenv("SUPABASE_ANON_KEY", "public-test-key")
    monkeypatch.setattr(main.app.state, "redis", None)

    async def verify_user(_client, _url, _key, _token):
        return {"id": "test-user"}

    calls = []

    def recognize(_image, *, config, timeout):
        calls.append((config, timeout))
        if config == "--oem 3 --psm 4":
            return "Invoice\nWorkshop: Westside Fleet\nGrand Total Rs. 3,250.00"
        return ""

    monkeypatch.setattr(main, "verify_supabase_user", verify_user)
    monkeypatch.setattr(main.pytesseract, "image_to_string", recognize)
    image_buffer = io.BytesIO()
    Image.new("RGB", (120, 160), "white").save(image_buffer, format="JPEG")

    async def run_request():
        transport = httpx.ASGITransport(app=main.app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            return await client.post(
                "/ocr/scan-bill",
                headers={"Authorization": "Bearer signed-in-test-token"},
                files={"file": ("invoice.jpg", image_buffer.getvalue(), "image/jpeg")},
            )

    response = asyncio.run(run_request())

    assert response.status_code == 200
    assert response.json()["grand_total"] == 3250.0
    assert calls == [
        ("--oem 3 --psm 6", 8),
        ("--oem 3 --psm 11", 8),
        ("--oem 3 --psm 4", 8),
    ]


def test_bill_ocr_reports_engine_timeout_as_408_not_unreadable_image(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setenv("SUPABASE_ANON_KEY", "public-test-key")
    monkeypatch.setattr(main.app.state, "redis", None)

    async def verify_user(_client, _url, _key, _token):
        return {"id": "test-user"}

    def timeout(_image, *, config, timeout):
        raise RuntimeError("Tesseract process timeout")

    monkeypatch.setattr(main, "verify_supabase_user", verify_user)
    monkeypatch.setattr(main.pytesseract, "image_to_string", timeout)
    image_buffer = io.BytesIO()
    Image.new("RGB", (120, 160), "white").save(image_buffer, format="JPEG")

    async def run_request():
        transport = httpx.ASGITransport(app=main.app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            return await client.post(
                "/ocr/scan-bill",
                headers={"Authorization": "Bearer signed-in-test-token"},
                files={"file": ("invoice.jpg", image_buffer.getvalue(), "image/jpeg")},
            )

    response = asyncio.run(run_request())

    assert response.status_code == 408
    assert "timed out" in response.json()["detail"].lower()


def test_bill_ocr_returns_actionable_error_for_missing_multipart_file(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setenv("SUPABASE_ANON_KEY", "public-test-key")

    async def verify_user(_client, _url, _key, _token):
        return {"id": "test-user"}

    monkeypatch.setattr(main, "verify_supabase_user", verify_user)

    async def run_request():
        transport = httpx.ASGITransport(app=main.app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            return await client.post(
                "/ocr/scan-bill",
                headers={"Authorization": "Bearer signed-in-test-token"},
                data={"image": "wrong-field-name"},
            )

    response = asyncio.run(run_request())

    assert response.status_code == 400
    assert "multipart 'file' field" in response.json()["detail"]
