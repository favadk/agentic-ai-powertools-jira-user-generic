FROM mcr.microsoft.com/powershell:latest

LABEL maintainer="QA Framework Team" \
      version="1.0" \
      description="Agentic AI QA Framework - Automated QA lifecycle with GitHub Copilot agents"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    nodejs \
    npm \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node packages globally
RUN npm install -g \
    protractor \
    http-server \
    && npm cache clean --force

# Install PowerShell modules
RUN pwsh -Command \
    "Install-Module -Name Az.Automation -Force -ErrorAction SilentlyContinue; \
     Install-Module -Name PSScheduledJob -Force -ErrorAction SilentlyContinue"

# Copy framework code
COPY . /app
WORKDIR /app

# Install local Node dependencies
RUN npm install || true

# Create necessary directories
RUN mkdir -p /app/docs/TestCases \
    && mkdir -p /app/docs/TestExecution \
    && mkdir -p /app/docs/Automation \
    && mkdir -p /app/scripts/triggers \
    && mkdir -p /app/setup-wizard

# Expose ports
EXPOSE 8080 9000 9001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD pwsh -Command "if (Test-Path '/app/scripts/monitor-state.json') { exit 0 } else { exit 1 }"

# Set permissions
RUN chmod +x /app/scripts/*.ps1

# Default command: run monitors continuously
CMD ["pwsh", "-Command", \
    "Set-Location /app; \
    . ./scripts/xray-api.ps1; \
    Write-Host '=== Agentic QA Framework Started ==='; \
    Write-Host 'Monitor interval: Every 30 minutes'; \
    Write-Host 'Log location: /app/logs/'; \
    Write-Host ''; \
    while($true) { \
        try { \
            Write-Host \"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Running monitors...\"; \
            . ./scripts/monitor-story-changes.ps1 -PostAck 2>&1 | Tee-Object -FilePath /app/logs/monitor-story-changes.log -Append; \
            . ./scripts/monitor-po-responses.ps1 -PostAck 2>&1 | Tee-Object -FilePath /app/logs/monitor-po-responses.log -Append; \
            Write-Host \"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Monitors completed. Sleeping 30 min...\"; \
            Start-Sleep -Seconds 1800; \
        } catch { \
            Write-Error \"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Monitor error: $_\"; \
            Start-Sleep -Seconds 300; \
        } \
    }"]
