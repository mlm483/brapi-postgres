from typing import List
from flask import Flask, Request, request
import psycopg

CONN_STR = "postgresql://postgres:postgres@localhost:5430/postgres"

app = Flask(__name__)


def prepare_list_query_param(
    request: Request, param: str | None, fallback: str | None = None
) -> List[str] | None:
    parameter = request.args.get(param)
    fallback_parameter = request.args.get(fallback) if fallback else None
    parameter = parameter or fallback_parameter
    if parameter is None:
        return None
    return [parameter]

@app.get("/brapi/v2/serverinfo")
def get_serverinfo():
    return {"@context":None,"metadata":{},"result":{"calls":[{"dataTypes":["application/json"],"contentTypes":["application/json"],"methods":["GET"],"service":"serverinfo","versions":["2.0","2.1"]},{"dataTypes":["application/json"],"contentTypes":["application/json"],"methods":["GET","POST"],"service":"programs","versions":["2.0","2.1"]},{"dataTypes":["application/json"],"contentTypes":["application/json"],"methods":["GET","PUT"],"service":"programs/{programDbId}","versions":["2.0","2.1"]},{"dataTypes":["application/json"],"contentTypes":["application/json"],"methods":["POST"],"service":"search/programs","versions":["2.0","2.1"]},{"dataTypes":["application/json"],"contentTypes":["application/json"],"methods":["GET"],"service":"search/programs/{searchResultsDbId}","versions":["2.0","2.1"]},{"dataTypes":["application/json"],"contentTypes":["application/json"],"methods":["GET","POST"],"service":"germplasm","versions":["2.0","2.1"]},{"dataTypes":["application/json"],"contentTypes":["application/json"],"methods":["GET","PUT"],"service":"germplasm/{germplasmDbId}","versions":["2.0","2.1"]},{"dataTypes":["application/json"],"contentTypes":["application/json"],"methods":["GET"],"service":"germplasm/{germplasmDbId}/mcpd","versions":["2.0","2.1"]},{"dataTypes":["application/json"],"contentTypes":["application/json"],"methods":["POST"],"service":"search/germplasm","versions":["2.0","2.1"]},{"dataTypes":["application/json"],"contentTypes":["application/json"],"methods":["GET"],"service":"search/germplasm/{searchResultsDbId}","versions":["2.0","2.1"]}],"contactEmail":"bidevteam@cornell.edu","documentationURL":"https://brapi.org/specification","location":"Ithaca, NY, USA","organizationName":"Breeding Insight","organizationURL":"https://breedinginsight.org","serverDescription":"BrAPI PostgreSQL Server","serverName":"BrAPI PostgreSQL Server"}}

@app.get("/brapi/v2/programs")
def get_programs():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT search_programs(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);",
                (
                    prepare_list_query_param(request, "abbreviation"),
                    prepare_list_query_param(request, "commonCropName"),
                    prepare_list_query_param(
                        request, "externalReferenceId", fallback="externalReferenceID"
                    ),
                    prepare_list_query_param(request, "externalReferenceSource"),
                    prepare_list_query_param(request, "leadPersonDbId"),
                    prepare_list_query_param(request, "leadPersonName"),
                    prepare_list_query_param(request, "objective"),
                    prepare_list_query_param(request, "programDbId"),
                    prepare_list_query_param(request, "programName"),
                    prepare_list_query_param(request, "programType"),
                ),
            )
            result = cur.fetchone()
            return result[0]


@app.post("/brapi/v2/programs")
def post_programs():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT post_programs(%s);", (request.get_data().decode("utf-8"),)
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


# TODO: pass params from post body!
@app.post("/brapi/v2/search/germplasm")
def search_germplasm():
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
            cur.execute("SELECT post_germplasm(%s);", (request.get_data().decode("utf-8"),))
            result = cur.fetchone()
            return result[0]


# TODO: pass params from post body!
@app.post("/brapi/v2/search/lists")
def search_lists():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT search_lists(null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);"
            )  # TODO: params!
            result = cur.fetchone()
            return result[0]


@app.post("/brapi/v2/lists")
def post_lists():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT post_lists(%s);", (request.get_data().decode("utf-8"),))
            result = cur.fetchone()
            return result[0]
