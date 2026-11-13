# Multi-stage Dockerfile for DeFi-Oracle-CrossChain-Sentinel
FROM python:3.11-slim as builder

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.11-slim as runner

WORKDIR /app
RUN groupadd -r sentinel && useradd -r -g sentinel sentinel

COPY --from=builder /root/.local /home/sentinel/.local
COPY --chown=sentinel:sentinel . /app

ENV PATH=/home/sentinel/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER sentinel

ENTRYPOINT ["python", "cli.py"]
CMD ["demo"]
