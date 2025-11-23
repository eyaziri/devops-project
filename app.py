from flask import Flask, request, jsonify
import requests
import redis
import time
import logging
from datetime import datetime, timezone
import os

# Configuration de l'application
app = Flask(__name__)

# Configuration Redis avec gestion d'erreur
try:
    cache = redis.Redis(
        host=os.getenv('REDIS_HOST', 'localhost'),
        port=6379,
        decode_responses=True,
        socket_connect_timeout=5,
        socket_timeout=5
    )
    # Test de connexion
    cache.ping()
    print("✅ Redis connecté avec succès!")
except redis.ConnectionError as e:
    print(f"❌ Erreur Redis: {e}")
    print("💡 Utilisation du cache en mémoire")
    # Fallback: cache en mémoire
    class MemoryCache:
        def __init__(self):
            self._cache = {}
        
        def get(self, key):
            return self._cache.get(key)
        
        def setex(self, key, expire, value):
            self._cache[key] = value
        
        def ping(self):
            return False
        
        def keys(self, pattern):
            return [k for k in self._cache.keys() if pattern in k]
        
        def info(self, section):
            return {'used_memory_human': '0B'}
    
    cache = MemoryCache()

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Métriques
metrics = {
    'total_requests': 0,
    'cache_hits': 0,
    'translation_errors': 0,
    'response_times': []
}

class TraceContext:
    def __init__(self):
        self.trace_id = f"trace_{int(time.time())}"

class TranslationService:
    @staticmethod
    def translate_text(text, target_lang='fr'):
        """Service de traduction avec fallback"""
        try:
            # Essayer MyMemory API
            response = requests.get(
                'https://api.mymemory.translated.net/get',
                params={
                    'q': text,
                    'langpair': f'en|{target_lang}'
                },
                timeout=5
            )
            
            if response.status_code == 200:
                result = response.json()
                translated = result['responseData']['translatedText']
                
                if translated and "PLEASE SELECT" not in translated:
                    return translated
            
            # Fallback vers le mock
            return TranslationService.mock_translation(text, target_lang)
                
        except Exception as e:
            logger.warning(f"Translation service down, using mock: {str(e)}")
            return TranslationService.mock_translation(text, target_lang)
    
    @staticmethod
    def mock_translation(text, target_lang):
        """Traduction mock pour les tests"""
        mock_translations = {
            'hello world': {'fr': 'bonjour le monde', 'es': 'hola mundo', 'de': 'hallo welt'},
            'hello': {'fr': 'bonjour', 'es': 'hola', 'de': 'hallo'},
            'good morning': {'fr': 'bonjour', 'es': 'buenos días', 'de': 'guten morgen'},
            'i love programming': {'fr': "j'adore programmer", 'es': 'me encanta programar', 'de': 'ich liebe Programmierung'},
            'thank you': {'fr': 'merci', 'es': 'gracias', 'de': 'danke'},
            'how are you': {'fr': 'comment ça va', 'es': 'cómo estás', 'de': 'wie geht es dir'},
            'goodbye': {'fr': 'au revoir', 'es': 'adiós', 'de': 'auf wiedersehen'}
        }
        
        text_lower = text.lower().strip()
        if text_lower in mock_translations and target_lang in mock_translations[text_lower]:
            return mock_translations[text_lower][target_lang]
        else:
            return f"[TEST] {text} → {target_lang}"

    @staticmethod
    def get_cache_key(text, target_lang):
        return f"translation:{target_lang}:{hash(text)}"

# Middleware
@app.before_request
def before_request():
    request.start_time = time.time()
    request.trace_ctx = TraceContext()
    logger.info(f"Request: {request.method} {request.path}")

@app.after_request
def after_request(response):
    response_time = time.time() - request.start_time
    metrics['response_times'].append(response_time)
    if len(metrics['response_times']) > 100:  # Garder seulement les 100 dernières
        metrics['response_times'].pop(0)
    return response

# Routes
@app.route('/translate', methods=['POST'])
def translate_text():
    metrics['total_requests'] += 1
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
            
        text = data.get('text', '').strip()
        target_lang = data.get('target_lang', 'fr')
        
        if not text:
            return jsonify({'error': 'Text is required'}), 400
        
        # Vérifier le cache
        cache_key = TranslationService.get_cache_key(text, target_lang)
        cached_result = cache.get(cache_key)
        
        if cached_result:
            metrics['cache_hits'] += 1
            logger.info(f"Cache hit: {text[:30]}...")
            return jsonify({
                'translated_text': cached_result,
                'cached': True,
                'trace_id': request.trace_ctx.trace_id
            })
        
        # Traduction
        translated = TranslationService.translate_text(text, target_lang)
        
        if translated:
            cache.setex(cache_key, 3600, translated)  # Cache 1 heure
            logger.info(f"New translation: {text[:30]}... → {translated[:30]}...")
            
            return jsonify({
                'translated_text': translated,
                'cached': False,
                'trace_id': request.trace_ctx.trace_id
            })
        else:
            metrics['translation_errors'] += 1
            return jsonify({'error': 'Translation failed'}), 500
            
    except Exception as e:
        metrics['translation_errors'] += 1
        logger.error(f"Error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/metrics')
def get_metrics():
    """Endpoint pour les métriques"""
    recent_times = metrics['response_times'][-10:]  # 10 dernières requêtes
    avg_time = sum(recent_times)/len(recent_times) if recent_times else 0
    cache_rate = metrics['cache_hits'] / metrics['total_requests'] if metrics['total_requests'] > 0 else 0
    
    return jsonify({
        'total_requests': metrics['total_requests'],
        'cache_hits': metrics['cache_hits'],
        'cache_hit_rate': round(cache_rate, 2),
        'translation_errors': metrics['translation_errors'],
        'avg_response_time_seconds': round(avg_time, 3),
        'redis_connected': cache.ping()
    })

@app.route('/health')
def health_check():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'redis_connected': cache.ping()
    })

@app.route('/')
def home():
    return jsonify({
        'message': '🚀 Translation API is running!',
        'version': '1.0.0',
        'endpoints': {
            'POST /translate': 'Translate text (JSON: {"text": "hello", "target_lang": "fr"})',
            'GET /metrics': 'Get performance metrics',
            'GET /health': 'Health check'
        }
    })

if __name__ == '__main__':
    print("🚀 Starting Translation API...")
    print("📊 Endpoints:")
    print("   POST http://localhost:5000/translate")
    print("   GET  http://localhost:5000/metrics") 
    print("   GET  http://localhost:5000/health")
    print("\n💡 Exemple de test:")
    print('   curl -X POST http://localhost:5000/translate -H "Content-Type: application/json" -d "{\"text\": \"hello world\", \"target_lang\": \"fr\"}"')
    app.run(host='0.0.0.0', port=5000, debug=False)