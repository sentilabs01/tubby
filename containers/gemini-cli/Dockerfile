FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=20

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

WORKDIR /app

RUN npm install -g @google/gemini-cli

COPY mcp-server.js .
COPY package.json .

RUN npm install

RUN useradd --create-home --shell /bin/bash gemini
RUN chown -R gemini:gemini /app
USER gemini

EXPOSE 8002

COPY health-check.js .

CMD ["node", "mcp-server.js"] 