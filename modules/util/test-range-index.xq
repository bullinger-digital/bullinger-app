xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:collection("/db/apps/bullinger-data/data")//tei:text[ft:query(., "text:Bullinger")]:)

(:collection('/db/apps/bullinger-data/data/letters')//tei:TEI:)
let $places := doc("/db/apps/bullinger-data/data/index/localities.xml")//tei:place
let $all-leters := collection('/db/apps/bullinger-data/data/letters')/tei:TEI
let $not-referenced-places := 
    for $place in $places
        let $id := $place/@xml:id/string()
        let $ref-in-letters := $all-leters//tei:placeName/@ref[. = $id]
        let $ref := if($ref-in-letters) then (count($ref-in-letters)) else (0)
        let $source-in-letters := $all-leters//tei:placeName/@source[. = $id]
        let $source := if($source-in-letters) then (count($source-in-letters)) else (0)
        return
            if($ref = 0 and $source = 0 )
            then ($id)
            else () 
return
    $not-referenced-places