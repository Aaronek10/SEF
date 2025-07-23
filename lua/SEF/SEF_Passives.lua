PassiveEffects = {

    PassiveTemplate = {
        Icon = "SEF_Icons/warning.png",
        Desc = "", 
        Effect = function(ent) end,
        ClientHooks = {},
        ServerHooks = {}
    },

    IronSkin = {
        Icon = "SEF_Icons/endurance.png",
        Desc = "Received damage is reduced by 20%.",
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(target, dmginfo)
                    if target and target:HavePassive("IronSkin") then
                        dmginfo:ScaleDamage(0.8)
                        target:EmitSound("phx/epicmetal_hard.wav", 110, math.random(75, 125), 1)
                    end
                end
            }
        }
    },

    Fireborn = {
        Icon = "SEF_Icons/bloodlust.png",
        Desc = "You are immune to Fire Damage and it also heals you.",
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(target, dmginfo)
                    if target:IsPlayer() and target:HavePassive("Fireborn") then
                        if dmginfo:IsDamageType(DMG_BURN) then
                            local healAmount = dmginfo:GetDamage()
                            dmginfo:ScaleDamage(0)
                            if healAmount > 0 then
                                target:SetHealth(math.min(target:Health() + healAmount, target:GetMaxHealth()))
                                target:EmitSound("npc/headcrab_poison/ph_rattle1.wav", 110, math.random(75, 125), 1)
                            end
                        end
                    end
                end
            }
        }
    },

    PassiveTenacity = {
        Icon = "icon32/tool.png",
        Name = "Reletless",
        Desc = "Debuffs applied to you have 50% reduced duration.",
        ServerHooks = {
            {
                HookType = "Think",
                HookFunction = function()
                    for _, ent in ents.Iterator() do
                        if not IsValid(ent) or not ent:IsPlayer() then continue end
                        if ent:HavePassive("PassiveTenacity") then
                            for effectName, effectData in pairs(EntActiveEffects[ent]) do
                                if StatusEffects[effectName].Type == "DEBUFF" and not effectData.PassiveTenacityAffected then
                                    local NewDuration = EntActiveEffects[ent][effectName].Duration * (1 - (50 / 100))
                                    ent:ChangeDuration(effectName, NewDuration)
                                    ent:EmitSound("resource/warning.wav", 110, 100, 1)
                                    effectData.PassiveTenacityAffected = true
                                end
                            end
                        end
                    end
                end
            }
        }
    }
}
