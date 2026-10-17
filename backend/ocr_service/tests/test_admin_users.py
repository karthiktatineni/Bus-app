import asyncio

import httpx

import main


ADMIN = {"id": "admin-user", "company_id": "company-1", "role": "admin", "status": "active"}


def _request(payload):
    async def run():
        transport = httpx.ASGITransport(app=main.app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            return await client.post(
                "/admin/users",
                headers={"Authorization": "Bearer signed-in-test-token"},
                json=payload,
            )

    return asyncio.run(run())


def _configure_admin(monkeypatch, *, profile=ADMIN):
    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setenv("SUPABASE_ANON_KEY", "public-test-key")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "server-only-test-key")

    async def verify_user(_client, _url, _key, token):
        assert token == "signed-in-test-token"
        return {"id": "admin-user"}

    monkeypatch.setattr(main, "verify_supabase_user", verify_user)
    return profile


def test_admin_create_uses_auth_admin_and_creates_confirmed_company_profile(monkeypatch):
    _configure_admin(monkeypatch)
    calls = []

    async def admin_request(_client, _base, _key, path, method="GET", payload=None, **_kwargs):
        calls.append((path, method, payload))
        if path == "profiles" and method == "GET":
            return [ADMIN]
        if path == "auth/v1/admin/users" and method == "POST":
            return {"id": "new-user"}
        if path == "profiles" and method == "POST":
            return None
        raise AssertionError((path, method))

    monkeypatch.setattr(main, "supabase_admin_request", admin_request)
    response = _request({
        "action": "create",
        "name": "New Staff",
        "email": "staff@example.com",
        "password": "FleetPulseTest!2026",
        "phone": "+91 99999 11111",
        "role": "staff",
    })

    assert response.status_code == 201
    assert response.json() == {"id": "new-user", "status": "active"}
    auth_payload = calls[1][2]
    assert calls[1][:2] == ("auth/v1/admin/users", "POST")
    assert auth_payload["email_confirm"] is True
    assert auth_payload["password"] == "FleetPulseTest!2026"
    assert calls[2][2]["company_id"] == "company-1"
    assert calls[2][2]["status"] == "active"


def test_non_admin_cannot_create_users(monkeypatch):
    staff = {**ADMIN, "role": "staff"}
    _configure_admin(monkeypatch, profile=staff)

    async def admin_request(_client, _base, _key, path, **_kwargs):
        assert path == "profiles"
        return [staff]

    monkeypatch.setattr(main, "supabase_admin_request", admin_request)
    response = _request({
        "action": "create",
        "name": "New Staff",
        "email": "staff@example.com",
        "password": "FleetPulseTest!2026",
        "role": "staff",
    })
    assert response.status_code == 403


def test_admin_delete_transfers_storage_then_deletes_auth_user(monkeypatch):
    _configure_admin(monkeypatch)
    calls = []
    target = {
        "id": "staff-user", "company_id": "company-1", "name": "Staff",
        "email": "staff@example.com", "phone": "", "role": "staff", "status": "active",
    }

    async def admin_request(_client, _base, _key, path, method="GET", payload=None, **_kwargs):
        calls.append((path, method, payload))
        if path == "profiles" and method == "GET":
            return [ADMIN] if len(calls) == 1 else [target]
        return None

    monkeypatch.setattr(main, "supabase_admin_request", admin_request)
    response = _request({"action": "remove", "id": "staff-user"})

    assert response.status_code == 200
    assert response.json() == {"id": "staff-user", "status": "deleted"}
    assert calls[-2][0] == "rpc/rpc_transfer_user_storage_ownership"
    assert calls[-2][2] == {"p_user_id": "staff-user", "p_new_owner_id": "admin-user"}
    assert calls[-1][:2] == ("auth/v1/admin/users/staff-user", "DELETE")


def test_only_active_admin_cannot_demote_themselves(monkeypatch):
    _configure_admin(monkeypatch)
    calls = []
    only_admin = ADMIN

    async def admin_request(_client, _base, _key, path, method="GET", payload=None, params=None, **_kwargs):
        calls.append((path, method, params))
        if path == "profiles" and method == "GET":
            if params and params.get("role") == "eq.admin":
                return [only_admin]
            if len([call for call in calls if call[0] == "profiles"]) == 1:
                return [ADMIN]
            return [only_admin]
        return None

    monkeypatch.setattr(main, "supabase_admin_request", admin_request)
    response = _request({
        "action": "update",
        "id": "admin-user",
        "name": "Admin",
        "email": "admin@example.com",
        "phone": "",
        "role": "staff",
    })

    assert response.status_code == 409
    assert "at least one active administrator" in response.json()["detail"]
    assert not any(path.startswith("auth/v1/admin/users/") for path, _method, _params in calls)
