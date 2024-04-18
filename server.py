from typing import List
from flask import Flask, Request, request
import psycopg

CONN_STR = "postgresql://postgres:postgres@localhost:5430/postgres"

app = Flask(__name__)


def prepare_query_param(
    request: Request, param: str | None, fallback: str | None = None
) -> List[str] | None:
    parameter = request.args.get(param)
    fallback_parameter = request.args.get(fallback) if fallback else None
    parameter = parameter or fallback_parameter
    if parameter is None:
        return None
    return [parameter]


@app.get("/brapi/v2/programs")
def get_programs():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT search_program(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);",
                (
                    prepare_query_param(request, "abbreviation"),
                    prepare_query_param(request, "commonCropName"),
                    prepare_query_param(
                        request, "externalReferenceId", fallback="externalReferenceID"
                    ),
                    prepare_query_param(request, "externalReferenceSource"),
                    prepare_query_param(request, "leadPersonDbId"),
                    prepare_query_param(request, "leadPersonName"),
                    prepare_query_param(request, "objective"),
                    prepare_query_param(request, "programDbId"),
                    prepare_query_param(request, "programName"),
                    prepare_query_param(request, "programType"),
                ),
            )
            result = cur.fetchone()
            return result[0]


@app.post("/brapi/v2/programs")
def post_programs():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT post_program(%s);", (request.get_data().decode("utf-8"),)
            )
            result = cur.fetchone()
            return result[0]


# TODO: pass query params!
@app.get("/brapi/v2/germplasm")
def get_germplasm():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT search_germplasm(null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);"
            )  # TODO: params!
            result = cur.fetchone()
            return result[0]


@app.post("/brapi/v2/germplasm")
def post_germplasm():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT post_germplasm(%s);", (request.get_data().decode("utf-8"),)
            )
            result = cur.fetchone()
            return result[0]
