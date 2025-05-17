AddComponentPostInit(
    "sandstorms",
    function(self)
        local inst = self.inst
        if inst:HasTag("cave") then
            return
        end
        --Private
        local _sandstormactive = false
        local _issandstormseason = false
        local _iswet = false
        --[[ Private member functions ]]
        local function ShouldActivateSandstorm()
            return _issandstormseason and not _iswet
        end
        local function ToggleSandstorm()
            if _sandstormactive ~= ShouldActivateSandstorm() then
                _sandstormactive = not _sandstormactive
                inst:PushEvent("ms_stormchanged", { stormtype = STORM_TYPES.SANDSTORM, setting = _sandstormactive })
            end
        end
        --[[ Private event handlers ]]
        local function OnSeasonTick(src, data)
            if GetModConfigData("spring") then
                _issandstormseason = data.season ~= SEASONS.WINTER
            else
                _issandstormseason = data.season == SEASONS.SUMMER or data.season == SEASONS.AUTUMN
            end
            ToggleSandstorm()
        end
        local function OnWeatherTick(src, data)
            _iswet = data.wetness > 0 or data.snowlevel > 0
            ToggleSandstorm()
        end
        --Register events
        inst:ListenForEvent(
            "weathertick",
            function(...)
                local args = { ... }
                inst:DoTaskInTime(
                    0.25,
                    function()
                        OnWeatherTick(unpack(args))
                    end
                )
            end
        )
        inst:ListenForEvent(
            "seasontick",
            function(...)
                local args = { ... }
                inst:DoTaskInTime(
                    0.25,
                    function()
                        OnSeasonTick(unpack(args))
                    end
                )
            end
        )
        -- Component Functions
        local function IsInSandstorm(self, ent)
            return _sandstormactive and ent.components.areaaware ~= nil and
                ent.components.areaaware:CurrentlyInTag("sandstorm")
        end
        local function GetSandstormLevel(self, ent)
            if
                _sandstormactive and ent.components.areaaware ~= nil and
                ent.components.areaaware:CurrentlyInTag("sandstorm")
            then
                local oasislevel = self:CalcOasisLevel(ent)
                return oasislevel < 1 and math.clamp(self:CalcSandstormLevel(ent) - oasislevel, 0, 1) or 0
            end
            return 0
        end
        local function IsSandstormActive(self)
            return _sandstormactive
        end
        local oldIsInSandstorm = inst.components.sandstorms.IsInSandstorm
        inst.components.sandstorms.IsInSandstorm = function(...)
            return oldIsInSandstorm(...) or IsInSandstorm(...)
        end
        local oldGetSandstormLevel = inst.components.sandstorms.GetSandstormLevel
        inst.components.sandstorms.GetSandstormLevel = function(...)
            local level = oldGetSandstormLevel(...)
            if level == 0 then
                return GetSandstormLevel(...)
            end
            return level
        end
        local oldIsSandstormActive = inst.components.sandstorms.IsSandstormActive
        inst.components.sandstorms.IsSandstormActive = function(...)
            return oldIsSandstormActive(...) or IsSandstormActive(...)
        end
    end
)
