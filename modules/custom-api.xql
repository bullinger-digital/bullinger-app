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
import module namespace cr="jinntec.de/cleanup-register-data" at "util/cleanup-register-data.xqm";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace facets="http://teipublisher.com/facets" at "facets.xql";

import module namespace roaster="http://e-editiones.org/roaster";

import module namespace ext="http://teipublisher.com/ext-common" at "ext.xql";
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
    let $key := $request?parameters?key
    let $sortBy := $request?parameters?order
    let $sortDir := $request?parameters?dir
    let $limit := $request?parameters?limit
    let $start := $request?parameters?start
    let $filter := $request?parameters?search
    let $correspondentsOnly := $request?parameters?view = "correspondents"
    
    let $entries := api:persons-all-list-filter($filter, $correspondentsOnly)
    let $sorted := api:persons-all-list-sort($entries, $sortBy, $sortDir)
    let $subset := subsequence($sorted, $start, $limit)
    return (
        session:set-attribute($config:session-prefix || ".persons.hits", $entries),
        session:set-attribute($config:session-prefix || ".persons.hitCount", count($entries)),
        map {
            "count": count($entries),
            "results":
                array {
                    for $person at $index in $subset
                        let $link := function($content) {
                            <a style="color:var(--bb-beige);text-decoration:none;" href="../persons/{$person/@xml:id}">{$content}</a>
                        }
                        return
                            map {
                                "forename": $link(ft:field($person, 'forename')[1]),
                                "surname": $link(ft:field($person, 'surname')[1]),
                                "sent-count": ft:field($person, 'sent-count')[1],
                                "received-count": ft:field($person, 'received-count')[1]
                            }
                }
        })
};

declare function api:persons-all-list-filter($filter as xs:string?, $correspondentsOnly as xs:boolean?) {    
    let $options := api:get-register-query-options()
    let $correspondentsFilter := if ($correspondentsOnly) then " AND (sent-count:[1 TO *] OR received-count:[1 TO *])" else ""
    let $items :=     
            if ($filter and $filter != '') 
            then (
                $config:persons//tei:person[ft:query(., '(all-names:(' || $filter || '*) OR mentioned-names:(' || $filter || '*))' || $correspondentsFilter, $options)]
            ) 
            else (
                $config:persons//tei:person[ft:query(., 'all-names:*' || $correspondentsFilter, $options)]
            )
    return 
        $items
};

declare function api:persons-all-list-sort($entries as element()*, $sortBy as xs:string?, $dir as xs:string?) {
    let $collation := "http://www.w3.org/2013/collation/UCA?lang=de"
    let $sorted :=
        sort($entries, $collation, function($person) {
            switch ($sortBy)
                case "name" return 
                    lower-case(ft:field($person, 'name')[1])
                case "surname" return 
                    lower-case(ft:field($person, 'surname')[1])
                case "forename" return 
                    lower-case(ft:field($person, 'forename')[1])
                case "sent-count" return
                    xs:integer(ft:field($person, 'sent-count')[1])
                case "received-count" return
                    xs:integer(ft:field($person, 'received-count')[1])
                default return
                    lower-case(ft:field($person, 'surname')[1])
        })
    return
        if ($dir = "asc") then
            $sorted
        else
            reverse($sorted)
};

