import os
import psycopg2


def test_database_connection():

    conn = psycopg2.connect(
        host=os.environ["DB_HOST"],
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"]
    )

    cur = conn.cursor()

    cur.execute("SELECT 1")

    result = cur.fetchone()

    assert result[0] == 1

    conn.close()