import json
import pytest
import os
import sys
from fastapi.testclient import TestClient
sys.path.append(os.path.join(os.path.dirname( __file__ ), ".."))
from main import app

client = TestClient(app)

@pytest.mark.parametrize("id", [i + 1 for i in range(5)])
def test_model(id):
    with open(f"test/{id}.json") as file_in:
        with open(f"test/{id}.expected.json") as file_out:
            response = client.post("/predict", json=json.load(file_in))
            assert response.status_code == 200
            assert response.json() == json.load(file_out)