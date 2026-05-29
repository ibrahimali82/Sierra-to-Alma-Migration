/*
    Retrieves all current patron fines from Sierra
	Ibrahim Ali
	Auraria Library - University of Colorado Denver
*/
-- this query will get hold, bib, and item information from holds that are 
-- INN-Reach or ILL 
-----

SELECT
p.ptype_code,
p.home_library_code as patron_home_library_code,
n.last_name || ', ' ||n.first_name || COALESCE(' ' || NULLIF(n.middle_name, ''), '') AS "patron_name",
r.record_type_code || r.record_num as record_num,

CASE
	WHEN r.record_type_code = 'i' THEN (
		SELECT
		-- i.item_status_code
		CASE
			WHEN i.item_status_code = '-' THEN 'AVAILABLE'
			WHEN i.item_status_code = 'm' THEN 'MISSING'
			WHEN i.item_status_code = 'z' THEN 'CL RETURNED'
			WHEN i.item_status_code = 'o' THEN 'LIB USE ONLY'
			WHEN i.item_status_code = 'n' THEN 'BILLED NOTPAID'
			WHEN i.item_status_code = '$' THEN 'BILLED PAID'
			WHEN i.item_status_code = 't' THEN 'IN TRANSIT'
			WHEN i.item_status_code = '!' THEN 'ON HOLDSHELF'
			WHEN i.item_status_code = 'l' THEN 'LOST'
			-- At INN-Reach sites, the following additional codes and definitions are standard:
			WHEN i.item_status_code = '@' THEN 'OFF SITE'
			WHEN i.item_status_code = '#' THEN 'RECEIVED'
			WHEN i.item_status_code = '%' THEN 'RETURNED'
			WHEN i.item_status_code = '&' THEN 'REQUEST'
			WHEN i.item_status_code = '_' THEN 'REREQUEST'
			WHEN i.item_status_code = '(' THEN 'PAGED'
			WHEN i.item_status_code = ')' THEN 'CANCELLED'
			WHEN i.item_status_code = '1' THEN 'LOAN REQUESTED'
			ELSE i.item_status_code
		END
		FROM
		sierra_view.item_record as i

		WHERE
		i.record_id = r.id

		LIMIT 1
	)
	ELSE NULL
END as item_record_status,

-- get the bib record id from holds (which can be item-level, volume-level, or bib-level)
CASE
	WHEN r.record_type_code = 'i' THEN (
		SELECT
		l.bib_record_id

		FROM
		sierra_view.bib_record_item_record_link as l

		WHERE
		l.item_record_id = h.record_id

		LIMIT 1
	)

	WHEN r.record_type_code = 'j' THEN (
		SELECT
		l.bib_record_id

		FROM
		sierra_view.bib_record_volume_record_link as l

		WHERE
		l.volume_record_id = h.record_id

		LIMIT 1
	)

	WHEN r.record_type_code = 'b' THEN (
		h.record_id
	)

	ELSE NULL
END as bib_record_id,

CASE
	WHEN h.status = '0' THEN 'On hold'
	WHEN h.status = 'b' THEN 'Bib hold ready for pickup.'
	WHEN h.status = 'j' THEN 'Volume hold ready for pickup.'
	WHEN h.status = 'i' THEN 'Item hold ready for pickup.'
	WHEN h.status = 't' THEN 'Bib, item, or volume in transit to pickup location.'
END as hold_status,

h.*

FROM
sierra_view.hold as h

LEFT OUTER JOIN
sierra_view.record_metadata as r
ON
  r.id = h.record_id

LEFT OUTER JOIN
sierra_view.patron_record as p
ON
  p.record_id = h.patron_record_id

LEFT OUTER JOIN
sierra_view.patron_record_fullname as n
ON
  n.patron_record_id = h.patron_record_id

WHERE
-- uncomment / comment out here to limit to INN-Reach / ILL holds 
(	is_ir IS true
	OR is_ill IS true
)
;
-----

-----
SELECT 
p.best_title,
p.publish_year,
t.*

FROM 
temp_holds_data as t

JOIN
sierra_view.bib_record_property as p
ON
  p.bib_record_id = t.bib_record_id




-- this query will get hold, bib, and item information from holds that are 
-- INN-Reach or ILL
-- Includes:
--   - proper Sierra check digit for patron record #
--   - patron barcode
--   - item barcode
--   - holds placed before 2026-01-01

SELECT
p.ptype_code,

p.home_library_code as patron_home_library_code,

n.last_name || ', ' || n.first_name || 
COALESCE(' ' || NULLIF(n.middle_name, ''), '') AS patron_name,

