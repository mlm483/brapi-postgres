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
SELECT
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
;