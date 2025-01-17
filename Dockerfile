FROM python:3.11-slim-bookworm AS BUILDER

LABEL org.opencontainers.image.author="Agence Data Services"
LABEL org.opencontainers.image.description="benchmark_llm_serving"

COPY prebuildfs /
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install python common
RUN install_packages software-properties-common

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=true

RUN python -m venv /opt/venv \
    && pip install --upgrade pip
ENV VIRTUAL_ENV="/opt/venv" PATH="/opt/venv/bin:${PATH}"

WORKDIR /app

# Install package
COPY pyproject.toml setup.py README.md requirements.txt version.txt /app
COPY src/benchmark_llm_serving /app/src/benchmark_llm_serving

RUN python -m pip install -r requirements.txt && python -m pip install .

FROM python:3.11-slim-bookworm

COPY prebuildfs /
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install python common and git-lfs
RUN install_packages software-properties-common git-lfs

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:${PATH}" \
    PIP_NO_CACHE_DIR=true

COPY --from=builder /opt/venv /opt/venv

WORKDIR /app
# Clone repository
RUN git clone --no-checkout https://github.com/France-Travail/benchmark_llm_serving.git
WORKDIR benchmark_llm_serving
RUN git lfs pull -I datasets/*.json

COPY src/benchmark_llm_serving/bench_suite.py /app
ENV DATASET_FOLDER="/app/benchmark_llm_serving/datasets"

CMD ["python", "/app/bench_suite.py"]