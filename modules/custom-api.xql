xquery version "3.1";

(:~
 : This is the place to import your own XQuery modules for either:
 :
 : 1. custom API request handling functions
 : 2. custom templating functions to be called from one of the HTML templates
 :)
module namespace api="http://teipublisher.com/api/custom";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: Add your own module imports here :)
import module namespace app="teipublisher.com/app" at "app.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";


(:~
 : Keep this. This function does the actual lookup in the imported modules.
 :)
declare function api:lookup($name as xs:string, $arity as xs:integer) {
    try {
        function-lookup(xs:QName($name), $arity)
    } catch * {
        ()
    }
};

declare function api:persons-all-list($request as map(*)) {
    let $log := util:log("info","api:persons-all-list") 
    let $search := normalize-space($request?parameters?search)
    let $letterParam := $request?parameters?category    
    let $sortDir := $request?parameters?dir
    let $limit := $request?parameters?limit      
    let $log := util:log("info","api:names-all-list $search:"||$search || " - $letterParam:"||$letterParam||" - $limit:" || $limit ) 
    let $items :=     
            if ($search and $search != '') 
            then (
                $config:persons//tei:person[ft:query(., 'name:(' || $search || '*)')]
            ) 
            else (
                $config:persons//tei:person
            )            
    let $log := util:log("info", map {
        "function":"api:names-all-list $search:",
        "items count":count($items)
    })             
    let $sorted_items := for $item in $items
                            order by $item/tei:persName[@type='main'] ascending
                            return
                                $item
    let $log := util:log("info","api:names-all-list  found items:"||count($sorted_items) ) 
    let $byKey := for-each($sorted_items, function($item as element()) {
        let $label := $item/tei:persName[@type='main']/@n/string()
        let $sortKey :=
            if (starts-with($label, "von ")) then
                substring($label, 5)
            else
                $label
        return
            [lower-case($sortKey), $label, $item]
    })
    let $sorted := api:sort($byKey, $sortDir)
    let $letter := 
        if ((count($sorted_items) < $limit)  or $search != '') then 
            "[A-Z]"
        else if (not($letterParam) or $letterParam = '') then (
            substring($sorted[1]?1, 1, 1) => upper-case()
        )
        else
            $letterParam
    let $byLetter :=
        if ($letter = '[A-Z]') then
            $sorted
        else
            filter($sorted, function($entry) {
                starts-with($entry?1, lower-case($letter))
            })

    return
        map {
            "items": api:output-name($byLetter, $letter, $search),
            "categories":
                if ((count($sorted_items) < $limit)  or $search != '') then
                    []
                else array {
                    for $index in 1 to string-length('0123456789AÄBCDEFGHIJKLMNOÖPQRSTUÜVWXYZ')
                    let $alpha := substring('0123456789AÄBCDEFGHIJKLMNOÖPQRSTUÜVWXYZ', $index, 1)
                    let $hits := count(filter($sorted, function($entry) { starts-with($entry?1, lower-case($alpha))}))
                    where $hits > 0
                    return
                        map {
                            "category": $alpha,
                            "count": $hits
                        },
                    map {
                        "category": "[A-Z]",
                        "count": count($sorted),
                        "label": <pb-i18n key="all">Alle</pb-i18n>
                    }
                }
        }
};

declare function api:output-name($list, $letter as xs:string, $search as xs:string?) {
    array {
        for $item in $list
            let $log := util:log("info", map {
                "function":"api:output-name", 
                "$item":$item?3
            })
            return
            if(string-length($item?2)>0)
            then (
            let $type := local-name($item?3)   
            let $letterParam := if ($letter = "[A-Z]") then substring(($item?3/tei:persName[@type='main']/@n/string()), 1, 1) else $letter
            let $params := "&amp;category=" || $letterParam || "&amp;search=" || $search
            return
                <span class="{$type}List">
                    <a href="{$item?3/@xml:id}?{$params}">{$item?2}</a>                    
                </span>
            ) else()
    }
};

