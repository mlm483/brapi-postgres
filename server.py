from flask import Flask, request
import psycopg

CONN_STR = "postgresql://postgres:postgres@localhost:5430/postgres"

app = Flask(__name__)


@app.get("/brapi/v2/programs")
def get_programs():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT search_program(null, null, null, null, null, null, null, null, null, null);")
            return [dict(program[0]) for program in cur.fetchall()]

@app.post("/brapi/v2/programs")
def post_programs():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT post_program(%s);", (request.get_data().decode("utf-8"),))
            result = cur.fetchone()
            print(result)
            return result[0]

@app.get("/brapi/v2/germplasm")
def get_germplasm():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT search_germplasm();")  # TODO: params!
            return [dict(program[0]) for program in cur.fetchall()]

@app.post("/brapi/v2/germplasm")
def post_germplasm():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT post_germplasm(%s);", (request.get_data().decode("utf-8"),))
            result = cur.fetchone()
            return result