if CLIENT then

    local ply = LocalPlayer()
    ActiveEffects = {}
    ActivePassives = {}
    PlayerEffectStacks = {}
    PlayerPassiveStacks = {}
    AllEntEffects = {}

    local LastValidEntities = {}

    local CachedMaterials = {
        Circle = Material("SEF_Icons/StatusEffectCircle.png"),
        Square = Material("SEF_Icons/PassiveSquare.png")
    }

    surface.CreateFont("SEFFont", {
        font = "Stratum2 Md",
        size = 20,
        weight = 500,
        antialias = true,
        outline = false,
        shadow = true
    })

    surface.CreateFont("SEFFontSmall", {
        font = "Stratum2 Md",
        size = 15,
        weight = 500,
        antialias = true,
        outline = false,
        shadow = true
    })

    CreateClientConVar("SEF_StatusEffectX", 50, true, false, "X position of Status Effects applied on you.", 0, 1920)
    CreateClientConVar("SEF_StatusEffectY", 925, true, false, "Y position of Status Effects applied on you.", 0, 1080)
    CreateClientConVar("SEF_ScaleUI", 1, true, false, "Scale UI with this ConVar if you see it too small or too big", 0.1, math.huge)
    CreateClientConVar("SEF_StatusEffectDisplay", 0, true, false, "Shows effects on players/NPCS/Lambdas.", 0, 2)
    CreateClientConVar("SEF_StatusEffectHUDStyle", 1, true, false, "Change style of Status Effects.", -1, 2)
    local ScaleUI

    local function SplitCamelCase(str)
        return str:gsub("(%l)(%u)", "%1 %2")
    end

    local function DrawStatusEffectTimer(x, y, effectName, effectDesc, duration, startTime)
        local effect = StatusEffects[effectName]
        if not effect then return end

        local mouseX = gui.MouseX()
        local mouseY = gui.MouseY()
        ScaleUI = GetConVar("SEF_ScaleUI"):GetFloat()
    
        local centerX = x * ScaleUI
        local centerY = y * ScaleUI
        local radius = 22 * ScaleUI
        local innerRadius = 20 * ScaleUI

        if centerX - radius < 0 then centerX = radius end
        if centerY - radius < 0 then centerY = radius end
        if centerX + radius > ScrW() then centerX = ScrW() - radius end
        if centerY + radius > ScrH() then centerY = ScrH() - radius end
    
        surface.SetFont("SEFFont")
    
        local FormattedName = effect.Name or SplitCamelCase(effectName)
    
        local NameW, NameH = surface.GetTextSize(FormattedName)
        local DescW, DescH = 0, 0
        if effectDesc and effectDesc ~= "" then
            DescW, DescH = surface.GetTextSize(effectDesc)
        end
        local DurW, DurH = surface.GetTextSize("Duration: " .. duration .. " seconds")
        local TotalWidth = math.max(NameW, DurW, DescW)
        local TotalHeight = NameH + DurH + DescH
        local StackAmount
        local StackName
        local StackWidth, StackHeight
        local StackNumberWidth, StackNumberHeight
        if PlayerEffectStacks[effectName] then
            StackAmount = PlayerEffectStacks[effectName]
            if effect.StackName then
                StackName = tostring(effect.StackName)
            else
                StackName = "Stacks"
            end
            StackWidth, StackHeight = surface.GetTextSize(StackName)
            StackNumberWidth, StackNumberHeight = surface.GetTextSize(StackAmount)
        else
            StackAmount = 0
            StackName = nil
            StackWidth, StackHeight = nil
            StackNumberWidth, StackNumberHeight = nil
        end
    
        local icon = Material(effect.Icon)
    
        -- Oblicz upływ czasu
        local elapsedTime = CurTime() - startTime
        local fraction = math.Clamp(elapsedTime / duration, 0, 1)
        local startAngle = 270  -- Początkowy kąt (góra)
        local angle = 360 * (1 - fraction)  -- Odwrotność frakcji aby się "opróżniało"
    
        local innerVertices = {}
        table.insert(innerVertices, { x = centerX, y = centerY })
    
        for i = 0, 360, 1 do
            local rad = math.rad(i)
            table.insert(innerVertices, {
                x = centerX + math.cos(rad) * innerRadius,
                y = centerY + math.sin(rad) * innerRadius
            })
        end
    
        if effect.Type == "BUFF" then
            surface.SetDrawColor(9, 73, 0)
        else
            surface.SetDrawColor(53, 0, 0)
        end
        draw.NoTexture()
        surface.DrawPoly(innerVertices)
    
        -- Rysowanie kółka
        local vertices = {}
        table.insert(vertices, { x = centerX, y = centerY })
    
        for i = startAngle, startAngle + angle, 1 do
            local rad = math.rad(i)
            table.insert(vertices, {
                x = centerX + math.cos(rad) * radius,
                y = centerY + math.sin(rad) * radius
            })
        end
    
        if effect.Type == "BUFF" then
            surface.SetDrawColor(30, 255, 0, 255)
            TextColor = Color(30, 255, 0, 255)
        else
            surface.SetDrawColor(255, 0, 0, 255)
            TextColor = Color(255, 0, 0, 255)
        end
        draw.NoTexture()
        surface.DrawPoly(vertices)
    
        surface.SetDrawColor(80, 80, 80)
        surface.SetMaterial(CachedMaterials.Circle)
        surface.DrawTexturedRectRotated(centerX, centerY, 50 * ScaleUI, 50 * ScaleUI, 0)
    
        -- Rysowanie ikony w środku
        surface.SetMaterial(icon)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(centerX - 16 * ScaleUI, centerY - 16 * ScaleUI, 32 * ScaleUI, 32 * ScaleUI)
    
        local remainingTime = duration - (CurTime() - startTime)
        local TimeDisplay
        if remainingTime == math.huge then
            TimeDisplay = "∞"
        else
            TimeDisplay = math.Round(remainingTime)
        end

        draw.SimpleText(TimeDisplay, "SEFFont", centerX, centerY + 24 * ScaleUI, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT)
        if StackAmount > 1 then
            draw.SimpleText(StackName .. ": " .. StackAmount, "SEFFontSmall", centerX, centerY + 42 * ScaleUI, Color(255, 238, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT)
        end
    
        if mouseX >= centerX - 16 * ScaleUI and mouseX <= centerX + 16 * ScaleUI and mouseY >= centerY - 16 * ScaleUI and mouseY <= centerY + 16 * ScaleUI then
            local tooltipX = mouseX
            local tooltipY = mouseY + 30
    
            if tooltipX + TotalWidth + 10 > ScrW() then
                tooltipX = ScrW() - TotalWidth - 10
            end
            if tooltipY + TotalHeight > ScrH() then
                tooltipY = ScrH() - TotalHeight - 10
            end
    
            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawRect(tooltipX, tooltipY, TotalWidth + 10, TotalHeight)
            
            draw.SimpleText(FormattedName, "SEFFont", tooltipX + 5, tooltipY, Color(255, 208, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            if DescH > 0 then
                draw.DrawText(effectDesc, "SEFFont", tooltipX + 5, tooltipY + NameH, TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end

            draw.SimpleText("Duration: " .. duration .. " seconds", "SEFFont", tooltipX + 5, tooltipY + NameH + DescH, TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end
    
    local function DrawBoxStatusEffectTimer(x, y, effectName, effectDesc, duration, startTime)
        local effect = StatusEffects[effectName]
        if not effect then return end
    
        local mouseX = gui.MouseX()
        local mouseY = gui.MouseY()
        local ScaleUI = GetConVar("SEF_ScaleUI"):GetFloat()
    
        surface.SetFont("SEFFont")
    
        local FormattedName = effect.Name or SplitCamelCase(effectName)
    
        local NameW, NameH = surface.GetTextSize(FormattedName)
        local DescW, DescH = 0, 0
        if effectDesc and effectDesc ~= "" then
            DescW, DescH = surface.GetTextSize(effectDesc)
        end
        local DurW, DurH = surface.GetTextSize("Duration: " .. duration .. " seconds")
        local TotalWidth = math.max(NameW, DurW, DescW)
        local TotalHeight = NameH + DurH + DescH
        local StackAmount
        local StackName
        local StackWidth, StackHeight
        local StackNumberWidth, StackNumberHeight
        if PlayerEffectStacks[effectName] then
            StackAmount = PlayerEffectStacks[effectName]
            StackName = effect.StackName or "Stacks"
            StackWidth, StackHeight = surface.GetTextSize(StackName)
            StackNumberWidth, StackNumberHeight = surface.GetTextSize(StackAmount)
        else
            StackAmount, StackName, StackWidth, StackHeight = 0, nil, nil, nil
            StackNumberWidth, StackNumberHeight = nil
        end
    
        local icon = Material(effect.Icon)
    
        local TextColor, BarColor
        if effect.Type == "BUFF" then
            surface.SetDrawColor(30, 255, 0, 255)
            TextColor, BarColor = Color(30, 255, 0, 255), Color(30, 125, 0)
        else
            surface.SetDrawColor(255, 0, 0, 255)
            TextColor, BarColor = Color(255, 0, 0, 255), Color(80, 0, 0)
        end
    
        local remainingTime = duration - (CurTime() - startTime)
        local TimeDisplay = remainingTime == math.huge and "∞" or remainingTime < 10 and string.format("%.1f", remainingTime) or remainingTime > 10 and math.Round(remainingTime)
        local barWidth = 147 * (remainingTime / duration)

        if remainingTime == math.huge then barWidth = 148 end
    
        -- Scaled background rect
        surface.SetDrawColor(80, 80, 80)
        surface.DrawOutlinedRect(x * ScaleUI, y * ScaleUI, 150 * ScaleUI, 50 * ScaleUI, 2)
        surface.SetDrawColor(80, 80, 80, 100)
        surface.DrawRect(x * ScaleUI, y * ScaleUI, 150 * ScaleUI, 50 * ScaleUI)
    
        -- Scaled inner colored bar
        surface.SetDrawColor(BarColor)
        surface.DrawRect((x + 2) * ScaleUI, (y + 2) * ScaleUI, barWidth * ScaleUI, 46 * ScaleUI)
    
        -- Icon
        surface.SetMaterial(icon)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRectRotated((x + 25) * ScaleUI, (y + 25) * ScaleUI, 30 * ScaleUI, 30 * ScaleUI, 0)
    
        -- Remaining time display
        draw.SimpleText(TimeDisplay, "SEFFont", (x + 140) * ScaleUI, (y + 15) * ScaleUI, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_LEFT)
    
        -- Stack display
        if StackAmount > 1 then
            draw.SimpleText(StackName .. ": " .. StackAmount, "SEFFont", (x + 155) * ScaleUI, (y + 15) * ScaleUI, Color(255, 238, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
        end
    
        -- Tooltip for hover
        if mouseX >= x * ScaleUI and mouseX <= (x + 150) * ScaleUI and mouseY >= y * ScaleUI and mouseY <= (y + 50) * ScaleUI then
            local tooltipX, tooltipY = mouseX, mouseY + 30
            if tooltipX + TotalWidth + 10 > ScrW() then
                tooltipX = ScrW() - TotalWidth - 10
            end
            if tooltipY + TotalHeight > ScrH() then
                tooltipY = ScrH() - TotalHeight - 10
            end
    
            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawRect(tooltipX, tooltipY, (TotalWidth + 10) * ScaleUI, TotalHeight * ScaleUI)
            
            draw.SimpleText(FormattedName, "SEFFont", tooltipX + 5, tooltipY, Color(255, 208, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            if DescH > 0 then
                draw.DrawText(effectDesc, "SEFFont", tooltipX + 5, tooltipY + NameH, TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
            draw.SimpleText("Duration: " .. duration .. " seconds", "SEFFont", tooltipX + 5, tooltipY + NameH + DescH, TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end

    local function DrawSquareStatusEffectTimer(x, y, effectName, effectDesc, duration, startTime)
        local effect = StatusEffects[effectName]
        if not effect then return end
    
        local mouseX = gui.MouseX()
        local mouseY = gui.MouseY()
        local ScaleUI = GetConVar("SEF_ScaleUI"):GetFloat()
    
        surface.SetFont("SEFFont")
    
        local FormattedName = effect.Name or SplitCamelCase(effectName)
    
        local NameW, NameH = surface.GetTextSize(FormattedName)
        local DescW, DescH = 0, 0
        if effectDesc and effectDesc ~= "" then
            DescW, DescH = surface.GetTextSize(effectDesc)
        end
        local DurW, DurH = surface.GetTextSize("Duration: " .. duration .. " seconds")
        local TotalWidth = math.max(NameW, DurW, DescW)
        local TotalHeight = NameH + DurH + DescH
        local StackAmount
        local StackName
        local StackWidth, StackHeight
        local StackNumberWidth, StackNumberHeight
        if PlayerEffectStacks[effectName] then
            StackAmount = PlayerEffectStacks[effectName]
            StackName = effect.StackName or "Stacks"
            StackWidth, StackHeight = surface.GetTextSize(StackName)
            StackNumberWidth, StackNumberHeight = surface.GetTextSize(StackAmount)
        else
            StackAmount, StackName, StackWidth, StackHeight = 0, nil, nil, nil
            StackNumberWidth, StackNumberHeight = nil
        end
    
        local icon = Material(effect.Icon)
    
        local TextColor, BarColor
        if effect.Type == "BUFF" then
            surface.SetDrawColor(30, 255, 0, 255)
            TextColor, BarColor = Color(30, 255, 0, 255), Color(30, 125, 0)
        else
            surface.SetDrawColor(255, 0, 0, 255)
            TextColor, BarColor = Color(255, 0, 0, 255), Color(80, 0, 0)
        end
    
        local remainingTime = duration - (CurTime() - startTime)
        local TimeDisplay = remainingTime == math.huge and "∞" or remainingTime < 10 and string.format("%.1f", remainingTime) or remainingTime > 10 and math.Round(remainingTime)
        local barHeight = 50 * (remainingTime / duration)

        if remainingTime == math.huge then barHeight = 50 end
    
        -- Scaled background rect
        surface.SetDrawColor(80, 80, 80)
        surface.DrawOutlinedRect(x * ScaleUI, y * ScaleUI, 50 * ScaleUI, 50 * ScaleUI, 2)
        surface.SetDrawColor(80, 80, 80, 100)
        surface.DrawRect(x * ScaleUI, y * ScaleUI, 50 * ScaleUI, 50 * ScaleUI)
    
        -- Scaled inner colored bar
        surface.SetDrawColor(BarColor)
        surface.DrawRect((x + 1) * ScaleUI, (y + 50 - barHeight) * ScaleUI, 48 * ScaleUI, barHeight * ScaleUI)
    
        -- Icon
        surface.SetMaterial(icon)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRectRotated((x + 25) * ScaleUI, (y + 25) * ScaleUI, 30 * ScaleUI, 30 * ScaleUI, 0)
    
        -- Remaining time display
        draw.SimpleText(TimeDisplay, "SEFFont", (x + 25) * ScaleUI, (y - 20) * ScaleUI, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
        -- Stack display
        if StackAmount > 1 then
            draw.SimpleText(StackName .. ": " .. StackAmount, "SEFFont", (x + 25) * ScaleUI, (y + 60) * ScaleUI, Color(255, 238, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    
        -- Tooltip for hover
        if mouseX >= x * ScaleUI and mouseX <= (x + 50) * ScaleUI and mouseY >= y * ScaleUI and mouseY <= (y + 50) * ScaleUI then
            local tooltipX, tooltipY = mouseX, mouseY + 30
            if tooltipX + TotalWidth + 10 > ScrW() then
                tooltipX = ScrW() - TotalWidth - 10
            end
            if tooltipY + TotalHeight > ScrH() then
                tooltipY = ScrH() - TotalHeight - 10
            end
    
            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawRect(tooltipX, tooltipY, (TotalWidth + 10) * ScaleUI, TotalHeight * ScaleUI)
            
            draw.SimpleText(FormattedName, "SEFFont", tooltipX + 5, tooltipY, Color(255, 208, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            if DescH > 0 then
                draw.DrawText(effectDesc, "SEFFont", tooltipX + 5, tooltipY + NameH, TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
            draw.SimpleText("Duration: " .. duration .. " seconds", "SEFFont", tooltipX + 5, tooltipY + NameH + DescH, TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end
    

    local function DrawActivePassive(x, y, passiveName, passiveDesc)
        local effect = PassiveEffects[passiveName]
        if not effect then return end
    
        local mouseX = gui.MouseX()
        local mouseY = gui.MouseY()
        ScaleUI = GetConVar("SEF_ScaleUI"):GetFloat()
    
        -- Przeskalowanie pozycji
        local centerX = x * ScaleUI
        local centerY = y * ScaleUI
    
        surface.SetFont("SEFFont")
    
        local FormattedName = effect.Name or SplitCamelCase(passiveName)
    
        local TextColor = Color(255, 255, 255)
        local NameW, NameH = surface.GetTextSize(FormattedName)
        local DescW, DescH = 0, 0
        if passiveDesc and passiveDesc ~= "" then
            DescW, DescH = surface.GetTextSize(passiveDesc)
        end
        local TotalWidth = math.max(NameW, DescW)
        local TotalHeight = (NameH + DescH)
        local StackAmount
        if PlayerPassiveStacks[passiveName] then
            StackAmount = PlayerPassiveStacks[passiveName]
            if effect.StackName then
                StackName = tostring(effect.StackName)
            else
                StackName = "Stacks"
            end
        else
            StackAmount = 0
            StackName = nil
        end

    
        -- Sprawdzanie granic ekranu
        local halfIconSize = 16 * ScaleUI
        if centerX - halfIconSize < 0 then centerX = halfIconSize end
        if centerY - halfIconSize < 0 then centerY = halfIconSize end
        if centerX + halfIconSize > ScrW() then centerX = ScrW() - halfIconSize end
        if centerY + halfIconSize > ScrH() then centerY = ScrH() - halfIconSize end
    
        local icon = Material(effect.Icon)
    
        -- Rysowanie tła ikony
        surface.SetDrawColor(80, 80, 80)
        surface.SetMaterial(CachedMaterials.Square)
        surface.DrawTexturedRectRotated(centerX, centerY, 40 * ScaleUI, 40 * ScaleUI, 0)
    
        -- Rysowanie ikony
        surface.SetMaterial(icon)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(centerX - halfIconSize, centerY - halfIconSize, 32 * ScaleUI, 32 * ScaleUI)

        if StackAmount > 1 then
            draw.SimpleText(StackName .. ": " .. StackAmount, "SEFFontSmall", centerX, centerY + 38 * ScaleUI, Color(251, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT)
        end
    
        -- Sprawdzanie pozycji myszy
        if mouseX >= centerX - halfIconSize and mouseX <= centerX + halfIconSize and mouseY >= centerY - halfIconSize and mouseY <= centerY + halfIconSize then
            surface.SetDrawColor(0, 0, 0, 155)
            surface.DrawRect(mouseX, mouseY + 30, (TotalWidth + 10), (TotalHeight + 15))
            draw.SimpleText(FormattedName, "SEFFont", mouseX + 5, mouseY + 30, Color(0,162,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("[Passive]", "SEFFont", mouseX + 5, mouseY + 45, Color(0,162,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            if DescH > 0 then
                draw.DrawText(passiveDesc, "SEFFont", mouseX + 5, mouseY + 45 + NameH, TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
        end
    end
    

    local function WithinDistance(A, target, dist)
        local Dist = dist * dist

        return A:GetPos():DistToSqr( target ) < Dist
    end
    
    local function DisplayStatusEffects()
            
        local StatusEffX = math.floor(GetConVar("SEF_StatusEffectX"):GetInt() * (ScrW()/1920))
        local StatusEffY = math.floor(GetConVar("SEF_StatusEffectY"):GetInt() * (ScrH()/1080))
        local PassiveX = math.floor(GetConVar("SEF_StatusEffectX"):GetInt() * (ScrW()/1920))
        local PassiveY = math.floor((GetConVar("SEF_StatusEffectY"):GetInt() + 25) * (ScrH()/1080))
        local StatusEffectStyle = GetConVar("SEF_StatusEffectHUDStyle"):GetInt()
        local Margin = 20

        for effectName, effectData in SortedPairsByMemberValue(ActiveEffects, "StartTime", false) do

            if StatusEffectStyle == 0 then

                DrawStatusEffectTimer(StatusEffX , StatusEffY, effectName, effectData.Desc, effectData.Duration, effectData.StartTime)

                StatusEffX = StatusEffX + 50

            elseif StatusEffectStyle == 1 then

                DrawBoxStatusEffectTimer(StatusEffX , StatusEffY, effectName, effectData.Desc, effectData.Duration, effectData.StartTime)

                StatusEffY = StatusEffY - 55


            elseif StatusEffectStyle == 2 then

                DrawSquareStatusEffectTimer(StatusEffX , StatusEffY, effectName, effectData.Desc, effectData.Duration, effectData.StartTime)

                StatusEffX = StatusEffX + 50

            elseif StatusEffectStyle == -1 then end

        end

        for passiveName, passiveData in pairs(ActivePassives) do
            
            DrawActivePassive(PassiveX, PassiveY - 75, passiveName, passiveData)

            PassiveX = PassiveX + 50

        end

    end


    ----------------------3D RENDERING OF EFFECTS-------------------------------------

    local function Draw3DStatusEffect(ent, effectName, duration, startTime, offset)
        local effect = StatusEffects[effectName]
        if not IsValid(ent) then return end
        if not effect then return end
        if not WithinDistance(LocalPlayer(), ent:GetPos(), 1500) then return end

        local EntPos = ent:GetPos() + ent:GetUp() * (ent:OBBMaxs().z + 15)
        local EntAngle = (EntPos - EyePos()):GetNormalized():Angle()

        local rightVector = EntAngle:Right() -- Wektor prostopadły w lokalnym układzie
        EntPos = EntPos + rightVector * offset -- Dodanie przesunięcia względem obrotu kamery
    
        -- Rotacja 3D2D
        EntAngle:RotateAroundAxis(EntAngle:Up(), -90)
        EntAngle:RotateAroundAxis(EntAngle:Forward(), 90)
    
        -- Skalowanie i ikona
        local ScaleUI = GetConVar("SEF_ScaleUI"):GetFloat()
        local AdjustValue = ScaleUI > 2 and ScaleUI * 0.5 or 1
    
        local icon = Material(effect.Icon)
        local radius = 11.5 * AdjustValue
        local innerRadius = 9.5 * AdjustValue
    
        -- Obliczanie czasu trwania
        local elapsedTime = CurTime() - startTime
        local fraction = math.Clamp(elapsedTime / duration, 0, 1)
        local startAngle = 270
        local angle = 360 * (1 - fraction)
    
        -- Rysowanie efektu
        cam.Start3D2D(EntPos, EntAngle, 0.5)
            -- Pasek wypełnienia efektu

            local innerVertices = {}
            table.insert(innerVertices, { x = 0, y = 0 })
        
            for i = 0, 360, 1 do
                local rad = math.rad(i)
                table.insert(innerVertices, {
                    x = math.cos(rad) * innerRadius,
                    y = math.sin(rad) * innerRadius
                })
            end
        
            if effect.Type == "BUFF" then
                surface.SetDrawColor(9, 73, 0)
            else
                surface.SetDrawColor(53, 0, 0)
            end
            draw.NoTexture()
            surface.DrawPoly(innerVertices)


            local vertices = {}
            table.insert(vertices, { x = 0, y = 0 })
            for i = startAngle, startAngle + angle, 1 do
                local rad = math.rad(i)
                table.insert(vertices, {
                    x = math.cos(rad) * radius,
                    y = math.sin(rad) * radius
                })
            end
    
            if StatusEffects[effectName].Type == "BUFF" then
                surface.SetDrawColor(30, 255, 0, 255)
            else
                surface.SetDrawColor(255, 0, 0, 255)
            end
            draw.NoTexture()
            surface.DrawPoly(vertices)
    
            -- Ikona okręgu
            surface.SetDrawColor(80, 80, 80)
            surface.SetMaterial(CachedMaterials.Circle)
            surface.DrawTexturedRectRotated(0, 0, 23 * AdjustValue, 23 * AdjustValue, 0)
    
            -- Rysowanie ikony efektu
            surface.SetMaterial(icon)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRectRotated(0, 0, 18 * AdjustValue, 18 * AdjustValue, 0)
        cam.End3D2D()
    end

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
    
    

    -- Funkcja rysująca efekty
    local function DisplayStatusEffects3D()
        if not GetConVar("SEF_StatusEffectDisplay"):GetBool() then return end

        -- Pętla tylko przez widoczne encje
        for _, ent in ipairs(LastValidEntities) do
            local statuseffects = AllEntEffects[ent]
            if not statuseffects then continue end

            -- Oblicz przesunięcia
            local effectCount = table.Count(statuseffects)
            local spacing = 13
            local startOffset = -((effectCount - 1) * spacing) / 2

            local index = 0
            for effectName, effectData in SortedPairsByMemberValue(statuseffects, "StartTime", false) do
                local offset = startOffset + index * spacing
                Draw3DStatusEffect(ent, effectName, effectData.Duration, effectData.StartTime, offset)
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
            print("[SEF] Nieznana akcja w SEF_EntityData:", action)
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