# Full-Stack FastAPI and React Template

This guide will help you deploy a full stack web application (React frontend and FastAPI + PostgreSQL backend) using Docker containers, with Traefik as the reverse proxy to route traffic between services.

## Project Structure

The repository is organized into two main directories:

- **frontend**: Contains the ReactJS application.
- **backend**: Contains the FastAPI application and PostgreSQL database integration.

Each directory has its own README file with detailed instructions specific to that part of the application.

## Requirements

1. **Fork the Repository**:
   - Create a fork of this repository to add the necessary Docker and proxy configuration files.

2. **Dockerization**:
   - Write Dockerfiles to containerize both the React frontend and FastAPI backend. Ensure each service can be built and run locally in their respective containers.

3. **Configure Traefik**:
   - Serve the frontend and backend on the same host machine port (80).
   - Serve the frontend on the root (/).
   - Proxy `/api` on the backend to `/api` on the main domain.
   - Proxy `/docs` on the backend to `/docs` on the main domain.

4. **Database Configuration**:
   - Configure the application to use a PostgreSQL database. Ensure the database is properly set up and connected.

5. **Adminer Setup**:
   - Configure Adminer to run on port 8080. Ensure Adminer is accessible via the subdomain `db.y2o.chickenkiller.com` and is properly connected to the PostgreSQL database.

6. **Proxy Manager Setup**:
   - Configure the proxy manager to run on port 8090. Ensure the proxy manager is accessible via the subdomain `proxy.y2o.chickenkiller.com`.

7. **Cloud Deployment**:
   - Deploy your Dockerized application to an AWS EC2 instance. Set up a domain for your application (e.g., `y2o.chickenkiller.com`). Configure HTTP to redirect to HTTPS. Configure www to redirect to non-www.

## Getting Started

### 1. Fork the Repository

Begin by forking this repository to your GitHub account. This allows you to modify the repository and add the necessary configuration files for Docker and Traefik.

### 2. Dockerization

**Frontend Dockerfile**

Navigate to the `frontend` directory and create a Dockerfile:

```Dockerfile
# frontend/Dockerfile

# Stage 1: Build the React application
FROM node:20 as build

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json to leverage Docker cache
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . /app

# Build the application
RUN npm run build

# Stage 2: Serve the static files with Nginx
FROM nginx:alpine

# Copy the build output to the Nginx html directory
COPY --from=build /app/dist /usr/share/nginx/html

# Expose the port Nginx will serve on
EXPOSE 80

# Command to run Nginx
CMD ["nginx", "-g", "daemon off;"]

```

### 3. Configure Traefik

Create a `docker-compose.yml` file at the root of your project to define all services and configure Traefik:

```yaml
services:

  traefik:
    image: traefik:v2.5
    env_file:
      - .env
    command:
      - "--api.insecure=true"
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.traefik.address=:8090"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.myresolver.acme.email=ayinglar@gmail.com"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
      - "8090:8090"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./letsencrypt:/letsencrypt"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`proxy.${DOMAIN}`)"
      - "traefik.http.routers.api.service=api@internal"
      - "traefik.http.routers.api.entrypoints=websecure"
      - "traefik.http.services.api.loadbalancer.server.port=8090"
      - "traefik.http.routers.api.tls.certresolver=myresolver"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
      - "traefik.http.routers.http-catchall.rule=HostRegexp(`{host:.+}`)"
      - "traefik.http.routers.http-catchall.entrypoints=web"
      - "traefik.http.routers.http-catchall.middlewares=redirect-to-https"
      - "traefik.http.routers.www-to-non-www.rule=Host(`www.${DOMAIN}`)"
      - "traefik.http.routers.www-to-non-www.entrypoints=websecure"
      - "traefik.http.routers.www-to-non-www.tls.certresolver=myresolver"
      - "traefik.http.middlewares.www-to-non-www.redirectregex.regex=^https://www\\.(.*)"
      - "traefik.http.middlewares.www-to-non-www.redirectregex.replacement=https://$1"
      - "traefik.http.middlewares.www-to-non-www.redirectregex.permanent=true"
      - "traefik.http.routers.www-to-non-www.middlewares=www-to-non-www@docker"

  frontend:
    build: ./frontend
    env_file:
      - frontend/.env
    ports:
      - "3000:80"
    labels:
      - "traefik.http.routers.frontend.rule=Host(`${DOMAIN}`)"
      - "traefik.http.routers.frontend.entrypoints=websecure"
      - "traefik.http.routers.frontend.tls.certresolver=myresolver"

  backend:
    build: ./backend
    depends_on:
      - db
    ports:
      - "8000:8000"
    env_file:
      - backend/.env
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.backend.rule=Host(`${DOMAIN}`) && PathPrefix(`/api`, `/docs`, `/redoc`)"
      - "traefik.http.routers.backend.entrypoints=websecure"
      - "traefik.http.routers.backend.tls.certresolver=myresolver"

  db:
    image: postgres:13
    env_file:
      - backend/.env
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql

  adminer:
    image: adminer
    restart: always
    env_file:
      - .env
    ports:
      - "8080:8080"
    labels:
      - "traefik.http.routers.adminer.rule=Host(`db.${DOMAIN}`)"
      - "traefik.http.routers.adminer.entrypoints=websecure"
      - "traefik.http.routers.adminer.tls.certresolver=myresolver"

volumes:
  postgres_data:
```

### 4. FastAPI Backend Dockerfile

```Dockerfile

FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        python3-dev \
        postgresql-client \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:$PATH"

# Copy only the pyproject.toml and poetry.lock files to the container and install dependencies
COPY pyproject.toml poetry.lock* /app

# Install dependencies
RUN poetry config virtualenvs.create false \
    && poetry install --no-dev --no-interaction --no-ansi

# Copy the rest of the application
COPY . .

# Copy and run prestart.sh
COPY ./prestart.sh /app/prestart.sh
RUN chmod +x /app/prestart.sh

# Expose port
EXPOSE 8000

# Set the PYTHONPATH
ENV PYTHONPATH=/app

# Run prestart script before starting the app
CMD ["bash", "-c", "poetry run bash ./prestart.sh && poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"]

```
### 5. Adminer Setup

Adminer is configured to run on port 8080 and can be accessed via the subdomain `db.y2o.chickenkiller.chikenkiller.com`. This setup is defined in the `docker-compose.yml` file.

### 6. Proxy Manager Setup

Traefik is configured as the proxy manager and can be accessed via port 8090. This setup is also defined in the `docker-compose.yml` file.

### 7. Cloud Deployment

Deploy your Dockerized application to an AWS EC2 instance:

1. **Launch an EC2 Instance**:
   - Launch an EC2 instance and SSH into it.
   - Install Docker and Docker Compose on the instance.

2. **Clone Your Repository**:
   - Clone your forked repository to the EC2 instance.
   - Navigate to the project directory.

3. **Run Docker Compose**:
   - Execute `docker-compose up -d` to start all services.

4. **Set Up Your Domain**:
   - Get a free subdomain from Afraid DNS if you don't have one.
   - Point your domain or subdomain to your EC2 instance's IP address.
   - Configure Traefik to handle HTTP to HTTPS redirection and non-www to www redirection.


5. **Update configuration**:
   Ensure you update the necessary configurations in the `.env` file, particularly the database configuration.

By following these instructions, you should be able to set up and deploy the full-stack application successfully. For more detailed instructions, refer to the README files in the frontend and backend directories.