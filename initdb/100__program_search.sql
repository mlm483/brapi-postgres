CREATE OR REPLACE FUNCTION search_program(
    abbreviations text[],
    common_crop_names text[],
    external_reference_ids text[],
    external_reference_sources text[],
    lead_person_db_ids text[],
    lead_person_names text[],
    objectives text[],
    program_db_ids text[],
    program_names text[],
    program_types integer[]
)
    RETURNS json AS $$
DECLARE
BEGIN
    RETURN (SELECT
                json_agg(
                        json_build_object(
                                'abbreviation', p.abbreviation,
                                'additionalInfo', p.additional_info,
                                'commonCropName', c.crop_name,
                                'documentationURL', p.documentationurl,
                                'externalReferences', COALESCE((SELECT json_agg(
                                                                               json_build_object('referenceID', xr.external_reference_id,
                                                                                                 'referenceId', xr.external_reference_id,
                                                                                                 'referenceSource', xr.external_reference_source))
                                                                FROM program_external_references pxr
                                                                         LEFT JOIN external_reference xr ON pxr.external_references_id = xr.id
                                                                WHERE pxr.program_entity_id = p.id), '[]'::json),
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
                (common_crop_names IS NULL OR common_crop_names @> ARRAY[c.crop_name])
              AND
                (
                    COALESCE(external_reference_ids, external_reference_sources) IS NULL
                        OR
                    (p.id IN (
                        SELECT program_entity_id
                        FROM program_external_references pxr JOIN external_reference xr ON pxr.external_references_id = xr.id
                        WHERE external_reference_ids @> ARRAY[xr.external_reference_id] AND external_reference_sources @> ARRAY[xr.external_reference_source]
                        )
                    )
                )
              AND
                (lead_person_db_ids IS NULL OR lead_person_names @> ARRAY[p.lead_person_id])
              AND
                (objectives IS NULL OR objectives @> ARRAY[p.objective])
              AND
                (program_db_ids IS NULL OR program_db_ids @> ARRAY[p.id])
              AND
                (program_names IS NULL OR program_names @> ARRAY[p.name])
              AND
                (program_types IS NULL OR program_types @> ARRAY[p.program_type])
    );
END;
$$ LANGUAGE plpgsql;
