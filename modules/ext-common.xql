xquery version "3.1";

module namespace ext="http://teipublisher.com/ext-common";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

(: declare namespace tei="http://www.tei-c.org/ns/1.0"; :)
declare default element namespace "http://www.tei-c.org/ns/1.0";

(: $type should be either 'sent' or 'received :)
declare function ext:correspondents-by-letter($letter, $type as xs:string) {
    let $items := for $item in $letter//correspAction[@type = $type]/(persName,orgName,roleName)
        return ext:correspondent-by-item($item)
    return string-join($items, ', ')
};


(: Item should be one of persName, orgName, roleName :)
declare function ext:correspondent-by-item($item) {
    typeswitch ($item)
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
};

declare function ext:date-by-letter($item) {
    let $date := typeswitch($item)
        case element(correspAction) return $item/date
        default return $item//correspAction[@type = "sent"]/date
    return if(fn:string-length($date/text()) > 0) then
        $date/text()
    else if(exists($date/@when)) then
        format-date($date/@when, '[D1o] [MNn] [Y]', 'de', (), ())
    else if (exists($date/@notBefore) and exists($date/@notAfter)) then
        "Zwischen " || format-date($date/@notBefore, '[D1o] [MNn] [Y]', 'de', (), ()) || " und " || format-date($date/@notAfter, '[D1o] [MNn] [Y]', 'de', (), ())
    else if(exists($date/@notBefore)) then
        "Nach " || format-date($date/@notBefore, '[D1o] [MNn] [Y]', 'de', (), ())
    else if(exists($date/@notAfter)) then
        "Vor " || format-date($date/@notAfter, '[D1o] [MNn] [Y]', 'de', (), ())
    else
        "Unbekannt"
};

declare function ext:place-by-letter($letter) {
    let $place-id := $letter//correspAction[@type = 'sent']/placeName/@source
    return $config:localities//place[@xml:id=$place-id]
};