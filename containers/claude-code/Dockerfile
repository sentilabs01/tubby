FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=18

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

WORKDIR /app

RUN npm install -g @anthropic-ai/claude-code

COPY mcp-server.js .
COPY package.json .

RUN npm install

RUN useradd --create-home --shell /bin/bash claude
RUN chown -R claude:claude /app
USER claude

EXPOSE 8001

COPY health-check.js .

CMD ["node", "mcp-server.js"] 