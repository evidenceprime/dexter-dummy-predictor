FROM python:3.13.3-slim-bookworm@sha256:21e39cf1815802d4c6f89a0d3a166cc67ce58f95b6d1639e68a394c99310d2e5

RUN apt-get update && apt-get upgrade -y
RUN pip install --upgrade pip

ARG UID=46012
ARG USER=predictor
RUN adduser --gecos '' --disabled-password --uid $UID $USER

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

COPY requirements.txt constraints.txt .

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
