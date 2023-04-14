FROM python:3.8-slim-buster

RUN apt-get update && apt-get upgrade -y

ARG UID=46012
ARG USER=predictor
RUN adduser --gecos '' --disabled-password --uid $UID $USER

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN python -m pip install -r requirements.txt
RUN python -m spacy download en_core_web_sm

WORKDIR /app
COPY . /app

USER root
RUN chown -R $USER:$USER /app/
USER $USER

WORKDIR /app

EXPOSE 8000
CMD ["uvicorn", "main:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]