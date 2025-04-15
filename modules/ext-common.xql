xquery version "3.1";

module namespace ext="http://teipublisher.com/ext-common";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
(: declare default element namespace "http://www.tei-c.org/ns/1.0"; :)

declare function ext:get-header($letter, $lang-browser as xs:string?) {
    let $root := $letter/ancestor::tei:TEI
    let $senders := ext:correspondents-by-letter($letter, 'sent')
    let $receivers := ext:correspondents-by-letter($letter, 'received')

    let $navigation-item := id($root/@xml:id, doc("/db/apps/bullinger-data/generated/navigation.xml"))
    let $previous-letter := $navigation-item/tei:ptr[@type='prev']/@target
    let $next-letter := $navigation-item/tei:ptr[@type='next']/@target
    let $previous-letter-correspondence := $navigation-item/tei:ptr[@type='prev-same-correspondents']/@target
    let $next-letter-correspondence := $navigation-item/tei:ptr[@type='next-same-correspondents']/@target
    let $type := $letter/ancestor::tei:TEI/@type/string()

    return <div>
        <div class="letter-navigation">
            <div class="center-l">
                <a title="Vorheriger Brief (nach Datum)" href="./{$previous-letter}"><iron-icon icon="chevron-left"/></a>
                <a title="Vorheriger Brief (mit gleichen Korrespondenten)" href="./{$previous-letter-correspondence}"><iron-icon icon="chevron-left"/><iron-icon class="double-icon" icon="chevron-left"/></a>
                <a title="Nächster Brief (mit gleichen Korrespondenten)" href="./{$next-letter-correspondence}"><iron-icon icon="chevron-right"/><iron-icon class="double-icon" icon="chevron-right"/></a>
                <a title="Nächster Brief (nach Datum)" href="./{$next-letter}"><iron-icon icon="chevron-right"/></a>
                <span class="letter-navigation-mark-names">
                    <label><input type="checkbox" onclick="javascript:document.body.classList.toggle('colorize-named-entities', this.checked)" /> <pb-i18n key="mark-named-entities">(Namen markieren)</pb-i18n></label>
                </span>
            </div>
        </div>
        <div class="header-container center-l">
            <div>
                <h1>
                    <span style="color:var(--bb-beige);">{$senders}</span>{" "}
                    <pb-i18n key="_to_">(an)</pb-i18n>{" "}
                    <span style="color:var(--bb-beige);">{$receivers}</span>
                </h1>
                <div class="subtitle">
                    <span>
                        <iron-icon id="date-range" icon="date-range" /> {ext:date-by-letter($letter, $lang-browser)}
                        <iron-icon id="map-near-me" icon="maps:near-me" /> {ext:place-name(ext:place-by-letter($letter, 'sent'))}
                    </span>
                    <span class="doc-type">
                        <pb-i18n key="metadata.types.{$type}">{$type}</pb-i18n>
                    </span>
                </div>
            </div>
            <div style="flex-shrink: 0;">
                {
                    let $persons := (for $persName in $letter//tei:correspDesc//tei:persName[@ref]
                        group by $persref := $persName/@ref
                        let $person := id($persref, doc('/db/apps/bullinger-data/data/index/persons.xml'))/ancestor::tei:person
                        where $person//tei:idno[@subtype='portrait']
                        return $person)
                    return if (exists($persons)) then
                        <div class="portrait-container">
                            {
                                for $p in $persons
                                let $url := $p//tei:idno[@subtype='portrait']/text()
                                let $title := $p/tei:persName[@type='main']//tei:forename || " " || $p/tei:persName[@type='main']//tei:surname
                                return <div class="portrait">
                                    <img src="resources/portraits/{$url}" alt="{$title}" />
                                </div>
                            }
                        </div>
                    else ()
                }
            </div>
        </div>
    </div>
};

