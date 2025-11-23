# 🚀 Translation API - DevOps Project

## Features
- REST API for text translation
- Docker containerization
- CI/CD with GitHub Actions
- Kubernetes deployment
- Security scanning (SAST/DAST)
- Observability with metrics and logging

## Quick Start
```bash
docker-compose up
curl -X POST http://localhost:5000/translate -H "Content-Type: application/json" -d '{"text": "hello", "target_lang": "fr"}'
