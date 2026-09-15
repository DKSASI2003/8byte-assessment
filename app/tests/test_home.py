from app.app import main

def test_home():

    client = main.test_client()

    response = client.get("/")

    assert response.status_code == 200

    assert "message" in response.json