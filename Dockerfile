FROM python:3.11.11-slim-bookworm AS builder

RUN apt-get update && apt-get upgrade -y
RUN pip install --upgrade pip

# renovate: datasource=pip depName=poetry
ENV POETRY_VERSION=2.1.1
RUN pip install poetry==$POETRY_VERSION --no-cache

COPY pyproject.toml poetry.lock ./

RUN apt-get install gcc g++ --no-install-recommends -y \
    && poetry config virtualenvs.create false \
    && poetry install --no-cache --only main \
    && apt-get remove -y gcc g++ \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

FROM python:3.11.11-slim-bookworm

RUN apt-get update && apt-get upgrade -y
RUN pip install --upgrade pip && pip uninstall setuptools -y

ARG UID=46012
ARG USER=predictor
RUN adduser --gecos '' --disabled-password --uid $UID $USER

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin/poetry /usr/local/bin/poetry

USER $USER

WORKDIR /app
COPY --chown=$USER:$USER main.py /app

EXPOSE 8000
CMD ["python3","-m","uvicorn", "main:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]