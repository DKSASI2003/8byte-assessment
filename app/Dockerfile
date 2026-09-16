FROM python:3.12-slim

RUN apt-get update && \
    apt-get install -y nginx && \
    apt-get clean

WORKDIR /

COPY requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir -r /app/requirements.txt

COPY . /app

COPY nginx/default.conf /etc/nginx/sites-available/default

EXPOSE 80

CMD service nginx start && python -m app.app