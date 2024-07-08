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
# CMD ["bash", "./prestart.sh"] && ["poetry", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
CMD ["bash", "-c", "poetry run bash ./prestart.sh && poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"]