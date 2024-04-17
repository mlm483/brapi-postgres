from flask import Flask, request
import psycopg

CONN_STR = "postgresql://postgres:postgres@localhost:5430/postgres"

app = Flask(__name__)


@app.get("/brapi/v2/programs")
def get_programs():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """SELECT
                    json_build_object(
                    'abbreviation', p.abbreviation,
                    'additionalInfo', p.additional_info,
                    'commonCropName', c.crop_name,
                    'documentationURL', p.documentationurl,
                    'externalReferences', COALESCE((SELECT json_agg(
                                                                json_build_object('referenceID', xr.external_reference_id,
                                                                                    'referenceId', xr.external_reference_id,
                                                                                    'referenceSource',
                                                                                    xr.external_reference_source))
                                                    FROM program_external_references pxr LEFT JOIN external_reference xr ON pxr.external_references_id = xr.id WHERE pxr.program_entity_id = p.id
                                                ), '[]'::json),
                    'fundingInformation', p.funding_information,
                    'leadPersonDbId', p.lead_person_id,
                    'leadPersonName', lp.first_name || ' ' || lp.last_name,
                    'objective', p.objective,
                    'programName', p.name,
                    'programType', p.program_type  -- TODO: make text field.
                    )
                FROM
                    program p
                    LEFT JOIN
                    crop c ON p.crop_id = c.id
                    LEFT JOIN
                    person lp ON p.lead_person_id = lp.id
                """
            )
            return [dict(program[0]) for program in cur.fetchall()]


@app.post("/brapi/v2/programs")
def post_programs():
    print(request.get_data())
    print(type(request.get_data()))
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT post_program(%s);", (request.get_data().decode("utf-8"),))
            result = cur.fetchone()
            print(result)
            return result[0]


@app.post("/brapi/v2/germplasm")
def post_germplasm():
    with psycopg.connect(CONN_STR) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT post_germplasm(%s);", (request.get_data().decode("utf-8"),))
            result = cur.fetchone()
            return result