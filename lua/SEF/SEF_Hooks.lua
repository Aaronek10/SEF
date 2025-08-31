
if SERVER then
    hook.Add("Think", "EntityStatusEffectsThink", function()
        for entity, effects in pairs(EntActiveEffects) do
            if IsValid(entity) and (entity:IsPlayer() or entity:IsNPC() or entity:IsNextBot()) then
                for effectName, effectData in pairs(effects) do
                    local currentTime = CurTime()
                    local TimeLeft = effectData.StartTime + effectData.Duration - currentTime
                    if TimeLeft > 0 then
                        if not effectData.HasBegun or (effectData.HasBegun and effectData.IsReApplied) then
                            if effectData.FunctionBegin then
                                effectData.FunctionBegin(entity, unpack(effectData.Args))
                            end
                            effectData.HasBegun = true
                            effectData.IsReApplied = nil
                        end

                        if effectData.Function then
                            effectData.Function(entity, effectData.Duration, unpack(effectData.Args))
                        end
                    else
                        if effectData.FunctionEnd then
                            effectData.FunctionEnd(entity, unpack(effectData.Args))
                        end

                        if effectData.Stackable then
                            entity:ResetSEFStacks(effectName)
                        end

                        entity:RemoveEffect(effectName)
                    end
                end
            elseif not IsValid(entity) then
                EntActiveEffects[entity] = nil
            end
        end
    end)
    
    

    hook.Add("Think", "EntityPassivesEffectThink", function()
        for entity, Passives in pairs(EntActivePassives) do
            if IsValid(entity) and (entity:IsPlayer() or entity:IsNPC() or entity:IsNextBot()) then
                for effectName, PassiveData in pairs(Passives) do
                    if PassiveData.Function then
                        PassiveData.Function(entity)
                    end
                end
            elseif not IsValid(entity) then
                EntActivePassives[entity] = nil
            end
        end
    end)


    local function CreateEffectHooks()
        -- Przetwarzanie efektów
        for effect, effectData in pairs(StatusEffects) do
            if effect and effectData.ServerHooks then
                for index, hookData in ipairs(effectData.ServerHooks) do
                    if hookData.HookType then
                        local hookID = "SEF_SERVER_EFFECT_" .. effect .. tostring(index)
                        
                        if not hookData.HookInit then
                            hookData.LastHookFunction = hookData.HookFunction
    
                            print("[Status Effect Framework] Effect Hook has been created: " .. effect .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, function(...)
                                hookData.HookFunction(...)
                            end)
    
                            hookData.HookInit = true
                        elseif hookData.LastHookFunction ~= hookData.HookFunction then
                            print("[Status Effect Framework] Updating Hook Function for: " .. effect .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, function(...)
                                hookData.HookFunction(...)
                            end)
    
                            hookData.LastHookFunction = hookData.HookFunction
                        end
                    end
                end
            end
        end
    
        -- Przetwarzanie efektów pasywnych (jeśli istnieją)
        for passive, PassiveData in pairs(PassiveEffects) do
            if passive and PassiveData.ServerHooks then
                for index, hookData in ipairs(PassiveData.ServerHooks) do
                    if hookData.HookType ~= "" then
                        local hookID = "SEF_SERVER_PASSIVE_" .. passive .. tostring(index)
    
                        if not hookData.HookInit then
                            hookData.LastHookFunction = hookData.HookFunction
    
                            print("[Status Effect Framework] Passive Hook has been created: " .. passive .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, function(...)
                                hookData.HookFunction(...)
                            end)
    
                            hookData.HookInit = true
                        elseif hookData.LastHookFunction ~= hookData.HookFunction then
                            print("[Status Effect Framework] Updating Hook Function for: " .. passive .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, function(...)
                                hookData.HookFunction(...)
                            end)
    
                            hookData.LastHookFunction = hookData.HookFunction
                        end
                    end
                end
            end
        end
    end
    

    hook.Add("PlayerDeath", "RemoveStatusEffects", function(victim, inflictor, attacker)
        if IsValid(victim) and EntActiveEffects[victim] then
            for effectName, _ in pairs(EntActiveEffects[victim]) do
                if not StatusEffects[effectName].SoftDelete then
                    victim:RemoveEffect(effectName)
                else
                    victim:SoftRemoveEffect(effectName)
                end
                victim:ClearSEFStacks()
            end
        end
        BaseStatResetAll(victim)
    end)

    hook.Add("LambdaOnKilled", "RemoveStatusEffectsLambda", function(lambda, dmg, isSilent)
        if IsValid(lambda) and EntActiveEffects[lambda] then
            for effectName, _ in pairs(EntActiveEffects[lambda]) do
                timer.Simple(0.5, function()
                    if IsValid(lambda) then
                        lambda:SoftRemoveEffect(effectName)
                    end
                end)
            end
        end
        BaseStatResetAll(lambda)
    end)

    hook.Add("Think", "SEF_UpdateEffectDesc", function()
        for entity, effects in pairs(EntEffectStacks) do
            if IsValid(entity) then
                local hasActiveEffects = false

                for effectName, stackCount in pairs(effects) do
                    local effectData = StatusEffects[effectName]
                    if effectData and effectData.Stackable then
                        local previousStack = entity.PreviousEffectStacks and entity.PreviousEffectStacks[effectName] or 0

                        if stackCount ~= previousStack then
                            if isfunction(effectData.Desc) then
                                local newDesc = effectData.Desc(stackCount, unpack(EntActiveEffects[entity][effectName].Args))

                                if entity:IsPlayer() then
                                    net.Start("SEF_UpdateDesc")
                                    net.WriteString(effectName)
                                    net.WriteString(newDesc)
                                    net.Send(entity)
                                end

                                entity.PreviousEffectStacks = entity.PreviousEffectStacks or {}
                                entity.PreviousEffectStacks[effectName] = stackCount
                            end
                        end

                        hasActiveEffects = true
                    end
                end

                if entity.PreviousEffectStacks then
                    for prevEffectName in pairs(entity.PreviousEffectStacks) do
                        if not effects[prevEffectName] then
                            entity.PreviousEffectStacks[prevEffectName] = nil
                        end
                    end

                    if not hasActiveEffects then
                        entity.PreviousEffectStacks = nil
                    end
                end
            end
        end

        for entity, passives in pairs(EntPassiveStacks) do
            if IsValid(entity) then
                local hasActivePassives = false

                for passiveName, stackCount in pairs(passives) do
                    local passiveData = PassiveEffects[passiveName]
                    if passiveData and passiveData.Stackable then
                        local previousStack = entity.PreviousPassiveStacks and entity.PreviousPassiveStacks[passiveName] or 0

                        if stackCount ~= previousStack then
                            if isfunction(passiveData.Desc) then
                                local newDesc = passiveData.Desc(stackCount, unpack(EntActivePassives[entity][passiveName].Args))

                                if entity:IsPlayer() then
                                    net.Start("SEF_UpdateDesc")
                                    net.WriteString(passiveName)
                                    net.WriteString(newDesc)
                                    net.Send(entity)
                                end

                                entity.PreviousPassiveStacks = entity.PreviousPassiveStacks or {}
                                entity.PreviousPassiveStacks[passiveName] = stackCount
                            end
                        end

                        hasActivePassives = true
                    end
                end

                if entity.PreviousPassiveStacks then
                    for prevPassiveName in pairs(entity.PreviousPassiveStacks) do
                        if not passives[prevPassiveName] then
                            entity.PreviousPassiveStacks[prevPassiveName] = nil
                        end
                    end

                    if not hasActivePassives then
                        entity.PreviousPassiveStacks = nil
                    end
                end
            end
        end
    end)
    

    hook.Add("InitPostEntity", "CreateSEFHooks", function() 
        CreateEffectHooks()

        for _, ply in ipairs(player.GetAll()) do
            if ply:IsValid() then
                ply:ConCommand("SEF_CreateClientHooks")
                ply:ClearAllEffectDelays() -- To ensure no residual delays
            end
        end
    end)

    concommand.Add("SEF_CreateEffectHooks", function(ply, cmd, args)
        CreateEffectHooks()
    end, nil, "Reloads or creates all SEF hooks.")
