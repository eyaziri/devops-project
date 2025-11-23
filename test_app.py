import unittest
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from app import TranslationService

class TestTranslationAPI(unittest.TestCase):
    
    def test_translation_service_mock(self):
        result = TranslationService.mock_translation('hello', 'fr')
        self.assertEqual(result, 'bonjour')
        
    def test_translation_service_spanish(self):
        result = TranslationService.mock_translation('hello', 'es')
        self.assertEqual(result, 'hola')
        
    def test_translation_cache_key(self):
        key = TranslationService.get_cache_key('test', 'fr')
        self.assertIn('translation:fr:', key)

if __name__ == '__main__':
    unittest.main()