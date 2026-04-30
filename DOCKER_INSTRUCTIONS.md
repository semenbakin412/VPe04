# Пошаговая инструкция для новичка

Этот проект запускает:
- `backend` — Flask API на порту `5000`
- `frontend` — Nginx + HTML страница на порту `80`

Фронтенд обращается к API через `/api/...`, а Nginx проксирует запросы в Flask.

## 1) Что нужно установить заранее

1. Docker
2. Docker Compose (обычно уже входит в Docker Desktop)

Проверьте:

```bash
docker --version
docker compose version
```

## 2) Какие файлы есть в проекте

- `app.py` — Flask API
- `requirements.txt` — библиотеки Python
- `Dockerfile` — как собирать образ backend
- `docker-compose.yml` — запуск backend + frontend вместе
- `frontend/index.html` — простая веб-страница
- `frontend/nginx.conf` — настройки Nginx прокси
- `.github/workflows/deploy.yml` — CI/CD workflow для GitHub Actions

## 3) Быстрый запуск локально

Из папки проекта выполните:

```bash
docker compose up --build -d
```

Проверка:

```bash
docker compose ps
```

Если всё хорошо:
- сайт: [http://localhost](http://localhost)
- API напрямую: [http://localhost:5000/health](http://localhost:5000/health)
- API через Nginx: [http://localhost/api/health](http://localhost/api/health)

Для проверки преподавателем с внешней машины используйте:
- сайт: [http://168.222.143.87](http://168.222.143.87)
- API через Nginx: [http://168.222.143.87/api/health](http://168.222.143.87/api/health)

## 4) Полезные команды

Логи:

```bash
docker compose logs -f
```

Остановка:

```bash
docker compose down
```

Перезапуск с пересборкой:

```bash
docker compose up --build -d
```

## 5) Как проверить API руками

```bash
curl http://localhost/api/health
curl http://localhost/api/info
curl http://localhost/api/multiply/10/5
curl http://localhost/api/divide/20/4
curl http://168.222.143.87/api/health
curl http://168.222.143.87/api/multiply/10/5
```

## 6) Как работает GitHub Actions деплой

Workflow в `.github/workflows/deploy.yml` запускается при `push` в ветку `main`:
1. Собирает Docker image.
2. Пушит image в GHCR:
   - `ghcr.io/<owner>/flask-test-app:latest`
   - `ghcr.io/<owner>/flask-test-app:<commit_sha>`
3. По SSH подключается к серверу, копирует `docker-compose.yml` и `frontend`,
   затем запускает `backend + frontend` через `docker compose`.

## 7) Что нужно добавить в Secrets на GitHub

Откройте репозиторий -> `Settings` -> `Secrets and variables` -> `Actions`, добавьте:

- `SSH_HOST` — IP/домен сервера
- `SSH_USER` — пользователь SSH
- `SSH_PRIVATE_KEY` — приватный ключ (без пароля или с заранее настроенной поддержкой)
- `GHCR_USERNAME` — GitHub username владельца образа
- `GHCR_TOKEN` — PAT для pull из GHCR на сервере (`read:packages`)

`GITHUB_TOKEN` создавать не нужно: GitHub даёт его автоматически внутри workflow.

## 8) Первый деплой в GitHub

```bash
git add .
git commit -m "Add Flask Docker app with CI/CD deploy workflow"
git branch -M main
git push -u origin main
```

После push:
1. Откройте вкладку `Actions` в GitHub.
2. Зайдите в запуск `Build and Deploy`.
3. Убедитесь, что оба job зелёные: `build-and-push` и `deploy`.

## 9) Если что-то не работает

- Проверьте логи локально: `docker compose logs -f`
- Проверьте, что порт `80` и `5000` не заняты
- Проверьте GitHub Secrets (`SSH_HOST`, `SSH_USER`, `SSH_PRIVATE_KEY`)
- На сервере убедитесь, что установлен Docker
