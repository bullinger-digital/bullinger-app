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