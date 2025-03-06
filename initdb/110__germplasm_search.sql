CREATE OR REPLACE FUNCTION search_germplasm(
    accessionNumbers text[],
    binomialNames text[],
    collections text[],
    commonCropNames text[],
    externalReferenceIds text[],
    externalReferenceSources text[],
    familyCodes text[],
    genus_list text[],  -- TODO: make "genus" but handle name ambiguity.
    germplasmDbIds text[],
    germplasmNames text[],
    germplasmPUIs text[],
    instituteCodes text[],
    parentDbIds text[],
    progenyDbIds text[],
    programDbIds text[],
    programNames text[],
    species_list text[],  -- TODO: make "species" but handle name ambiguity.
    studyDbIds text[],
    studyNames text[],
    synonyms text[],
    trialDbIds text[],
    trialNames text[]
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
                                 'germplasmDbId', g.id,
                                 'germplasmName', g.germplasm_name,
                                 'externalReferences', COALESCE((SELECT json_agg(
                                                                                json_build_object('referenceID',
                                                                                                  xr.external_reference_id,
                                                                                                  'referenceId',
                                                                                                  xr.external_reference_id,
                                                                                                  'referenceSource',
                                                                                                  xr.external_reference_source))
                                                                 FROM germplasm_external_references gxr
                                                                          LEFT JOIN external_reference xr ON gxr.external_references_id = xr.id
                                                                 WHERE gxr.germplasm_entity_id = g.id), '[]'::json),
                                 'additionalInfo', g.additional_info,
                                 'accessionNumber', g.accession_number,
                                 'acquisitionDate', TO_CHAR(g.acquisition_date, 'YYYY-MM-DD'),
                                 'biologicalStatusOfAccessionCode', g.biological_status_of_accession_code,
                                 'biologicalStatusOfAccessionDescription',
                                 'TODO', -- TODO: store actual text value in database, currently only a java enum.
                                 'breedingMethodDbId', g.breeding_method_id,
                                 'breedingMethodName', bm.name,
                                 'collection', g.collection,
                                 'commonCropName', c.crop_name,
                                 'countryOfOriginCode', g.country_of_origin_code,
                                 'defaultDisplayName', g.default_display_name,
                                 'documentationURL', g.documentationurl,
                                 'donors', COALESCE((SELECT json_agg(
                                                                json_build_object('donorAccessionNumber',
                                                                                  donor.donor_accession_number,
                                                                                  'donorInstituteCode',
                                                                                  donor.donor_institute_code,
                                                                                  'germplasmPUI',
                                                                                  donor.germplasmpui)
                                                        )
                                                     FROM germplasm_donor donor
                                                     WHERE donor.germplasm_id = g.id), '[]'::json),
                                 'genus', g.genus,
                                 'germplasmOrigin',
                                 COALESCE(
                                     (SELECT json_agg(
                                             json_build_object(
                                                     'coordinateUncertainty', go.coordinate_uncertainty,
                                                     'coordinates', json_build_object(
                                                             'geometry', json_build_object(
                                                             'coordinates',
                                                             json_build_array(crd.latitude, crd.longitude, crd.altitude),
                                                             'type', geo.type
                                                                         ),
                                                             'type',
                                                             'Feature' -- TODO: is this dynamic, or hard coded?
                                                    )
                                             )
                                         )
                                    FROM germplasm_origin go
                                               LEFT JOIN geojson geo ON go.coordinates_id = geo.id
                                               LEFT JOIN coordinate crd on geo.id = crd.geojson_id
                                    WHERE go.germplasm_id = g.id),
                                    '[]'::json
                                 ),
                                 'germplasmPUI', g.germplasmpui,
                                 'germplasmPreprocessing', g.germplasm_preprocessing,
                                 'instituteCode', gi.institute_code,
                                 'instituteName', gi.institute_name,
                                 'pedigree', COALESCE(this_node.pedigree_string, ''), -- TODO: is this the best way?
                                 'seedSource', g.seed_source,
                                 'seedSourceDescription', g.seed_source_description,
                                 'species', g.species,
                                 'speciesAuthority', g.species_authority,
                                 -- TODO: store actual text values for storageTypes in the database!! This is only for demo purpose, the data isn't meaningful.
                                 'storageTypes', COALESCE((SELECT json_agg(json_build_object('code',
                                                                                             stor.type_of_germplasm_storage_code,
                                                                                             'description', 'TODO'))
                                                           FROM germplasm_entity_type_of_germplasm_storage_code stor
                                                           WHERE stor.germplasm_entity_id = g.id), '[]'::json),
                                 'subtaxa', g.subtaxa,
                                 'subtaxaAuthority', g.subtaxa_authority,
                                 'synonyms',
                                 COALESCE((SELECT json_agg(json_build_object('synonym', s.synonym, 'type', s.type))
                                           FROM germplasm_synonym s
                                           WHERE s.germplasm_id = g.id), '[]'::json),
                                 'taxonIds', COALESCE(
                                         (SELECT json_agg(json_build_object('sourceName', taxon.source_name,
                                                                            'taxonId', taxon.taxon_id))
                                          FROM germplasm_taxon taxon
                                          WHERE taxon.germplasm_id = g.id), '[]'::json)
                             )
                        )
                        ,
                        '[]'::json
                    )
                )

            )



            FROM
                germplasm g
                LEFT JOIN
                breeding_method bm ON g.breeding_method_id = bm.id
                LEFT JOIN
                crop c ON g.crop_id = c.id
                LEFT JOIN
                germplasm_institute gi ON g.id = gi.germplasm_id
                LEFT JOIN
                pedigree_node this_node ON g.id = this_node.germplasm_id
            WHERE
                (accessionNumbers IS NULL OR accessionNumbers @> ARRAY[g.accession_number])
                AND
                (binomialNames IS NULL OR
                binomialNames @> ARRAY[g.genus || ' ' || g.species]) -- TODO: potentially expand.
                AND
                (collections IS NULL OR collections @> ARRAY[g.collection])
                AND
                (commonCropNames IS NULL OR commonCropNames @> ARRAY[c.crop_name])
                AND
                (
                COALESCE(externalReferenceIds, externalReferenceSources) IS NULL
                OR
                (
                g.id IN
                (SELECT germplasm_entity_id
                FROM germplasm_external_references gxr
                         JOIN external_reference xr ON gxr.external_references_id = xr.id
                WHERE externalReferenceIds @> ARRAY[xr.external_reference_id]
                  AND externalReferenceSources @> ARRAY[xr.external_reference_source])
                )
                )
                AND
                (familyCodes IS NULL OR familyCodes @> ARRAY[family_code]) -- TODO: double check this.
                AND
                (genus_list IS NULL OR genus_list @> ARRAY[g.genus])
                AND
                (germplasmDbIds IS NULL OR germplasmDbIds @> ARRAY[g.id])
                AND
                (germplasmNames IS NULL OR germplasmNames @> ARRAY[g.germplasm_name])
                AND
                (germplasmPUIs IS NULL OR germplasmPUIs @> ARRAY[g.germplasmpui])
                AND
                (instituteCodes IS NULL OR instituteCodes @> ARRAY[gi.institute_code])
                AND
                (
                parentDbIds IS NULL
                OR
                -- Get germplasm by parentDbIds.  -- TODO: hardcoded EdgeType (parent=0, child=1, sibling=2)
                g.id IN (SELECT child.germplasm_id
                    FROM pedigree_node parent
                             JOIN pedigree_edge e ON parent.id = e.connceted_node_id AND e.edge_type = 0
                             JOIN pedigree_node child ON e.this_node_id = child.id
                    WHERE parentDbIds @> ARRAY[parent.id])
                )
                AND
                (
                progenyDbIds IS NULL
                OR
                -- Get germplasm by progenyDbIds.  -- TODO: hardcoded EdgeType (parent=0, child=1, sibling=2)
                g.id IN (SELECT parent.germplasm_id
                    FROM pedigree_node parent
                             JOIN pedigree_edge e ON parent.id = e.connceted_node_id AND e.edge_type = 0
                             JOIN pedigree_node child ON e.this_node_id = child.id
                    WHERE progenyDbIds @> ARRAY[child.id])
                )
                -- TODO: germplasm doesn't seem to have relationship to program.
                --         AND
                --         (programDbIds IS NULL OR programDbIds @> ARRAY[])
                --         AND
                --         (programNames IS NULL OR programNames @> ARRAY[])
                AND
                (species_list IS NULL OR species_list @> ARRAY[g.species])
                -- TODO: germplasm doesn't seem to have relationship to study.
                --         AND
                --         (studyDbIds IS NULL OR studyDbIds @> ARRAY[])
                --         AND
                --         (studyNames IS NULL OR studyNames @> ARRAY[])
                AND
                (
                synonyms IS NULL
                OR
                g.id IN
                (SELECT gs.germplasm_id FROM germplasm_synonym gs WHERE synonyms @> ARRAY[gs.synonym])
                )
                -- TODO: germplasm doesn't seem to have relationship to program.
                --         AND
                --         (trialDbIds IS NULL OR trialDbIds @> ARRAY[])
                --         AND
                --         (trialNames IS NULL OR trialNames @> ARRAY[])
    );
END;
$$ LANGUAGE plpgsql;