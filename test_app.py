import unittest
import app

class TestTranslationAPI(unittest.TestCase):
    
    def test_health_endpoint(self):
        with app.app.test_client() as client:
            response = client.get('/health')
            self.assertEqual(response.status_code, 200)
            self.assertIn(b'healthy', response.data)

if __name__ == '__main__':
    unittest.main()