declare function api:localities-all-list($request as map(*)) {
    let $search := normalize-space($request?parameters?search)
    let $letterParam := $request?parameters?category    
    let $sortDir := $request?parameters?dir
    let $limit := $request?parameters?limit      
    
    let $places :=     
            if ($search and $search != '') 
            then (
                $config:localities//tei:place[ft:query(., '(name:(' || $search || '*) OR mentioned-names:(' || $search || '*))', map {
                    "leading-wildcard": "yes",
                    "filter-rewrite": "yes"
                })]
            ) 
            else (
                $config:localities//tei:place[ft:query(., 'name:*', map {
                    "leading-wildcard": "yes",
                    "filter-rewrite": "yes"
                })]
            )            
    
    let $byLetter :=
        map:merge(
            for $place in $places
            let $name := ft:field($place, 'name')[1]
            order by $name
            group by $letter := substring($name, 1, 1) => upper-case()
            return
                map:entry($letter, $place)
        )
    let $letter :=
        if ((count($places) < $limit) or $search != '') then
            "[A-Z]"
        else if (not($letterParam) or $letterParam = '') then
            head(sort(map:keys($byLetter)))
        else
            $letterParam

    let $itemsToShow :=
        if ($letter = '[A-Z]') then
            $places
        else
            $byLetter($letter)
    return
        map {
            "items": api:output-locality($itemsToShow, $letter, $search),
            "categories":
                if ((count($places) < $limit)  or $search != '') then
                    []
                else array {
                    for $index in 1 to string-length('0123456789AÄBCDEFGHIJKLMNOÖPQRSTUÜVWXYZ')
                    let $alpha := substring('0123456789AÄBCDEFGHIJKLMNOÖPQRSTUÜVWXYZ', $index, 1)
                    let $hits := count($byLetter($alpha))
                    where $hits > 0
                    return
                        map {
                            "category": $alpha,
                            "count": $hits
                        },
                    map {
                        "category": "[A-Z]",
                        "count": count($places),
                        "label": <pb-i18n key="registers.all">Alle</pb-i18n>
                    }
                }
        }
};

