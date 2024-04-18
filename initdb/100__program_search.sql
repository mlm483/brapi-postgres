CREATE OR REPLACE FUNCTION search_programs(
    abbreviations text[],
    commonCropNames text[],
    externalReferenceIds text[],
    externalReferenceSources text[],
    leadPersonDbIds text[],
    leadPersonNames text[],
    objectives text[],
    programDbIds text[],
    programNames text[],
    programTypes integer[]
)
    RETURNS json AS $$
DECLARE
BEGIN
    RETURN (
        SELECT
            json_build_object(
                    '@context', '[]'::json,
                    'metadata', '{}'::json,  -- TODO: pagination, count, status, etc.
                    'result', json_build_object(
                            'data',
                            COALESCE(
                                    json_agg(
                                            json_build_object(
                                                    'abbreviation', p.abbreviation,
                                                    'additionalInfo', p.additional_info,
                                                    'commonCropName', c.crop_name,
                                                    'documentationURL', p.documentationurl,
                                                    'externalReferences', COALESCE((SELECT json_agg(
                                                                                                   json_build_object(
                                                                                                           'referenceID',
                                                                                                           xr.external_reference_id,
                                                                                                           'referenceId',
                                                                                                           xr.external_reference_id,
                                                                                                           'referenceSource',
                                                                                                           xr.external_reference_source))
                                                                                    FROM program_external_references pxr
                                                                                             LEFT JOIN external_reference xr ON pxr.external_references_id = xr.id
                                                                                    WHERE pxr.program_entity_id = p.id),
                                                                                   '[]'::json),
                                                    'fundingInformation', p.funding_information,
                                                    'leadPersonDbId', p.lead_person_id,
                                                    'leadPersonName', lp.first_name || ' ' || lp.last_name,
                                                    'objective', p.objective,
                                                    'programName', p.name,
                                                    'programType', CASE
                                                                       WHEN p.program_type = 1 THEN 'PROJECT'
                                                                       ELSE 'STANDARD' END, -- TODO: ProgramType is hardcoded (STANDARD=0, PROJECT=1)
                                                    'programDbId', p.id
                                            )
                                    ),
                                    '[]'::json
                            )
                  )

            )
            FROM
                program p
                    LEFT JOIN
                crop c ON p.crop_id = c.id
                    LEFT JOIN
                person lp ON p.lead_person_id = lp.id
            WHERE
                (abbreviations IS NULL OR abbreviations @> ARRAY[p.abbreviation])
              AND
                (commonCropNames IS NULL OR commonCropNames @> ARRAY[c.crop_name])
              AND
                (
                    COALESCE(externalReferenceIds, externalReferenceSources) IS NULL
                        OR
                    (p.id IN (
                        SELECT program_entity_id
                        FROM program_external_references pxr JOIN external_reference xr ON pxr.external_references_id = xr.id
                        WHERE externalReferenceIds @> ARRAY[xr.external_reference_id] AND externalReferenceSources @> ARRAY[xr.external_reference_source]
                        )
                    )
                )
              AND
                (leadPersonDbIds IS NULL OR leadPersonNames @> ARRAY[p.lead_person_id])
              AND
                (objectives IS NULL OR objectives @> ARRAY[p.objective])
              AND
                (programDbIds IS NULL OR programDbIds @> ARRAY[p.id])
              AND
                (programNames IS NULL OR programNames @> ARRAY[p.name])
              AND
                (programTypes IS NULL OR programTypes @> ARRAY[p.program_type])
    );
END;
$$ LANGUAGE plpgsql;
