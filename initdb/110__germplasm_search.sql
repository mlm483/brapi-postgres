SELECT json_build_object(
               'germplasmDbId', g.id,
               'germplasmName', g.germplasm_name,
               'externalReferences', COALESCE((SELECT json_agg(
                                                              json_build_object('referenceID', xr.external_reference_id,
                                                                                'referenceId', xr.external_reference_id,
                                                                                'referenceSource',
                                                                                xr.external_reference_source))
                                               FROM germplasm_external_references gxr LEFT JOIN external_reference xr ON gxr.external_references_id = xr.id WHERE gxr.germplasm_entity_id = g.id
                                              ), '[]'::json),
               'additionalInfo', g.additional_info,
               'accessionNumber', g.accession_number,
               'acquisitionDate', g.acquisition_date,
               'biologicalStatusOfAccessionCode', g.biological_status_of_accession_code,
               'biologicalStatusOfAccessionDescription', 'TODO',  -- TODO: store actual text value in database, currently only a java enum.
               'breedingMethodDbId', g.breeding_method_id,
               'breedingMethodName', bm.name,
               'collection', g.collection,
               'commonCropName', c.crop_name,
               'countryOfOriginCode', g.country_of_origin_code,
               'defaultDisplayName', g.default_display_name,
               'documentationURL', g.documentationurl,
               'donors', COALESCE((SELECT json_agg(
                                                  json_build_object('donorAccessionNumber', donor.donor_accession_number, 'donorInstituteCode', donor.donor_institute_code, 'germplasmPUI', donor.germplasmpui)
                                          ) FROM germplasm_donor donor WHERE donor.germplasm_id = g.id), '[]'::json),
               'genus', g.genus,
               'germplasmOrigin',
               COALESCE(
                       (SELECT
                            json_agg(
                                    json_build_object(
                                            'coordinateUncertainty', go.coordinate_uncertainty,
                                            'coordinates', json_build_object(
                                                    'geometry', json_build_object(
                                                    'coordinates', json_build_array(crd.latitude, crd.longitude, crd.altitude),
                                                    'type', geo.type
                                                                ),
                                                    'type', 'Feature'  -- TODO: is this dynamic, or hard coded?
                                                           )
                                    )
                            )
                        FROM germplasm_origin go LEFT JOIN geojson geo ON go.coordinates_id = geo.id LEFT JOIN coordinate crd on geo.id = crd.geojson_id WHERE go.germplasm_id = g.id
                       ),
                       '[]'::json
               ),
               'germplasmPUI', g.germplasmpui,
               'germplasmPreprocessing', g.germplasm_preprocessing,
               'instituteCode', gi.institute_code,
               'instituteName', gi.institute_name,
               'pedigree', COALESCE(this_node.pedigree_string, ''),  -- TODO!
               'seedSource', g.seed_source,
               'seedSourceDescription', g.seed_source_description,
               'species', g.species,
               'speciesAuthority', g.species_authority,
           -- TODO: store actual text values for storageTypes in the database!! This is only for demo purpose, the data isn't meaningful.
               'storageTypes', COALESCE((SELECT json_agg(json_build_object('code', stor.type_of_germplasm_storage_code, 'description', 'TODO'))
                                         FROM germplasm_entity_type_of_germplasm_storage_code stor WHERE stor.germplasm_entity_id = g.id), '[]'::json),
               'subtaxa', g.subtaxa,
               'subtaxaAuthority', g.subtaxa_authority,
               'synonyms', COALESCE((SELECT json_agg(json_build_object('synonym', s.synonym, 'type', s.type)) FROM germplasm_synonym s WHERE s.germplasm_id = g.id), '[]'::json),
               'taxonIds', COALESCE((SELECT json_agg(json_build_object('sourceName', taxon.source_name, 'taxonId', taxon.taxon_id)) FROM germplasm_taxon taxon WHERE taxon.germplasm_id = g.id), '[]'::json)
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
GROUP BY
    g.id, g.germplasm_name, g.accession_number, g.additional_info, g.acquisition_date,
    g.biological_status_of_accession_code, g.breeding_method_id, g.crop_id, g.seed_source,
    g.seed_source_description, g.species, g.species_authority, g.subtaxa, g.subtaxa_authority,
    g.collection, g.germplasm_preprocessing,
    gi.institute_code, gi.institute_name,
    bm.name,
    c.crop_name,
    this_node.pedigree_string
;