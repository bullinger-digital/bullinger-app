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
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";

declare variable $api:QUERY_OPTIONS := map {
    "leading-wildcard": "yes",
    "filter-rewrite": "yes"
};

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

declare function api:person-filter($filter as xs:string?, $key as xs:string, $role as xs:string) {
    let $person := id(xmldb:decode($key), $config:persons)
    let $log := util:log("info", "api:person-filter: found person: " || $person/@xml:id/string())
    let $matches := 
        for $id in $person//tei:persName/@xml:id
            return (
                let $log := util:log("info", "find letters with id : " || $id)
                return
                    collection($config:data-default)/tei:TEI//tei:correspAction[@type=$role]//tei:persName[@ref = $id]
            )
    let $log := util:log("info", "app:mentions: $matches: " || count($matches) || " in " || $config:data-default)
    return
        for $match in $matches
            let $root := root($match)
            group by $id := $root//tei:TEI/@xml:id/string()
            order by $id ascending
            return
                $root[1]//tei:TEI
};

declare function api:person-is-sender($request as map(*)) {    
    let $key := $request?parameters?key
    let $sortBy := $request?parameters?order
    let $sortDir := $request?parameters?dir
    let $limit := $request?parameters?limit
    let $start := $request?parameters?start    
    let $filter := $request?parameters?search
    let $log := util:log("info", "api:person-is-sender " || $key)
    let $entries := api:person-filter($filter,$key, "sent")    
    let $subset := subsequence($entries, $start, $limit)
    return (
        session:set-attribute($config:session-prefix || ".sender.hits", $entries),
        session:set-attribute($config:session-prefix || ".sender.hitCount", count($entries)),
        map {
            "count": count($entries),
            "results":
                array {
                    for $letter in $subset
                        let $id := $letter/@xml:id/string()
                        let $title := $letter//tei:titleStmt/tei:title/text()
                        let $send-place := id($letter//tei:correspAction[@type="sent"]/tei:placeName/@source/string(), $config:localities)
                        let $send-place-name := api:get-place-name($send-place)
                        let $date := api:handle-date($letter//tei:correspAction[@type="sent"]/tei:date)
                        let $recipients := api:get-correspAction($letter//tei:correspAction[@type="received"])
                        let $recipients-place := id($letter//tei:correspAction[@type="received"]/tei:placeName/@source/string(), $config:localities)
                        let $recipients-place-name := api:get-place-name($recipients-place)
                        return
                            map {                            
                                "title": <a href="../{$id}">{$title}</a>,
                                "place": $send-place-name,
                                "date":$date,
                                "recipients":$recipients,
                                "recipients-place":$recipients-place-name
                            }
                }
        }
)};

declare function api:person-is-recipient($request as map(*)) {    
    let $key := $request?parameters?key
    let $sortBy := $request?parameters?order
    let $sortDir := $request?parameters?dir
    let $limit := $request?parameters?limit
    let $start := $request?parameters?start    
    let $filter := $request?parameters?search
    let $log := util:log("info", "api:person-is-recipient " || $key)
    let $entries := api:person-filter($filter,$key, "received")    
    let $subset := subsequence($entries, $start, $limit)
    return (
        session:set-attribute($config:session-prefix || ".receiver.hits", $entries),
        session:set-attribute($config:session-prefix || ".receiver.hitCount", count($entries)),
        map {
            "count": count($entries),
            "results":
                array {
                    for $letter in $subset
                        let $id := $letter/@xml:id/string()
                        let $title := $letter//tei:titleStmt/tei:title/text()
                        let $send-place := id($letter//tei:correspAction[@type="sent"]/tei:placeName/@source/string(), $config:localities)
                        let $send-place-name := api:get-place-name($send-place)
                        let $date := api:handle-date($letter//tei:correspAction[@type="sent"]/tei:date)
                        let $senders := api:get-correspAction($letter//tei:correspAction[@type="sent"])
                        let $recipients-place := id($letter//tei:correspAction[@type="received"]/tei:placeName/@source/string(), $config:localities)
                        let $recipients-place-name := api:get-place-name($recipients-place)                        
                        return
                            map {                            
                                "title": <a href="../{$id}">{$title}</a>,
                                "place": $send-place-name,
                                "date":$date,
                                "senders":$senders,
                                "recipients-place":$recipients-place-name
                            }
                }
        }
)};


declare function api:get-correspAction($corresp as element(tei:correspAction)?){
    let $entities := for $entity in $corresp/tei:*
                        return
                            typeswitch($entity)
                                case element(tei:persName) return (api:get-persName($entity))
                                case element(tei:orgName) return (api:get-orgName($entity))
                                case element(tei:roleName) return (api:get-roleName($entity))
                                default return () 
    return
        string-join($entities, "; ")
};

declare function api:get-persName($persName as element(tei:persName)?){
    let $person := id($persName/@ref, $config:persons)    
    (: let $log := util:log("info", "api:get-persName persName/@ref: " || $persName/@ref) :)
    return  
        $person/tei:forename/text() || " " || $person/tei:surname/text()
};

declare function api:get-orgName($orgName as element(tei:orgName)?){
    let $org := id($orgName/@ref, $config:orgs)
    let $log := util:log("info", "api:get-orgName orgName/@ref: " || $orgName/@ref)
    return  
        $org/tei:name[@xml:lang="de"][@type=$orgName/@type]/text()

};
declare function api:get-roleName($roleName as element(tei:roleName)?){
    let $role := id($roleName/@ref, $config:roles)
    let $log := util:log("info", "api:get-roleName roleName/@ref: " || $roleName/@ref)
    let $form := $role/tei:form[@xml:lang="de"][@type=$roleName/@type]/text()
    let $place := 
        if($roleName/tei:placeName/@ref) 
        then (
            let $role-place := id($roleName/tei:placeName/@ref/string(), $config:localities)
            return
                api:get-place-name($role-place)
        ) else ()
    let $org :=
        if($roleName/tei:orgName/@ref)
        then ( api:get-orgName($roleName/tei:orgName)  )
        else ()

    return  
        string-join(($form, $org, $place), " ")
};

declare function api:get-place-name($place as element(tei:place)?){
    if($place/tei:settlement)
    then ($place/tei:settlement/text())
    else if($place/tei:district)  
    then ($place/tei:district/text())
    else ($place/tei:country/text())
};

(: declare function api:handle-date($date as element(tei:date)){ :)
declare function api:handle-date($date){    
    if($date/@when)
        then ( api:format-date($date/@when) ) 
    else if($date/@notBefore and $date/@notAfter)
        then(
            "Zwischen " || api:format-date($date/@notBefore/string()) || " und " || api:format-date($date/@notAfter/string())
        )
    else if($date/@notBefore)
    then ( "Nicht vor " || api:format-date($date/@notBefore/string()))
    else if($date/@notAfter)
    then ( "Nicht nach " || api:format-date($date/@notAfter/string()))    
    else ()
};

declare function api:format-date($date as xs:string?){
    if(string-length($date) = 0) 
    then ()
    else if(matches($date, '^\d{4}$'))
    then $date
    else if (matches($date, '^\d{4}-\d{2}$')) then
        format-date(xs:date($date || '-01'), '[MNn] [Y]', "de", (), ())
    else
        format-date(xs:date($date), '[D]. [MNn] [Y]', "de", (), ())
};