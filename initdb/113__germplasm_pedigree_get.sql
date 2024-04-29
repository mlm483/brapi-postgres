
CREATE OR REPLACE FUNCTION get_pedigree(
    "germplasmDbId" text
)
    RETURNS json AS $$
BEGIN
    RETURN (
        SELECT json_build_object(
            '@context', '[]'::json,
            'metadata', '{}'::json,  -- TODO: pagination, count, status, etc.
            'result', (
                SELECT json_build_object(
                    'crossingProjectDbId', node.crossing_project_id,
                    'crossingYear', node.crossing_year,  -- TODO
                    'familyCode', node.family_code,
                    'germplasmDbId', "germplasmDbId",
                    'germplasmName', germ.germplasm_name,
                    'parents', json_agg(
                        (
                            SELECT json_build_object(
                                'germplasmDbId', parent.id,
                                'germplasmName', parent.germplasm_name,
                                'parentType', to_parent_type(e.parent_type)
                            )
                            FROM
                                pedigree_node parent_node
                                JOIN
                                pedigree_edge e ON parent_node.id = e.connceted_node_id AND e.edge_type = edge_type_to_int('parent') -- TODO: hardcoded EdgeType (parent=0, child=1, sibling=2)
                                JOIN
                                germplasm parent ON parent_node.germplasm_id = parent.id
                            WHERE e.this_node_id = (SELECT child_node.id
                                                 FROM pedigree_node child_node
                                                 WHERE child_node.germplasm_id = "germplasmDbId")
                        )
                    ),
                    'pedigree', node.pedigree_string,
                    'siblings', json_agg(
                        (
                            SELECT
                            json_build_object(
                                    'germplasmDbId', sibling.id,
                                    'germplasmName', sibling.germplasm_name
                            )
                            FROM
                            pedigree_node sibling_node
                            JOIN
                            pedigree_edge pe ON sibling_node.id = pe.this_node_id AND pe.edge_type = edge_type_to_int('parent')
                            JOIN
                            germplasm sibling ON sibling_node.germplasm_id = sibling.id
                            WHERE
                            pe.connceted_node_id IN
                            (
                                SELECT parent_node.id
                                FROM
                                    pedigree_node parent_node
                                    JOIN
                                    pedigree_edge e ON parent_node.id = e.connceted_node_id AND e.edge_type = edge_type_to_int('parent')
                                WHERE e.this_node_id = (SELECT id FROM pedigree_node WHERE germplasm_id = "germplasmDbId")
                            )
                        )
                    )
                )
                FROM
                    germplasm germ
                    JOIN
                    pedigree_node node ON germ.id = node.germplasm_id
                WHERE
                    germ.id = "germplasmDbId"
            )
        )
    );
END
$$ LANGUAGE plpgsql;