declare function ext:metadata-by-letter($letter, $lang-browser as xs:string?) {
    let $root := $letter/ancestor::tei:TEI
    let $hbbw-no := if(fn:starts-with($root/@source/string(), 'HBBW') and string-length($root/@n/string()) > 0) then ($root/@n/string()) else ()
    let $hbbw-band := if(fn:starts-with($root/@source/string(), 'HBBW-')) then (fn:substring-after($root/@source/string(), '-')) else ()
    
    let $languages := for $l in $letter//tei:langUsage/tei:language
        where $l/@usage > 0
        order by $l/@usage div 10 descending
        return <pb-i18n key="metadata.language.{$l/@ident}">({$l/@ident/string()})</pb-i18n>

    return <div>
        <div>
            <div id="sourceDesc">
                <div>
                    <div><pb-i18n key="metadata.date">(Datum)</pb-i18n></div>
                    <div>
                        {
                        let $note := $letter//tei:correspAction[@type='sent']/tei:date/tei:note
                        return <div>
                            {ext:date-by-letter($letter, $lang-browser)}
                            {if (exists($note)) then <pb-popover>
                                <span slot="default"><iron-icon class="metadata-info-icon" id="info-outline" icon="info-outline"/></span>
                                <span slot="alternate">{$note/text()}</span>
                            </pb-popover> else ()}
                        </div>
                        }
                    </div>
                </div>
                <div>
                    <div><pb-i18n key="metadata.sender">(Absender)</pb-i18n></div>
                    <div>{
                        for $i in $letter//tei:correspAction[@type='sent']/*[self::tei:persName or self::tei:orgName or self::tei:roleName]
                        return <div>{ext:correspondent-by-item($i)}</div>
                    }</div>
                </div>
                <div>
                    <div><pb-i18n key="metadata.addressee">(Empfänger)</pb-i18n></div>
                    <div>{
                        for $i in $letter//tei:correspAction[@type='received']/*[self::tei:persName or self::tei:orgName or self::tei:roleName]
                        return <div>{ext:correspondent-by-item($i)}</div>
                    }</div>
                </div>
                {
                    if(exists($letter//tei:correspAction[@type='sent']/tei:placeName)) then
                        <div>
                            <div><pb-i18n key="metadata.place">(Absendeort)</pb-i18n></div>
                            <div>{ext:place-name(ext:place-by-letter($letter, 'sent'))}</div>
                        </div>
                    else ()
                }
                {ext:get-documents-signatures($letter)}
                {
                    if(exists($languages)) then
                        <div>
                            <div><pb-i18n key="metadata.languages">(Sprachen)</pb-i18n></div>
                            <div>
                                {ext:join-sequence(
                                    $languages
                                , ", ")}
                            </div>
                        </div>
                    else ()
                }
                {if (exists($letter//tei:listBibl/tei:bibl[@type='Gedruckt'])) then <div>
                    <div><pb-i18n key="metadata.printed">(Gedruckt in)</pb-i18n></div>
                    <div>
                        <ul>
                            {
                                for $b in $letter//tei:listBibl/tei:bibl where $b/@type = 'Gedruckt' order by fn:starts-with($b/tei:title/text(), 'HBBW') descending
                                return <li>{
                                    if ($b/@subtype != 'Gedruckt' and string-length($b/@subtype) > 0) then
                                        replace($b/@subtype, '__', ' ') || ": " || $b/tei:title/text()
                                    else 
                                        $b/tei:title/text()
                                }</li>
                            }
                        </ul>
                    </div>
                </div> else ()}
                
                {
                    if($hbbw-no) then
                        <div>
                            <div>HBBW-Briefnummer</div>
                            <div>
                                <a target="_blank" href="http://teoirgsed.uzh.ch/SedWEB.cgi?Alias=Briefe&amp;Lng=1&amp;aheight=910&amp;PrjName=Bullinger+-+Briefwechsel&amp;fld_418={$hbbw-no}">Band {$hbbw-band}, Nr. {$hbbw-no}</a>
                            </div>
                        </div>
                    else ()
                }

                {
                    let $parents := $letter//tei:correspContext/tei:ref[@type='parent']
                    return if (exists($parents)) then 
                        <div>
                            <div><pb-i18n key="metadata.referenced">(Verweise auf diesen Eintrag)</pb-i18n></div>
                            <div>{ext:get-letter-reference-links($parents)}</div>
                        </div>
                    else ()
                }

                {
                    let $children := $letter//tei:correspContext/tei:ref[@type='child']
                    return if (exists($children)) then 
                        <div>
                            <div><pb-i18n key="metadata.references">(Dieser Eintrag verweist auf)</pb-i18n></div>
                            <div>{ext:get-letter-reference-links($children)}</div>
                        </div>
                    else ()
                }
                
            </div>
        </div>
    </div>
};

declare function ext:get-letter-reference-links($refs) {
    ext:join-sequence(
        for $ref in $refs
        let $id := fn:replace($ref/@target, 'file', '')
        return <a href="file{$id}">{$id}</a>,
        ', '
    )
};

declare function ext:get-documents-signatures($letter) {
    for $msdesc in $letter//tei:msDesc
    let $text := $msdesc/tei:msIdentifier/tei:idno[@subtype=($msdesc/@subtype)]/text()
    let $note := $msdesc/tei:msIdentifier/tei:idno[@subtype='Hinweis']
    let $subtype := fn:replace($msdesc/@subtype, '__', ' ')
    let $archive-ref := $msdesc//tei:repository/@ref
    let $archive := doc('/db/apps/bullinger-data/data/index/archives.xml')//tei:org[@xml:id=$archive-ref]
    let $era := $msdesc//tei:idno[@subtype='Ära']
    let $author := $msdesc//tei:author
    where string-length($text) > 0
    return <div>
        <div>
            <pb-i18n key="metadata.documents.{$msdesc/@subtype}">({$subtype})</pb-i18n>
        </div>
        <div>
            {
                if(exists($archive)) then
                    (<a href="{$archive/tei:idno[@subtype='url']}">{$archive/tei:orgName}</a>, ", ")
                else ()
            }
            {$text}
            {if (exists($era)) then (" (", $era, ")") else ()}
            {if (exists($note) or exists($author)) then 
                <pb-popover>
                    <span slot="default"><iron-icon class="metadata-info-icon" title="Hinweis" id="info-outline" icon="info-outline"/></span>
                    <span slot="alternate">
                        {$note}
                        {if (exists($note) and exists($author)) then (<br />) else ()}
                        {if (exists($author)) then ("Autor: ", $author) else ()}
                    </span>
                </pb-popover>
            else ()}
        </div>
    </div>
};

(: Helper function to join a sequence of elements with a separator :)
declare function ext:join-sequence($items as element()*, $separator as xs:string) {
    for $e at $i in $items
    return 
        if ($i eq 1) then $e
        else ($separator, $e)
};

declare function ext:get-title($letter) {
    let $senders := ext:correspondents-by-letter($letter, 'sent')
    let $receivers := ext:correspondents-by-letter($letter, 'received')
    return $senders || " an " || $receivers
};

(: $type should be either 'sent' or 'received :)
declare function ext:correspondents-by-letter($letter, $type as xs:string) {
    let $items := for $item in $letter//tei:correspAction[@type = $type]/*[self::tei:persName or self::tei:orgName or self::tei:roleName]
        order by $item
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
        case element(tei:persName) return
            let $persName := id($item/@ref, $config:persons)
            return
                <a href="./persons/{upper-case($item/@ref)}">{$persName/tei:forename || " " || $persName/tei:surname}</a>
        case element(tei:orgName) return
            if(fn:string-length($item/text()) > 0) then
                ($item/text())
            else (id($item/@ref, $config:orgs)/string())
        default return
            "[...]"
};

declare function ext:date-by-letter($item, $lang-browser as xs:string?) {
    let $lang := if(starts-with($lang-browser, 'de')) then 'de' else 'en'
    
    let $date := typeswitch($item)
        case element(tei:correspAction) return $item/tei:date
        default return $item//tei:correspAction[@type = "sent"]/tei:date
    return if(fn:string-length($date/text()) > 0) then
        $date/text()
    else if(exists($date/@when)) then
        ext:format-date($date/@when, $lang)
    else if (exists($date/@notBefore) and exists($date/@notAfter)) then
        (
            <pb-i18n key="dates.between">(Between)</pb-i18n>,
            " ",
            ext:format-date($date/@notBefore, $lang),
            " ",
            <pb-i18n key="dates.and">(und)</pb-i18n>,
            " ", 
            ext:format-date($date/@notAfter, $lang)
        )
    else if(exists($date/@notBefore)) then
        (
            <pb-i18n key="dates.after">(Nach)</pb-i18n>,
            " ",
            ext:format-date($date/@notBefore, $lang)
        )
    else if(exists($date/@notAfter)) then
        (
            <pb-i18n key="dates.before">(Vor)</pb-i18n>,
            " ",
            ext:format-date($date/@notAfter, $lang)
        )
    else
        <pb-i18n key="dates.unknown">(Unbekannt)</pb-i18n>
};

declare function ext:format-date($date as xs:string?, $lang as xs:string){
    if(string-length($date) = 0) then
        ()
    else if(matches($date, '^\d{4}$')) then
        $date
    else if (matches($date, '^\d{4}-\d{2}$')) then
        format-date(xs:date($date || '-01'), '[MNn] [Y]', $lang, (), ())
    else if (matches($date, '^\d{4}-\d{2}-\d{2}$')) then
        format-date(xs:date($date), '[D]. [MNn] [Y]', $lang, (), ())
    else
        $date
};


declare function ext:place-name($place) {
    let $settlement := $place//tei:settlement/text()
    let $district := $place//tei:district/text()
    let $country := $place//tei:country/text()
    let $place-name := if($settlement) then
            ($settlement)
        else if ($district) then
            ($district)
        else if ($country) then
            ($country)
        else ("[...]")
    return $place-name
};

declare function ext:place-by-letter($letter, $type as xs:string) {
    let $place-id := $letter//tei:correspAction[@type = $type]/tei:placeName/@ref
    return id($place-id, $config:localities)
};

declare function ext:place-by-letter($letter) {
    ext:place-by-letter($letter, 'sent')
};

(: Converts a polygon string to an array of coordinaates in the format [x, y, w, h] :)
declare function ext:convert-polygon-to-coordinates($polygon as xs:string) {
    let $points := tokenize($polygon, '\s+')
    let $x-values := for $p in $points return number(tokenize($p, ',')[1])
    let $y-values := for $p in $points return number(tokenize($p, ',')[2])
    let $x-min := min($x-values)
    let $x-max := max($x-values)
    let $y-min := min($y-values)
    let $y-max := max($y-values)
    let $width := $x-max - $x-min
    let $height := $y-max - $y-min
    return concat("[", $x-min, ", ", $y-min, ", ", $width, ", ", $height, "]")
};