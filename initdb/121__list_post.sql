--     "additionalInfo": {},
--     "data": [
--       "758a78c0",
--       "2c78f9ee"
--     ],
--     "dateCreated": "2024-04-18T23:10:25.403Z",
--     "dateModified": "2024-04-18T23:10:25.403Z",
--     "externalReferences": [
--     ],
--     "listDescription": "This is a list of germplasm I would like to investigate next season",
--     "listName": "MyGermplasm_Sept_2020",
--     "listOwnerName": "Bob Robertson",
--     "listOwnerPersonDbId": "58db0628",
--     "listSize": 53,
--     "listSource": "GeneBank Repository 1.3",
--     "listType": "germplasm"

CREATE OR REPLACE FUNCTION list_type_to_int(value text)
    RETURNS int AS $$
DECLARE
    result int;
BEGIN
    -- TODO: hardcoded (germplasm=0,markers=1,programs=2,trials=3,studies=4,observationUnits=5,observations=6,observationVariables=7,samples=8).
    CASE value
        WHEN 'germplasm' THEN result := 0;
        WHEN 'markers' THEN result := 1;
        WHEN 'programs' THEN result := 2;
        WHEN 'trials' THEN result := 3;
        WHEN 'studies' THEN result := 4;
        WHEN 'observationUnits' THEN result := 5;
        WHEN 'observations' THEN result := 6;
        WHEN 'observationVariables' THEN result := 7;
        WHEN 'samples' THEN result := 8;
        END CASE;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION post_lists(lists_str text)
    RETURNS json AS $$
DECLARE
    row record;
    xref record;
    crop_id text;
    xref_id uuid;
    lists json;
    list_uuid uuid;
    list_db_ids text[];
BEGIN
    SELECT lists_str::json INTO lists;
    FOR row IN SELECT * FROM json_array_elements(lists) LOOP
        SELECT gen_random_uuid() INTO list_uuid;
        list_db_ids := list_db_ids || list_uuid::text;

        -- Create list record.
        INSERT INTO list
            (id, additional_info, auth_user_id, date_created, date_modified, description, list_name,
            list_owner_name, list_source, list_type, list_owner_person_id)
        VALUES
            (
            list_uuid,
            row->->'additionalInfo',
            null,  -- auth_user_id
            row->->'dateCreated',
            row->->'dateModified',
            row->->'listDescription',
            row->->'listName',
            row->->'listOwnerName',
            row->->'listSource',
            list_type_to_int(row->->'listType'),
            row->->'listOwnerPersonDbId'
            );

        -- Create xrefs.
        FOR xref IN SELECT * FROM json_populate_recordset(NULL::xrefrequest, row."externalReferences") LOOP
            SELECT gen_random_uuid() INTO xref_id;
            -- Create external_reference record.
            INSERT INTO external_reference (id, external_reference_id, external_reference_source)
            VALUES (xref_id, COALESCE(xref."referenceId", xref."referenceID"), xref."referenceSource");
            -- Create list_external_references record.
            INSERT INTO list_external_references (list_entity_id, external_references_id)
            VALUES (list_uuid, xref_id);
        END LOOP;
    END LOOP;
    RETURN (
        SELECT * FROM search_lists(null, null, null, null, null, null, null, list_db_ids, null, null, null, null, null, null, null)
    );
END
$$ LANGUAGE plpgsql;
