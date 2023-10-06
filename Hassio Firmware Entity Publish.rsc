{
    global discoverypath "homeassistant/"
    global domainpath "update/"

    #-------------------------------------------------------
    #Get variables to build device string
    #-------------------------------------------------------

    global ID
    if ([/system/resource/get board-name] != "CHR") do={
    set ID [/system/routerboard get serial-number];#ID
    } else={
    set ID [system/license/get system-id ]
    }
    #-------------------------------------------------------
    #Build device string
    #-------------------------------------------------------
    local DeviceString [parse [system/script/get "HassioLib_DeviceString" source]]
    global dev [$DeviceString]
    global buildconfig do= {
        global discoverypath
        global domainpath
        global ID
        global dev

        #build config for Hassio
        local config "{\"~\":\"$discoverypath$domainpath$ID/$name\",\
            \"name\":\"$name\",\
            \"stat_t\":\"~/state\",\
            \"uniq_id\":\"$ID_$name\",\
            \"obj_id\":\"$ID_$name\",\
            $dev\
        }"
        /iot/mqtt/publish broker="Home Assistant" message=$config topic="$discoverypath$domainpath$ID/$name/config" retain=yes              
    }
    #-------------------------------------------------------
    #Handle routerboard firmware for non CHR
    #-------------------------------------------------------
    if ([/system/resource/get board-name] != "CHR") do={
        $buildconfig name="RouterBOARD"
    }

    #-------------------------------------------------------
    #Handle RouterOS
    #-------------------------------------------------------
    $buildconfig name="RouterOS"

    #-------------------------------------------------------
    #Handle LTE interfaces
    #-------------------------------------------------------
    :foreach iface in=[/interface/lte/ find] do={
    local ifacename [/interface/lte get $iface name]

    #Get manufacturer and model for LTE interface
    local lte [ [/interface/lte/monitor [/interface/lte get $iface name] once as-value] manufacturer]
        if ($lte->"manufacturer"="\"MikroTik\"") do={
            {
            #build config for LTE
            local modemname [:pick ($lte->"model")\
                ([:find ($lte->"model") "\"" -1] +1)\
                [:find ($lte->"model") "\"" [:find ($lte->"model") "\"" -1]]]
            $buildconfig name=$modemname
            }
        }
    }
}