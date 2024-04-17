-- germplasm example JSON
-- [
--   {
--     "accessionNumber": "A0000003",
--     "acquisitionDate": "2024-04-17",
--     "additionalInfo": {
--       "additionalProp1": "string",
--       "additionalProp2": "string",
--       "additionalProp3": "string"
--     },
--     "biologicalStatusOfAccessionCode": "420",
--     "biologicalStatusOfAccessionDescription": "Genetic stock",
--     "breedingMethodDbId": "ffcce7ef",
--     "breedingMethodName": "Male Backcross",
--     "collection": "Rice Diversity Panel 1 (RDP1)",
--     "commonCropName": "Maize",
--     "countryOfOriginCode": "BES",
--     "defaultDisplayName": "A0000003",
--     "documentationURL": "https://wiki.brapi.org",
--     "donors": [
--       {
--         "donorAccessionNumber": "A0000123",
--         "donorInstituteCode": "PER001"
--       }
--     ],
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
--     "genus": "Aspergillus",
--     "germplasmName": "A0000003",
--     "germplasmOrigin": [
--       {
--         "coordinateUncertainty": "20",
--         "coordinates": {
--           "geometry": {
--             "coordinates": [
--               -76.506042,
--               42.417373,
--               123
--             ],
--             "type": "Point"
--           },
--           "type": "Feature"
--         }
--       }
--     ],
--     "germplasmPUI": "http://pui.per/accession/A0000003",
--     "germplasmPreprocessing": "EO:0007210; transplanted from study 2351 observation unit ID: pot:894",
--     "instituteCode": "PER001",
--     "instituteName": "The BrAPI Institute",
--     "pedigree": "A0000001/A0000002",
--     "seedSource": "INRA:095115_inra",
--     "seedSourceDescription": "Branches were collected from a 10-year-old tree growing in a progeny trial established in a loamy brown earth soil.",
--     "species": "fructus",
--     "speciesAuthority": "Smith, 1822",
--     "storageTypes": [
--       {
--         "code": "20",
--         "description": "Field collection"
--       },
--       {
--         "code": "11",
--         "description": "Short term"
--       }
--     ],
--     "subtaxa": "Aspergillus fructus A",
--     "subtaxaAuthority": "Smith, 1822",
--     "synonyms": [
--       {
--         "synonym": "variety_1",
--         "type": "Pre-Code"
--       }
--     ],
--     "taxonIds": [
--       {
--         "sourceName": "NCBI",
--         "taxonId": "2026747"
--       }
--     ]
--   }
-- ]

DROP TYPE germplasm_request;
CREATE TYPE germplasm_request as
(
    "accessionNumber" text,
    "acquisitionDate" text,
    "additionalInfo" text,
    "biologicalStatusOfAccessionCode" text,
    "biologicalStatusOfAccessionDescription" text,
    "breedingMethodDbId" text,
    "breedingMethodName" text,
    "collection" text,
    "commonCropName" text,
    "countryOfOriginCode" text,
    "defaultDisplayName" text,
    "documentationURL" text,
    "donors" json,
    "externalReferences" json,
    "genus" text,
    "germplasmName" text,
    "germplasmOrigin" json,
    "germplasmPUI" text,
    "germplasmPreprocessing" text,
    "instituteCode" text,
    "instituteName" text,
    "pedigree" text,
    "seedSource" text,
    "seedSourceDescription" text,
    "species" text,
    "speciesAuthority" text,
    "storageTypes" json,
    "subtaxa" text,
    "subtaxaAuthority" text,
    "synonyms" json,
    "taxonIds" json
);
CREATE TYPE donor_request AS (
     "donorAccessionNumber" text,
     "donorInstituteCode" text
 );
CREATE TYPE origin_request AS (
    "coordinateUncertainty" text,
    "coordinates" json
);
CREATE TYPE storage_type AS (
    "code" text,
    "description" text
);
CREATE TYPE synonym_request AS (
   "synonym" text,
   "type" text
);
CREATE TYPE taxon_request AS (
    "sourceName" text,
    "taxonId" text
);
CREATE TYPE xrefrequest AS
(
    "id" text,
    "referenceSource" text,
    "referenceId" text
);

CREATE OR REPLACE FUNCTION post_germplasm(germplasm_str text)
    RETURNS VOID AS $$
DECLARE
    row record;
    xref record;
    donor record;
    synonym_record record;
    origin record;
    taxon record;
    crop_id text;
    xref_id uuid;
    germplasm_json json;
    germplasm_uuid uuid;
    coordinates_uuid uuid;
    geojson_uuid uuid;
    node_uuid uuid;
    female_parent text;
    female_parent_node_uuid text;
    male_parent text;
    male_parent_node_uuid text;
