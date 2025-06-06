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
    let $sent-count := count(collection($config:data-default)//tei:TEI[ft:query(.//tei:text, 'sender:' || $key)])
    let $received-count := count(collection($config:data-default)//tei:TEI[ft:query(.//tei:text, 'recipient:' || $key)])
    let $total := $sent-count + $received-count
    let $mentions-count := count(collection($config:data-default)//tei:TEI[ft:query(.//tei:text, 'mentioned-persons:' || $key)])
    return
        map {
            "key": $key,
            "type": local-name($person),
            "data": $person,
            "sent-count":$sent-count,
            "received-count":$received-count,
            "total-count":$total,
            "mentions-count": $mentions-count
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

declare %templates:wrap    
function app:person-gnd($node as node(), $model as map(*)) {
    let $gnd := replace(($model?data)//tei:idno[@subtype="gnd"], "^https://d-nb.info/gnd/", "")
    return  
        $gnd
};

declare %templates:wrap    
function app:person-hls($node as node(), $model as map(*)) {
    let $hls := replace(($model?data)//tei:idno[@subtype="hls"], "^https://hls-dhs-dss.ch/de/articles/([0-9]+)/.*", "$1")
    return  
        $hls
};

declare %templates:replace   
function app:name-alternatives($node as node(), $model as map(*)) {    
    let $aliases := ($model?data)//tei:persName[@type="alias"]

    return
        if (exists($aliases)) 
        then (
            element div {
                attribute class { "alias-list" },
                element strong {
                    element pb-i18n {
                        attribute key { "further-names"},
                        "Weitere Namen"
                    }
                },
                element p {
                    (
                        for $alias in $aliases
                        let $full-alias := $alias/tei:forename/text() || " " || $alias/tei:surname/text()
                        return $full-alias
                        (: (<span class="alias">{ $full-alias }</span>, <br />) :)
                    )
                    => string-join("; ")
                }
            }
        )
        else ()
};


declare %templates:replace   
function app:bio-footnotes($node as node(), $model as map(*)) {    
    let $person := ($model?data)
    (: Biographical footnotes are identified by the ana attribute with the value "bio". We only display footnotes
        where the first persName reference matches the person's xml:id. :)
    let $footnotes := (
        for $note in collection($config:data-default)//tei:note[@ana="bio" and (.//tei:persName)[1][@ref=lower-case($person/@xml:id)]]
        order by string-length($note/string()) descending
        return $note
    )
        
    return 
        if (count($footnotes) > 0)
        then (
            element div {
                attribute class { "bio-footnotes" },
                element hr {},
                element pb-i18n {
                    attribute key { "registers.persons.biographical-footnotes"},
                    "(Zusatzinformationen)"
                },
                element div {
                    attribute class { "bio-footnotes-list" },
                    (
                        for $note in $footnotes
                        let $note-content-string := $note/string()
                        let $letter-id := replace($note/ancestor::tei:TEI/@xml:id/string(), "file", "")
                        return element span {
                            attribute style { "margin-right: 0.3em;" },
                            element a {
                                attribute href { "../file" || $letter-id },
                                element pb-popover {
                                    attribute placement { "top" },
                                    element span {
                                        attribute slot { "default" },
                                        $letter-id || " "
                                    },
                                    element div {
                                        attribute style { "max-height: 200px; overflow-y: auto;" },
                                        attribute slot { "alternate" },
                                        element div {
                                            "Fussnote " || $note/@n || " in Brief " || $letter-id || ":"
                                        },
                                        element div {
                                            $note-content-string
                                        }
                                    }
                                }
                            }
                        }
                    )
                }
            }
        )
        else ()
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
        (: let $log := util:log("info", "app:mentions-of-person: $id: '" || $id || "' title:  '" || $title || "'") :)
        return
            element div {
                element a  {
                    attribute href { $config:context-path || "/" || $id },
                    $title
                }
            }
};

declare %templates:replace
function app:mentions-of-locality($node as node(), $model as map(*)) {
    let $key := $model?key
    (: let $log := util:log("info", "app:mentions-of-locality: $key: " || $key ) :)
    let $place := id(xmldb:decode($key), $config:localities)
    (: let $log := util:log("info", "app:mentions-of-locality: found locality: " || $person/@xml:id/string()) :)
    let $matches := collection($config:data-default)//tei:placeName[@ref = $place/@xml:id]
    (: let $log := util:log("info", "app:mentions-of-locality: $matches: " || count($matches) || " in " || $config:data-default)     :)
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
    let $matches := collection($config:data-default)//tei:correspAction[@type=$type]//tei:placeName[@ref = $person/@xml:id]
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
    let $meta-information := $data//tei:idno[not(@subtype = 'portrait' or @subtype = 'histHub')]

    return
        if (count($meta-information) = 0)
        then ()
        else element { node-name($node) } {
            $node/@*,
            <strong><pb-i18n key="further-information">Weitere Informationen</pb-i18n></strong>,
            <ul class="meta-info--link-list">{
                for $entry in $meta-information
                let $subtype := $entry/@subtype/string()
                order by $subtype ascending
                return
                    element li {
                        element a {
                            attribute class { "meta-info--link", "meta-info--link__" || $subtype },
                            attribute href { $entry/text() },
                            attribute target { "blank_" },
                            attribute title { $subtype },
                            upper-case($subtype)
                        }
                    }
            }</ul>
        }
};

declare %templates:wrap
function app:person-letters-sent ($node as node(), $model as map(*)) {       
     (
        <strong><pb-i18n key="sent">Gesendet</pb-i18n></strong>,
        <br/>,
        <p class="count">{ $model?sent-count }</p>
    )
};

declare %templates:wrap
function app:person-letters-received ($node as node(), $model as map(*)) {    
        <strong><pb-i18n key="received">Empfangen</pb-i18n></strong>,
        <br/>,
        <p class="count">{ $model?received-count }</p>
};
declare %templates:wrap
function app:person-letters-total ($node as node(), $model as map(*)) {    
    (
        <strong><pb-i18n key="total">Total</pb-i18n></strong>,
        <br/>,
        <p class="count">{ $model?total-count}</p>
    )
};

declare %templates:wrap
function app:person-letters-mentions ($node as node(), $model as map(*)) {    
    (
        <strong><pb-i18n key="mentions">(Erwähnungen)</pb-i18n></strong>,
        <br/>,
        <p class="count">{ $model?mentions-count}</p>
    )
};


declare %templates:replace
function app:person-loosely-annotated ($node as node(), $model as map(*)) {    
    if (exists($model?data//tei:note[@type = 'loosely-annotated'])) then
        <div class="person-loosely-annotated"><pb-i18n key="registers.persons.loosely-annotated">(loosely-annotated)</pb-i18n></div>
    else ()
};


declare 
    %templates:replace
function app:image($node as node(), $model as map(*)) {
    let $img-url := $model?data//tei:idno[@subtype="portrait"]/text()
    return
        if (string-length($img-url) > 0)
        then 
            element figure {
                attribute class { "detail-image" },
                element img {
                    attribute src { "../resources/portraits/" || $img-url }
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
    %templates:replace    
function app:show-map($node as node(), $model as map(*)) {
    let $place := $model?data
    let $geo := $place//tei:geo/text()
    let $coords := tokenize($geo, " ")
    let $latitude := $coords[1]
    let $longitude := $coords[2]
    return
        if(string-length(normalize-space($geo ) ) > 1)
        then (
            <pb-leaflet-map id="map" zoom="14" subscribe="map" emit="map" cluster="" latitude="{$latitude}" longitude="{$longitude}">
                <pb-map-layer show="" 
                    base="" 
                    label="Mapbox OSM"
                    url="https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{{z}}/{{x}}/{{y}}?access_token={{accessToken}}"
                    max-zoom="19" 
                    access-token="pk.eyJ1Ijoid29sZmdhbmdtbSIsImEiOiJjam1kMjVpMnUwNm9wM3JwMzdsNGhhcnZ0In0.v65crewF-dkNsPF3o1Q4uw" 
                    attribution="© Mapbox © OpenStreetMap">
                </pb-map-layer>
            </pb-leaflet-map>
        ) 
        else (
            <div style="text-align:center;font-style:italic;"><pb-i18n key="no-geo-data">Keine Geodaten verfügbar</pb-i18n></div>
        ) 
};

declare 
    %templates:replace
function app:transcription-source($node as node(), $model as map(*)) {
    let $tei := collection($config:data-default)//tei:TEI[@xml:id=$model?doc]
    let $bibl-source := $tei//tei:sourceDesc/tei:bibl[@type="transcription"]
    let $bibl := id($bibl-source/@source, $config:bibliography)/tei:bibl
    let $text := if ($bibl) then (
        <span><pb-i18n key="source">(Quelle)</pb-i18n>: {$bibl/text()}</span>
    ) else if ($tei/@source/string() = "HTR") then (
        <pb-i18n key="automaticTranscription">(Automatische Transkription)</pb-i18n>
    ) else ""
    return
        if(fn:string-length($text) > 0)
        then (
            <pb-popover class="source-info" persistent="true" theme="light">
                <iron-icon slot="default" icon="info-outline" class="source-info--icon"/>
                <span slot="alternate">{$text}</span>
            </pb-popover>
        ) else ()
};

declare 
    %templates:replace
function app:facsimile-source($node as node(), $model as map(*)) {
    let $tei := collection($config:data-default)//tei:TEI[@xml:id=$model?doc]
    let $bibl := $tei//tei:sourceDesc/tei:bibl[@type="scan"]
    return
        if($bibl) 
        then (
            <pb-popover class="source-info" persistent="true" theme="light">
                <iron-icon slot="default" icon="info-outline" class="source-info--icon"/>
                <span slot="alternate"><pb-i18n key="source">(Quelle)</pb-i18n>: {$bibl/text()}</span>
            </pb-popover>
        ) else ()
};

declare 
    %templates:wrap
function app:facsimile-availability($node as node(), $model as map(*)) {
    let $tei := collection($config:data-default)//tei:TEI[@xml:id=$model?doc]
    let $link := $tei//tei:sourceDesc//tei:idno[@subtype="Quelle"]
    return
        if($link and matches($link/text(), "^https?://")) 
        then (
            <pb-i18n key="facsimileExternal">(Das Faksimile für diesen Brief ist extern verfügbar:)</pb-i18n>,
            <br />,
            <a href="{$link/text()}" target="_blank">
                { $link/text() }
            </a>
        ) else (
            <pb-i18n key="facsimileUnavailable">(faksimileUnavailable)</pb-i18n>
        )
};
