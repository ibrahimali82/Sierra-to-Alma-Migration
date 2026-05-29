/*
-- Ibrahim Ali
-- Auraria Library - University of Colorado Denver
-- Sierra Fines Extract With Checkdigit
*/

SELECT 

    'p' || 
    patron_rm.record_num ||
    
    CASE 
        WHEN (
            (
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
        )
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

    AS "RECORD #(PATRON)",

    patron_view.barcode 
    AS "PATRON BARCODE",

    concat(item_view.record_type_code,item_view.record_num) 
    AS "RECORD #(ITEM)",

    assessed_gmt::timestamp 
    AS "ASSESSED DATE",

    trunc((item_charge_amt + processing_fee_amt + billing_fee_amt),2) 
    AS "TOTAL CHARGES",

    invoice_num 
    AS "INVOICE",

    trunc(paid_amt,2) 
    AS "PAID AMOUNT",

    trunc(item_charge_amt,2) 
    AS "ITEM FEE",

    trunc(processing_fee_amt,2) 
    AS "PROCESSING FEE",

    trunc(billing_fee_amt,2) 
    AS "BILLING FEE",

    description 
    AS "FINE COMMENT",

    checkout_gmt::timestamp 
    AS "OUT DATE",

    due_gmt::timestamp 
    AS "DUE DATE",

    returned_gmt::timestamp 
    AS "RETURNED DATE",

    charge_code 
    AS "CHARGE TYPE",

    title 
    AS "ITEM TITLE"

FROM sierra_view.fine

LEFT JOIN sierra_view.item_view 
ON fine.item_record_metadata_id = item_view.id

LEFT JOIN sierra_view.patron_view 
ON fine.patron_record_id = patron_view.id

LEFT JOIN sierra_view.record_metadata AS patron_rm
ON fine.patron_record_id = patron_rm.id

ORDER BY 1;
