CREATE OR REPLACE FUNCTION to_list_type(value int)
    RETURNS text AS $$
DECLARE
    result text;
BEGIN
    -- TODO: hardcoded (germplasm=0,markers=1,programs=2,trials=3,studies=4,observationUnits=5,observations=6,observationVariables=7,samples=8).
    CASE value
        WHEN 0 THEN result := 'germplasm';
        WHEN 1 THEN result := 'markers';
        WHEN 2 THEN result := 'programs';
        WHEN 3 THEN result := 'trials';
        WHEN 4 THEN result := 'studies';
        WHEN 5 THEN result := 'observationUnits';
        WHEN 6 THEN result := 'observations';
        WHEN 7 THEN result := 'observationVariables';
        WHEN 8 THEN result := 'samples';
    END CASE;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION search_lists(
    commonCropNames text[],
    dateCreatedRangeEnd timestamp,
    dateCreatedRangeStart timestamp,
    dateModifiedRangeEnd timestamp,
    dateModifiedRangeStart timestamp,
    externalReferenceIds text[],
    externalReferenceSources text[],
    listDbIds text[],
    listNames text[],
    listOwnerNames text[],
    listOwnerPersonDbIds text[],
    listSources text[],
    listType text,
    programDbIds text[],
    programNames text[]
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
                                                    'additionalInfo', l.additional_info,
                                                    'dateCreated', to_char(l.date_created, 'YYYY-MM-DD"T"HH24:MI:SSZ'),
                                                    'dateModified', to_char(l.date_modified, 'YYYY-MM-DD"T"HH24:MI:SSZ'),
                                                    'externalReferences', COALESCE((SELECT json_agg(
                                                                                                   json_build_object(
                                                                                                           'referenceID', xr.external_reference_id,
                                                                                                           'referenceId', xr.external_reference_id,
                                                                                                           'referenceSource', xr.external_reference_source))
                                                                                    FROM list_external_references lxr
                                                                                        LEFT JOIN external_reference xr ON lxr.external_references_id = xr.id
                                                                                    WHERE lxr.list_entity_id = l.id),
                                                                                   '[]'::json),
                                                    'listDbId', l.id,
                                                    'listDescription', l.description,
                                                    'listName', l.list_name,
                                                    'listOwnerName', l.list_owner_name,
                                                    'listOwnerPersonDbId', l.list_owner_person_id,
                                                    'listSize', (SELECT COUNT(li.id) FROM list_item li WHERE li.list_id = l.id),
                                                    'listSource', l.list_source,
                                                    'listType', to_list_type(l.list_type) -- l.list_type  -- TODO: change from enum to text.
                                            )
                                    ),
                                    '[]'::json
                            )
                  )

            )
            FROM
                list l
            WHERE
                -- TODO: list doesn't seem to have a relationship to crop.
--                 (commonCropNames IS NULL OR commonCropNames  @> ARRAY[])
--                 AND
                (dateCreatedRangeEnd IS NULL OR dateCreatedRangeEnd <= l.date_created)
                AND
                (dateCreatedRangeStart IS NULL OR dateCreatedRangeStart >= l.date_created)
                AND
                (dateModifiedRangeEnd IS NULL OR dateModifiedRangeEnd <= l.date_modified)
                AND
                (dateModifiedRangeStart IS NULL OR dateModifiedRangeStart >= l.date_modified)
                AND
                (listDbIds IS NULL OR listDbIds  @> ARRAY[l.id])
                AND
                (listNames IS NULL OR listNames  @> ARRAY[l.list_name])
                AND
                (listOwnerNames IS NULL OR listOwnerNames  @> ARRAY[l.list_owner_name])
                AND
                (listOwnerPersonDbIds IS NULL OR listOwnerPersonDbIds  @> ARRAY[l.list_owner_person_id])
                AND
                (listSources IS NULL OR listSources  @> ARRAY[l.list_source])
                AND
                (listType IS NULL OR listType = to_list_type(l.list_type))
                -- TODO: list doesn't seem to have a relationship to program.
--                 AND
--                 (programDbIds IS NULL OR programDbIds  @> ARRAY[])
--                 AND
--                 (programNames IS NULL OR programNames  @> ARRAY[])
                AND
                (
                    COALESCE(externalReferenceIds, externalReferenceSources) IS NULL
                        OR
                    (l.id IN (
                        SELECT list_entity_id
                        FROM list_external_references lxr JOIN external_reference xr ON lxr.external_references_id = xr.id
                        WHERE externalReferenceIds @> ARRAY[xr.external_reference_id] AND externalReferenceSources @> ARRAY[xr.external_reference_source]
                        )
                    )
                )
    );
END;
$$ LANGUAGE plpgsql;
