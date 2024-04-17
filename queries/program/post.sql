-- programs example JSON
-- [
--   {
--     "abbreviation": "P1",
--     "additionalInfo": {
--       "additionalProp1": "string",
--       "additionalProp2": "string",
--       "additionalProp3": "string"
--     },
--     "commonCropName": "Tomatillo",
--     "documentationURL": "https://wiki.brapi.org",
--     "externalReferences": [
--       {
--         "referenceId": "doi:10.155454/12341234",
--         "referenceSource": "DOI"
--       },
--       {
--         "referenceId": "75a50e76",
--         "referenceSource": "Remote Data Collection Upload Tool"
--       }
--     ],
--     "fundingInformation": "EU: FP7-244374",
--     "leadPersonDbId": "fe6f5c50",
--     "leadPersonName": "Bob Robertson",
--     "objective": "Make a better tomatillo",
--     "programName": "Tomatillo_Breeding_Program",
--     "programType": "STANDARD"
--   }
-- ]
CREATE TYPE PROGRAMTYPEENUM AS ENUM ('STANDARD', 'PROJECT');
DROP TYPE programrequest;
create type programrequest as
(
    "id"                 text,
    "abbreviation"       text,
    "additionalInfo"     json,
    "commonCropName"     text,
    "documentationURL"   text,
    "externalReferences" json,
    "fundingInformation" text,
    "leadPersonDbId"     text,
    "leadPersonName"     text,
    "objective"          text,
    "programName"        text,
    "programType"        programtypeenum
);
CREATE TYPE xrefrequest AS
(
    "id" text,
    "referenceSource" text,
    "referenceId" text
);
ALTER TABLE program ALTER COLUMN program_type TYPE PROGRAMTYPEENUM USING 'STANDARD'::PROGRAMTYPEENUM;

CREATE OR REPLACE FUNCTION post_program(programs_str text)
RETURNS VOID AS $$
DECLARE
    row record;
    xref record;
    crop_id text;
    xref_id uuid;
    programs json;
BEGIN
    SELECT programs_str::json INTO programs;
    FOR row IN SELECT * FROM json_populate_recordset(NULL::programrequest, programs) LOOP
        -- Look up crop_id based on commonCropName.
        SELECT id INTO crop_id FROM crop WHERE crop_name = row."commonCropName";
        -- Create program record.
        INSERT INTO program
            (id, additional_info, abbreviation, documentationurl, name, objective, program_type, crop_id, lead_person_id, funding_information)
        VALUES
        (
            row."id",
            row."additionalInfo",
            row.abbreviation,
            row."documentationURL",
            row."programName",
            row."objective",
            row."programType",
            crop_id,
            row."leadPersonDbId",
            row."fundingInformation"
        );
        -- Create xrefs.
        FOR xref IN SELECT * FROM json_populate_recordset(NULL::xrefrequest, row."externalReferences") LOOP
            SELECT gen_random_uuid() INTO xref_id;
            -- Create external_reference record.
            INSERT INTO external_reference
                (id, external_reference_id, external_reference_source)
            VALUES (xref_id, xref."referenceId", xref."referenceSource");
            -- Create program_external_references record.
            INSERT INTO program_external_references
                (program_entity_id, external_references_id)
            VALUES (row."id", xref_id);
        END LOOP;
    END LOOP;
END
$$ LANGUAGE plpgsql;

-- INSERT INTO person (id, first_name, last_name) VALUES ('fe6f5c50', 'Bob', 'Robertson');

DELETE FROM program WHERE id <> '0';
DELETE FROM program_external_references WHERE program_external_references.program_entity_id <> '';
DELETE FROM external_reference WHERE id <> '0';

SELECT postprogram('[{"id":"fafafa","abbreviation":"P1","additionalInfo":{"additionalProp1":"string","additionalProp2":"string","additionalProp3":"string"},"commonCropName":"Blueberry","documentationURL":"https://wiki.brapi.org","externalReferences":[{"referenceId":"doi:10.155454/12341234","referenceSource":"DOI"},{"referenceId":"75a50e76","referenceSource":"Remote Data Collection Upload Tool"}],"fundingInformation":"EU: FP7-244374","leadPersonDbId":"fe6f5c50","leadPersonName":"Bob Robertson","objective":"Make a better tomatillo","programName":"Tomatillo_Breeding_Program","programType":"STANDARD"}]');