declare function api:output-locality($list, $letter as xs:string, $search as xs:string?) {
    array {
        for $place in $list
            let $name := ft:field($place, 'name')[1]
            return
                if(string-length($name)>0)
                then (                       
                let $categoryParam := if ($letter = "[A-Z]") then substring($name, 1, 1) else $letter
                let $params := "&amp;category=" || $categoryParam || "&amp;search=" || $search                           
                let $coords := tokenize($place/tei:location/tei:geo)
                return
                    element span {
                        attribute class { "place" },
                        element span {
                            element a {
                                attribute href { $place/@xml:id || "?" || $params },
                                $name
                            }
                        },
                        if(string-length(normalize-space($place/tei:location/tei:geo)) > 0)
                        then (
                            element pb-geolocation {
                                attribute latitude { $coords[1] },
                                attribute longitude { $coords[2] },
                                attribute label { $name},
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
    let $places := $config:localities//tei:place[ft:query(., 'name:*', map {
                    "leading-wildcard": "yes",
                    "filter-rewrite": "yes"
                })]
    return
        array {
            for $place in $places
            return
                if(string-length(normalize-space($place/tei:location/tei:geo)) > 0)
                then (
                    let $tokenized := tokenize($place/tei:location/tei:geo)                    
                    let $name := ft:field($place, 'name')[1]
                    return
                        map {
                            "latitude":$tokenized[1],
                            "longitude":$tokenized[2],
                            "label":$name,
                            "id":$place/@xml:id/string()
                        }
                ) else ()
            }
};


declare function api:sort-letters($entries as element()*, $sortBy as xs:string, $dir as xs:string) {
    let $sorted :=
        sort($entries, (), function($letter) {
            switch ($sortBy)
                case "title" return
                    lower-case(ext:get-title($letter))
                case "place" return
                    lower-case(ext:place-name(ext:place-by-letter($letter, 'sent')))
                case "recipients" return
                    lower-case(ext:correspondents-by-letter($letter, 'received'))
                case "senders" return
                    lower-case(ext:correspondents-by-letter($letter, 'sent'))
                case "recipients-place" return
                    lower-case(ext:place-name(ext:place-by-letter($letter, 'received')))
                (: Default: sort by date :)
                default return
                    let $date := $letter//tei:correspAction[@type="sent"]/tei:date
                    return if ($date/@when) then $date/@when
                    else if ($date/@notBefore) then $date/@notBefore
                    else if ($date/@notAfter) then $date/@notAfter
                    else "_" || $letter/@xml:id
        })
    return
        if ($dir = "asc") then
            $sorted
        else
            reverse($sorted)

};

declare function api:person-filter($filter as xs:string?, $key as xs:string, $view as xs:string?) {
    let $options := api:get-register-query-options()
    let $all-letters := collection($config:data-default)//tei:TEI
    let $letters := switch ($view)
        case "correspondence" return
            $all-letters[ft:query(.//tei:text, 'correspondant:' || $key , $options)]
        default return
            $all-letters[ft:query(.//tei:text, 'mentioned-persons:' || $key , $options)]
    let $result := 
        if ($filter) then
            $letters[ft:query(.//tei:text, 'title:(' || $filter || '*)', $options)] 
        else $letters
    return 
        $result
};

declare function api:get-register-query-options() {
    map:merge((
        $api:QUERY_OPTIONS,
        map {
            "facets":
                map:merge((
                    for $param in request:get-parameter-names()[starts-with(., 'facet-')]
                    let $dimension := substring-after($param, 'facet-')
                    let $paramValue := request:get-parameter($param, ())                        
                    return
                        if($paramValue and $paramValue != "null")
                        then (
                            map {
                                $dimension: request:get-parameter($param, ())
                            }
                        ) else ()
                ))
        }
    ))
};


declare function api:register-select($request as map(*)) {
    switch($request?parameters?type)
        case "archives" return api:archives($request)
        case "organizations" return api:organizations($request)
        case "bibliography" return api:bibliography($request)
        default return ()
};

declare function api:bibliography($request as map(*)) {
    let $key := $request?parameters?key
    let $sortBy := $request?parameters?order
    let $sortDir := $request?parameters?dir
    let $limit := $request?parameters?limit
    let $start := $request?parameters?start    
    let $filter := $request?parameters?search
    
    let $log := util:log("info", "api:bibliography started")

    let $entries := api:bibliography-filter($filter)
    let $log := util:log("info", "api:bibliography entries: " || count($entries))
    let $sorted := api:bibliography-sort($entries, $sortBy, $sortDir)
    let $log := util:log("info", "api:bibliography $sorted: " || count($sorted))
    let $subset := subsequence($sorted, $start, $limit)
    return (
        (:session:set-attribute($config:session-prefix || ".bibliography.hits", $entries),
        session:set-attribute($config:session-prefix || ".bibliography.hitCount", count($entries)),:)
        map {
            "count": count($entries),
            "results":
                array {
                    for $bibl in $subset
                        let $title := ft:field($bibl, "bibl-title")
                        let $text := ft:field($bibl, "bibl-text")
                        return
                            map {
                                "title": $title,
                                "text": $text
                            }
                }
        })
};

declare function api:bibliography-filter($filter as xs:string?) {
    let $options := api:get-register-query-options()
    let $bibliography := $config:bibliography//tei:standOff/tei:listBibl
    let $result := 
        if ($filter) then
            $bibliography/tei:bibl[ft:query(., 'bibl-title:(' || $filter || '*) OR bibl-text:(' || $filter || '*)', $options)]
        else
            $bibliography/tei:bibl[ft:query(., 'bibl-title:*', $options)]
    return 
        $result
};

declare function api:bibliography-sort($entries as element()*, $sortBy as xs:string, $dir as xs:string) {
    let $sorted :=
        sort($entries, (), function($bibl) {
            switch ($sortBy)
                case "title" return
                    lower-case(ft:field($bibl, 'bibl-title')[1])
                case "text" return
                    lower-case(ft:field($bibl, 'bibl-text')[1])
                default return
                    lower-case(ft:field($bibl, 'bibl-title')[1])
        })
    return
        if ($dir = "asc") then
            $sorted
        else
            reverse($sorted)
};

declare function api:archives($request as map(*)) {
    let $key := $request?parameters?key
    let $sortBy := $request?parameters?order
    let $sortDir := $request?parameters?dir
    let $limit := $request?parameters?limit
    let $start := $request?parameters?start    
    let $filter := $request?parameters?search
    
    let $entries := api:archives-filter($filter)
    let $log := util:log("info", "api:archives entries: " || count($entries))
    let $sorted := api:archives-sort($entries, $sortBy, $sortDir)
    let $log := util:log("info", "api:archives $sorted: " || count($sorted))
    let $subset := subsequence($sorted, $start, $limit)
    return (
        session:set-attribute($config:session-prefix || ".archives.hits", $entries),
        session:set-attribute($config:session-prefix || ".archives.hitCount", count($entries)),
        map {
            "count": count($entries),
            "results":
                array {
                    for $org in $subset
                        let $name := ft:field($org, "archive-name")
                        let $url := $org/tei:idno[@subtype="url"]/text()
                        let $count := ft:field($org, "archive-count")
                        return
                            map {
                                "archive": <a style="color:var(--bb-beige);text-decoration:none;" href="{$url}" target="_blank">{$name}</a>,
                                "document-count": <a style="color:var(--bb-beige);text-decoration:none;" href="../letters.html?facet-archive={$org/@xml:id}">{$count}</a>
                            }
                }
        })
};

declare function api:archives-filter($filter as xs:string?) {    
    let $options := api:get-register-query-options()
    let $result := 
        if ($filter) then
            $config:archives//tei:org[ft:query(., 'archive-name:(' || $filter || '*)', $options)]
        else
            $config:archives//tei:org[ft:query(., 'archive-name:*', $options)]
    return 
        $result
};

declare function api:archives-sort($entries as element()*, $sortBy as xs:string, $dir as xs:string) {
    let $sorted :=
        sort($entries, (), function($org) {
            switch ($sortBy)
                case "document-count" return 
                    xs:integer(ft:field($org, "archive-count"))
                default return
                    lower-case(ft:field($org, 'archive-name')[1])
        })
    return
        if ($dir = "asc") then
            $sorted
        else
            reverse($sorted)
};

declare function api:organizations($request as map(*)) {
    let $key := $request?parameters?key
    let $sortBy := $request?parameters?order
    let $sortDir := $request?parameters?dir
    let $limit := $request?parameters?limit
    let $start := $request?parameters?start    
    let $filter := $request?parameters?search
    
    let $entries := api:organizations-filter($filter)
    let $sorted := api:organizations-sort($entries, $sortBy, $sortDir)
    let $subset := subsequence($sorted, $start, $limit)
    return (
        session:set-attribute($config:session-prefix || ".organizations.hits", $entries),
        session:set-attribute($config:session-prefix || ".organizations.hitCount", count($entries)),
        map {
            "count": count($entries),
            "results":
                array {
                    for $org at $index in $subset
                        let $name := ft:field($org, 'org-name')[1]
                        let $count := ft:field($org, 'org-count')[1]
                        return
                            map {
                                "name": <a style="color:var(--bb-beige);text-decoration:none;" href="../letters.html?facet-organization={$org/@xml:id}">{$name}</a>,
                                "count": $count
                            }
                }
        })
};

declare function api:organizations-filter($filter as xs:string?) {    
    let $options := api:get-register-query-options() 
    let $organizations := $config:orgs//tei:orgName[ft:query(., '*:* AND NOT org-count:0')]
    let $result := 
        if ($filter) then
            $organizations[ft:query(., 'org-name:(' || $filter || '*)', $options)]
        else
            $organizations[ft:query(., 'org-name:*', $options)]
    return 
        $result
};

declare function api:organizations-sort($entries as element()*, $sortBy as xs:string, $dir as xs:string) {
    let $sorted :=
        sort($entries, (), function($org) {
            switch ($sortBy)
                case "count" return 
                    xs:integer(ft:field($org, 'org-count')[1])
                default return
                    lower-case(ft:field($org, 'org-name')[1])
        })
    return
        if ($dir = "asc") then
            $sorted
        else
            reverse($sorted)
};

declare function api:register-person-detail($request as map(*)) {
    let $key := $request?parameters?key
    let $sortBy := $request?parameters?order
    let $sortDir := $request?parameters?dir
    let $limit := $request?parameters?limit
    let $start := $request?parameters?start    
    let $filter := $request?parameters?search

    let $entries := api:person-filter($filter,$key,$request?parameters?view)
    let $sorted := api:sort-letters($entries, $sortBy, $sortDir)
    let $subset := subsequence($sorted, $start, $limit)
    return (
        session:set-attribute($config:session-prefix || ".persons.hits", $entries),
        session:set-attribute($config:session-prefix || ".persons.hitCount", count($entries)),
        map {
            "count": count($entries),
            "results":
                array {
                    for $letter in $subset
                        let $id := $letter/@xml:id/string()
                        let $title := ext:get-title($letter)
                        let $senders := ext:correspondents-by-letter($letter, 'sent')
                        let $send-place-name := ext:place-name(ext:place-by-letter($letter, 'sent'))
                        let $date := ext:date-by-letter($letter, $request?parameters?language)
                        let $recipients := ext:correspondents-by-letter($letter, 'received')
                        let $recipients-place-name :=  ext:place-name(ext:place-by-letter($letter, 'received'))
                        return
                            map {
                                "title": <a style="color:var(--bb-beige);text-decoration:none;" href="../{$id}">{$title}</a>,
                                "senders":$senders,
                                "place": $send-place-name,
                                "date":<span>{$date}</span>,
                                "recipients":$recipients,
                                "recipients-place":$recipients-place-name
                            }
                }
        }
)};

declare function api:register-locality-detail($request as map(*)) {    
    let $key := $request?parameters?key
    let $sortBy := $request?parameters?order
    let $sortDir := $request?parameters?dir
    let $limit := $request?parameters?limit
    let $start := $request?parameters?start    
    let $filter := $request?parameters?search
    let $view := $request?parameters?view

    let $entries := api:locality-filter($filter,$key,$view)
    let $sorted := api:sort-letters($entries, $sortBy, $sortDir)
    let $subset := subsequence($sorted, $start, $limit)
    return (
        session:set-attribute($config:session-prefix || ".localities.hits", $entries),
        session:set-attribute($config:session-prefix || ".localities.hitCount", count($entries)),
        map {
            "count": count($entries),
            "results":
                array {
                    for $letter in $subset
                        let $id := $letter/@xml:id/string()
                        let $title := ext:get-title($letter)
                        let $senders := ext:correspondents-by-letter($letter, 'sent')
                        let $send-place-name := ext:place-name(ext:place-by-letter($letter, 'sent'))
                        let $date := ext:date-by-letter($letter, $request?parameters?language)
                        let $recipients := ext:correspondents-by-letter($letter, 'received')
                        let $recipients-place-name :=  ext:place-name(ext:place-by-letter($letter, 'received'))
                        return
                            map {
                                "title": <a style="color:var(--bb-beige);text-decoration:none;" href="../{$id}">{$title}</a>,
                                "senders":$senders,
                                "place": $send-place-name,
                                "date":<span>{$date}</span>,
                                "recipients":$recipients,
                                "recipients-place":$recipients-place-name
                            }
                }
        }
)};

declare function api:locality-filter($filter as xs:string?, $key as xs:string, $view as xs:string?) {    
    let $options := api:get-register-query-options()

    let $all-letters := collection($config:data-default)//tei:TEI
    let $letters := switch ($view)
        case "correspondence" return
            $all-letters[ft:query(.//tei:text, 'place:' || $key , $options)]
        default return
            $all-letters[ft:query(.//tei:text, 'place:' || $key || ' OR mentioned-places:' || $key , $options)]
    let $result := 
        if ($filter) then
            $letters[ft:query(.//tei:text, 'title:(' || $filter || '*)', $options)] 
        else $letters
    return
        $result
};

declare function api:cleanup-register-data($request as map(*)) {   
    cr:cleanup-register($request?parameters?file)
};

declare function api:facets($request as map(*)) {    
    let $hits := session:get-attribute($config:session-prefix || ".hits")
    let $_ := util:log("info", "api:facets")
    where count($hits) > 0
    return
        <div>

        {
            for $config in $config:facets-persons?*
            return
                facets:display($config, $hits)
        }
        </div>

};

declare function api:facets-search($request as map(*)) {
    let $value := $request?parameters?value
    let $query := $request?parameters?query
    let $type := $request?parameters?type

    let $hits := session:get-attribute($config:session-prefix || ".hits")
    let $facets := ft:facets($hits, $type, ())

    let $facet-config := (for $f in $config:facets?*
                        where $f instance of map(*) and map:get($f, 'dimension') = $type
                        return $f)[1]
    
    let $matches := 
        for $key in if (exists($request?parameters?value)) 
                            then $request?parameters?value 
                            else map:keys($facets)
            let $text := 
                switch($type) 
                    case "sender" 
                    case "recipient"
                    case "mentioned-persons"
                        return
                            let $persName := $config:persons/id($key)/parent::tei:person/tei:persName[@type='main']
                            let $name := string-join(($persName/tei:forename, $persName/tei:surname), " ")
                            return
                                $name 
                    case "place"
                    case "mentioned-places"
                        return
                            let $place := $config:localities/id($key)
                            
                            let $settlement := $place//tei:settlement/text()
                            let $district := $place//tei:district/text()
                            let $country := $place//tei:country/text()
                            let $name :=  if($settlement) then ($settlement) else if ($district) then ($district) else ($country)
                            return
                                $name
                    case "archive" return
                        let $archive := $config:archives/id($key)
                        return
                            string-join(($archive/tei:orgName/text(), $archive/tei:addName/text()), ", ")
                    case "organization" return
                        let $group := $config:orgs/id($key)
                        return
                            string($group)
                    case "hbbw-number" return
                        $key
                    case "signature" return
                        $key
                    case "letter-id" return
                        $key
                    case "language-threshold" return
                        map:get($facet-config, 'output')($key)
                    case "has-facsimile" return
                        map:get($facet-config, 'output')($key)
                    default return 
                        let $_ := util:log("info", "api:facets-search: default return, $type: " || $type)
                        return 
                            ("unknown facet type " || $type)
            (: Numerical values should be sorted by number and ascending (double negation using - and descending) :)
            order by if($type = 'hbbw-number' or $type = 'letter-id') then -(xs:integer(replace($text, "[^\d]+", ""))) else $facets($key) descending, $text
            return 
                map {
                    "text": $text,
                    "freq": $facets($key),
                    "value": $key
                } 

        let $log := util:log("info", "api:facets-search: $matches: " || count($matches))
        let $filtered := filter($matches, function($item) {
            matches($item?text, '(?:^|\W)' || $request?parameters?query, 'i')
        })
        let $log := util:log("info", "api:facets-search: filtered $matches: " || count($filtered))
        return
            array { $filtered }
};

declare function api:include-static-content($request as map(*)) as node()* {
    let $page := $request?parameters?page
    let $language := tokenize($request?parameters?language, '-')[1]
    let $source-document := $page || "-" || $language || ".html"
    let $path := $config:app-root || "/static/" || $source-document
    return
        if (not(doc-available($path)))
        then error((), "The content page could not be found: " || $source-document)
        else doc($path)//main/node()
};

declare function api:timeline($request as map(*)) {
    let $entries := session:get-attribute($config:session-prefix || '.hits')
    let $datedEntries := filter($entries, function($entry) {
            try {
                let $date := ft:field($entry, "date", "xs:date")
                return
                    exists($date) and year-from-date($date) != 1000
            } catch * {
                false()
            }
        })
    return
        map:merge(
            for $entry in $datedEntries
            group by $date := ft:field($entry, "date", "xs:date")
            return
                map:entry(format-date($date, "[Y0001]-[M01]-[D01]"), map {
                    "count": count($entry),
                    "info": ''
                })
        )
};

declare function api:redirect-old-url($request as map(*)) {
    let $uri := replace($request?path, "/letter/", "../file")
    return roaster:response(301,  "text/plain", "Redirected from old url", map { "Location": $uri })
};