declare function api:localities-all-list($request as map(*)) {
    let $log := util:log("info","api:localities-all-list") 
    let $search := normalize-space($request?parameters?search)
    let $letterParam := $request?parameters?category    
    let $sortDir := $request?parameters?dir
    let $limit := $request?parameters?limit      
    let $log := util:log("info","api:names-all-list $search:"||$search || " - $letterParam:"||$letterParam||" - $limit:" || $limit ) 
    let $items :=     
            if ($search and $search != '') 
            then (
                $config:localities//tei:place[ft:query(., 'name:(' || $search || '*)')]
            ) 
            else (
                $config:localities//tei:place
            )            
    let $log := util:log("info", map {
        "function":"api:names-all-list $search:",
        "items count":count($items)
    })             
    let $sorted_items := for $item in $items
                            order by $item/tei:settlement,$item/tei:district, $item/tei:country  ascending
                            return
                                $item
    let $log := util:log("info","api:names-all-list  found items:"||count($sorted_items) ) 
    let $byKey := for-each($sorted_items, function($item as element()) {
        let $label := $item/tei:settlement || " / " || $item/tei:district || " / " || $item/tei:country
        return
            [lower-case($label), $label, $item]
    })
    let $sorted := api:sort($byKey, $sortDir)
    let $letter := 
        if ((count($sorted_items) < $limit)  or $search != '') then 
            "[A-Z]"
        else if (not($letterParam) or $letterParam = '') then (
            substring($sorted[1]?1, 1, 1) => upper-case()
        )
        else
            $letterParam
    let $byLetter :=
        if ($letter = '[A-Z]') then
            $sorted
        else
            filter($sorted, function($entry) {
                starts-with($entry?1, lower-case($letter))
            })

    return
        map {
            "items": api:output-locality($byLetter, $letter, $search),
            "categories":
                if ((count($sorted_items) < $limit)  or $search != '') then
                    []
                else array {
                    for $index in 1 to string-length('0123456789AÄBCDEFGHIJKLMNOÖPQRSTUÜVWXYZ')
                    let $alpha := substring('0123456789AÄBCDEFGHIJKLMNOÖPQRSTUÜVWXYZ', $index, 1)
                    let $hits := count(filter($sorted, function($entry) { starts-with($entry?1, lower-case($alpha))}))
                    where $hits > 0
                    return
                        map {
                            "category": $alpha,
                            "count": $hits
                        },
                    map {
                        "category": "[A-Z]",
                        "count": count($sorted),
                        "label": <pb-i18n key="all">Alle</pb-i18n>
                    }
                }
        }
};

declare function api:output-locality($list, $letter as xs:string, $search as xs:string?) {
    array {
        for $item in $list
            let $log := util:log("info", map {
                "function":"api:output-name", 
                "$item":$item
            })            
            return
                if(string-length($item?2)>0)
                then (
                let $place := $item?3
                let $title := $place/tei:settlement || " / " || $place/tei:district || " / " || $place/tei:country
                let $categoryParam := if ($letter = "[A-Z]") then substring($title, 1, 1) else $letter
                let $params := "&amp;category=" || $categoryParam || "&amp;search=" || $search
                let $label := $title                
                let $coords := tokenize($place/tei:location/tei:geo)
                return
                    element span {
                        attribute class { "place" },
                        element span {
                            element a {
                                attribute href { $place/@xml:id || "?" || $params },
                                $label
                            }
                        },
                        if(string-length(normalize-space($place/tei:location/tei:geo)) > 0)
                        then (
                            element pb-geolocation {
                                attribute latitude { $coords[1] },
                                attribute longitude { $coords[2] },
                                attribute label { $label},
                                attribute emit {"map"},
                                attribute event { "click" },
                                attribute zoom { 9 },

                                element iron-icon {
                                    attribute icon {"maps:map" }
                                }
                            }
                        )
                        else ()
                    }
                ) else()
    }
};

declare function api:localities-all($request as map(*)) {    
    let $places :=
        for $place in $config:localities//tei:place
            order by $place/tei:settlement,$place/tei:district, $place/tei:country 
        return
            $place
    return
        array {
            for $place in $places
            return
                if(string-length(normalize-space($place/tei:location/tei:geo)) > 0)
                then (
                    let $tokenized := tokenize($place/tei:location/tei:geo)
                    return
                        map {
                            "latitude":$tokenized[1],
                            "longitude":$tokenized[2],
                            "label":$place/tei:settlement/text() || " / " || $place/tei:district/text() || " / " || $place/tei:country/text(),
                            "id":$place/@xml:id/string()
                        }
                ) else()
            }
};


declare function api:sort($persons as array(*)*, $dir as xs:string) {        
    let $sorted :=
        sort($persons,"?", function($entry) {
            $entry?1
        })
    return
        if ($dir = "asc") then
            $sorted
        else
            reverse($sorted)
};
