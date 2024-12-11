Config = {
    FuseTime = 10.0,     -- Default fuse time
    MaxGrenades = 3,     -- Default max grenades
    BaseVelocity = 20.0, -- Base throwing velocity
    
    Grenades = {
        ["grenade"] = {
            model       = `s_baseball01x`,  -- grenade model
            itemName    = "grenade",        -- usable item name
            fuseTime    = 10.0,             -- time to explode
            maxCount    = 3,                -- Max gernades per use
            explode     = function(coords)
                Citizen.InvokeNative(0x7D6F58F69DA92530, 
                    coords.x, coords.y, coords.z,
                    26,     -- EXP_TAG_DYNAMITESTACK
                    2.0,    -- damage scale
                    true,   -- is audible
                    false,  -- is invisible
                    1.0     -- shake
                )
            end
        },
        ["gaz_grenade"] = {
            model       = `s_baseball01x`,
            itemName    = "gaz_grenade",
            fuseTime    = 10.0,
            maxCount    = 5,
            explode     = function(coords)
                Citizen.InvokeNative(0x7D6F58F69DA92530, 
                    coords.x, coords.y, coords.z,
                    35,     -- EXP_TAG_POISON_BOTTLE
                    2.0,
                    true,
                    false,
                    0.0
                )
            end
        }
        -- Add more grenade types here
    }
}