1. Python Flask приложение (app.py)
#!/usr/bin/env python3
"""
Простое Flask приложение для тестирования Docker контейнера
"""

from flask import Flask, jsonify
import os
import platform
import datetime

app = Flask(__name__)

@app.route('/')
def home():
    """Главная страница с информацией о контейнере"""
    return jsonify({
        'message': 'Приложение успешно запущено в Docker контейнере!',
        'timestamp': datetime.datetime.now().isoformat(),
        'python_version': platform.python_version(),
        'platform': platform.platform(),
        'container_id': os.environ.get('HOSTNAME', 'unknown'),
        'environment': dict(os.environ)
    })

@app.route('/health')
def health():
    """Эндпоинт для проверки здоровья приложения"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.datetime.now().isoformat()
    })

@app.route('/info')
def info():
    """Информация о системе"""
    return jsonify({
        'python_version': platform.python_version(),
        'platform': platform.platform(),
        'architecture': platform.architecture(),
        'processor': platform.processor(),
        'hostname': os.environ.get('HOSTNAME', 'unknown'),
        'working_directory': os.getcwd(),
        'user': os.environ.get('USER', 'unknown')
    })

@app.route('/multiply/<int:a>/<int:b>')
def multiply(a, b):
    return jsonify({'result': a * b})

@app.route('/divide/<int:a>/<int:b>')
def divide(a, b):
    if b == 0:
        return jsonify({'error': 'Division by zero'}), 400
    return jsonify({'result': a / b})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)

2. Файл зависимостей (requirements.txt)
Flask==2.3.3
Werkzeug==2.3.7

3. Dockerfile
# Используем официальный Python образ
FROM python:3.11-slim

WORKDIR /app

# Копируем файл зависимостей и устанавливаем
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копируем приложение
COPY app.py .

# Создаем пользователя для безопасности
RUN useradd --create-home --shell /bin/bash appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

ENV FLASK_APP=app.py
ENV FLASK_ENV=production

CMD ["python", "app.py"]

4. Docker Compose (docker-compose.yml)
version: '3.8'

services:
  backend:
    image: argonpower/flask-test-app:latest
    container_name: flask-backend
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=production
      - PORT=5000
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  frontend:
    image: nginx:alpine
    container_name: nginx-frontend
    ports:
      - "80:80"
    volumes:
      - ./frontend:/usr/share/nginx/html:ro
      - ./frontend/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - backend
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  app-network:
    driver: bridge

volumes:
  nginx-logs:

5. Конфигурация Nginx (frontend/nginx.conf)
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://backend:5000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;

        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
}

6. Веб-интерфейс (frontend/index.html)
HTML + JS с интерактивными кнопками для взаимодействия с Flask API через Nginx (/api/...).
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Docker Test App - Frontend</title>
<style>
/* CSS стиль как в предыдущем примере */
</style>
</head>
<body>
<div class="container">
  <!-- Контент и кнопки -->
</div>

<script>
const API_BASE = '/api';
/* JavaScript код: checkHealth, getSystemInfo, getHomeInfo, multiply, divide, autoRefresh */
</script>
</body>
</html>

Код JS идентичен предыдущему примеру, только с API_BASE='/api' для прокси через Nginx.
7. Инструкция по запуску
# Быстрый старт с Docker Compose

1. Запуск всех сервисов:
docker-compose up -d

2. Проверка статуса:
docker-compose ps

3. Просмотр логов:
docker-compose logs -f

4. Доступ к приложению:
- http://localhost — веб-интерфейс
- http://localhost:5000 — прямой доступ к API

5. Тестирование API:
curl http://localhost/api/health
curl http://localhost/api/info
curl http://localhost/api/multiply/10/5
curl http://localhost/api/divide/20/4

6. Остановка:
docker-compose down

7. Пересборка и запуск:
docker-compose up --build -d

8. Публикация образа Flask в Docker Hub
# Авторизация в Docker Hub
docker login

# Сборка образа с тегом
docker build -t argonpower/flask-test-app:latest .

# Пуш в Docker Hub
docker push argonpower/flask-test-app:latest

Образ доступен: https://hub.docker.com/r/argonpower/flask-test-app
Использование через docker-compose или docker run.
9. Структура проекта
AutoDeploy/
├── app.py
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── frontend/
│   ├── index.html
│   └── nginx.conf
└── DOCKER_INSTRUCTIONS.md

Важные моменты
Веб-интерфейс обращается к API через Nginx (/api), чтобы избежать ошибок net::ERR_NAME_NOT_RESOLVED.
Flask работает на внутреннем порту 5000.
Nginx проксирует запросы к Flask внутри одной сети Docker Compose.
Автообновление и healthcheck включены для удобства мониторинга.

Создай простой проект (например, Flask-или FastAPI-приложение).
Добавь в проект папку .github/workflows и создай в ней файл deploy.yml, который:
запускается при push в ветку main;
выполняет сборку Docker-образа;
пушит образ в GitHub Container Registry.
Добавь job для деплоя на сервер через SSH-Action.
Проверь, что после коммита в ветку main workflow успешно отработал
