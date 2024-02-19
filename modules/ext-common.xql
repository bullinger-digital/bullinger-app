
xquery version "3.1";

module namespace ext="http://teipublisher.com/ext-common";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

(: declare namespace tei="http://www.tei-c.org/ns/1.0"; :)
declare default element namespace "http://www.tei-c.org/ns/1.0";

declare function ext:sender-by-letter($letter) {
    let $items := for $item in $letter//correspAction[@type = "sent"]/(persName,orgName,roleName)
        return typeswitch ($item)
            case element(persName) return
                let $persName := id($item/@ref, $config:persons)
                return
                    $persName/forename || " " || $persName/surname
            case element(orgName) return
                id($item/@ref, $config:orgs)/name[@xml:lang='de'][@type=$item/@type]
            case element(roleName) return
                id($item/@ref, $config:roles)/form[@xml:lang="de"][@type=$item/@type]
            default return
                ()
    return string-join($items, ', ')
};