from app.app import app
def test_home():

    client = app.test_client()

    response = client.get("/")

    assert response.status_code == 200

    assert response.mimetype == "text/html"
    assert b"8Byte Task Manager" in response.data