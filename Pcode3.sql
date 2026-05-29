/*
-- Ibrahim Ali
-- Auraria Library - University of Colorado Denver
-- Pcode3
*/

SELECT DISTINCT 
    'p' || rm.record_num || 'a' AS record_number, -- Using 'a' as the standard placeholder
    patron.barcode,
    name.first_name,
    name.last_name,
    patron.pcode3,
    pcode3property.name AS pcode3_name,
    patron.home_library_code,
    patron.ptype_code,
    rm.creation_date_gmt
FROM 
    sierra_view.patron_view AS patron
JOIN 
    sierra_view.record_metadata rm ON patron.id = rm.id AND rm.record_type_code = 'p'
JOIN 
    sierra_view.patron_record_fullname AS name ON patron.id = name.patron_record_id
JOIN (
    SELECT 
        propertyname.name, 
        property.code::integer AS code_int
    FROM 
        sierra_view.user_defined_property property
    JOIN 
        sierra_view.user_defined_category propertycategory ON property.user_defined_category_id = propertycategory.id
    JOIN 
        sierra_view.user_defined_property_name AS propertyname ON property.id = propertyname.user_defined_property_id
    WHERE 
        propertycategory.code = 'pcode3'
) AS pcode3property ON patron.pcode3 = pcode3property.code_int
    AND rm.deletion_date_gmt IS NULL