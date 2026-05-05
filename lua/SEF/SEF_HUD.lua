if CLIENT then

    local ply = LocalPlayer()
    ActiveEffects = {}
    ActivePassives = {}
    PlayerEffectStacks = {}
    PlayerPassiveStacks = {}
    AllEntEffects = {}
    local LastValidEntities = {}
    local ToolTipData = {}

    CreateClientConVar("SEF_StatusEffectX", 50, true, false, "X position of Status Effects applied on you.", 0, 1920)
    CreateClientConVar("SEF_StatusEffectY", 925, true, false, "Y position of Status Effects applied on you.", 0, 1080)
    CreateClientConVar("SEF_ScaleUI", 1, true, false, "Scale UI with this ConVar if you see it too small or too big", 0.1, math.huge)
    CreateClientConVar("SEF_StatusEffectDisplay", 0, true, false, "Shows effects on players/NPCS/Lambdas.", 0, 2)
    CreateClientConVar("SEF_StatusEffectHUDStyle", 1, true, false, "Change style of Status Effects.", -1, 3)
    CreateClientConVar("SEF_HUDStyle", "Default", true, false, "Change style of HUD. It uses string name of the style. [for ex. Default]")
    local ScaleUI

    local function WithinDistance(A, target, dist)
        local Dist = dist * dist

        return A:GetPos():DistToSqr( target ) < Dist
    end
    
    local function DisplayStatusEffects()
            
        local StatusEffX = math.floor(GetConVar("SEF_StatusEffectX"):GetInt() * (ScrW()/1920))
        local StatusEffY = math.floor(GetConVar("SEF_StatusEffectY"):GetInt() * (ScrH()/1080))
        local PassiveX = math.floor(GetConVar("SEF_StatusEffectX"):GetInt() * (ScrW()/1920))
        local PassiveY = math.floor((GetConVar("SEF_StatusEffectY"):GetInt() + 25) * (ScrH()/1080))
        local style = SEFHUDStyles[GetConVar("SEF_HUDStyle"):GetString()] or SEFHUDStyles.Default

        local hoveredName, hoveredData = nil, nil

        for effectName, effectData in SortedPairsByMemberValue(ActiveEffects, "StartTime", false) do
            style.DrawFunction(effectName, effectData, StatusEffX, StatusEffY)
            local bounds = style.TooltipMouseBounds or { x = 50, y = 50 }
            local isHovered = SEFHUDHelpers.IsHover(
                StatusEffX,
                StatusEffY,
                bounds.x,
                bounds.y
            )

            --surface.DrawRect(StatusEffX - bounds.x/2, StatusEffY - bounds.y/2, bounds.x, bounds.y)

            if isHovered then
                hoveredName = effectName
                hoveredData = effectData
            end

            if hoveredName then
                local mx, my = gui.MouseX(), gui.MouseY()

                style.DrawTooltipFunction(
                    hoveredName,
                    hoveredData,
                    mx,
                    my
                )
            end

            StatusEffY = StatusEffY + style.StyleSpacingY
            StatusEffX = StatusEffX + style.StyleSpacingX

        end

		for passiveName, passiveData in pairs(ActivePassives) do

		end

    end
    ----------------------3D RENDERING OF EFFECTS-------------------------------------
    local function UpdateVisibleEntities()
        local visibleEntities = {}
    
        for ent, statuseffects in pairs(AllEntEffects) do
            if IsValid(ent) and  ent ~= LocalPlayer() and WithinDistance(LocalPlayer(), ent:GetPos(), 1500) then
                local distance = LocalPlayer():GetPos():DistToSqr(ent:GetPos()) -- Kwadrat odległości (optymalniejsze)
                table.insert(visibleEntities, { ent = ent, dist = distance })
            elseif not IsValid(ent) then
                print("[Status Effect Framework] Removed data about no longer valid entity.")
                AllEntEffects[ent] = nil
            end
        end
    
        -- Sortowanie bytów według odległości (rosnąco)
        table.SortByMember(visibleEntities, "dist", true)
    
        -- Zachowaj tylko 10 najbliższych
        LastValidEntities = {}
        for i = 1, math.min(10, #visibleEntities) do
            table.insert(LastValidEntities, visibleEntities[i].ent)
        end
    end

    timer.Create("UpdateVisibleEntities", 0.5, 0, UpdateVisibleEntities)
    
    

    function SEFGetOverlayTransform(ent, offset)
        if not IsValid(ent) then return end
        local pos = ent:GetPos() + ent:GetUp() * (ent:OBBMaxs().z + 15)

        local ang = (pos - EyePos()):GetNormalized():Angle()

        local right = ang:Right()
        pos = pos + right * offset

        ang:RotateAroundAxis(ang:Up(), -90)
        ang:RotateAroundAxis(ang:Forward(), 90)

        return {
            pos = pos,
            ang = ang,
            scale = 0.5
        }
    end

    -- Funkcja rysująca efekty

    local function DisplayStatusEffects3D()

        if not GetConVar("SEF_StatusEffectDisplay"):GetBool() then return end
        local style = SEFHUDStyles[GetConVar("SEF_HUDStyle"):GetString()] or SEFHUDStyles.Default

        for _, ent in ipairs(LastValidEntities) do
            local CurrentEntStatusEffects = AllEntEffects[ent]
            if not CurrentEntStatusEffects then continue end

            local effectCount = table.Count(CurrentEntStatusEffects)
            local spacingX = style.OverlaySpacingX or 13
            local spacingY = style.OverlaySpacingY or 0
            local startOffset = -((effectCount - 1) * spacingX) / 2

            local index = 0

            for effectName, effectData in SortedPairsByMemberValue(CurrentEntStatusEffects, "StartTime", false) do

                local offset = startOffset + index * spacingX

                local transform = SEFGetOverlayTransform(ent, offset)
                if not transform then continue end

                cam.Start3D2D(transform.pos, transform.ang, transform.scale)

                    style.DrawOverlayFunction(ent, effectName, effectData)

                cam.End3D2D()

                index = index + 1
            end
        end
    end
    

    net.Receive("SEF_EffectData", function()
        local action = net.ReadString()
        local effectType = net.ReadString()

        if effectType == "Effect" then
            local effectName = net.ReadString()

            if action == "Add" then
                local desc = net.ReadString()
                local duration = net.ReadFloat()
                local startTime = CurTime()

                ActiveEffects[effectName] = {
                    EffectName = effectName,
                    Desc = desc,
                    Duration = duration,
                    StartTime = startTime
                }
            elseif action == "Remove" then
                ActiveEffects[effectName] = nil
            end

        elseif effectType == "Passive" then
            local passiveName = net.ReadString()

            if action == "Add" then
                local desc = net.ReadString()

                ActivePassives[passiveName] = {
                    PassiveName = passiveName,
                    PassiveDesc = desc
                }

            elseif action == "Remove" then
                ActivePassives[passiveName] = nil
            end
        end
    end)


    net.Receive("SEF_EntityData", function()
        local action = net.ReadString()    -- "Add" lub "Remove"
        local ent = net.ReadEntity()
        local effectName = net.ReadString()

        if not IsValid(ent) then return end

        if action == "Add" then
            local duration = net.ReadFloat()
            local startTime = net.ReadFloat()

            AllEntEffects[ent] = AllEntEffects[ent] or {}
            AllEntEffects[ent][effectName] = {
                Duration = duration,
                StartTime = startTime
            }
        elseif action == "Remove" then
            if AllEntEffects[ent] then
                AllEntEffects[ent][effectName] = nil
                if next(AllEntEffects[ent]) == nil then
                    AllEntEffects[ent] = nil
                end
            end
        else
            print("[SEF] Unknown action in SEF_EntityData:", action)
        end
    end)


    net.Receive("SEF_UpdateData", function()
        local Ent = net.ReadEntity()
        local EffectName = net.ReadString()
        local ChangedTime = net.ReadFloat()

        if AllEntEffects[Ent] and AllEntEffects[Ent][EffectName] then
            AllEntEffects[Ent][EffectName].Duration = ChangedTime
        end

        if Ent == LocalPlayer() then
            if ActiveEffects[EffectName] then
                ActiveEffects[EffectName].Duration = ChangedTime
            end
        end
    end)

    net.Receive("SEF_StackSystem", function() 
        local command = net.ReadString()
        local effect = net.ReadString()
        local stacks = net.ReadInt(32)
    
        if command == "ADD" then
            if StatusEffects[effect] then
                PlayerEffectStacks[effect] = (PlayerEffectStacks[effect] or 0) + stacks
            elseif PassiveEffects[effect] then
                PlayerPassiveStacks[effect] = (PlayerPassiveStacks[effect] or 0) + stacks
            end
        elseif command == "SET" then
            if StatusEffects[effect] then
                PlayerEffectStacks[effect] = stacks
            elseif PassiveEffects[effect] then
                PlayerPassiveStacks[effect] =  stacks
            end
        elseif command == "REMOVE" then
            if StatusEffects[effect] then
                if PlayerEffectStacks[effect] then
                    PlayerEffectStacks[effect] = PlayerEffectStacks[effect] - stacks
                    if PlayerEffectStacks[effect] <= 0 then
                        PlayerEffectStacks[effect] = nil
                    end
                end
            elseif PassiveEffects[effect] then
                if PlayerPassiveStacks[effect] then
                    PlayerPassiveStacks[effect] = PlayerPassiveStacks[effect] - stacks
                    if PlayerPassiveStacks[effect] <= 0 then
                        PlayerPassiveStacks[effect] = nil
                    end
                end
            end
    
        elseif command == "CLEAR" then
            if StatusEffects[effect] then
                PlayerEffectStacks[effect] = nil
            elseif PassiveEffects[effect] then
                PlayerPassiveStacks[effect] = nil
            end
    
        elseif command == "CLEARALL" then
            PlayerEffectStacks = {}
            PlayerPassiveStacks = {}
        end
    end)

    net.Receive("SEF_UpdateDesc", function()
        local effectName = net.ReadString()
        local newDesc = net.ReadString()

        if ActiveEffects[effectName] then
            ActiveEffects[effectName].Desc = newDesc
        elseif ActivePassives[effectName] then
            ActivePassives[effectName].Desc = newDesc
        end
    end)


    hook.Add("HUDPaint", "DisplayStatusEffectsHUD", DisplayStatusEffects)
    hook.Add("PostDrawTranslucentRenderables", "DisplayStatusEffectsHUD3D", DisplayStatusEffects3D)
end