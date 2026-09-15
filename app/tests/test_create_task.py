from unittest.mock import patch, MagicMock
from app import app


@patch("app.get_connection")
def test_create_task(mock_get_connection):

    mock_conn = MagicMock()
    mock_cursor = MagicMock()

    mock_conn.cursor.return_value = mock_cursor
    mock_get_connection.return_value = mock_conn

    client = app.test_client()

    response = client.post(
        "/api/tasks",
        json={
            "title": "Deploy to AWS"
        }
    )

    assert response.status_code == 200
    assert response.json["status"] == "created"

    mock_cursor.execute.assert_called_once()

    mock_conn.commit.assert_called_once()