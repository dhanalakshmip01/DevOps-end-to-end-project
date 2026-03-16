from datetime import UTC, datetime, timedelta

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Paste


def test_health(client: TestClient) -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_create_paste(client: TestClient) -> None:
    response = client.post(
        "/api/pastes",
        json={"content": "print('hello world')", "language": "python", "expiry": "never"},
    )
    assert response.status_code == 201
    data = response.json()
    assert "short_code" in data
    assert len(data["short_code"]) == 8
    assert data["language"] == "python"
    assert data["view_count"] == 0
    assert data["expires_at"] is None


def test_create_paste_with_title(client: TestClient) -> None:
    response = client.post(
        "/api/pastes",
        json={"title": "My Script", "content": "echo hello", "language": "bash", "expiry": "1d"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "My Script"
    assert data["expires_at"] is not None


def test_get_paste_increments_view_count(client: TestClient) -> None:
    create_resp = client.post(
        "/api/pastes",
        json={"content": "SELECT 1", "language": "sql", "expiry": "never"},
    )
    short_code = create_resp.json()["short_code"]

    r1 = client.get(f"/api/pastes/{short_code}")
    assert r1.status_code == 200
    assert r1.json()["view_count"] == 1

    r2 = client.get(f"/api/pastes/{short_code}")
    assert r2.json()["view_count"] == 2


def test_paste_not_found(client: TestClient) -> None:
    response = client.get("/api/pastes/doesntexist")
    assert response.status_code == 404


def test_delete_paste(client: TestClient) -> None:
    create_resp = client.post(
        "/api/pastes",
        json={"content": "to be deleted", "language": "plaintext", "expiry": "never"},
    )
    short_code = create_resp.json()["short_code"]

    delete_resp = client.delete(f"/api/pastes/{short_code}")
    assert delete_resp.status_code == 204

    get_resp = client.get(f"/api/pastes/{short_code}")
    assert get_resp.status_code == 404


def test_expired_paste_returns_404(client: TestClient) -> None:
    # Create a paste
    create_resp = client.post(
        "/api/pastes",
        json={"content": "this will expire", "language": "plaintext", "expiry": "1h"},
    )
    short_code = create_resp.json()["short_code"]

    # Manually set expires_at to the past via the DB session
    db: Session = next(client.app.dependency_overrides[get_db]())  # type: ignore[attr-defined]
    paste = db.query(Paste).filter(Paste.short_code == short_code).first()
    assert paste is not None
    paste.expires_at = datetime.now(UTC) - timedelta(hours=2)
    db.commit()
    db.close()

    response = client.get(f"/api/pastes/{short_code}")
    assert response.status_code == 404
    assert "expired" in response.json()["detail"].lower()


def test_create_paste_empty_content_fails(client: TestClient) -> None:
    response = client.post(
        "/api/pastes",
        json={"content": "", "language": "plaintext", "expiry": "never"},
    )
    assert response.status_code == 422


def test_create_paste_invalid_language_fails(client: TestClient) -> None:
    response = client.post(
        "/api/pastes",
        json={"content": "some text", "language": "cobol", "expiry": "never"},
    )
    assert response.status_code == 422
