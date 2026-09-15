from unittest.mock import patch, MagicMock
from app import app


@patch("app.get_connection")
def test_get_tasks(mock_get_connection):

    mock_conn = MagicMock()
    mock_cursor = MagicMock()

    mock_cursor.fetchall.return_value = [
        (1, "Learn Terraform"),
        (2, "Learn GitHub Actions")
    ]

    mock_conn.cursor.return_value = mock_cursor
    mock_get_connection.return_value = mock_conn

    client = app.test_client()

    response = client.get("/api/tasks")

    assert response.status_code == 200

    assert response.json == [
        {
            "id": 1,
            "title": "Learn Terraform"
        },
        {
            "id": 2,
            "title": "Learn GitHub Actions"
        }
    ]