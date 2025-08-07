FROM python:3.13.6-slim-bookworm@sha256:6f79e7a10bb7d0b0a50534a70ebc78823f941fba26143ecd7e6c5dca9d7d7e8a

RUN apt-get update && apt-get upgrade -y

# renovate: datasource=pypi depName=pip
ENV PIP_VERSION=25.2
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

USER $USER

WORKDIR /app
COPY --chown=$USER:$USER main.py /app

EXPOSE 8000
CMD ["uvicorn", "main:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]
