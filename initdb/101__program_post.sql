
CREATE TYPE program_request AS
(
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
    "programType"        text
);

CREATE TYPE xrefrequest AS
(
    "id" text,
    "referenceSource" text,
    "referenceId" text,
    "referenceID" text
);

CREATE OR REPLACE FUNCTION post_programs(programs_str text)
RETURNS json AS $$
DECLARE
    row record;
    xref record;
    crop_id text;
    xref_id uuid;
    programs json;
    program_uuid uuid;
    program_db_ids text[];
BEGIN
    SELECT programs_str::json INTO programs;
    FOR row IN SELECT * FROM json_populate_recordset(NULL::program_request, programs) LOOP
        SELECT gen_random_uuid() INTO program_uuid;
        program_db_ids := program_db_ids || program_uuid::text;
        -- Look up crop_id based on commonCropName.
        SELECT id INTO crop_id FROM crop WHERE crop_name = row."commonCropName";
        -- Crop is expected to exist.
        IF crop_id IS NULL THEN
            RAISE EXCEPTION 'Species % does not exist in the database.', row."commonCropName";
        END IF;
        -- Create program record.
        INSERT INTO program
            (id, additional_info, abbreviation, documentationurl, name, objective, program_type, crop_id, lead_person_id, funding_information)
        VALUES
        (
            program_uuid,
            row."additionalInfo",
            row."abbreviation",
            row."documentationURL",
            row."programName",
            row."objective",
            CASE WHEN row."programType" = 'PROJECT' THEN 1 ELSE 0 END,  -- TODO: ProgramType is hardcoded (STANDARD=0, PROJECT=1)
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
            VALUES (xref_id, COALESCE(xref."referenceId", xref."referenceID"), xref."referenceSource");
            -- Create program_external_references record.
            INSERT INTO program_external_references
                (program_entity_id, external_references_id)
            VALUES (program_uuid, xref_id);
        END LOOP;
    END LOOP;
    RETURN (
        SELECT * FROM search_programs(null, null, null, null, null, null, null, program_db_ids, null, null)
    );
END
$$ LANGUAGE plpgsql;
