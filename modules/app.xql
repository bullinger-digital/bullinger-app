xquery version "3.1";

(: 
 : Module for app-specific template functions
 :
 : Add your own templating functions here, e.g. if you want to extend the template used for showing
 : the browsing view.
 :)
module namespace app="teipublisher.com/app";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare %templates:wrap    
function app:page-title($node as node(), $model as map(*), $page as xs:string) {    
    (: let $json := json-doc($config:app-root || "/resources/i18n/app/" || $lang || ".json")
    let $title := map:get($json, "title-" || $page)
    (: let $log := util:log("info", "page:title for '" || $page || "' is '" || $title || "'") :)
    return
        $title || " - " || map:get($json, "title-suffix") :)
    $page
};


declare
    %templates:wrap    
    %templates:default("key","")
function app:load-person($node as node(), $model as map(*), $key as xs:string) {
    let $person := id(xmldb:decode($key), $config:persons)
    (: let $log := util:log("info", "app:load-actor $name: " || $actor/tei:*[@type="full"]/text() || " - $key:" || $key) :)
    
    return 
        map {                
                "key":$key,  
                "type":local-name($person),              
                "data":$person
        }    
};

declare
    %templates:wrap    
    %templates:default("key","")
function app:load-locality($node as node(), $model as map(*), $key as xs:string) {
    let $place := id(xmldb:decode($key), $config:localities)
    (: let $log := util:log("info", "app:load-actor $name: " || $actor/tei:*[@type="full"]/text() || " - $key:" || $key) :)
    let $settlement := $place//tei:settlement/text()
    let $district := $place//tei:district/text()
    let $country := $place//tei:country/text()
    let $place-name := if($settlement) then ($settlement) else if ($district) then ($district) else ($country)
    
    let $model-metadata := 
        map {  
                "key":$key,
                "data":$place,
                "name":$place-name
        }
    let $additional-model-data := 
        if (string-length(normalize-space($place//tei:geo/text())) > 1)
        then (
            let $geo-token := tokenize($place//tei:geo/text(), " ")
            return 
                map {
                    "latitude": $geo-token[1],
                    "longitude": $geo-token[2]                    
                }
        )
        else ()
    (: let $log := util:log("info", ("$additional-model-data", $additional-model-data)) :)

    return map:merge((
        $model,
        $model-metadata, 
        $additional-model-data
    ))
};

declare %templates:wrap    
function app:person-name-full($node as node(), $model as map(*)) {
    let $persName := ($model?data)//tei:persName[@type="main"]
    return  
        $persName/tei:forename/text() || " " || $persName/tei:surname/text()
};

declare %templates:replace   
function app:name-alternatives($node as node(), $model as map(*)) {    
    let $alt-names := for $persName in ($model?data)//tei:persName[@type="alias"]
                      return
                        $persName/tei:forename/text() || " " || $persName/tei:surname/text()
    let $names := string-join($alt-names, "; ")            
    return
        if(string-length($names )> 0) 
        then (
            element p {
                element pb-i18n {
                    attribute key { "further-names"},
                    "Weitere Namen"
                },
                ": " || $names
            }
        )else ()
};

declare %templates:replace
function app:mentions($node as node(), $model as map(*)) {
    let $key := $model?key    
    (: let $log := util:log("info", "app:mentions: $key: " || $key ) :)
    let $person := id(xmldb:decode($key), $config:persons)
    (: let $log := util:log("info", "app:mentions: found person: " || $person/@xml:id/string()) :)
    let $matches := 
        for $id in $person//tei:persName/@xml:id
            return (
                collection($config:data-default)//tei:text//tei:persName[@ref = $id],
                collection($config:data-default)//tei:msContents//tei:persName[@ref = $id]
            )
    (: let $log := util:log("info", "app:mentions: $matches: " || count($matches) || " in " || $config:data-default)     :)
    return
        if (count($matches) eq 0)
        then ()
        else if (count($matches) <= 5)
        then (
            app:print-mentions($matches)
        )
        else (
            element details {
                app:print-mentions($matches)
            })
};
declare function app:print-mentions($matches) {
    element summary {
        element pb-i18n { 
            attribute key {"mentions-of"},
            "Erwähnungen in Briefen"
        }
    },
    for $match in $matches
        group by $file := util:document-name($match)
        order by $file ascending 
        let $root := root($match[1])
        let $title := $root//tei:titleStmt/tei:title/string()
        let $id := $root/tei:TEI/@xml:id/string()
        (: let $log := util:log("info", "app:mentions: $id: '" || $id || "' title:  '" || $title || "'") :)
        return
            element div {
                element a  {
                    attribute href { $config:context-path || "/" || $id },
                    $title
                }
            }
};

declare %templates:replace
function app:person-is-sender($node as node(), $model as map(*)) {
    let $key := $model?key        
    let $person := id(xmldb:decode($key), $config:persons)
    (: let $log := util:log("info", "app:person-is-sender: found person: " || $person/@xml:id/string()) :)
    return 
        app:person-in-corresp-action($node, $model, $person, "sent")
};

declare %templates:replace
function app:person-is-recipient($node as node(), $model as map(*)) {
    let $key := $model?key        
    let $person := id(xmldb:decode($key), $config:persons)
    (: let $log := util:log("info", "app:person-is-recipient: found person: " || $person/@xml:id/string()) :)
    return 
        app:person-in-corresp-action($node, $model, $person, "received")

};

declare function app:person-in-corresp-action($node, $model, $person, $type) {
    let $matches := 
        for $id in $person//tei:persName/@xml:id
            return (
                    collection($config:data-default)//tei:correspAction[@type=$type]//tei:persName[@ref = $id]
            )
    (: let $log := util:log("info", "app:person-in-corresp-action: $matches: " || count($matches) || " in type " || $type)     :)
    return
        if (count($matches) eq 0)
        then ()
        else (
            element details {
                templates:process($node/node(), $model)
            }
        )
};


declare %templates:replace
function app:locality-is-sender($node as node(), $model as map(*)) {
    let $key := $model?key        
    let $place := id(xmldb:decode($key), $config:localities)
    (: let $log := util:log("info", "app:locality-is-sender: found locality: " || $place/@xml:id/string()) :)
    return 
        app:locality-in-corresp-action($node, $model, $place, "sent")
};

declare %templates:replace
function app:locality-is-recipient($node as node(), $model as map(*)) {
    let $key := $model?key        
    let $place := id(xmldb:decode($key), $config:localities)
    (: let $log := util:log("info", "app:locality-is-recipient: found locality: " || $place/@xml:id/string()) :)
    return 
        app:locality-in-corresp-action($node, $model, $place, "received")

};

declare function app:locality-in-corresp-action($node, $model, $person, $type) {
    let $matches := collection($config:data-default)//tei:correspAction[@type=$type]//tei:placeName[@source = $person/@xml:id]
    (: let $log := util:log("info", "app:locality-in-corresp-action: $matches: " || count($matches) || " in type " || $type)     :)
    return
        if (count($matches) eq 0)
        then ()
        else (
            element details {
                templates:process($node/node(), $model)
            }
        )
};

declare %templates:replace   
function app:further-information($node as node(), $model as map(*)) {
    let $data := $model?data
    let $meta-information := 
            for $entry in $data//tei:idno[not(@subtype = 'portrait')]
                order by $entry/@subtype ascending
                (: let $log := util:log("info", "app:place-ptr: type: " || $entry/@type) :)
                return
                        element li {
                            element a {
                                attribute href {$entry/text()},
                                attribute target { "blank_"},
                                $entry/@subtype/string()
                            }
                        }
    return
        if (count($meta-information) = 0)
        then ()
        else
            <div class="metadaten">
                <summary>
                    <pb-i18n key="further-information">Weitere Informationen</pb-i18n>
                </summary>
                <ul>{ $meta-information }</ul>
            </div>
};

declare 
    %templates:replace
function app:image($node as node(), $model as map(*)) {    
    let $img-url := substring-before($model?data//tei:idno[@subtype="portrait"]/text(),'"')
    return
        if (string-length($img-url) > 0)
        then 
            element figure {
                attribute class { "detail-image" },
                element img {
                    attribute src { "../../bullinger-data/data/portraits/" || $img-url }
                }
            }
        else ()
};

declare %templates:wrap    
function app:locality-name($node as node(), $model as map(*)) {
    $model?name
};

declare 
    %templates:replace    
function app:pb-geolocation($node as node(), $model as map(*)) {
    element pb-geolocation {
        attribute latitude {$model?latitude},
        attribute longitude {$model?longitude},
        attribute label {$model?name},
        attribute auto {},
        $model?name
    }

};

declare 
    %templates:wrap    
function app:show-map($node as node(), $model as map(*)) {
    let $place := $model?data
    return
        if(string-length(normalize-space($place//tei:geo/text() ) ) > 1)
        then ( templates:process($node/*, $model) ) 
        else (
            <div style="text-align:center;font-style:italic;"><pb-i18n key="no-geo-data">Keine Geodaten verfügbar</pb-i18n></div>
        ) 
};
