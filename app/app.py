from flask import Flask, jsonify
from prometheus_flask_exporter import PrometheusMetrics
import psycopg2
import os

main = Flask(__name__)

metrics = PrometheusMetrics(main)

DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")


@main.route("/")
def home():
    return jsonify({
        "message": "8byte DevOps Assignment"
    })


@main.route("/health")
def health():
    return jsonify({
        "status": "healthy"
    })


@main.route("/db-check")
def db_check():

    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

    conn.close()

    return jsonify({
        "database": "connected"
    })


if __name__ == "__main__":
    main.run(host="0.0.0.0", port=5000)