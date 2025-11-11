# Dockerfile for Docling + PySpark

# Use Official apache/spark image
FROM apache/spark-py:latest

# Metadata
LABEL maintainer="roburishabh@outlook.com"
LABEL version="1.0"
LABEL description="Docling + PySpark for distributed PDF processing"

# Set the working directory
WORKDIR /app

# Install System dependencies (Linux)
USER root 
RUN apt-get update && apt-get install -y \
    openjdk-11-jre-headless \
    tesseract-ocr \
    tesseract-ocr-eng \
    poppler-utils \
    libgomp1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1-mesa-glx \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*


# Copy requirements-docker.txt and install python dependencies
COPY requirements-docker.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements-docker.txt

# Copy application code
COPY scripts/ /app/scripts/
COPY assets/ /app/assets/

# Set Python path
ENV PYTHONPATH="/app:$PYTHONPATH"

# Create output directory
RUN mkdir -p /app/output && chmod 777 /app/output

# Create spark user if it doesn't exist and set up home directory
RUN if ! id -u spark > /dev/null 2>&1; then \
        useradd -m -u 185 -s /bin/bash spark; \
    fi && \
    mkdir -p /home/spark && \
    chown -R spark:spark /home/spark && \
    chown -R spark:spark /app && \
    chmod -R 755 /home/spark

# Set HOME environment variable to fix Spark ivy2 cache issue
ENV HOME=/home/spark

# Switch back to non-root user for security
USER spark

# Entry point
ENTRYPOINT ["/opt/spark/bin/spark-submit"]
CMD ["--help"]