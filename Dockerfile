FROM python:3.8.19-slim-bookworm

RUN apt-get update && apt-get upgrade -y
RUN pip install --upgrade pip

ARG UID=46012
ARG USER=predictor
RUN adduser --gecos '' --disabled-password --uid $UID $USER

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .

RUN apt-get install -y gcc g++ && \
    python -m pip install -r requirements.txt &&  \
    apt-get remove -y gcc g++ && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

RUN python -m spacy download en_core_web_sm

WORKDIR /app
RUN chown -R $USER:$USER /app/
COPY --chown=$USER:$USER . /app

USER $USER

EXPOSE 8000
CMD ["uvicorn", "main:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]
