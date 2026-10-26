FROM python:3.11.16-slim-trixie@sha256:e41613d42d4891e4930f79523f93f81bbc7632584ec65e36ab055f41a800b41e

RUN apt-get update && apt-get upgrade -y

# renovate: datasource=pypi depName=pip
ENV PIP_VERSION=26.2.1
RUN pip install pip==${PIP_VERSION}

ARG UID=46012
ARG USER=predictor
RUN adduser --gecos '' --disabled-password --uid $UID $USER

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

COPY requirements.txt constraints.txt ./

RUN apt-get install -y gcc g++ && \
    PIP_CONSTRAINT=constraints.txt python -m pip install -r requirements.txt &&  \
    apt-get remove -y gcc g++ && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Remove PIP inherited from base image
RUN rm -rf \
    /usr/local/lib/python*/site-packages/pip \
    /usr/local/lib/python*/site-packages/pip-*.dist-info \
    /usr/local/bin/pip \
    /usr/local/bin/pip3 \
    /usr/local/bin/pip3.*

USER $USER

WORKDIR /app
COPY --chown=$USER:$USER main.py /app

EXPOSE 8000
CMD ["uvicorn", "main:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]
