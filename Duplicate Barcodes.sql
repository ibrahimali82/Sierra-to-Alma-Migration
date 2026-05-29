/*
----Retrieves all current patron fines from Sierra
----Ibrahim Ali
----Auraria Library - University of Colorado Denver
----Duplicate Barcodes
*/

SELECT
	p.index_entry AS "Barcode",
	COUNT (p.index_entry) AS "Count"
FROM
	sierra_view.phrase_entry p
WHERE
	p.index_tag = 'b'
GROUP BY p.index_entry
HAVING COUNT (p.index_entry) > 1;
--
-- Duplicate Barcodes with item Numbers
--
SELECT
    p.index_entry AS "Barcode",
    COUNT(p.index_entry) AS "Count",
    STRING_AGG(rm.record_type_code || rm.record_num || 'a', ', ') AS "Item_Numbers"
FROM
    sierra_view.phrase_entry p
JOIN
    sierra_view.record_metadata rm ON p.record_id = rm.id
WHERE
    p.index_tag = 'b'
    AND rm.deletion_date_gmt IS NULL -- Excludes deleted records
GROUP BY 
    p.index_entry
HAVING 
    COUNT(p.index_entry) > 1
ORDER BY 
    "Count" DESC;