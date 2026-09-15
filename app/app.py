from flask import Flask, request, jsonify
from app.db import get_connection

app = Flask(__name__)

@app.route("/")
def home():
    return {"service": "8byte Task API"}

@app.route("/health")
def health():
    return {"status": "healthy"}

@app.route("/api/tasks")
def tasks():
    conn = get_connection()

    cur = conn.cursor()

    cur.execute(
        "SELECT id,title FROM tasks"
    )

    rows = cur.fetchall()

    return jsonify(
        [
            {
                "id": r[0],
                "title": r[1]
            }
            for r in rows
        ]
    )

@app.route("/api/tasks", methods=["POST"])
def create_task():

    title = request.json["title"]

    conn = get_connection()

    cur = conn.cursor()

    cur.execute(
        """
        INSERT INTO tasks(title)
        VALUES(%s)
        """,
        (title,)
    )

    conn.commit()

    return {"status": "created"}

if __name__ == "__app__":
    app.run(
        host="0.0.0.0",
        port=5000
    )