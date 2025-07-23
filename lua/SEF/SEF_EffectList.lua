StatusEffects = {
    Healing = {
        Icon = "SEF_Icons/health-normal.png",
        Type = "BUFF",
        Desc = function(healamount, delay)
            if delay == nil then
                return string.format("You are regenerating %d HP each 0.3 sec.", healamount)
            else
                return string.format("You are regenerating %d HP each %g sec.", healamount, delay)
            end
        end,
        EffectBegin = function(ent)
            if not ent.HealingEffectSound then
                EmitSound("Healing.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.HealingEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.HealingEffectSound = nil
        end,
        Effect = function(ent, time, healamount, delay)
            local TimeLeft = ent:GetTimeLeft("Healing")
            local HealDelay = delay

            if HealDelay == nil then HealDelay = 0.3 end

            if TimeLeft > 0.1 then
                if not ent.HealingEffectDelay then
                    ent.HealingEffectDelay  = CurTime()
                end
                if CurTime() >= ent.HealingEffectDelay then
                    ent:SetHealth(math.min(ent:Health() + healamount, ent:GetMaxHealth()))
                    ent.HealingEffectDelay = CurTime() + HealDelay
                end
            end
        end,
        DisplayFunction = function(ent)
            if ent:IsValid() then
                local emitter = ParticleEmitter(ent:GetPos())

                if not ent.HealParticleTime then
                    ent.HealParticleTime = CurTime()
                end

                if emitter then
                    local angle = math.Rand(0, 360)
                    local distance = math.Rand(0, 25)
                    local offset = Vector(math.cos(math.rad(angle)) * distance, math.sin(math.rad(angle)) * distance, 10)
                    local particlePos = ent:GetPos() + offset
                    local particle = emitter:Add(Material("SEF_Icons/health-normal.png"), particlePos)
                    if particle and CurTime() >= ent.HealParticleTime + 0.3 then
                        particle:SetVelocity(Vector(0, 0, 50))
                        particle:SetLifeTime(0)
                        particle:SetDieTime(2)
                        particle:SetStartAlpha(255)
                        particle:SetEndAlpha(0)
                        particle:SetStartSize(5)
                        particle:SetEndSize(0)
                        particle:SetColor(255, 255, 255)
                        ent.HealParticleTime = CurTime()
                    end
        
                    emitter:Finish()
                end
            end
        end                       
    },
    HealthBoost = {
        Icon = "SEF_Icons/health-increase.png",
        Type = "BUFF",
        Desc = function(added)
            return string.format("Your max health has been increased by %d HP!", added)
        end,
        EffectBegin = function(ent, healthadd)
            local currentHealthAdd = ent.HealthBoostLastAdded or 0
            if currentHealthAdd > 0 then
                BaseStatRemove(ent, "MaxHealth", currentHealthAdd)
            end
            BaseStatAdd(ent, "MaxHealth", healthadd)
            ent.HealthBoostLastAdded = healthadd

            if not ent.HealthBoostEffectSound then
                EmitSound("Energized.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.HealthBoostEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            if ent.HealthBoostLastAdded then
                BaseStatRemove(ent, "MaxHealth", ent.HealthBoostLastAdded)
                ent.HealthBoostLastAdded = nil
                ent.HealthBoostEffectSound = nil
            end
        end,
        EffectOnRemove = function(ent)
            if ent.HealthBoostLastAdded then
                BaseStatRemove(ent, "MaxHealth", ent.HealthBoostLastAdded)
                ent.HealthBoostLastAdded = nil
                ent.HealthBoostEffectSound = nil
            end
        end,
        HookType = "",
        HookFunction = function() end
    },
    Energized = {
        Icon = "SEF_Icons/healing-shield.png",
        Type = "BUFF",
        Desc = function(healamount, delay, maxamount)
            if maxamount != nil and delay == nil then
                return string.format("You are regenerating %d shield each 0.3 sec.\n [Max Armor: %d]", healamount, maxamount)
            elseif maxamount != nil and delay != nil then
                return string.format("You are regenerating %d shield each %g sec.\n [Max Armor: %d]", healamount, delay, maxamount)
            elseif delay != nil and maxamount == nil then
                return string.format("You are regenerating %d shield each %g sec up to your max shield amount.", healamount, delay)
            end
        end,
        EffectBegin = function(ent)
            if not ent.EnergizedEffectSound then
                EmitSound("Energized.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.EnergizedEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.EnergizedEffectSound = nil
        end,
        Effect = function(ent, time, healamount, delay, maxamount)
            local TimeLeft = ent:GetTimeLeft("Energized")
            if maxamount == nil then maxamount = ent:GetMaxArmor() end
            local HealDelay = delay
            if HealDelay == nil then HealDelay = 0.3 end

            if TimeLeft > 0.1  then
                if not ent.ShieldingEffectDelay then
                    ent.ShieldingEffectDelay = CurTime()
                end
                if CurTime() >= ent.ShieldingEffectDelay  then
                    ent:SetArmor(math.min(ent:Armor() + healamount, maxamount))
                    ent.ShieldingEffectDelay = CurTime() + HealDelay
                end
            end
        end,
        DisplayFunction = function(ent)
            if ent:IsValid() then
                local emitter = ParticleEmitter(ent:GetPos())

                if not ent.ArmorParticleTime then
                    ent.ArmorParticleTime = CurTime()
                end

                if emitter then
                    -- Losowanie kąta i odległości do umieszczenia cząsteczki wokół encji
                    local angle = math.Rand(0, 360)
                    local distance = math.Rand(0, 25)
                    local offset = Vector(math.cos(math.rad(angle)) * distance, math.sin(math.rad(angle)) * distance, 10)
                    local particlePos = ent:GetPos() + offset
                    local particle = emitter:Add(Material("SEF_Icons/healing-shield.png"), particlePos)
                    if particle and CurTime() >= ent.ArmorParticleTime + 0.3 then
                        particle:SetVelocity(Vector(0, 0, 50))  -- Ustawienie prędkości w górę
                        particle:SetLifeTime(0)
                        particle:SetDieTime(2)
                        particle:SetStartAlpha(255)
                        particle:SetEndAlpha(0)
                        particle:SetStartSize(5)
                        particle:SetEndSize(0)
                        particle:SetColor(255, 255, 255)
                        ent.ArmorParticleTime = CurTime()
                    end
        
                    emitter:Finish()
                end
            end
        end
    },
    Broken = {
        Icon = "SEF_Icons/broken.png",
        Type = "DEBUFF",
        Desc = function(maxhealth)
            return string.format("Your health is capped at %d HP.", maxhealth)
        end,
        EffectBegin = function(ent)
            if not ent.BrokenEffectSound then
                EmitSound("broken.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.BrokenEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.BrokenEffectSound = nil
        end,
        Effect = function(ent, time, maxhealth)
            local TimeLeft = ent:GetTimeLeft("Broken")
            if TimeLeft > 0.1  then
                ent.BrokenEffectMaxHealth = maxhealth

                if ent:Health() >= ent.BrokenEffectMaxHealth then
                    ent:SetHealth(ent.BrokenEffectMaxHealth)
                end

                if ent:HaveEffect("Healing") then
                    ent:RemoveEffect("Healing")
                elseif ent:HaveEffect("HealthBoost") then
                    ent:SoftRemoveEffect("HealthBoost")
                end

            end
        end,
        HookType = "",
        HookFunction = function() end
    },
    Exposed = {
        Icon = "SEF_Icons/exposed.png",
        Type = "DEBUFF",
        Desc = "Received damage is doubled.",
        EffectBegin = function(ent)
            if not ent.ExposedEffectSound then
                ent:EmitSound("exposed.mp3", 100, 100, 0.3)
                ent.ExposedEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.ExposedEffectSound = nil
        end,
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(target, dmginfo)
                    if target and target:HaveEffect("Exposed") then
                        dmginfo:ScaleDamage(2)
                        target:EmitSound("npc/zombie/zombie_hit.wav", 110, 100, 0.2)
                    end
                end
            }
        }
    },
    Endurance = {
        Icon = "SEF_Icons/endurance.png",
        Type = "BUFF",
        Desc = function(percent)
            if percent == nil then percent = 50 end
            return string.format("Received damage is reduced by %d%%", percent)
        end,
        EffectBegin = function(ent, percent)
            if not ent.EnduranceEffectSound then
                EmitSound("Endurance.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.EnduranceEffectSound = true
            end

            if percent ~= nil then
                ent.EndurancePercent = 1 - (percent / 100)
            else
                ent.EndurancePercent = 0.5
            end
        end,
        EffectEnd = function(ent)
            ent.EnduranceEffectSound = nil
        end,
        Effect = function(ent, time)
        end,
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(target, dmginfo)
                    if target and target:HaveEffect("Endurance") then
                        dmginfo:ScaleDamage(target.EndurancePercent)
                        target:EmitSound("phx/epicmetal_hard.wav", 110, math.random(75, 125), 1)
                    end
                end
            }
        }
    },
    Haste = {
        Icon = "SEF_Icons/haste.png",
        Type = "BUFF",
        Desc = function(amount)
            return string.format("Your movement speed is increased by %d units.", amount)
        end,
        EffectBegin = function(ent, speedAdd)
            if ent:IsPlayer() or ent.IsLambdaPlayer then
                if ent.HasteEffectLastAdded then
                    BaseStatRemove(ent, "WalkSpeed", ent.HasteEffectLastAdded)
                    BaseStatRemove(ent, "RunSpeed", ent.HasteEffectLastAdded)
                end

                BaseStatAdd(ent, "WalkSpeed", speedAdd)
                BaseStatAdd(ent, "RunSpeed", speedAdd)
                ent.HasteEffectLastAdded = speedAdd

                if not ent.HasteEffectSound then
                    EmitSound("Haste.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                    ent.HasteEffectSound = true
                end
            end
        end,
        EffectEnd = function(ent)
            if ent:IsPlayer() or ent.IsLambdaPlayer then
                if ent.HasteEffectLastAdded then
                    BaseStatRemove(ent, "WalkSpeed", ent.HasteEffectLastAdded)
                    BaseStatRemove(ent, "RunSpeed", ent.HasteEffectLastAdded)
                    ent.HasteEffectLastAdded = nil
                    ent.HasteEffectSound = nil
                end
            end
        end,
        EffectOnRemove = function(ent)
            if ent:IsPlayer() or ent.IsLambdaPlayer then
                if ent.HasteEffectLastAdded then
                    BaseStatRemove(ent, "WalkSpeed", ent.HasteEffectLastAdded)
                    BaseStatRemove(ent, "RunSpeed", ent.HasteEffectLastAdded)
                    ent.HasteEffectLastAdded = nil
                    ent.HasteEffectSound = nil
                end
            end
        end,
        DisplayFunction = function(ent)
            if ent:IsValid() then
                -- Inicjalizacja czasu i liczby cząsteczek, jeśli nie istnieją
                if not ent.HasteParticleTime then
                    ent.HasteParticleTime = CurTime()
                end
                if not ent.HasteParticleCount then
                    ent.HasteParticleCount = 0
                end

        
                -- Sprawdzanie, czy liczba cząsteczek nie przekroczyła limitu
                if ent.HasteParticleCount < 10 then
                    local emitter = ParticleEmitter(ent:GetPos())
        
                    if emitter then
                        -- Sprawdzanie, czy minął czas od ostatniej emisji
                        if CurTime() >= ent.HasteParticleTime + 0.01 then
                            local angle = math.Rand(0, 360)
                            local distance = math.Rand(0, 15)
                            local offset = Vector(math.cos(math.rad(angle)) * distance, math.sin(math.rad(angle)) * distance, 10)
                            local particlePos = ent:GetPos() + offset
                            local particle = emitter:Add(Material("SEF_Icons/arrow_up.png"), particlePos)
                            
                            if particle then
                                particle:SetVelocity(Vector(0, 0, 50))  -- Ustawienie prędkości w górę
                                particle:SetLifeTime(0)
                                particle:SetDieTime(3)
                                particle:SetStartAlpha(255)
                                particle:SetEndAlpha(0)
                                particle:SetStartSize(5)
                                particle:SetEndSize(0)
                                particle:SetColor(0, 255, 0)
        
                                -- Aktualizacja czasu i licznika cząsteczek
                                ent.HasteParticleTime = CurTime()
                                ent.HasteParticleCount = ent.HasteParticleCount + 1
                            end
        
                            emitter:Finish()
                        end
                    end
                end
        
                -- Usuwanie licznika cząsteczek, jeśli czas efektu "Haste" minął
                local timeLeft = ent:GetEntTimeLeft("Haste")
                if timeLeft < 0.1 then
                    if ent.HasteParticleCount then
                        ent.HasteParticleCount = nil
                    end
                    if ent.HasteParticleTime then
                        ent.HasteParticleTime = nil
                    end
                end
            end
        end             
    },
    Exhaust = {
        Icon = "SEF_Icons/exhaust.png",
        Type = "DEBUFF",
        Desc = "You are tired. \nYour speed can't be increased.",
        EffectBegin = function(ent)
            if not ent.ExhaustEffectSound then
                EmitSound("Exhaust.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.ExhaustEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.ExhaustEffectSound = nil
        end,
        Effect = function(ent, time)
            local TimeLeft = ent:GetTimeLeft("Exhaust")
    
            if TimeLeft > 0.1 then
                if ent:HaveEffect("Haste") then
                    ent:SoftRemoveEffect("Haste")
                end
                
                if ent:IsPlayer() or ent.IsLambdaPlayer then
                    if ent:GetWalkSpeed() > EntBaseStats[ent].WalkSpeed then
                        local excessWalkSpeed = ent:GetWalkSpeed() - EntBaseStats[ent].WalkSpeed
                        BaseStatRemove(ent, "WalkSpeed", excessWalkSpeed)
                    end
                    if ent:GetRunSpeed() > EntBaseStats[ent].RunSpeed then
                        local excessRunSpeed = ent:GetRunSpeed() - EntBaseStats[ent].RunSpeed
                        BaseStatRemove(ent, "RunSpeed", excessRunSpeed)
                    end
                elseif ent:IsNextBot() and not ent.IsLambdaPlayer then
                    if ent:GetDesiredSpeed() > EntBaseStats[ent].RunSpeed then
                        local excessSpeed = ent:GetDesiredSpeed() - EntBaseStats[ent].RunSpeed
                        BaseStatRemove(ent, "RunSpeed", excessSpeed)
                    end
                end
            end
        end
    },    
    Hindered = {
        Icon = "SEF_Icons/hindered.png",
        Type = "DEBUFF",
        Desc = function(amount)
            return string.format("Your movement speed is decreased by %d units!", amount)
        end,
        EffectBegin = function(ent, speedDecrease)
            if ent:IsPlayer() or ent.IsLambdaPlayer then
                -- Zmiana prędkości gracza
                if ent.HinderedEffectLastAdded then
                    BaseStatAdd(ent, "WalkSpeed", ent.HinderedEffectLastAdded)
                    BaseStatAdd(ent, "RunSpeed", ent.HinderedEffectLastAdded)
                end
    
                BaseStatRemove(ent, "WalkSpeed", speedDecrease)
                BaseStatRemove(ent, "RunSpeed", speedDecrease)
    
                ent.HinderedEffectLastAdded = speedDecrease
            end

            if not ent.HinderedEffectSound then
                EmitSound("Exhaust.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.HinderedEffectSound = true
            end
        end,
        Effect = function(ent, time, speedDecrease)
            if ent:IsNPC() and not ent:IsNextBot() then
                if not ent.PreviousMovement then
                    ent.PreviousMovement = ent:GetMovementActivity()
                end
                ent:SetMovementActivity(ACT_WALK)
            end
        end, 
        EffectEnd = function(ent, speedDecrease)
            if ent:IsPlayer() then
                if ent.HinderedEffectLastAdded then
                    BaseStatAdd(ent, "WalkSpeed", ent.HinderedEffectLastAdded)
                    BaseStatAdd(ent, "RunSpeed", ent.HinderedEffectLastAdded)
                    ent.HinderedEffectLastAdded = nil
                end
            elseif ent:IsNPC() and not ent:IsNextBot() and ent:Health() > 0 then
                ent:SetMovementActivity(ent.PreviousMovement)
                ent.PreviousMovement = nil
            end

            ent.HinderedEffectSound = nil
            ent.HinderedParticleTime = nil
            ent.HinderedParticleCount = nil
        end,
        EffectOnRemove = function(ent)
            if ent:IsPlayer() then
                if ent.HinderedEffectLastAdded then
                    BaseStatAdd(ent, "WalkSpeed", ent.HinderedEffectLastAdded)
                    BaseStatAdd(ent, "RunSpeed", ent.HinderedEffectLastAdded)
                    ent.HinderedEffectLastAdded = nil
                end
            elseif ent:IsNPC() and not ent:IsNextBot() and ent:Health() > 0 then
                ent:SetMovementActivity(ent.PreviousMovement)
                ent.PreviousMovement = nil
            end

            ent.HinderedEffectSound = nil
            ent.HinderedParticleTime = nil
            ent.HinderedParticleCount = nil
        end,
        DisplayFunction = function(ent)
            if ent:IsValid() then
                -- Inicjalizacja czasu i liczby cząsteczek, jeśli nie istnieją
                if not ent.HinderedParticleTime then
                    ent.HinderedParticleTime = CurTime()
                end
                if not ent.HinderedParticleCount then
                    ent.HinderedParticleCount = 0
                end

        
                -- Sprawdzanie, czy liczba cząsteczek nie przekroczyła limitu
                if ent.HinderedParticleCount < 10 then
                    local emitter = ParticleEmitter(ent:GetPos())
        
                    if emitter then
                        -- Sprawdzanie, czy minął czas od ostatniej emisji
                        if CurTime() >= ent.HinderedParticleTime + 0.01 then
                            local angle = math.Rand(0, 360)
                            local distance = math.Rand(0, 15)
                            local offset = Vector(math.cos(math.rad(angle)) * distance, math.sin(math.rad(angle)) * distance, 100)
                            local particlePos = ent:GetPos() + offset
                            local particle = emitter:Add(Material("SEF_Icons/arrow_down.png"), particlePos)
                            
                            if particle then
                                particle:SetVelocity(Vector(0, 0, -50))  -- Ustawienie prędkości w górę
                                particle:SetLifeTime(0)
                                particle:SetDieTime(3)
                                particle:SetStartAlpha(255)
                                particle:SetEndAlpha(0)
                                particle:SetStartSize(5)
                                particle:SetEndSize(0)
                                particle:SetColor(255, 0, 0)
        
                                -- Aktualizacja czasu i licznika cząsteczek
                                ent.HinderedParticleTime = CurTime()
                                ent.HinderedParticleCount = ent.HinderedParticleCount + 1
                            end
        
                            emitter:Finish()
                        end
                    end
                end
        
                -- Usuwanie licznika cząsteczek, jeśli czas efektu "Haste" minął
                local timeLeft = ent:GetEntTimeLeft("Hindered")
                if timeLeft < 0.1 then
                    if ent.HinderedParticleCount then
                        ent.HinderedParticleCount = nil
                    end
                    if ent.HinderedParticleTime then
                        ent.HinderedParticleTime = nil
                    end
                end
            end
        end             
    },    
    Bleeding = {
        Icon = "SEF_Icons/bleed.png",
        Type = "DEBUFF",
        Desc = function(damageamount)
            return string.format("You are bleeding.\n You are losing %d HP each 0.3 sec.", damageamount)
        end,
        EffectBegin = function(ent)
            if not ent.BleedingEffectSound then
                EmitSound("Bleeding.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.BleedingEffectSound = true
            end
        end,
        Effect = function(ent, time, damageamount, delay, inf)
            local TimeLeft = ent:GetTimeLeft("Bleeding")
            if TimeLeft > 0.1 then

                if not ent.BleedingEffectDelay then
                    ent.BleedingEffectDelay  = CurTime()
                end

                local BleedDelay = delay
                if BleedDelay == nil then BleedDelay = 0.3 end

                if CurTime() >= ent.BleedingEffectDelay  then
                    if IsValid(inf) then
                        local dmg = DamageInfo()
                        dmg:SetDamage(damageamount)
                        dmg:SetInflictor(inf)
                        dmg:SetAttacker(inf)
                        dmg:SetDamageType(DMG_SLASH)
                        ent:TakeDamageInfo(dmg)
                    else
                        ent:TakeDamage(damageamount)
                    end

                    
                    local DmgSound = {
                        "weapons/crossbow/hitbod1.wav",
                        "weapons/crossbow/hitbod2.wav"
                    }

                    local randomSound = DmgSound[math.random(#DmgSound)]

                    -- Efekt krwi
                    local effectData = EffectData()
                    effectData:SetOrigin(ent:WorldSpaceCenter() + Vector(0, 0, 10)) -- Pozycja, z której będzie tryskać krew
                    effectData:SetMagnitude(5) -- Ilość cząsteczek
                    effectData:SetScale(1) -- Skala efektu
                    effectData:SetColor(0) -- Kolor krwi (0 - czerwony, 1 - żółty)
                    util.Effect("BloodImpact", effectData, true, true)

                    ent:EmitSound(randomSound, 100, math.random(90, 140), 1, CHAN_AUTO)
                    
                    ent.BleedingEffectDelay = CurTime() + BleedDelay
                end
            end
        end,
        EffectEnd = function(ent)
            ent.BleedingEffectDelay = nil
            ent.BleedingEffectSound = nil
        end
    },
    Incapacitated = {
        Icon = "SEF_Icons/incap.png",
        Type = "DEBUFF",
        Desc = "You are unable to use any weapons or tools.",
        EffectBegin = function(ent)
            if not ent.IncapacitatedEffectSound then
                EmitSound("Incapacitated.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.IncapacitatedEffectSound = true
            end
        end,
        Effect = function(ent, time)
            local TimeLeft = ent:GetTimeLeft("Incapacitated")
            if TimeLeft > 0.5 then
                if ent:IsPlayer() then
                    if not ent.IncapEffectWeapon then
                        ent.IncapEffectWeapon = ent:GetActiveWeapon():GetClass()
                    end
                    ent:SetActiveWeapon(NULL)
                elseif ent.IsLambdaPlayer then

                    if not ent.IncapEffectWeapon then
                        ent.IncapEffectWeapon = ent.l_Weapon
                    end

                    ent:RetreatFrom()    
                    ent:SwitchWeapon("none")
                elseif ent:IsNPC() then
                    if not ent.IncapEffectWeapon and IsValid(ent:GetActiveWeapon()) then
                        ent.IncapEffectWeapon = ent:GetActiveWeapon():GetClass()
                    end

                    if IsValid(ent:GetActiveWeapon()) then
                        ent:GetActiveWeapon():Remove()
                    end
                end
            elseif TimeLeft <= 0.1 then
                if ent:IsPlayer() then
                    if ent.IncapEffectWeapon ~= nil then
                        ent:SelectWeapon(ent.IncapEffectWeapon)
                    end
                    ent.IncapEffectWeapon = nil
                elseif ent.IsLambdaPlayer then
                    if ent.IncapEffectWeapon ~= nil then
                        ent:SwitchWeapon(ent.IncapEffectWeapon)
                    end
                    ent.IncapEffectWeapon = nil
                elseif ent:IsNPC() then
                    if ent.IncapEffectWeapon ~= nil then
                        ent:Give(ent.IncapEffectWeapon)
                    end
                    ent.IncapEffectWeapon = nil
                end
            end
        end,
        EffectEnd = function(ent)
            ent.IncapacitatedEffectSound = nil
        end
    },
    Tenacity = {
        Icon = "SEF_Icons/tenacity.png",
        Desc = function(percent)
            if percent == nil then percent = 50 end
            return string.format("Debuffs are %d%% shorter.", percent)
        end,
        Type = "BUFF",
        EffectBegin = function(ent)
            if not ent.TenacityEffectSound then
                EmitSound("Tenacity.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.TenacityEffectSound = true
            end
        end,
        Effect = function(ent, time, percent)
            if percent == nil then percent = 50 end
            for effectName, effectData in pairs(EntActiveEffects[ent]) do
                if StatusEffects[effectName].Type == "DEBUFF" and not effectData.TenacityAffected then
                    local NewDuration = EntActiveEffects[ent][effectName].Duration * (1 - (percent / 100))
                    ent:ChangeDuration(effectName, NewDuration)
                    effectData.TenacityAffected = true
                end
            end
        end,
        EffectEnd = function(ent)
            ent.TenacityEffectSound = nil
        end
    },
    Bloodlust = {
        Icon = "SEF_Icons/bloodlust.png",
        Type = "BUFF",
        Desc = function(dmgincr, lifesteal)
            if lifesteal ~= nil then
                return string.format("You are hungry for blood! \nDamage you deal is increased by %d%%\n %d%% of dealt damage is received as healing.", dmgincr, lifesteal)
            else
                return string.format("You are hungry for blood! \nDamage you deal is increased by %d%%", dmgincr)
            end
        end,
        EffectBegin = function(ent)
            if not ent.BloodlustEffectSound then
                EmitSound("Bloodlust.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.BloodlustEffectSound = true
            end
        end,
        Effect = function(ent, time, dmgincr, lifesteal)
            if ent:GetTimeLeft("Bloodlust") > 0.1 then
                if lifesteal ~= nil and lifesteal ~= 0 then
                    ent.BloodLustDMGIncrease = dmgincr
                    ent.BloodLustLifeSteal = lifesteal
                else
                    ent.BloodLustDMGIncrease = dmgincr
                end
            end
        end,
        EffectEnd = function(ent)
            ent.BloodlustEffectSound = nil
        end,
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(target, dmginfo)
                    local attacker = dmginfo:GetAttacker()
                    if target and target ~= attacker and (target:IsNPC() or target:IsPlayer() or target:IsNextBot()) and attacker:HaveEffect("Bloodlust") then
                        dmginfo:ScaleDamage(1 + (attacker.BloodLustDMGIncrease / 100))
                        target:EmitSound("npc/manhack/grind_flesh1.wav", 110, 100, 1)
                        if attacker.BloodLustLifeSteal ~= nil then
                            attacker:SetHealth(math.min(attacker:Health() + (dmginfo:GetDamage() * (attacker.BloodLustLifeSteal / 100)), attacker:GetMaxHealth()))
                            attacker:EmitSound("npc/headcrab_fast/headbite.wav", 110, 100, 1)
                        end
                    end
                end
            }
        }

    },
    Stunned = { 
        Icon = "SEF_Icons/stunned.png",
        Desc = "You are unable to move or do any action.", 
        Type = "DEBUFF",
        EffectBegin = function(ent)
            if ent:IsPlayer() then
                ent:DoAnimationEvent(ACT_HL2MP_IDLE_COWER)
            elseif ent.IsLambdaPlayer then
                ent:DoAnimationEvent(ACT_HL2MP_IDLE_COWER)
                ent.l_isfrozen = true
            end

            if not ent.StunnedEffectSound then
                EmitSound("Stunned.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.StunnedEffectSound = true
            end

        end,
        Effect = function(ent)
            if ent:IsPlayer() then
                ent:SetActiveWeapon(NULL)
            elseif ent.IsLambdaPlayer then
                ent.l_Weapon = "none"
            end
        end,
        EffectEnd = function(ent)
            if ent:IsPlayer() then
                ent:DoAnimationEvent(ACT_HL2MP_RUN)
            elseif ent.IsLambdaPlayer then
                ent:DoAnimationEvent(ACT_HL2MP_RUN)
            end

            ent.StunnedEffectSound = nil
        end,
        ClientHooks = {
            {
                HookType = "CalcView",
                HookFunction = function(ply, pos, angles, fov)
                    if IsValid(ply) and ply:HaveEffect("Stunned") then
                        local view = {
                            origin = pos - (angles:Forward() * 100) + Vector(0, 0, 10),
                            angles = angles,
                            fov = fov,
                            drawviewer = true
                        }
                        return view
                    end
                end,
            },
            {
                HookType = "CreateMove",
                HookFunction = function(cmd)
                    local ply = LocalPlayer()
                    if ply:HaveEffect("Stunned") then
                        local angles = cmd:GetViewAngles()
                        cmd:SetViewAngles(angles)
                        cmd:SetForwardMove(0)
                        cmd:SetSideMove(0)
                        cmd:SetUpMove(0)
                        cmd:SetViewAngles(angles)
                    end
                end,
            },
        },
    },
    Wither = {
        Name = "Withering",
        Icon = "SEF_Icons/wither.png",
        Type = "DEBUFF",
        Desc = function(witheramount, delay)
            return string.format("You are losing %d HP each %g sec.", witheramount, delay)
        end,
        EffectBegin = function(ent)
            if not ent.WitherEffectSound then
                EmitSound("Withered.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.WitherEffectSound = true
            end
        end,
        Effect = function(ent, time, witheramount, delay)
            local TimeLeft = ent:GetTimeLeft("Wither")
            if TimeLeft > 0.1 then
    
                if not ent.WitheringEffectDelay then
                    ent.WitheringEffectDelay = CurTime()
                end
    
                if CurTime() >= ent.WitheringEffectDelay  then
                    ent:SetHealth(math.min(ent:Health() - witheramount, ent:GetMaxHealth()))
                    ent.WitheringEffectDelay = CurTime() + delay
                end
    
                if ent:IsPlayer() and ent:Health() <= 0 and ent:Alive()then
                    ent:Kill()
                elseif not ent:IsPlayer() and ent:Health() <= 0 then
                    ent:TakeDamage(1) 
                end
    
            end
        end,
        EffectEnd = function(ent)
            ent.WitherEffectSound = nil
        end
    },
    Discharge = {
        Icon = "SEF_Icons/discharge.png",
        Type = "DEBUFF",
        Desc = function(dischAmount, delay)
            return string.format("You are losing %d shield each %g sec.", dischAmount, delay)
        end,
        EffectBegin = function(ent)
            if not ent.DischargeEffectSound then
                EmitSound("Discharge.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.DischargeEffectSound = true
            end
        end,
        Effect = function(ent, time, dischAmount, delay)
            local TimeLeft = ent:GetTimeLeft("Discharge")

            if TimeLeft > 0.1 and ent.Armor then
                if isnumber(ent:Armor()) then
                    if not ent.ShieldingEffectDelay then
                        ent.ShieldingEffectDelay = CurTime()
                    end
        
                    if CurTime() >= ent.ShieldingEffectDelay then
                        if ent.Armor and ent:Armor() > 0 then
                            ent:SetArmor(math.min(ent:Armor() - dischAmount))
                            ent.ShieldingEffectDelay = CurTime() + delay
                        end
                    end
        
                    if ent:Armor() <= 0 then
                        ent:RemoveEffect("Discharge")
                    end
                end
            end
        end,
        EffectEnd = function(ent)
            ent.DischargeEffectSound = nil
        end,
        DisplayFunction = function(ent)
            local effectData = EffectData()
            effectData:SetEntity(ent)
            effectData:SetScale(0.1)
            effectData:SetMagnitude(0.1)
            util.Effect("TeslaHitboxes", effectData)
        end
    },
    Blindness = {
        Icon = "SEF_Icons/blind.png",
        Desc = "You are unable to see.", 
        Type = "DEBUFF",
        EffectBegin = function(ent)
            if not ent.BlindnessEffectSound then
                EmitSound("Blindness.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.BlindnessEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.BlindnessEffectSound = nil
        end,  
        ClientHooks = {
            {
                HookType = "HUDPaintBackground",
                HookFunction = function()
                    local ply = LocalPlayer()
                    local TimeLeft = ply:GetTimeLeft("Blindness")
    
                    if ply:HaveEffect("Blindness") then
                        local alpha = 255
                        local fadeStartTime = 0.5
    
                        if TimeLeft <= fadeStartTime then
                            alpha = math.max(0, 255 * (TimeLeft / fadeStartTime))
                        end

                        surface.SetDrawColor(0, 0, 0, alpha)
                        surface.DrawRect(0, 0, ScrW(), ScrH())
                    end
                end
            }
        },
        ServerHooks = {},
    },
    Poison = {
        Icon = "SEF_Icons/poison.png",
        Desc = function(damageamount, delay)
            if delay ~= nil and damageamount ~= nil then
                return string.format("You are losing %d HP each %g sec. \nYou can't heal.", damageamount, delay)
            elseif damageamount ~= nil then
                return string.format("You are losing %d HP each 0.3 sec. \nYou can't heal.", damageamount)
            elseif delay == nil and damageamount == nil then
                return string.format("You can't heal.")
            end
        end, 
        Type = "DEBUFF",
        EffectBegin = function(ent)
            ent.PoisonEffectHP = ent:Health()
            if not ent.PoisonEffectSound then
                EmitSound("Poison.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.PoisonEffectSound = true
            end
        end,
        Effect = function(ent, time, damageamount, delay, inf)
            local TimeLeft = ent:GetTimeLeft("Poison")
            if TimeLeft > 0.1 then

                if not ent.PoisonEffectDelay then
                    ent.PoisonEffectDelay  = CurTime()
                end

                local PoisonDelay = delay
                if PoisonDelay == nil then PoisonDelay = 0.3 end
                if damageamount == nil then damageamount = 0 end

                if ent:HaveEffect("Healing") then
                    ent:RemoveEffect("Healing")
                end

                if ent:Health() > ent.PoisonEffectHP then
                    ent:SetHealth(ent.PoisonEffectHP)
                elseif ent:Health() <= ent.PoisonEffectHP then
                    ent.PoisonEffectHP = ent:Health()
                end

                if CurTime() >= ent.PoisonEffectDelay  then
                    if IsValid(inf) then
                        local dmg = DamageInfo()
                        dmg:SetDamage(damageamount)
                        dmg:SetInflictor(inf)
                        dmg:SetAttacker(inf)
                        dmg:SetDamageType(DMG_ACID)
                        ent:TakeDamageInfo(dmg)
                    else
                        local dmg = DamageInfo()
                        dmg:SetDamage(damageamount)
                        dmg:SetInflictor(game.GetWorld())
                        dmg:SetAttacker(game.GetWorld())
                        dmg:SetDamageType(DMG_ACID)
                        ent:TakeDamageInfo(dmg)
                    end

                    if damageamount > 0 then
                        ent:EmitSound("physics/flesh/flesh_impact_bullet2.wav", 100, math.random(70, 135), 1)
                    end

                    ent.PoisonEffectDelay = CurTime() + PoisonDelay
                end
            end
        end,
        EffectEnd = function(ent)
            ent.PoisonEffectDelay = nil
            ent.PoisonEffectHP = nil
            ent.PoisonEffectSound = nil
        end,
        ClientHooks = {
            {
                HookType = "HUDPaintBackground",
                HookFunction = function()
                    local ply = LocalPlayer()
                    local TimeLeft = ply:GetTimeLeft("Poison")
                    local PoisonMat = Material("SEF_Overlay/SEFPoisonOverlay.png")
            
                    if ply:HaveEffect("Poison") then
                        local alpha = 255
                        local fadeStartTime = 0.5 -- Czas w sekundach, kiedy zaczyna zanikać
            
                        if TimeLeft <= fadeStartTime then
                            alpha = math.max(0, 255 * (TimeLeft / fadeStartTime))
                        end
            
                        surface.SetMaterial(PoisonMat)
                        surface.SetDrawColor(255, 255, 255, alpha)
                        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
                    end
                end
            }
        },        
        ServerHooks = {},
    },
    TempShield = {
        Name = "Temporary Shield",
        Icon = "SEF_Icons/shieldcomb.png", 
        Desc = function(amount, max)
           return string.format("Temporary Shield negates 100%% of received damage. \n If Temporary Shield stacks reach 0, Effect expires \n Damage above Shield stacks are transfered to health. \n Buff Shield: %g \n Current Shield: %g", max, amount) 
        end,
        Type = "BUFF",
        Stackable = true,
        StackName = "AHP",
        EffectBegin = function(ent, amount)
            ent:SetSEFStacks("TempShield", amount)
            if not ent.TempShieldEffectSound then
                EmitSound("TempShield.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.TempShieldEffectSound = true
            end
        end,
        Effect = function(ent) end,
        EffectEnd = function(ent)
            ent:ResetSEFStacks("TempShield")
            ent.TempShieldEffectSound = nil
        end,
        ClientHooks = {},
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(ent, dmg, taken)
                    local shieldStacks = ent:GetSEFStacks("TempShield")
                    if shieldStacks and shieldStacks > 0 then
                        local damage = dmg:GetDamage()

                        local effectData = EffectData()
                        effectData:SetEntity(ent)
                        effectData:SetScale(1)
                        effectData:SetMagnitude(4)
                        util.Effect("TeslaHitboxes", effectData)

                        if damage > shieldStacks then
                            local remainingDamage = damage - shieldStacks
    
                            ent:RemoveSEFStacks("TempShield", shieldStacks)

                            ent:RemoveEffect("TempShield")
    
                            dmg:SetDamage(remainingDamage)
                        else
                            ent:RemoveSEFStacks("TempShield", damage)

                            local impactSounds = {
                                "physics/metal/metal_computer_impact_bullet1.wav",
                                "physics/metal/metal_computer_impact_bullet2.wav",
                                "physics/metal/metal_computer_impact_bullet3.wav"
                            }
                            local randomSound = impactSounds[math.random(#impactSounds)]
                            EmitSound(randomSound, ent:GetPos(), 0, CHAN_AUTO, 1, 100)

                            dmg:SetDamage(0)
    
                            if ent:GetSEFStacks("TempShield") <= 0 then
                                ent:SoftRemoveEffect("TempShield")
                            end
                        end

                        if ent:GetSEFStacks("TempShield") <= 0 then
                            ent:EmitSound("hl1/fvox/armor_gone.wav")
                        end
                    end
                end,
            }
        }
    },
    Fatigue = {
        Icon = "SEF_Icons/fatigue.png",
        Type = "DEBUFF",
        Desc = "You are unable to sprint.",
        EffectBegin = function(ent)
            if not ent.ExhaustEffectSound then
                EmitSound("Exhaust.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.FatigueEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.FatigueEffectSound = nil
            if ent:IsPlayer() then
                ent:SprintEnable()
            end
        end,
        Effect = function(ent, time)
            local TimeLeft = ent:GetTimeLeft("Fatigue")
            if ent:IsPlayer() then
                ent:SprintDisable()
            end
        end,
        EffectOnRemove = function(ent)
            ent.FatigueEffectSound = nil
            if ent:IsPlayer() then
                ent:SprintEnable()
            end
        end
    },
    Vuln = {
        Icon = "SEF_Icons/vuln.png",
        Name = "Vulnerability",
        Desc = "Debuffs are 50% longer.",
        Type = "DEBUFF",
        EffectBegin = function(ent)
            if not ent.VulnEffectSound then
                EmitSound("Exposed.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.VulnEffectSound = true
            end
        end,
        Effect = function(ent, time)
            for effectName, effectData in pairs(EntActiveEffects[ent]) do
                if StatusEffects[effectName].Type == "DEBUFF" and not effectData.VulnAffected and StatusEffects[effectName].Name ~= "Vulnerability" then
                    local NewDuration = EntActiveEffects[ent][effectName].Duration * 1.5
                    ent:ChangeDuration(effectName, NewDuration)
                    effectData.VulnAffected = true
                end
            end
        end,
        EffectEnd = function(ent)
            ent.VulnEffectSound = nil
        end,
    },
    Concussion = {
        Icon = "SEF_Icons/concussion.png",
        Desc = "You have problems with hearing and seeing.", 
        Type = "DEBUFF",
        EffectBegin = function(ent)
            if not ent.ConcussionEffectSound then
                EmitSound("Blindness.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.ConcussionEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.ConcussionEffectSound = nil
        end,  
        ClientHooks = {
            -- Overlay na ekran
            {
                HookType = "HUDPaintBackground",
                HookFunction = function()
                    local ply = LocalPlayer()
                    local TimeLeft = ply:GetTimeLeft("Concussion")
                    local ConcScreen = Material("SEF_Overlay/SEFConcOverlay.png")
        
                    if ply:HaveEffect("Concussion") then
                        local alpha = 255
                        local fadeStartTime = 0.5

                        LocalPlayer():SetDSP(7, false)
                        LocalPlayer():EmitSound("npc/combine_gunship/dropship_engine_distant_loop1.wav", 45, 100, 0.2)
        
                        if TimeLeft <= fadeStartTime then
                            alpha = math.max(0, 255 * (TimeLeft / fadeStartTime))
                        end
    
                        surface.SetDrawColor(255, 255, 255, alpha)
                        surface.SetMaterial(ConcScreen)
                        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
                    else
                        LocalPlayer():SetDSP(0, false)
                        LocalPlayer():StopSound("npc/combine_gunship/dropship_engine_distant_loop1.wav")
                    end
                end
            },
            -- Efekt szarości i lekkiego rozmazania
            {
                HookType = "RenderScreenspaceEffects",
                HookFunction = function()
                    local ply = LocalPlayer()
                    if ply:HaveEffect("Concussion") then
                        -- Dodanie lekkiego rozmazania
                        DrawMotionBlur(0.1, 0.8, 0.05)
                    end
                end
            },
            -- Ruch kamery symulujący ogłuszenie
            {
                HookType = "CalcView",
                HookFunction = function(ply, pos, angles, fov)
                    if ply:HaveEffect("Concussion") then
                        local time = CurTime()
                        local view = {}
                        view.origin = pos
                        view.angles = angles + Angle(math.sin(time * 1.5) * 2, math.sin(time * 2) * 2, 0)
                        view.fov = fov
                        return view
                    end
                end
            }
        },
        ServerHooks = {},
    },
    DarkVision = {
        Icon = "SEF_Icons/darkvision.png",
        Desc = "You are seeing things in dark matter...", 
        Type = "DEBUFF",
        ClientHooks = {
            -- Overlay na ekran
            {
                HookType = "HUDPaintBackground",
                HookFunction = function()
                    local ply = LocalPlayer()
                    local TimeLeft = ply:GetTimeLeft("DarkVision")
                    local ConcScreen = Material("SEF_Overlay/SEFConcOverlay.png")
        
                    if ply:HaveEffect("DarkVision") then
                        local fadeStartTime = 0.5

                        local minAlpha = 155
                        local maxAlpha = 255
                        local frequency = 5 

                        local alpha = minAlpha + (maxAlpha - minAlpha) * 0.5 * (1 + math.sin(CurTime() * frequency))
            
                        if TimeLeft <= fadeStartTime then
                            alpha = math.max(0, alpha * (TimeLeft / fadeStartTime))
                        end
    
                        surface.SetDrawColor(255, 255, 255, alpha)
                        surface.SetMaterial(ConcScreen)
                        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
                    end
                end
            },
            -- Efekt szarości i lekkiego rozmazania
            {
                HookType = "RenderScreenspaceEffects",
                HookFunction = function()
                    local ply = LocalPlayer()
                    if ply:HaveEffect("DarkVision") then
                        local fadeStartTime = 0.5
                        local TimeLeft = ply:GetTimeLeft("DarkVision")
                        local multiplier = 0.1
            
                        -- Stopniowe rozjaśnianie, ograniczone do zakresu od 0 do 1
                        if TimeLeft <= fadeStartTime then
                            multiplier = math.Clamp(1 - (TimeLeft / fadeStartTime) * 0.9, 0, 1)
                        end
            
                        DrawColorModify({
                            ["$pp_colour_addr"] = 0,
                            ["$pp_colour_addg"] = 0,
                            ["$pp_colour_addb"] = 0,
                            ["$pp_colour_brightness"] = -0.1,
                            ["$pp_colour_contrast"] = 0.7,
                            ["$pp_colour_colour"] = multiplier, -- Ograniczone rozjaśnianie
                            ["$pp_colour_mulr"] = 0,
                            ["$pp_colour_mulg"] = 0,
                            ["$pp_colour_mulb"] = 0
                        })
                    end
                end
            },
            -- Ruch kamery symulujący ogłuszenie
            {
                HookType = "CalcView",
                HookFunction = function(ply, pos, angles, fov)
                    if ply:HaveEffect("Concussion") then
                        local time = CurTime()
                        local view = {}
                        view.origin = pos
                        view.angles = angles + Angle(math.sin(time * 1.5) * 2, math.sin(time * 2) * 2, 0)
                        view.fov = fov
                        return view
                    end
                end
            }
        },
        ServerHooks = {},
    },
    FallImm = {
        Name = "Fall Immunity",
        Icon = "SEF_Icons/fallimmune.png",
        Desc = "You won't take fall damage.", 
        Type = "BUFF",
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(ent, dmg)
                    if ent:HaveEffect("FallImm") then
                        if dmg:IsFallDamage() then
                            dmg:SetDamage(0)
                        end
                    end
                end,
            },
        },
    },
    Resilience = {
        Name = "Resilience",
        Icon = "SEF_Icons/resilience.png",
        Desc = "If you are about to die: \n Get Deep Wound status effect and 75% Damage Reduction for 5 sec. \nRegain 25% of your max health.",
        Type = "BUFF",
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(ent, dmginfo)
                    if not IsValid(ent) or not ent:IsPlayer() then return end
                    if not ent:HaveEffect("Resilience") then return end

                    local damage = dmginfo:GetDamage()
                    local health = ent:Health()

                    if damage >= health then
                        dmginfo:SetDamage(0)
                        local maxHealth = ent:GetMaxHealth()
                        local healAmount = maxHealth * 0.25

                        timer.Simple(0.1, function()
                            if not IsValid(ent) then return end
                            if not ent:Alive() then return end

                            ent:SetHealth(healAmount)
                            ent:ApplyEffect("DeepWound", math.huge)
                            ent:ApplyEffect("Endurance", 5, 75)
                            ent:EmitSound("npc/fast_zombie/claw_strike1.wav", 75, 100, 1, CHAN_BODY)
                            ent:RemoveEffect("Resilience")
                        end)
                    end
                end,
            },
        },
    },
    DeepWound = {
        Name = "Deep Wound",
        Icon = "SEF_Icons/deepwound.png",
        Desc = "Lose 1% of your max health each 0.5 sec. when not moving. \n Healing buff or having health above 25% will remove this effect. \n\n Resilience can't be applied while Deep Wound is active.",
        Type = "DEBUFF",
        Effect = function(ent, time)
            local TimeLeft = ent:GetTimeLeft("DeepWound")
            if TimeLeft > 0.1 then
                if not ent.DeepWoundEffectDelay then
                    ent.DeepWoundEffectDelay = CurTime()
                end

                if ent:HaveEffect("Resilience") then
                    ent:RemoveEffect("Resilience")
                end

                if ent:GetVelocity():LengthSqr() > 0 then
                    ent.DeepWoundEffectDelay = CurTime() + 0.5
                else
                    if CurTime() >= ent.DeepWoundEffectDelay then
                        local maxHealth = ent:GetMaxHealth()
                        local damageAmount = maxHealth * 0.01  -- 1% of max health
                        ent:SetHealth(math.max(ent:Health() - damageAmount, 0))
                        ent.DeepWoundEffectDelay = CurTime() + 0.5

                        if ent:Health() <= 0 then
                            if ent:IsPlayer() then
                                ent:Kill()
                            elseif ent:IsNPC() then
                                ent:TakeDamage(1)
                            end
                        end
                    end
                end

                if (ent:IsPlayer() and ent:Alive()) and (ent:HaveEffect("Healing") or ent:Health() > ent:GetMaxHealth() * 0.25) then
                    ent:SoftRemoveEffect("DeepWound")
                elseif ent:IsNPC() and (ent:Health() > ent:GetMaxHealth() * 0.25 or ent:HaveEffect("Healing")) then
                    ent:SoftRemoveEffect("DeepWound")
                end

            end
        end,
        DisplayFunction = function(ent)
            if ent:IsValid() then
                local emitter = ParticleEmitter(ent:GetPos())

                if not ent.DeepWoundParticleTime then
                    ent.DeepWoundParticleTime = CurTime()
                end

                if emitter then
                    local distance = math.Rand(0, 25)
                    local particlePos = ent:WorldSpaceCenter() + Vector(math.Rand(-distance, distance), math.Rand(-distance, distance), 0)
                    local particle = emitter:Add(Material("effects/splash4"), particlePos)
                    if particle and CurTime() >= ent.DeepWoundParticleTime + 0.1 then
                        particle:SetLifeTime(0)
                        particle:SetDieTime(math.random(10, 20))
                        particle:SetStartAlpha(255)
                        particle:SetEndAlpha(0)
                        particle:SetStartSize(10)
                        particle:SetEndSize(0)
                        particle:SetColor(255, 0, 0)
                        particle:SetGravity(Vector(0, 0, -800))
                        particle:SetAngleVelocity(Angle(math.random(-25, 25), 0, 0))
                        particle:SetCollide(true)
                        particle:SetCollideCallback(function(particle, hitpos, hitnormal)
                            local dropsounds = {
                                "ambient/water/rain_drip1.wav",
                                "ambient/water/rain_drip2.wav",
                                "ambient/water/rain_drip3.wav",
                                "ambient/water/rain_drip4.wav"
                            }
                            EmitSound(dropsounds[math.random(#dropsounds)], hitpos, 0, CHAN_AUTO, 0.1, 100)
                        end)
                        ent.DeepWoundParticleTime = CurTime()
                    end
        
                    emitter:Finish()
                end
            end
        end,
        EffectEnd = function(ent)
            ent:EmitSound("Haste.mp3", 75, 100, 1, CHAN_VOICE)
        end,
        ClientHooks = {
            {
                HookType = "HUDPaintBackground",
                HookFunction = function()
                    local ply = LocalPlayer()
                    local DeepWoundMat = Material("SEF_Overlay/DeepWound.png")
            
                    if ply:HaveEffect("DeepWound") then
                        local alpha = 255
            
                        surface.SetMaterial(DeepWoundMat)
                        surface.SetDrawColor(255, 255, 255, alpha)
                        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())

                        if not ply.HeartBeatDeepWoundSound then
                            ply:EmitSound("player/heartbeat1.wav", 100, 100, 1, CHAN_STATIC)
                            ply.HeartBeatDeepWoundSound = true
                        end
                    else
                        if ply.HeartBeatDeepWoundSound then
                            ply:StopSound("player/heartbeat1.wav")
                            ply.HeartBeatDeepWoundSound = nil
                        end
                    end
                end
            }
        }
    },
    DamageUp = {
        Name = "Damage Increase Buff",
        Icon = "SEF_Icons/dmg-up.png",
        Desc = function(dmgup)
            return string.format("You are dealing %d%% more damage.", dmgup)
        end,
        Type = "BUFF",
        Stackable = true,
        StackName = "+ % DMG",
        EffectBegin = function(ent, dmgup)
            ent:SetSEFStacks("DamageUp", dmgup)
        end,
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(target, dmginfo)
                    local attacker = dmginfo:GetAttacker()
                    if target and target ~= attacker and (target:IsNPC() or target:IsPlayer() or target:IsNextBot()) and attacker:HaveEffect("DamageUp") then
                        local dmgup = attacker:GetSEFStacks("DamageUp") or 0
                        dmginfo:ScaleDamage(1 + (dmgup / 100))
                    end
                end
            }
        },
    },
    DamageDown = {
        Name = "Damage Decrease Debuff",
        Icon = "SEF_Icons/dmg-down.png",
        Desc = function(dmgdown)
            return string.format("You are dealing %d%% less damage.", dmgdown)
        end,
        Type = "DEBUFF",
        Stackable = true,
        StackName = "- % DMG",
        EffectBegin = function(ent, dmgdown)
            ent:SetSEFStacks("DamageDown", dmgdown)
        end,
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(target, dmginfo)
                    local attacker = dmginfo:GetAttacker()
                    if target and target ~= attacker and (target:IsNPC() or target:IsPlayer() or target:IsNextBot()) and attacker:HaveEffect("DamageDown") then
                        local dmgdown = attacker:GetSEFStacks("DamageDown") or 0
                        dmginfo:ScaleDamage(1 - (dmgdown / 100))
                    end
                end
            }
        },
    }

    --[[
    Immortality = {
        Icon = "SEF_Icons/immortal.png",
        Desc = "True Blessing... \nYou have shield which makes you immune to all damage sources. \n All Damage is deflected to attackers. \nYou can't do anything while Immortality is active.",
        Type = "BUFF",
        SoftDelete = true,
        DisplayFunction = function(ent)
            if IsValid(ent) and ent:HaveEffect("Immortality") then
                if not ent.ImmortalityModel then
                    -- Tworzenie modelu i przypięcie do encji
                    local model = ClientsideModel("models/hunter/misc/shell2x2.mdl")
                    if IsValid(model) then
                        -- Przypięcie do encji bez rotacji
                        model:SetParent(ent)
                        model:SetPos(ent:WorldSpaceCenter())
                        model:SetAngles(Angle(0, 0, 0))  -- Ustawienie stałej orientacji
                        model:SetMaterial("Models/effects/comball_tape")
                        model:SetNoDraw(false)
    
                        -- Przechowywanie referencji do modelu
                        ent.ImmortalityModel = model
                    end
                end
    
                -- Aktualizacja pozycji modelu co klatkę, bez zmiany jego rotacji
                if IsValid(ent.ImmortalityModel) then
                    ent.ImmortalityModel:SetPos(ent:WorldSpaceCenter())
                    ent.ImmortalityModel:SetAngles(Angle(0, 0, 0))  -- Zachowanie stałej orientacji
                end
    
                -- Usunięcie modelu, gdy efekt wygasa lub gracz umiera
                if (ent:GetEntTimeLeft("Immortality") <= 0.1) or (ent:Health() <= 0) or (ent:IsPlayer() and not ent:Alive()) then
                    ent.ImmortalityModel:Remove()
                    ent.ImmortalityModel = nil
                end
            end

            if IsValid(ent) and not ent:HaveEffect("Immortality") then
                if IsValid(ent.ImmortalityModel) then
                    ent.ImmortalityModel:Remove()
                    ent.ImmortalityModel = nil
                end
            end
        end,
        Effect = function(ent, time)
            if ent:IsPlayer() then
                ent:SetActiveWeapon(NULL)
            end
        end,
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(ent, dmg)
                    if ent:HaveEffect("Immortality") then
                        local attacker = dmg:GetAttacker()  -- Pobranie atakującego
                        
                        -- Sprawdzenie, czy obrażenia nie są wynikiem efektu "Immortality"
                        if IsValid(attacker) and attacker ~= ent and dmg:GetDamage() > 0 then
                            local damageAmount = dmg:GetDamage()  -- Pobranie zadanych obrażeń
        
                            -- Zablokowanie obrażeń dla encji z efektem "Immortality"
                            dmg:SetDamage(0)
        
                            -- Tworzenie nowych obrażeń dla atakującego
                            local reflectedDmg = DamageInfo()
                            reflectedDmg:SetDamage(damageAmount)
                            reflectedDmg:SetAttacker(ent)
                            reflectedDmg:SetInflictor(ent)
                            reflectedDmg:SetDamageType(dmg:GetDamageType())

                            if not attacker:HaveEffect("Immortality") then 
                                attacker:TakeDamageInfo(reflectedDmg)
                            end
                        else
                            dmg:SetDamage(0)
                        end
                    end
                end
            }
        }             
    }]]--    
}