BEGIN
    SELECT germplasm_str::json INTO germplasm_json;
    FOR row IN SELECT * FROM json_populate_recordset(NULL::germplasm_request, germplasm_json) LOOP
            -- Look up crop_id based on commonCropName.
            SELECT id INTO crop_id FROM crop WHERE crop_name = row."commonCropName";
            -- PK for germplasm.
            SELECT gen_random_uuid() INTO germplasm_uuid;

            -- Create germplasm record.
            INSERT INTO germplasm (id, additional_info, auth_user_id, accession_number, acquisition_date, acquisition_source_code,
                                   biological_status_of_accession_code, collection, country_of_origin_code, default_display_name,
                                   documentationurl, genus, germplasm_name, germplasmpui, germplasm_preprocessing, mls_status,
                                   seed_source, seed_source_description, species, species_authority, subtaxa, subtaxa_authority,
                                   breeding_method_id, crop_id)
            VALUES (
                germplasm_uuid,  -- id
                row."additionalInfo",
                'anonymousUser', -- auth_user_id
                row."accessionNumber",
                row."acquisitionDate",
                null, -- acquisition_source_code
                row."biologicalStatusOfAccessionCode",
                row."collection",
                row."countryOfOriginCode",
                row."defaultDisplayName",
                row."documentationURL",
                row."genus",
                row."germplasmName",
                row."germplasmPUI",
                row."germplasmPreprocessing",
                null, -- mls_status
                row."seedSource",
                row."seedSourceDescription",
                row."species",
                row."speciesAuthority",
                row."subtaxa",
                row."subtaxaAuthority",
                row."breedingMethodDbId",
                crop_id  -- crop_id acquired from commonCropName
            );

            -- Create donors.
            FOR donor IN SELECT * FROM json_populate_recordset(NULL::donor_request, row."donors") LOOP
                INSERT INTO germplasm_donor (id, additional_info, auth_user_id, donor_accession_number, donor_institute_code,
                                             donor_institute_name, germplasmpui, germplasm_id)
                VALUES (
                    gen_random_uuid(),  -- id
                    null,  -- additional_info
                    null,  -- auth_user_id
                    donor."donorAccessionNumber",
                    donor."donorInstituteCode",
                    null,  -- donor_institute_name  -- TODO: could look up?
                    row."germplasmPUI",
                    germplasm_uuid
               );
            END LOOP;

            -- Create institute. -- TODO: make 2 columns on primary table?
            INSERT INTO germplasm_institute (id, institute_address, institute_code, institute_name, institute_type, germplasm_id)
            VALUES (
                    gen_random_uuid(),  -- id
                    null,  -- institute_address
                    row."instituteCode",
                    row."instituteName",
                    null,  -- institute_type
                    germplasm_uuid
           );

            -- Create origins.
            FOR origin IN SELECT * FROM json_populate_recordset(NULL::origin_request, row."germplasmOrigin") LOOP
                    SELECT gen_random_uuid() INTO geojson_uuid;
                    SELECT gen_random_uuid() INTO coordinates_uuid;
                    -- Create geojson.
                    INSERT INTO geojson (id, type) VALUES (geojson_uuid, origin."coordinates"->'geometry'->'coordinates'->->'type');
                    -- Create coordinate.
                    INSERT INTO coordinate (id, altitude, latitude, longitude, geojson_id)
                    VALUES (
                            coordinates_uuid,
                            origin."coordinates"->'geometry'->'coordinates'->->2, -- altitude
                            origin."coordinates"->'geometry'->'coordinates'->->0,  -- latitude
                            origin."coordinates"->'geometry'->'coordinates'->->1,  -- longitude
                            geojson_uuid
                       );
                    -- Create germplasm_origin.
                    INSERT INTO germplasm_origin (id, coordinate_uncertainty, coordinates_id, germplasm_id)
                    VALUES (
                            gen_random_uuid(),  -- id
                            origin."coordinateUncertainty",
                            coordinates_id,
                            germplasm_uuid
                           );
            END LOOP;

            -- Create synonyms.
            FOR synonym_record IN SELECT * FROM json_populate_recordset(NULL::synonym_request, row."synonyms") LOOP
                    INSERT INTO germplasm_synonym (id, synonym, type, germplasm_id)
                    VALUES (gen_random_uuid(), synonym_record."synonym", synonym_record."type", germplasm_uuid);
            END LOOP;

            -- Create taxons.
            FOR taxon IN SELECT * FROM json_populate_recordset(NULL::taxon_request, row."taxonIds") LOOP
                    insert into germplasm_taxon (id, source_name, taxon_id, germplasm_id)
                    values (gen_random_uuid(), taxon."sourceName", taxon."taxonId", germplasm_uuid);
            END LOOP;

            -- TODO: CURSED - remove or refactor as soon as possible. --------------------------------------------------
            -- Create pedigree.
            SELECT gen_random_uuid() INTO node_uuid;
            INSERT INTO pedigree_node (id, additional_info, auth_user_id, crossing_year, family_code, pedigree_string,
                                       crossing_project_id, germplasm_id)
            VALUES (
                node_uuid,  -- id
                null,  -- additional_info
                null,  -- auth_user_id
                null,  -- crossing_year
                null,  -- family_code
                row."pedigree",
                null,  -- crossing_project_id
                germplasm_uuid
           );
            -- TODO: parse pedigree string, lookup 5 possible identifiers, create node and edge records.
            -- TODO: hardcoded EdgeType (parent=0, child=1, sibling=2)
            -- TODO: hardcoded ParentType (MALE=0, FEMALE=1, SELF=2, POPULATION=3, CLONAL=4)
            -- Female Parent. Germplasm pedigree string is female/male by convention.
            SELECT split_part(row."pedigree", '/', 1) INTO female_parent;
            IF female_parent IS NOT NULL THEN
                -- Find female parent germplasm, match on any of id, germplasm_name, accession_number, germplasmpui or synonym.
                SELECT n.id INTO female_parent_node_uuid
                FROM
                    germplasm g
                    JOIN
                    pedigree_node n ON g.id = n.germplasm_id
                WHERE
                    g.id = female_parent
                    OR g.germplasm_name = female_parent
                    OR g.accession_number = female_parent
                    OR g.germplasmpui = female_parent
                    OR g.id = (SELECT germplasm_id FROM germplasm_synonym WHERE synonym = female_parent LIMIT 1)
                LIMIT 1
                ;
                -- Parents are expected to be created first.
                IF female_parent_node_uuid IS NULL THEN
                    RAISE NOTICE 'Expected female parent does not exist: %s.', female_parent;
                END IF;
                -- Create edges (bi-directional) for female parent.
                INSERT INTO pedigree_edge (id, additional_info, auth_user_id, edge_type, parent_type, connceted_node_id, this_node_id)
                VALUES
                    (
                        gen_random_uuid(),  -- id
                        null,  -- additional_info
                        null,  -- auth_user_id
                        0,  -- edge_type (parent)
                        1,  -- parent_type (FEMALE)
                        female_parent_node_uuid,  -- connceted_node_id
                        node_uuid  -- this_node_id
                    ),
                    (
                        gen_random_uuid(),  -- id
                        null,  -- additional_info
                        null,  -- auth_user_id
                        1,  -- edge_type (child)
                        1,  -- parent_type (FEMALE)
                        node_uuid,  -- connceted_node_id
                        female_parent_node_uuid  -- this_node_id
                    );
            END IF;
            -- Male Parent. Germplasm pedigree string is female/male by convention.
            SELECT split_part(row."pedigree", '/', 2) INTO male_parent;
            IF male_parent IS NOT NULL THEN
                -- Find male parent germplasm, match on any of id, germplasm_name, accession_number, germplasmpui or synonym.
                SELECT n.id INTO male_parent_node_uuid
                FROM
                    germplasm g
                        JOIN
                    pedigree_node n ON g.id = n.germplasm_id
                WHERE
                    g.id = male_parent
                   OR g.germplasm_name = male_parent
                   OR g.accession_number = male_parent
                   OR g.germplasmpui = male_parent
                   OR g.id = (SELECT germplasm_id FROM germplasm_synonym WHERE synonym = male_parent LIMIT 1)
                LIMIT 1
                ;
                -- Parents are expected to be created first.
                IF male_parent_node_uuid IS NULL THEN
                    RAISE NOTICE 'Expected male parent does not exist: %s.', male_parent;
                END IF;
                -- Create edges (bi-directional) for male parent.
                INSERT INTO pedigree_edge (id, additional_info, auth_user_id, edge_type, parent_type, connceted_node_id, this_node_id)
                VALUES
                    (
                        gen_random_uuid(),  -- id
                        null,  -- additional_info
                        null,  -- auth_user_id
                        0,  -- edge_type (parent)
                        0,  -- parent_type (MALE)
                        male_parent_node_uuid,  -- connceted_node_id
                        node_uuid  -- this_node_id
                    ),
                    (
                        gen_random_uuid(),  -- id
                        null,  -- additional_info
                        null,  -- auth_user_id
                        1,  -- edge_type (child)
                        0,  -- parent_type (MALE)
                        node_uuid,  -- connceted_node_id
                        male_parent_node_uuid  -- this_node_id
                    );
            END IF;
            -- TODO: END CURSED. ---------------------------------------------------------------------------------------

            -- Create xrefs.
            FOR xref IN SELECT * FROM json_populate_recordset(NULL::xrefrequest, row."externalReferences") LOOP
                SELECT gen_random_uuid() INTO xref_id;
                -- Create external_reference record.
                INSERT INTO external_reference
                (id, external_reference_id, external_reference_source)
                VALUES (xref_id, xref."referenceId", xref."referenceSource");
                -- Create germplasm_external_references record.
                INSERT INTO germplasm_external_references
                (germplasm_entity_id, external_references_id)
                VALUES (germplasm_uuid, xref_id);
            END LOOP;

        END LOOP;
END
$$ LANGUAGE plpgsql;




