-- Patron record number with Sierra check digit
'p' || patron_rm.record_num ||

CASE 
    WHEN (
        (
            SELECT SUM(
                digit::INTEGER * weight
            )
            FROM (
                SELECT 
                    substr(patron_rm.record_num::varchar, gs, 1) AS digit,
                    length(patron_rm.record_num::varchar) - gs + 2 AS weight
                FROM generate_series(1,length(patron_rm.record_num::varchar)) gs
            ) s
        ) % 11
    ) = 10
    THEN 'x'

    ELSE (
        (
            SELECT SUM(
                digit::INTEGER * weight
            )
            FROM (
                SELECT 
                    substr(patron_rm.record_num::varchar, gs, 1) AS digit,
                    length(patron_rm.record_num::varchar) - gs + 2 AS weight
                FROM generate_series(1,length(patron_rm.record_num::varchar)) gs
            ) s
        ) % 11
    )::varchar
END

AS patron_record_num,

pv.barcode AS patron_barcode,

r.record_type_code || r.record_num as record_num,

iv.barcode AS item_barcode,

CASE
	WHEN r.record_type_code = 'i' THEN (
		SELECT
		CASE
			WHEN i.item_status_code = '-' THEN 'AVAILABLE'
			WHEN i.item_status_code = 'm' THEN 'MISSING'
			WHEN i.item_status_code = 'z' THEN 'CL RETURNED'
			WHEN i.item_status_code = 'o' THEN 'LIB USE ONLY'
			WHEN i.item_status_code = 'n' THEN 'BILLED NOTPAID'
			WHEN i.item_status_code = '$' THEN 'BILLED PAID'
			WHEN i.item_status_code = 't' THEN 'IN TRANSIT'
			WHEN i.item_status_code = '!' THEN 'ON HOLDSHELF'
			WHEN i.item_status_code = 'l' THEN 'LOST'
			WHEN i.item_status_code = '@' THEN 'OFF SITE'
			WHEN i.item_status_code = '#' THEN 'RECEIVED'
			WHEN i.item_status_code = '%' THEN 'RETURNED'
			WHEN i.item_status_code = '&' THEN 'REQUEST'
			WHEN i.item_status_code = '_' THEN 'REREQUEST'
			WHEN i.item_status_code = '(' THEN 'PAGED'
			WHEN i.item_status_code = ')' THEN 'CANCELLED'
			WHEN i.item_status_code = '1' THEN 'LOAN REQUESTED'
			ELSE i.item_status_code
		END

		FROM
		sierra_view.item_record as i

		WHERE
		i.record_id = r.id

		LIMIT 1
	)

	ELSE NULL
END as item_record_status,

-- get the bib record id from holds
CASE
	WHEN r.record_type_code = 'i' THEN (
		SELECT
		l.bib_record_id

		FROM
		sierra_view.bib_record_item_record_link as l

		WHERE
		l.item_record_id = h.record_id

		LIMIT 1
	)

	WHEN r.record_type_code = 'j' THEN (
		SELECT
		l.bib_record_id

		FROM
		sierra_view.bib_record_volume_record_link as l

		WHERE
		l.volume_record_id = h.record_id

		LIMIT 1
	)

	WHEN r.record_type_code = 'b' THEN (
		h.record_id
	)

	ELSE NULL
END as bib_record_id,

CASE
	WHEN h.status = '0' THEN 'On hold'
	WHEN h.status = 'b' THEN 'Bib hold ready for pickup.'
	WHEN h.status = 'j' THEN 'Volume hold ready for pickup.'
	WHEN h.status = 'i' THEN 'Item hold ready for pickup.'
	WHEN h.status = 't' THEN 'Bib, item, or volume in transit to pickup location.'
END as hold_status,

h.*

FROM
sierra_view.hold as h

LEFT OUTER JOIN
sierra_view.record_metadata as r
ON r.id = h.record_id

LEFT OUTER JOIN
sierra_view.record_metadata as patron_rm
ON patron_rm.id = h.patron_record_id

LEFT OUTER JOIN
sierra_view.patron_record as p
ON p.record_id = h.patron_record_id

LEFT OUTER JOIN
sierra_view.patron_view as pv
ON pv.id = h.patron_record_id

LEFT OUTER JOIN
sierra_view.patron_record_fullname as n
ON n.patron_record_id = h.patron_record_id

LEFT OUTER JOIN
sierra_view.item_view as iv
ON iv.id = h.record_id

WHERE

-- limit to INN-Reach / ILL holds
(
	is_ir IS true
	OR is_ill IS true
)

AND h.placed_gmt < '2026-01-01'

;
