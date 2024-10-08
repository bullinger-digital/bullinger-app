xquery version "3.1";

module namespace ext="http://teipublisher.com/ext-common";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

(: declare namespace tei="http://www.tei-c.org/ns/1.0"; :)
declare default element namespace "http://www.tei-c.org/ns/1.0";


declare function ext:get-title($letter) {
    let $senders := ext:correspondents-by-letter($letter, 'sent')
    let $receivers := ext:correspondents-by-letter($letter, 'received')
    return $senders || " an " || $receivers
};

(: $type should be either 'sent' or 'received :)
declare function ext:correspondents-by-letter($letter, $type as xs:string) {
    let $items := for $item in $letter//correspAction[@type = $type]/(persName,orgName,roleName)
        return ext:correspondent-by-item($item)
    let $correspondents := string-join($items, ', ')
    return if(fn:string-length($correspondents) > 0) then
        $correspondents
    else
        "[...]"
};


(: Item should be one of persName, orgName, roleName :)
declare function ext:correspondent-by-item($item) {
    typeswitch ($item)
        case element(persName) return
            let $persName := id($item/@ref, $config:persons)
            return
                $persName/forename || " " || $persName/surname
        case element(orgName) return
            if(fn:string-length($item/text()) > 0) then
                ($item/text())
            else (id($item/@ref, $config:orgs)/string())
        case element(roleName) return
            id($item/@ref, $config:roles)/form[@xml:lang="de"][@type=$item/@type]
        default return
            ()
};

declare function ext:date-by-letter($item) {
    (: Todo: Translations for month names and additional date text :)
    let $date := typeswitch($item)
        case element(correspAction) return $item/date
        default return $item//correspAction[@type = "sent"]/date
    return if(fn:string-length($date/text()) > 0) then
        $date/text()
    else if(exists($date/@when)) then
        ext:format-date($date/@when)
    else if (exists($date/@notBefore) and exists($date/@notAfter)) then
        "Zwischen " || ext:format-date($date/@notBefore) || " und " || ext:format-date($date/@notAfter)
    else if(exists($date/@notBefore)) then
        "Nach " || ext:format-date($date/@notBefore)
    else if(exists($date/@notAfter)) then
        "Vor " || ext:format-date($date/@notAfter)
    else
        "Unbekannt"
};

declare function ext:format-date($date as xs:string?){
    if(string-length($date) = 0) then
        ()
    else if(matches($date, '^\d{4}$')) then
        $date
    else if (matches($date, '^\d{4}-\d{2}$')) then
        format-date(xs:date($date || '-01'), '[MNn] [Y]', "de", (), ())
    else if (matches($date, '^\d{4}-\d{2}-\d{2}$')) then
        format-date(xs:date($date), '[D]. [MNn] [Y]', "de", (), ())
    else
        $date
};


declare function ext:place-name($place) {
    let $settlement := $place//settlement/text()
    let $district := $place//district/text()
    let $country := $place//country/text()
    let $place-name := if($settlement) then ($settlement) else if ($district) then ($district) else ($country)
    return $place-name
};

declare function ext:place-by-letter($letter, $type as xs:string) {
    let $place-id := $letter//correspAction[@type = $type]/placeName/@ref
    return $config:localities//place[@xml:id=$place-id]
};

declare function ext:place-by-letter($letter) {
    ext:place-by-letter($letter, 'sent')
};