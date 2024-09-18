FROM python:3.12 as python-dev
# Install poetry
RUN pip install poetry

# Set up the in-tree virtual environment
WORKDIR /app
RUN poetry config virtualenvs.in-project true

# Capture the execution environment
RUN poetry env info --path > /tmp/poetry_env_path

# Export the main-only requirements to a file for installation
RUN poetry export --only main --without-hashes --output /tmp/requirements.txt

# Install the requirements in the virtual environment
RUN pip install -r /tmp/requirements.txt

# Runtime container
FROM python:3.12

# Copy the virtual environment from the python-dev stage
COPY --from=python-dev /app/.venv /app/.venv

# Set the virtual environment as the default Python environment
ENV PATH="/app/.venv/bin:$PATH"

# Copy your application code to the container
COPY . /app

# Set the working directory
WORKDIR /app

# Run your application
CMD ["/app/.venv/bin/python", "pkg_b/main.py"]