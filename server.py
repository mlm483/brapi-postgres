from typing import Any, Dict, List
from flask import Flask, Request, request
import psycopg

CONN_STR = "postgresql://postgres:postgres@localhost:5430/postgres"

app = Flask(__name__)


def prepare_list_query_param(
    request: Request, key: str | None, fallback: str | None = None
) -> List[str] | None:
    parameter = request.args.get(key)
    fallback_parameter = request.args.get(fallback) if fallback else None
    parameter = parameter or fallback_parameter
    if parameter is None:
        return None
    return [parameter]


def prepare_body_param(body: dict, key: str | None, fallback: str | None = None) -> Any:
    if key in body:
        return body[key]
    elif fallback in body:
        return body[fallback]
    return None
   

def get_request_json(request: Request) -> Dict:
    content_type = request.headers.get('Content-Type')
    if ('application/json' in content_type):
        json = request.json
        return json
    else:
        raise Exception(f'Content-Type "{content_type}" not supported!')


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


@app.get("/brapi/v2/germplasm")
def get_germplasm():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT search_germplasm(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);",
                (
                    prepare_list_query_param(request, "accessionNumbers"),
                    prepare_list_query_param(request, "binomialNames"),
                    prepare_list_query_param(request, "collections"),
                    prepare_list_query_param(request, "commonCropNames"),
                    prepare_list_query_param(request, "externalReferenceIds", fallback="externalReferenceIDs"),
                    prepare_list_query_param(request, "externalReferenceSources"),
                    prepare_list_query_param(request, "familyCodes"),
                    prepare_list_query_param(request, "genus_list"),
                    prepare_list_query_param(request, "germplasmDbIds"),
                    prepare_list_query_param(request, "germplasmNames"),
                    prepare_list_query_param(request, "germplasmPUIs"),
                    prepare_list_query_param(request, "instituteCodes"),
                    prepare_list_query_param(request, "parentDbIds"),
                    prepare_list_query_param(request, "progenyDbIds"),
                    prepare_list_query_param(request, "programDbIds"),
                    prepare_list_query_param(request, "programNames"),
                    prepare_list_query_param(request, "species_list"),
                    prepare_list_query_param(request, "studyDbIds"),
                    prepare_list_query_param(request, "studyNames"),
                    prepare_list_query_param(request, "synonyms"),
                    prepare_list_query_param(request, "trialDbIds"),
                    prepare_list_query_param(request, "trialNames"),
                )
            )
            result = cur.fetchone()
            return result[0]


@app.post("/brapi/v2/search/germplasm")
def search_germplasm():
    body = get_request_json(request)
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT search_germplasm(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);",
                (
                    prepare_body_param(body, "accessionNumbers"),
                    prepare_body_param(body, "binomialNames"),
                    prepare_body_param(body, "collections"),
                    prepare_body_param(body, "commonCropNames"),
                    prepare_body_param(body, "externalReferenceIds", fallback="externalReferenceIDs"),
                    prepare_body_param(body, "externalReferenceSources"),
                    prepare_body_param(body, "familyCodes"),
                    prepare_body_param(body, "genus_list"),
                    prepare_body_param(body, "germplasmDbIds"),
                    prepare_body_param(body, "germplasmNames"),
                    prepare_body_param(body, "germplasmPUIs"),
                    prepare_body_param(body, "instituteCodes"),
                    prepare_body_param(body, "parentDbIds"),
                    prepare_body_param(body, "progenyDbIds"),
                    prepare_body_param(body, "programDbIds"),
                    prepare_body_param(body, "programNames"),
                    prepare_body_param(body, "species_list"),
                    prepare_body_param(body, "studyDbIds"),
                    prepare_body_param(body, "studyNames"),
                    prepare_body_param(body, "synonyms"),
                    prepare_body_param(body, "trialDbIds"),
                    prepare_body_param(body, "trialNames"),
                )
            )
            result = cur.fetchone()
            return result[0]


@app.post("/brapi/v2/germplasm")
def post_germplasm():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT post_germplasm(%s);", (request.get_data().decode("utf-8"),))
            result = cur.fetchone()
            return result[0]


@app.post("/brapi/v2/search/lists")
def search_lists():
    body = get_request_json(request)
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT search_lists(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);",
                (
                    prepare_body_param(body, "commonCropNames"),
                    prepare_body_param(body, "dateCreatedRangeEnd"),
                    prepare_body_param(body, "dateCreatedRangeStart"),
                    prepare_body_param(body, "dateModifiedRangeEnd"),
                    prepare_body_param(body, "dateModifiedRangeStart"),
                    prepare_body_param(body, "externalReferenceIds"),
                    prepare_body_param(body, "externalReferenceSources"),
                    prepare_body_param(body, "listDbIds"),
                    prepare_body_param(body, "listNames"),
                    prepare_body_param(body, "listOwnerNames"),
                    prepare_body_param(body, "listOwnerPersonDbIds"),
                    prepare_body_param(body, "listSources"),
                    None if "listType" not in body else body["listType"],
                    prepare_body_param(body, "programDbIds"),
                    prepare_body_param(body, "programNames"),
                )
            )
            result = cur.fetchone()
            return result[0]


@app.post("/brapi/v2/lists")
def post_lists():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT post_lists(%s);", (request.get_data().decode("utf-8"),))
            result = cur.fetchone()
            return result[0]


@app.get("/brapi/v2/germplasm/<germplasmDbId>/progeny")
def get_progeny(germplasmDbId: str):
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT get_progeny(%s);", (germplasmDbId,))
            result = cur.fetchone()
            return result[0]


@app.get("/brapi/v2/germplasm/<germplasmDbId>/pedigree")
def get_progeny(germplasmDbId: str):
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT get_pedigree(%s);", (germplasmDbId,))
            result = cur.fetchone()
            return result[0]
