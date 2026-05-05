SEFHUDStyles = SEFHUDStyles or {}
SEFHUDHelpers = SEFHUDHelpers or {}

local CachedMaterials = {
    Circle = Material("SEF_Icons/StatusEffectCircle.png"),
    Square = Material("SEF_Icons/PassiveSquare.png")
}

if CLIENT then
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
end

SEFHUDStyles.Default = {
    DrawFunction = function(effectName, effectData, x, y)
        
        local barcolor
        //Simple backward compatibility, if Type is defined use it, otherwise check for Color or default to white.
        if StatusEffects[effectName].Type then
            if StatusEffects[effectName].Type == "BUFF" then
                barcolor = Color(0, 255, 0)
            elseif StatusEffects[effectName].Type == "DEBUFF" then
                barcolor = Color(255, 0, 0)
            end
        else
            if StatusEffects[effectName].Color then
                barcolor = StatusEffects[effectName].Color
            else
                barcolor = Color(255, 255, 255)
            end
        end

        surface.SetMaterial(CachedMaterials.Circle)
        surface.SetDrawColor(0, 0, 0)
        surface.DrawTexturedRectRotated(x, y, SEFHUDHelpers.Scale(50), SEFHUDHelpers.Scale(50), 0)
        local timer = SEFHUDHelpers.GetRemaining(effectData.Duration, effectData.StartTime)
        local progress = SEFHUDHelpers.GetProgress(effectData.StartTime, effectData.Duration)
        draw.SimpleText(timer, "SEFFontSmall", x, y + SEFHUDHelpers.Scale(30), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        SEFHUDHelpers.DrawRingProgress(x, y, SEFHUDHelpers.Scale(20), SEFHUDHelpers.Scale(3), progress, barcolor)

        surface.SetMaterial(SEFHUDHelpers.GetIcon(effectName))
        surface.SetDrawColor(barcolor.r, barcolor.g, barcolor.b, 255)
        surface.DrawTexturedRectRotated(x, y, SEFHUDHelpers.Scale(30), SEFHUDHelpers.Scale(30), 0)
    end,
    DrawTooltipFunction = function(Name, Data, x, y)
        local clamX, clamY = SEFHUDHelpers.ClampToScreen(x, y, 150)
        x, y = clamX, clamY
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(x - 75, y, 150, 50)
        surface.DrawOutlinedRect(x - 75, y, 150, 50, 3)
        draw.SimpleText(SEFHUDHelpers.SplitCamelCase(Name), "SEFFont", x, y, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        local description = Data.Desc
        draw.SimpleText(description, "SEFFontSmall", x, y + SEFHUDHelpers.Scale(25), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end,
    DrawOverlayFunction = function(ent, effectName, effectData)
        local progress = SEFHUDHelpers.GetProgress(effectData.StartTime, effectData.Duration)
        SEFHUDHelpers.DrawCircleProgress(0, 0, 8, progress, Color(255, 255, 255))

        surface.SetMaterial(CachedMaterials.Circle)
        surface.SetDrawColor(0, 0, 0)
        surface.DrawTexturedRectRotated(0, 0, 20, 20, 0)

        surface.SetMaterial(SEFHUDHelpers.GetIcon(effectName))
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRectRotated(0, 0, 10, 10, 0)
    end,
    DrawPassiveFunction = function(passiveName, passiveData, x, y)
    end,
    StyleSpacingX = 50,
    StyleSpacingY = 0,
    OverlaySpacingX = 9,
    OverlaySpacingY = 0,
    TooltipMouseBounds = { x = 45, y = 45 }
}





//Useful functions for drawing all kinds of UI.

-- SCALE
function SEFHUDHelpers.Scale(val)
    return val * GetConVar("SEF_ScaleUI"):GetFloat()
end

-- CLAMP TO SCREEN
function SEFHUDHelpers.ClampToScreen(x, y, radius)
    local sx, sy = ScrW(), ScrH()

    if x - radius < 0 then x = radius end
    if y - radius < 0 then y = radius end
    if x + radius > sx then x = sx - radius end
    if y + radius > sy then y = sy - radius end

    return x, y
end

-- PROGRESS 0-1
function SEFHUDHelpers.GetProgress(startTime, duration)
    local elapsed = CurTime() - startTime
    return math.Clamp(elapsed / duration, 0, 1)
end

function SEFHUDHelpers.GetIcon(effect)
    local EffectTable = StatusEffects[effect]
    local iconPath = EffectTable and EffectTable.Icon or "SEF_Icons/Default.png"
    local EffectIcon = Material(iconPath)
    return EffectIcon
end

-- REMAINING TIME
function SEFHUDHelpers.GetRemaining(duration, startTime)
    local remaining = duration - (CurTime() - startTime)

    if remaining == math.huge then
        return "∞"
    end

    if remaining > 10 then
        return math.Round(remaining)
    end

    return string.format("%.1f", remaining)
end

-- STACKS
function SEFHUDHelpers.GetStacks(name, isPassive)
    if isPassive then
        return PlayerPassiveStacks[name] or 0
    end

    return PlayerEffectStacks[name] or 0
end

-- HOVER CHECK
function SEFHUDHelpers.IsHover(x, y, w, h)
    local mx, my = gui.MouseX(), gui.MouseY()

    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

-- CAMEL CASE SPLIT
function SEFHUDHelpers.SplitCamelCase(str)
    return str:gsub("(%l)(%u)", "%1 %2")
end

-- RING PROGRESS
function SEFHUDHelpers.DrawRingProgress(x, y, radius, thickness, progress, color)
    local startAngle = -90
    local endAngle = startAngle + (360 * (1 - progress))

    surface.SetDrawColor(color)

    for i = startAngle, endAngle do
        local rad = math.rad(i)
        local nextRad = math.rad(i + 1)

        for t = 0, thickness do
            local r = radius - t

            surface.DrawLine(
                x + math.cos(rad) * r,
                y + math.sin(rad) * r,
                x + math.cos(nextRad) * r,
                y + math.sin(nextRad) * r
            )
        end
    end
end

-- Circle Progress
function SEFHUDHelpers.DrawCircleProgress(cx, cy, radius, progress, color)
    local startAngle = -90
    local endAngle = startAngle + (360 * (1 - progress))

    local verts = {}
    verts[1] = { x = cx, y = cy }

    for i = startAngle, endAngle do
        local rad = math.rad(i)
        verts[#verts + 1] = {
            x = cx + math.cos(rad) * radius,
            y = cy + math.sin(rad) * radius
        }
    end

    draw.NoTexture()
    surface.SetDrawColor(color)
    surface.DrawPoly(verts)
end