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

        local StackAmount = PlayerEffectStacks[effectName] or 0
        local StackName = (StackAmount > 0) and (effect.StackName or "Stacks") or nil

        local StackWidth, StackHeight, StackNumberWidth, StackNumberHeight = nil, nil, nil, nil
        if StackName then
            StackWidth, StackHeight = surface.GetTextSize(StackName)
            StackNumberWidth, StackNumberHeight = surface.GetTextSize(tostring(StackAmount))
        end
    
        if not CachedMaterials[effect] then
            CachedMaterials[effect] = Material(effect.Icon)
        end

        local icon = CachedMaterials[effect]
    
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

        local StackAmount = PlayerEffectStacks[effectName] or 0
        local StackName = (StackAmount > 0) and (effect.StackName or "Stacks") or nil

        local StackWidth, StackHeight, StackNumberWidth, StackNumberHeight = nil, nil, nil, nil
        if StackName then
            StackWidth, StackHeight = surface.GetTextSize(StackName)
            StackNumberWidth, StackNumberHeight = surface.GetTextSize(tostring(StackAmount))
        end
    
        if not CachedMaterials[effect] then
            CachedMaterials[effect] = Material(effect.Icon)
        end

        local icon = CachedMaterials[effect]
    
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

        local StackAmount = PlayerEffectStacks[effectName] or 0
        local StackName = (StackAmount > 0) and (effect.StackName or "Stacks") or nil

        local StackWidth, StackHeight, StackNumberWidth, StackNumberHeight = nil, nil, nil, nil
        if StackName then
            StackWidth, StackHeight = surface.GetTextSize(StackName)
            StackNumberWidth, StackNumberHeight = surface.GetTextSize(tostring(StackAmount))
        end
    
        if not CachedMaterials[effect] then
            CachedMaterials[effect] = Material(effect.Icon)
        end

        local icon = CachedMaterials[effect]
    
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
    
        if not CachedMaterials[effect] then
            CachedMaterials[effect] = Material(effect.Icon)
        end

        local icon = CachedMaterials[effect]
    
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

    local function DrawCircularStatusEffectTimer(x, y, effectName, effectDesc, duration, startTime)
        local effect = StatusEffects[effectName]
        if not effect then return end

        local mouseX = gui.MouseX()
        local mouseY = gui.MouseY()
        ScaleUI = GetConVar("SEF_ScaleUI"):GetFloat()

        local centerX = x * ScaleUI
        local centerY = y * ScaleUI
        local radius = 22 * ScaleUI
        local RadiusThickness = 5 * ScaleUI
        local InnerRadiusThickness = 2 * ScaleUI

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

        local StackAmount = PlayerEffectStacks[effectName] or 0
        local StackName = (StackAmount > 0) and (effect.StackName or "Stacks") or nil

        local StackWidth, StackHeight, StackNumberWidth, StackNumberHeight = nil, nil, nil, nil
        if StackName then
            StackWidth, StackHeight = surface.GetTextSize(StackName)
            StackNumberWidth, StackNumberHeight = surface.GetTextSize(tostring(StackAmount))
        end

        if not CachedMaterials[effect] then
            CachedMaterials[effect] = Material(effect.Icon)
        end

        local icon = CachedMaterials[effect]

        if effect.Type == "BUFF" then
            surface.SetDrawColor(30, 255, 0, 255)
            TextColor, BarColor = Color(30, 255, 0, 255), Color(30, 125, 0)
        else
            surface.SetDrawColor(255, 0, 0, 255)
            TextColor, BarColor = Color(255, 0, 0, 255), Color(80, 0, 0)
        end

        local function DrawCircularRing(centerX, centerY, radius, thickness, angleStart, angleEnd, color)
            surface.SetDrawColor(color)

            for i = angleStart, angleEnd do
                local rad = math.rad(i)
                local nextRad = math.rad(i + 1)

                for t = 0, thickness do
                    local r = radius - t
                    surface.DrawLine(
                        centerX + math.cos(rad) * r,
                        centerY + math.sin(rad) * r,
                        centerX + math.cos(nextRad) * r,
                        centerY + math.sin(nextRad) * r
                    )
                end
            end
        end

        DrawCircularRing(centerX, centerY, radius, InnerRadiusThickness, 0, 360, BarColor)

        -- Dynamiczny pierścień czasu (kolorowy)
        local currentTime = CurTime()
        local progress = math.Clamp((currentTime - startTime) / duration, 0, 1)
        local angleStart = -90
        local angleEnd = angleStart + 360 * (1 - progress)

        DrawCircularRing(centerX, centerY, radius + 2, RadiusThickness, angleStart, angleEnd, TextColor)

        -- Ikona
        surface.SetMaterial(icon)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRectRotated(centerX, centerY, 32 * ScaleUI, 32 * ScaleUI, 0)

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
    