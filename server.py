from flask import Flask, request
import psycopg

CONN_STR = "postgresql://postgres:postgres@localhost:5430/postgres"

app = Flask(__name__)

# TODO: pass query params!
@app.get("/brapi/v2/programs")
def get_programs():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT search_program(null, null, null, null, null, null, null, null, null, null);")
            result = cur.fetchone()
            # print(result)
            return result[0]

@app.post("/brapi/v2/programs")
def post_programs():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT post_program(%s);", (request.get_data().decode("utf-8"),))
            result = cur.fetchone()
            # print(result)
            return result[0]

# TODO: pass query params!
@app.get("/brapi/v2/germplasm")
def get_germplasm():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT search_germplasm(null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);")  # TODO: params!
            result = cur.fetchone()
            # print(result)
            return result[0]

@app.post("/brapi/v2/germplasm")
def post_germplasm():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT post_germplasm(%s);", (request.get_data().decode("utf-8"),))
            result = cur.fetchone()
            # print(result)
            return result[0]