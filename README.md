# AutoDeploy (Flask + Docker + GitHub Actions)

- есть простое API на Flask;
- есть Dockerfile и Docker Compose (backend + nginx frontend);
- есть GitHub Actions workflow, который при push в `main`:
  - собирает Docker image;
  - пушит image в **GitHub Container Registry** (GHCR);
  - деплоит на сервер по SSH.

## 1) Что находится в проекте

- `app.py` — Flask API
- `requirements.txt` — зависимости Python
- `Dockerfile` — сборка backend образа
- `docker-compose.yml` — запуск backend + frontend
- `frontend/index.html` — простая страница с кнопками
- `frontend/nginx.conf` — nginx проксирует `/api/*` в backend
- `.github/workflows/deploy.yml` — сборка, пуш в GHCR и деплой по SSH
- `DOCKER_INSTRUCTIONS.md` — подробная инструкция для новичка

## 2) Локальный запуск (проверка работоспособности)

### Шаг 1. Установите Docker

Проверьте, что Docker установлен:

```bash
docker --version
docker compose version
```

### Шаг 2. Запустите проект

В папке проекта:

```bash
docker compose up --build -d
```

Проверьте статус:

```bash
docker compose ps
```

### Шаг 3. Проверьте в браузере

- Frontend (локально): `http://localhost`
- Frontend (на сервере): `http://168.222.143.87`
- Backend напрямую (локально): `http://localhost:5000/health`
- Backend через nginx proxy (локально): `http://localhost/api/health`
- Backend через nginx proxy (на сервере): `http://168.222.143.87/api/health`

### Шаг 4. Проверьте API командами

```bash
curl http://localhost/api/health
curl http://localhost/api/info
curl http://localhost/api/multiply/10/5
curl http://localhost/api/divide/20/4
curl -i http://localhost/api/divide/10/0
curl http://168.222.143.87/api/health
curl http://168.222.143.87/api/multiply/10/5
```

Ожидаемо:
- `multiply` вернёт `50`
- `divide/10/0` вернёт HTTP 400 и JSON с ошибкой

### Шаг 5. Логи и остановка

```bash
docker compose logs -f
docker compose down
```

## 3) Настройка GitHub Actions (CI/CD) для сдачи

### Что делает workflow

`.github/workflows/deploy.yml` запускается при `push` в ветку `main`:
1. `build-and-push` — собирает образ и пушит в GHCR:
   - `ghcr.io/<owner>/flask-test-app:latest`
   - `ghcr.io/<owner>/flask-test-app:<sha>`
2. `deploy` — подключается по SSH к серверу, копирует `docker-compose.yml` и `frontend`,
   затем запускает оба сервиса через `docker compose`:
   - `backend` из GHCR образа (`ghcr.io/<owner>/flask-test-app:latest`)
   - `frontend` (nginx) на порту `80` с прокси в backend

### Какие Secrets нужно добавить в GitHub

Откройте репозиторий → `Settings` → `Secrets and variables` → `Actions` и добавьте:

1. `SSH_HOST` — IP или домен сервера
2. `SSH_USER` — пользователь SSH
3. `SSH_PRIVATE_KEY` — приватный SSH ключ (обычно содержимое `~/.ssh/id_rsa`)
4. `GHCR_USERNAME` — ваш GitHub username (или owner организации)
5. `GHCR_TOKEN` — **Personal Access Token** (PAT) для доступа к GHCR с сервера  
   Минимальные права: `read:packages`  
   Если репозиторий/пакет приватный — часто нужен ещё доступ к репо (GitHub подскажет при ошибке pull).

Важно: `GITHUB_TOKEN` вручную добавлять не нужно, он есть в Actions автоматически, но **на сервере его нет**, поэтому для `docker pull` нужен `GHCR_TOKEN`.

## 4) Как “сдать работу” (чеклист)

1. Проект пушится в GitHub в ветку `main`.
2. После push откройте вкладку `Actions`:
   - workflow `Build and Deploy` должен завершиться успешно (оба job зелёные).
3. В GHCR должен появиться образ:
   - `ghcr.io/<owner>/flask-test-app:latest`
4. На сервере после деплоя:
   - `docker ps` показывает `flask-backend` и `nginx-frontend`
   - `curl http://<server-ip>/api/health` возвращает `{"status":"healthy",...}`

### Что приложить как доказательство

- Скриншот вкладки `Actions` с зелёными job
- Скриншот/лог, что образ появился в `Packages` (GHCR)
- Вывод на сервере:
  - `docker ps`
  - `curl http://168.222.143.87/api/health`

