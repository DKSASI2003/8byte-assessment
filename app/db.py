import boto3
import json
import psycopg2

def get_connection():

    client = boto3.client(
        "secretsmanager",
        region_name="ap-south-1"
    )

    secret = client.get_secret_value(
        SecretId="8byte-postgres-secret"
    )

    creds = json.loads(
        secret["SecretString"]
    )

    return psycopg2.connect(
        host=creds["host"],
        user=creds["username"],
        password=creds["password"],
        dbname=creds["dbname"]
    )

def init_db():
    conn = get_connection()

    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS tasks (
                    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                    title TEXT NOT NULL
                )
                """
            )
        conn.commit()
    finally:
        conn.close()