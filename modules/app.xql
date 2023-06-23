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