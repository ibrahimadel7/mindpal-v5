from __future__ import annotations

import unittest

from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api.routes import router as api_router


class RootRouteTests(unittest.TestCase):
    def test_root_returns_ok_status(self) -> None:
        app = FastAPI()
        app.include_router(api_router)
        client = TestClient(app)

        response = client.get("/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok"})


if __name__ == "__main__":
    unittest.main()
