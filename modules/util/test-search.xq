xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

declare variable $local:QUERY_OPTIONS := map {
    "leading-wildcard": "yes",
    "filter-rewrite": "yes"
};
let $filter := ""
let $key :="P495"
let $role := "sent"

let $log := util:log("info", ("api:person-filter $filter: ", $filter, " - $key: ", $key, " - $role: ", $role) )
let $options :=
    map:merge((
        $local:QUERY_OPTIONS,
        map {
            "facets":
                map:merge((
                    for $param in request:get-parameter-names()[starts-with(., 'facet-')]
                    let $dimension := substring-after($param, 'facet-')
                    return
                        map {
                            $dimension: request:get-parameter($param, ())
                        }
                ))
        }
    ))

let $log := util:log("info", ("api:person-filter: found person: ", $options))
let $person := id(xmldb:decode($key), $config:persons)

let $matches := collection($config:data-default)/tei:TEI//tei:correspAction[@type=$role]//tei:persName[@ref = $person//tei:persName/@xml:id]                
let $letters := 
    for $match in $matches
        let $root := root($match)
        group by $id := $root//tei:TEI/@xml:id/string()
        order by $id ascending
        return
            $root[1]
            
let $log := util:log("info", ("api:person-filter: found letters: ", count($letters), " - filter enabled: ", boolean($filter)))
let $result := 
    if ($filter) then
        $letters//tei:text[ft:query(., 'title:(' || $filter || '*)', $options)] 
    else    
        $letters[ft:query(.//tei:text, 'title:*', $options)]
let $log := util:log("info", ("api:person-filter: filtered letters :", count($result)))
return 
    $result