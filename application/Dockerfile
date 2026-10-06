# ==============================================================================
# Hardened Multi-Stage Production Dockerfile
# Microservice: sathvik-payment-service
# Compliance: CIS Docker Benchmark, PCI-DSS v4.0
# ==============================================================================

# Stage 1: Build stage
FROM python:3.11-slim-bookworm AS builder

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Hardened Runtime stage
FROM python:3.11-slim-bookworm AS runtime

# Create an unprivileged user and group with explicit UID/GID
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -s /sbin/nologin -M appuser

# Remove package managers and package caches to reduce attack surface
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /app

# Copy dependencies and application from builder
COPY --from=builder /root/.local /home/appuser/.local
COPY --chown=10001:10001 main.py .

# Update PATH for user-installed python binaries
ENV PATH="/home/appuser/.local/bin:${PATH}"
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Enforce non-root execution
USER 10001:10001

EXPOSE 8000

# Container healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')" || exit 1

ENTRYPOINT ["python", "main.py"]
