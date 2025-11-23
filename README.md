🚀 Translation API - DevOps Project
📋 Description
Une API de traduction développée avec Flask dans le cadre d'un projet DevOps. Ce service fournit des traductions texte avec caching Redis, métriques avancées et observabilité complète.

Caractéristiques principales :

API RESTful pour la traduction de texte

Cache Redis avec fallback en mémoire

Métriques Prometheus complètes

Logs structurés et tracing

Health checks détaillés

Conteneurisation Docker

🏗️ Architecture
text
📁 project-root/
├── 📁 src/
│   └── app.py              # Application Flask principale
├── Dockerfile              # Configuration Docker
├── requirements.txt        # Dépendances Python
├── docker-compose.yml      # Orchestration avec Redis
└── README.md
🚀 Démarrage Rapide
Prérequis
Python 3.9+

Docker & Docker Compose

Git

Installation Locale
Cloner le repository

bash
git clone <votre-repo>
cd <project-folder>
Installer les dépendances

bash
pip install -r requirements.txt
Lancer l'application

bash
python src/app.py
L'API sera accessible sur : http://localhost:5001

Avec Docker Compose (Recommandé)
bash
docker-compose up -d
🐳 Utilisation avec Docker
Construction de l'image
bash
docker build -t translation-api:latest .
Lancer avec Docker
bash
docker run -p 5001:5001 translation-api:latest
📡 API Endpoints
GET /
Description: Page d'accueil avec documentation
Réponse:

json
{
  "message": "🚀 Translation API is running!",
  "version": "2.0.0",
  "endpoints": {
    "POST /translate": "Translate text",
    "GET /metrics": "Basic metrics",
    "GET /metrics/prometheus": "Prometheus metrics",
    "GET /metrics/detailed": "Detailed metrics",
    "GET /health": "Health check"
  }
}
POST /translate
Description: Traduit du texte
Body:

json
{
  "text": "hello world",
  "target_lang": "fr"
}
Réponse:

json
{
  "translated_text": "bonjour le monde",
  "cached": false,
  "trace_id": "trace_1700000000"
}
GET /health
Description: Vérifie le statut de l'API et des dépendances
Réponse:

json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "redis_connected": true,
  "observability": {
    "prometheus_endpoint": "/metrics/prometheus",
    "detailed_metrics": "/metrics/detailed"
  }
}
GET /metrics
Description: Métriques basiques de l'application
Réponse:

json
{
  "total_requests": 150,
  "cache_hits": 45,
  "cache_hit_rate": 0.3,
  "translation_errors": 2,
  "avg_response_time_seconds": 0.125,
  "redis_connected": true
}
GET /metrics/prometheus
Description: Métriques au format Prometheus pour le scraping
Réponse:

text
# HELP http_requests_total Total HTTP Requests
# TYPE http_requests_total counter
http_requests_total{method="POST",endpoint="/translate",status_code="200"} 45.0
GET /metrics/detailed
Description: Métriques détaillées combinées
Réponse:

json
{
  "application_metrics": {
    "total_requests": 150,
    "cache_hits": 45,
    "cache_hit_rate": 0.3,
    "translation_errors": 2,
    "avg_response_time_seconds": 0.125,
    "redis_connected": true
  }
}
🔍 Observabilité
Métriques Prometheus
Compteurs:

http_requests_total - Requêtes HTTP totales par méthode/endpoint/status

translations_total - Traductions par langue et cache

errors_total - Erreurs par type

Histogrammes:

http_request_duration_seconds - Durée des requêtes HTTP

translation_duration_seconds - Temps de traitement des traductions

Jauges:

active_requests - Requêtes actives en temps réel

redis_connected - Statut de connexion Redis (1=connecté, 0=déconnecté)

cache_size - Nombre d'éléments en cache

Logs Structurés
Timestamps précis

Niveaux de log (INFO, ERROR, WARNING)

ID de trace unique par requête

Endpoints et méthodes HTTP

Tracing
Chaque requête reçoit un trace_id unique dans la réponse pour le suivi distribué.

🔒 Sécurité
Configuration Redis sécurisée
Timeouts de connexion

Fallback en mémoire si Redis indisponible

Gestion robuste des erreurs

⚙️ Déploiement
Variables d'Environnement
bash
REDIS_HOST=localhost  # Hôte Redis
REDIS_PORT=6379       # Port Redis
Docker Compose
Le fichier docker-compose.yml inclut:

Service API Flask

Service Redis

Network partagée

📊 Monitoring
Vérification des métriques
bash
# Métriques basiques
curl http://localhost:5001/metrics

# Métriques Prometheus
curl http://localhost:5001/metrics/prometheus

# Santé de l'application
curl http://localhost:5001/health
Surveillance des logs
bash
# Avec Docker Compose
docker-compose logs -f api

# Logs directs
docker logs <container_id>
🐛 Dépannage
Problèmes courants
Redis non connecté:

bash
# Vérifier que Redis tourne
docker ps | grep redis

# Tester la connexion Redis
redis-cli ping
Port déjà utilisé:

bash
# Changer le port dans app.py
app.run(host='0.0.0.0', port=5002, debug=False)
Erreurs de dépendances:

bash
# Réinstaller les requirements
pip install -r requirements.txt --force-reinstall
Tests de fonctionnement
bash
# Test de traduction
curl -X POST http://localhost:5001/translate \
  -H "Content-Type: application/json" \
  -d '{"text":"hello world", "target_lang":"fr"}'

# Test de santé
curl http://localhost:5001/health

# Test métriques
curl http://localhost:5001/metrics/prometheus
🛠️ Développement
Structure du code
Flask : Framework web principal

Redis : Cache des traductions

Prometheus Client : Métriques

Requests : Appels API de traduction

Ajout de nouvelles fonctionnalités
Implémenter la logique métier dans TranslationService

Ajouter les métriques Prometheus correspondantes

Mettre à jour la documentation

Tester avec les endpoints existants

📝 Journal des Changements
v2.0.0 - Implémentation complète DevOps

Métriques Prometheus avancées

Health checks détaillés

Logs structurés et tracing

Configuration Docker complète

👥 Contribution
Forker le repository

Créer une branche feature

Tester les modifications

Soumettre une Pull Request

📞 Support
Pour toute question :

Ouvrir une Issue GitHub

