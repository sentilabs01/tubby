FROM python:3.9-slim

WORKDIR /app

# Install system dependencies including Node.js, npm, and redis-cli
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    redis-tools \
    git \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Copy backend files
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ .

EXPOSE 5001

CMD ["python", "app.py"]

