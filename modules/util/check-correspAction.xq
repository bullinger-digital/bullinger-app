xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:checkCorrespAction() {
    let $letters := collection('/db/apps/bullinger-data/data/letters')//tei:TEI
    let $correspActionSent := 
        for $correspSend in $letters//tei:correspAction[@type ="sent"]
            let $places := $correspSend//tei:place
            return
                if(count($places) = 0 )
                then (
                    element place {
                        attribute type {"no-place"},
                        attribute letter { util:document-name($correspSend)}
                    }
                )
                else if(count($places) > 1 )
                then (
                    element place {
                        attribute type {"multi-place"},
                        attribute letter { util:document-name($correspSend)}
                    }
                    
                ) else ()
                    
    let $correspActionReceived := 
            for $correspSend in $letters//tei:correspAction[@type ="received"]
            let $places := $correspSend//tei:place
            return
                if(count($places) = 0 )
                then (
                    element place {
                        attribute type {"no-place"},
                        attribute letter { util:document-name($correspSend)}
                    }
                )
                else if(count($places) > 1 )
                then (
                    element place {
                        attribute type {"multi-place"},
                        attribute letter { util:document-name($correspSend)}
                    }
                    
                ) else ()
    return
        element result {
            element correspActionSent {
                attribute no-place { count($correspActionSent[@type = "no-place"]) },
                attribute multi-place { count($correspActionSent[@type = "multi-place"]) },
                $correspActionSent[@type="multi-place"]
           },
            element correspActionReceived {
                attribute no-place { count($correspActionReceived[@type = "no-place"]) },
                attribute multi-place { count($correspActionReceived[@type = "multi-place"]) },
                $correspActionReceived[@type="multi-place"]
           }           
        }
}; 

local:checkCorrespAction()