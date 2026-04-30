FROM python:3.11-slim

WORKDIR /app

LABEL org.opencontainers.image.source="https://github.com/semenbakin412/VPe04"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

RUN useradd --create-home --shell /bin/bash appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

ENV FLASK_APP=app.py
ENV FLASK_ENV=production

CMD ["python", "app.py"]