else
    local function CreateClientEffectHooks()
        for effect, effectData in pairs(StatusEffects) do
            if effect and effectData.ClientHooks then
                for index, hookData in ipairs(effectData.ClientHooks) do
                    if hookData.HookType then
                        local hookID = "SEF_CLIENT_EFFECT_" .. effect .. tostring(index)
                        
                        if not hookData.HookInit then
                            hookData.LastHookFunction = hookData.HookFunction
    
                            print("[Status Effect Framework] Effect Hook has been created: " .. effect .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, hookData.HookFunction)
    
                            hookData.HookInit = true
                        elseif hookData.LastHookFunction ~= hookData.HookFunction then
                            print("[Status Effect Framework] Updating Hook Function for: " .. effect .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, hookData.HookFunction)
    
                            hookData.LastHookFunction = hookData.HookFunction
                        end
                    end
                end
            end
        end
    
        -- Przetwarzanie efektów pasywnych (jeśli istnieją)
        for passive, PassiveData in pairs(PassiveEffects) do
            if passive and PassiveData.ClientHooks then
                for index, hookData in ipairs(PassiveData.ClientHooks) do
                    if hookData.HookType ~= "" then
                        local hookID = "SEF_CLIENT_PASSIVE_" .. passive .. tostring(index)
    
                        if not hookData.HookInit then
                            hookData.LastHookFunction = hookData.HookFunction
    
                            print("[Status Effect Framework] Client Passive Hook has been created: " .. passive .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, hookData.HookFunction)
    
                            hookData.HookInit = true
                        elseif hookData.LastHookFunction ~= hookData.HookFunction then
                            print("[Status Effect Framework] Client Updating Hook Function for: " .. passive .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, hookData.HookFunction)
    
                            hookData.LastHookFunction = hookData.HookFunction
                        end
                    end
                end
            end
        end
    end

    local function CreateDisplayHooks()
        for effect, effectData in pairs(StatusEffects) do
            if effectData.DisplayFunction then
                local hookID = "SEF_DISPLAYHOOK_" .. effect
                
                -- Sprawdź, czy hook został już dodany
                if not effectData.DisplayHookInit then
                    -- Zapisz początkową funkcję hooka
                    effectData.LastDisplayFunction = effectData.DisplayFunction
    
                    -- Dodaj hooka
                    hook.Add("Think", hookID, function()
                        for ent, activeEffects in pairs(AllEntEffects) do
                            if activeEffects[effect] then
                                effectData.DisplayFunction(ent)
                            end
                        end
                    end)
    
                    -- Zaznacz, że hook został dodany
                    effectData.DisplayHookInit = true
    
                    print("[Status Effect Framework] Display Hook has been created for: " .. effect .. " Hook: " .. hookID)
                elseif effectData.LastDisplayFunction ~= effectData.DisplayFunction then
                    -- Funkcja hooka została zmieniona, zaktualizuj hooka
                    print("[Status Effect Framework] Updating Display Hook Function for: " .. effect .. " Hook: " .. hookID)
    
                    -- Usunięcie starego hooka, jeśli istnieje
                    hook.Remove("Think", hookID)
    
                    -- Dodanie nowego hooka
                    hook.Add("Think", hookID, function()
                        for ent, activeEffects in pairs(AllEntEffects) do
                            if activeEffects[effect] then
                                effectData.DisplayFunction(ent)
                            end
                        end
                    end)
    
                    -- Zaktualizuj zapis funkcji hooka
                    effectData.LastDisplayFunction = effectData.DisplayFunction
                end
            end
        end
    end


    hook.Add("InitPostEntity", "CreateSEFClientHooks", function() 
        CreateClientEffectHooks()
        CreateDisplayHooks()
    end)

    concommand.Add("SEF_CreateClientHooks", function(ply, cmd, args)
        CreateClientEffectHooks()
        CreateDisplayHooks()
    end, nil, "Reloads or creates all SEF hooks for Client.")

end