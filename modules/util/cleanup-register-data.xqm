xquery version "3.1";

module namespace cr="jinntec.de/cleanup-register-data";
declare namespace tei="http://www.tei-c.org/ns/1.0";


declare function cr:remove-not-referenced-places($register-path, $register-filename, $letters) {
    let $places-data := doc($register-path || $register-filename)
    let $placeNames := $letters//tei:placeName
    let $remove-places := 
        for $place in $places-data//tei:place
            let $refs :=  ($placeNames[@source = $place/@xml:id], $placeNames[@ref = $place/@xml:id])
            return
                if(count($refs) = 0)
                then (
                    update delete $place
                ) 
                else ()
    let $store := xmldb:store($register-path, $register-filename, $places-data)
    return
        $places-data
};

declare function cr:remove-not-referenced-persons($register-path, $register-filename, $letters) {
    let $persons-data := doc($register-path || $register-filename)
    let $remove-alias-persnames := 
        for $person in $persons-data//tei:persName[not(@type="main")]
            let $refs :=  $letters//tei:persName[@ref = $person/@xml:id] 
            return
                if(count($refs) = 0)
                then (
                    update delete $person
                ) 
                else ()
    let $store := xmldb:store($register-path, $register-filename, $persons-data)
    (: remove persName type main only if there is no alias anymore :)
    let $remove-main-persnames := 
        for $personName in $persons-data//tei:persName[@type="main"]
            let $person := $personName/parent::tei:person
            let $refs :=  $letters//tei:persName[@ref = $personName/@xml:id] 
            return
                if(count($refs) = 0 and exists($person) and not(exists($person/tei:persName[@type="alias"])))
                then (
                    update delete $personName
                ) 
                else ()
    let $store := xmldb:store($register-path, $register-filename, $persons-data)
    let $check-person := 
                for $noPersName in $persons-data//tei:person[not(exists(tei:persName))]
                    return
                        if(count($letters//tei:persName[@ref = $noPersName/@xml:id]) = 0)
                        then (
                            update delete $noPersName
                        ) 
                        else ()
    let $store := xmldb:store($register-path, $register-filename, $persons-data)
    return
        $persons-data
};

declare function cr:remove-not-referenced-archives($register-path, $register-filename, $letters) {
    let $archives-data := doc($register-path || $register-filename)
    let $remove-archives := 
        for $archive in $archives-data//tei:org
            let $refs :=  $letters//tei:repository[@ref = $archive/@xml:id] 
(:            let $log := util:log("info", "remove-not-referenced-archives: remove archive: " || (count($refs) = 0)):)
            return
                if(count($refs) = 0)
                then (
                    update delete $archive
                ) 
                else ()
    let $store := xmldb:store($register-path, $register-filename, $archives-data)
    return
        $archives-data
};

declare function cr:remove-not-referenced-groups($register-path, $register-filename, $letters) {
    let $groups-data := doc($register-path || $register-filename)
    let $remove-groups := 
        for $group in $groups-data//tei:nym
            let $refs :=  $letters//tei:roleName[@ref = $group/@xml:id] 
            (: let $log := util:log("info", "remove-not-referenced-groups: remove group: " || (count($refs) = 0)) :)
            return
                if(count($refs) = 0)
                then (
                    update delete $group
                ) 
                else ()
    let $store := xmldb:store($register-path, $register-filename, $groups-data)
    return
        $groups-data
};

declare function cr:remove-not-referenced-institutions($register-path, $register-filename, $letters) {
    let $inst-data := doc($register-path || $register-filename)
    let $remove-institutions := 
        for $inst in $inst-data//tei:org
            let $refs :=  $letters//tei:orgName[@ref = $inst/@xml:id] 
            (: let $log := util:log("info", "remove-not-referenced-institution: remove instituion: " || (count($refs) = 0)) :)
            return
                if(count($refs) = 0)
                then (
                    update delete $inst
                ) 
                else ()
    let $store := xmldb:store($register-path, $register-filename, $inst-data)
    return
        $inst-data
};

declare function cr:clean-all(){
let $register-root := "/db/apps/bullinger-data/data/index/"
let $all-letters := collection("/db/apps/bullinger-data/data/letters")
return  (
        cr:remove-not-referenced-places (       $register-root, "localities.xml",   $all-letters),
        cr:remove-not-referenced-persons (      $register-root, "persons.xml",      $all-letters),
        cr:remove-not-referenced-archives (     $register-root, "archives.xml",     $all-letters),
        cr:remove-not-referenced-groups (       $register-root, "groups.xml",       $all-letters),
        cr:remove-not-referenced-institutions ( $register-root, "institutions.xml", $all-letters)
    )
};


declare function cr:cleanup-register($file) {
    let $log := util:log("info", "cr:cleanup-register: file: " || $file)
    let $register-root := "/db/apps/bullinger-data/data/index/"
    let $all-letters := collection("/db/apps/bullinger-data/data/letters")    
    let $register := doc($register-root || $file)
    let $remove-not-referenced-entries := 
        switch($file)
            case "archives.xml" 
                return 
                    cr:remove-not-referenced-archives($register-root, $file, $all-letters)
            case "groups.xml" 
                return 
                    cr:remove-not-referenced-groups($register-root, $file, $all-letters)
            case "institutions.xml" 
                return 
                    cr:remove-not-referenced-institutions($register-root, $file, $all-letters)
            case "localities.xml" 
                return 
                    cr:remove-not-referenced-places($register-root, $file, $all-letters)
            case "persons.xml" 
                return 
                    cr:remove-not-referenced-persons($register-root, $file, $all-letters)
            default 
                return
                    <result>ERROR</result>
    return
        $register
};
