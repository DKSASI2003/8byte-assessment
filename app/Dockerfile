FROM python:3.12-slim

RUN apt-get update && \
    apt-get install -y nginx

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY . .

COPY nginx/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD service nginx start && python app.py