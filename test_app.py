import unittest
import json
from app import app  # Import spécifique de l'app Flask

class TestTranslationAPI(unittest.TestCase):
    
    def setUp(self):
        """Configuration avant chaque test"""
        self.app = app
        self.app.config['TESTING'] = True
        self.client = self.app.test_client()
    
    def tearDown(self):
        """Nettoyage après chaque test"""
        pass
    
    def test_health_endpoint(self):
        """Test du endpoint /health"""
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'healthy')
        self.assertIn('timestamp', data)
        self.assertIn('redis_connected', data)
    
    def test_home_endpoint(self):
        """Test du endpoint racine /"""
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.data)
        self.assertEqual(data['message'], '🚀 Translation API is running!')
        self.assertEqual(data['version'], '2.0.0')
        self.assertIn('features', data)
        self.assertIn('endpoints', data)
    
    def test_translate_endpoint_success(self):
        """Test du endpoint /translate avec succès"""
        test_data = {
            'text': 'hello world',
            'target_lang': 'fr'
        }
        
        response = self.client.post(
            '/translate',
            data=json.dumps(test_data),
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.data)
        self.assertIn('translated_text', data)
        self.assertIn('cached', data)
        self.assertIn('trace_id', data)
        # Vérifier que la traduction n'est pas vide
        self.assertTrue(len(data['translated_text']) > 0)
    
    def test_translate_endpoint_no_text(self):
        """Test /translate sans texte (erreur attendue)"""
        test_data = {
            'target_lang': 'fr'
        }
        
        response = self.client.post(
            '/translate',
            data=json.dumps(test_data),
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 400)
        
        data = json.loads(response.data)
        self.assertIn('error', data)
        self.assertEqual(data['error'], 'Text is required')
    
    def test_translate_endpoint_empty_text(self):
        """Test /translate avec texte vide"""
        test_data = {
            'text': '',
            'target_lang': 'fr'
        }
        
        response = self.client.post(
            '/translate',
            data=json.dumps(test_data),
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 400)
        
        data = json.loads(response.data)
        self.assertIn('error', data)
    
    def test_translate_endpoint_no_json(self):
        """Test /translate sans données JSON"""
        response = self.client.post(
            '/translate',
            data='not json',
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 400)
        
        data = json.loads(response.data)
        self.assertIn('error', data)
    
    def test_metrics_endpoint(self):
        """Test du endpoint /metrics"""
        response = self.client.get('/metrics')
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.data)
        self.assertIn('total_requests', data)
        self.assertIn('cache_hits', data)
        self.assertIn('cache_hit_rate', data)
        self.assertIn('redis_connected', data)
        self.assertIn('prometheus_metrics', data)
    
    def test_prometheus_metrics_endpoint(self):
        """Test du endpoint /metrics/prometheus"""
        response = self.client.get('/metrics/prometheus')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.content_type, 'text/plain; charset=utf-8')
        
        # Vérifier que ça contient des métriques Prometheus
        content = response.data.decode('utf-8')
        self.assertIn('http_requests_total', content)
        self.assertIn('# HELP', content)
    
    def test_detailed_metrics_endpoint(self):
        """Test du endpoint /metrics/detailed"""
        response = self.client.get('/metrics/detailed')
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.data)
        self.assertIn('application_metrics', data)
        self.assertIn('prometheus_endpoint', data)
        self.assertIn('health_endpoint', data)
    
    def test_invalid_endpoint(self):
        """Test d'un endpoint inexistant"""
        response = self.client.get('/nonexistent')
        self.assertEqual(response.status_code, 404)

if __name__ == '__main__':
    unittest.main(verbosity=2)