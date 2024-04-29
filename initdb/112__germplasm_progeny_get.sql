CREATE OR REPLACE FUNCTION to_parent_type(
    parent_type integer
)
RETURNS text AS $$
DECLARE
    result text;
BEGIN
    -- TODO: hardcoded ParentType (MALE=0, FEMALE=1, SELF=2, POPULATION=3, CLONAL=4)
    CASE parent_type
        WHEN 0 THEN result := 'MALE';
        WHEN 1 THEN result := 'FEMALE';
        WHEN 2 THEN result := 'SELF';
        WHEN 3 THEN result := 'POPULATION';
        WHEN 4 THEN result := 'CLONAL';
    END CASE;
    return result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION edge_type_to_int(edge_type text)
    RETURNS int AS $$
DECLARE
    result int;
BEGIN
    -- TODO: hardcoded EdgeType (parent=0, child=1, sibling=2)
    CASE edge_type
        WHEN 'parent' THEN result := 0;
        WHEN 'child' THEN result := 1;
        WHEN 'sibling' THEN result := 2;
    END CASE;
    RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_progeny(
    "germplasmDbId" text
)
    RETURNS json AS $$
BEGIN
    RETURN (
        SELECT
            json_build_object(
                '@context', '[]'::json,
                'metadata', '{}'::json,  -- TODO: pagination, count, status, etc.
                'result', json_build_object(
                    'germplasmDbId', "germplasmDbId",
                    'germplasmName', (SELECT germplasm_name FROM germplasm WHERE id = "germplasmDbId"),
                    'progeny',
                        COALESCE(
                            json_agg(
                                json_build_object(
                                    'germplasmDbId', progeny.id,
                                    'germplasmName', progeny.germplasm_name,
                                    'parentType', to_parent_type(e.parent_type)
                                )
                            ),
                            '[]'::json
                        )
                )
            )
        FROM
            pedigree_node progeny_node
            LEFT JOIN
            pedigree_edge e ON progeny_node.id = e.this_node_id AND e.edge_type = edge_type_to_int('parent')
            LEFT JOIN
            germplasm progeny ON progeny_node.germplasm_id = progeny.id
        WHERE
            e.connceted_node_id = (SELECT parent_node.id
                                   FROM pedigree_node parent_node
                                   WHERE parent_node.germplasm_id = "germplasmDbId")
    );
END;
$$ LANGUAGE plpgsql;
