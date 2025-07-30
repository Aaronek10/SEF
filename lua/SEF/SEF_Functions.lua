if SERVER then

    util.AddNetworkString("SEF_EffectData")
    util.AddNetworkString("SEF_EntityData")
    util.AddNetworkString("SEF_UpdateData")
    util.AddNetworkString("SEF_UpdateDesc")
    util.AddNetworkString("SEF_StackSystem")

    CreateConVar("SEF_LoggingMode", 0, FCVAR_NONE, "Enable displaying logs of SEF", 0, 1)

    local ENTITY = FindMetaTable("Entity")
    EntActiveEffects = {}
    EntActivePassives = {}
    EntBaseStats = {}
    EntEffectStacks = {}
    EntPassiveStacks = {}


    // CORE SEF FUNCTIONS

    function ENTITY:ApplyEffect(effectName, time, ...)
        local SEF_LoggingMode = GetConVar("SEF_LoggingMode")
        local effect = StatusEffects[effectName]
        if effect and (self:IsPlayer() or self:IsNPC() or self:IsNextBot()) then
    
            
    
            if not EntActiveEffects[self] then
                if SEF_LoggingMode:GetBool() then
                    print("[Status Effect Framework] Status Effect Table created for entity:", self)
                end
                EntActiveEffects[self] = {}
            end
    
            if not EntActiveEffects[self][effectName] then
                if SEF_LoggingMode:GetBool() then
                    print("[Status Effect Framework] Applied Effect:", effectName, "to entity:", self)
                end
            end
    
            local args = {...}
            EntActiveEffects[self][effectName] = {
                Function = effect.Effect,
                FunctionBegin = effect.EffectBegin,
                FunctionEnd = effect.EffectEnd,
                FunctionOnRemove = effect.EffectOnRemove,
                Stackable = effect.Stackable,
                StartTime = CurTime(),
                Duration = time,
                Args = args
            }
    
            local DynDesc
            if isfunction(effect.Desc) then
                if effect.Stackable then
                    local argsCopy = { unpack(args) }
                    table.insert(argsCopy, #argsCopy, self:GetSEFStacks(effectName))
                    DynDesc = effect.Desc(unpack(argsCopy))
                else
                    DynDesc = effect.Desc(unpack(args))
                end
            else
                DynDesc = effect.Desc
            end
    
            if self:IsPlayer() then
                net.Start("SEF_EffectData")
                    net.WriteString("Add")
                    net.WriteString("Effect")
                    net.WriteString(effectName)
                    net.WriteString(DynDesc)
                    net.WriteFloat(time)
                net.Send(self)
            end
    
            net.Start("SEF_EntityData")
            net.WriteString("Add")
            net.WriteEntity(self)
            net.WriteString(effectName)
            net.WriteFloat(time)
            net.WriteFloat(CurTime())
            net.Broadcast()
    
        else
            if SEF_LoggingMode:GetBool() then
                print("[Status Effect Framework] Effect not found")
            end
        end
    end


    function ENTITY:GetTimeLeft(effectName)
        
        if EntActiveEffects[self] and EntActiveEffects[self][effectName] then
            local effectData = EntActiveEffects[self][effectName]
            local elapsedTime = CurTime() - effectData.StartTime
            local remainingTime = effectData.Duration - elapsedTime
            return math.max(remainingTime, 0)
        else
            return 0 
        end
    end
    
    
    function ENTITY:RemoveEffect(effectName, ...)
        local SEF_LoggingMode = GetConVar("SEF_LoggingMode")
        local args = {...}
        
        if EntActiveEffects[self] and EntActiveEffects[self][effectName] then

            local effectData = EntActiveEffects[self][effectName]
            local timeLeft = self:GetTimeLeft(effectName)

            if effectData and effectData.FunctionOnRemove and timeLeft > 0.1 then
                effectData.FunctionOnRemove(self, timeLeft, unpack{args})
            end

            EntActiveEffects[self][effectName] = nil
            if SEF_LoggingMode:GetBool() then
                print("[Status Effect Framework] Removed Effect", effectName, "from entity:", self)
            end

            if self:IsPlayer() then
                net.Start("SEF_EffectData")
                    net.WriteString("Remove") 
                    net.WriteString("Effect")
                    net.WriteString(effectName)
                net.Send(self)

            end

            net.Start("SEF_EntityData")
            net.WriteString("Remove")
            net.WriteEntity(self)
            net.WriteString(effectName)
            net.Broadcast()
        else
            if SEF_LoggingMode:GetBool() then
                print("[Status Effect Framework] Effect not active or not found:", effectName)
            end
        end
    end

    function ENTITY:ApplyPassive(effectName)
        local SEF_LoggingMode = GetConVar("SEF_LoggingMode")
        local effect = PassiveEffects[effectName]
        if effect and (self:IsPlayer() or self:IsNPC() or self:IsNextBot()) then

            

            if not EntActivePassives[self] then
                if SEF_LoggingMode:GetBool() then
                    print("[Status Effect Framework] Passives Effect Table created for entity:", self)
                end
                EntActivePassives[self] = {}
            end

            if not EntActivePassives[self][effectName] then
                if SEF_LoggingMode:GetBool() then
                    print("[Status Effect Framework] Applied Passive Effect:", effectName, "to entity:", self)
                end
            end

            EntActivePassives[self][effectName] = {
                Function = effect.Effect,
            }

            local DynDesc = effect.Desc


            if self:IsPlayer() then
                net.Start("SEF_EffectData")
                    net.WriteString("Add")
                    net.WriteString("Passive") 
                    net.WriteString(passiveName) 
                    net.WriteString(DynDesc)
                net.Send(self)
            end

        else
            if SEF_LoggingMode:GetBool() then
                print("[Status Effect Framework] Passive not found")
            end
        end
    end
    
    function ENTITY:RemovePassive(effectName)
        local SEF_LoggingMode = GetConVar("SEF_LoggingMode")
        
        if EntActivePassives[self] and EntActivePassives[self][effectName] then
            EntActivePassives[self][effectName] = nil
            if SEF_LoggingMode:GetBool() then
                print("[Status Effect Framework] Removed Passive", effectName, "from entity:", self)
            end

            if self:IsPlayer() then
                net.Start("SEF_EffectData")
                    net.WriteString("Remove") 
                    net.WriteString("Passive") 
                    net.WriteString(passiveName)  
                net.Send(self)
            end
        else
            if SEF_LoggingMode:GetBool() then
                print("[Status Effect Framework] Passive not active or not found:", effectName)
            end
        end
    end

    function ENTITY:SoftRemoveEffect(effectName)
        local SEF_LoggingMode = GetConVar("SEF_LoggingMode")
        
        if EntActiveEffects[self] and EntActiveEffects[self][effectName] then
            if SEF_LoggingMode:GetBool() then
                print("[Status Effect Framework] Softremoved Effect", effectName, "from entity:", self)
            end
            EntActiveEffects[self][effectName].Duration = 1

            if self:IsPlayer() then
                net.Start("SEF_AddEffect")
                net.WriteString(effectName)
                net.WriteString("Effect is wearing off.")
                net.WriteFloat(2)
                net.Send(self)
            end

            net.Start("SEF_EntityAdd")
            net.WriteEntity(self)
            net.WriteString(effectName)
            net.WriteFloat(1)
            net.WriteFloat(CurTime())
            net.Broadcast()
        else
            if SEF_LoggingMode:GetBool() then
                print("[Status Effect Framework] Effect not active or not found:", effectName)
            end
        end
    end

    function ENTITY:HaveEffect(effectName)
        if EntActiveEffects[self] and EntActiveEffects[self][effectName] then
            return true
        else
            return false
        end
    end

    function ENTITY:HavePassive(effectName)
        if EntActivePassives[self] and EntActivePassives[self][effectName] then
            return true
        else
            return false
        end
    end

    function ENTITY:ChangeDuration(effectName, time)
        
        if EntActiveEffects[self] and EntActiveEffects[self][effectName] then
            local effectData = EntActiveEffects[self][effectName]
            effectData.Duration = time

            net.Start("SEF_UpdateData")
            net.WriteEntity(self)
            net.WriteString(effectName)
            net.WriteFloat(time)
            net.Broadcast()
        end
    end

    // BASE STATS FUNCTIONS

    local statFunctions = {
        MaxHealth = { 
            get = function(ent) return ent:GetMaxHealth() end, 
            set = function(ent, val) ent:SetMaxHealth(val) end 
        },
        MaxArmor = { 
            get = function(ent) return ent.GetMaxArmor and ent:GetMaxArmor() or 0 end,
            set = function(ent, val) if ent.SetMaxArmor then ent:SetMaxArmor(val) end end 
        },
        WalkSpeed = { 
            get = function(ent) return ent.GetWalkSpeed and ent:GetWalkSpeed() or 0 end,
            set = function(ent, val) if ent.SetWalkSpeed then ent:SetWalkSpeed(val) end end 
        },
        RunSpeed = { 
            get = function(ent) return ent.GetRunSpeed and ent:GetRunSpeed() or 0 end,
            set = function(ent, val) if ent.SetRunSpeed then ent:SetRunSpeed(val) end end 
        },
        JumpPower = { 
            get = function(ent) return ent.GetJumpPower and ent:GetJumpPower() or 0 end,
            set = function(ent, val) if ent.SetJumpPower then ent:SetJumpPower(val) end end 
        },
    }


    local function InitEntityBaseStats(ent)
        EntBaseStats[ent] = {
            MaxHealth = ent:GetMaxHealth(),
            MaxArmor = ent.GetMaxArmor and ent:GetMaxArmor() or 0,
            WalkSpeed = ent.GetWalkSpeed and ent:GetWalkSpeed() or 0,
            RunSpeed =  ent.GetRunSpeed and ent:GetRunSpeed() or 0,
            JumpPower = ent.GetJumpPower and ent:GetJumpPower() or 0
        }
    end


    function BaseStatAdd(ent, stat, value)
        local funcs = statFunctions[stat]
        if not funcs then return end

        local current = funcs.get(ent)
        funcs.set(ent, current + value)

        if GetConVar("SEF_LoggingMode"):GetBool() then
            print("[BaseStats System] Added " .. value .. " to statistic: " .. stat .. " on entity: " .. tostring(ent))
        end
    end

    function BaseStatRemove(ent, stat, value)
        local funcs = statFunctions[stat]
        if not funcs then return end

        local current = funcs.get(ent)
        funcs.set(ent, current - value)

        if GetConVar("SEF_LoggingMode"):GetBool() then
            print("[BaseStats System] Removed " .. value .. " from statistic: " .. stat .. " on entity: " .. tostring(ent))
        end
    end

    function BaseStatReset(ent, stat)
        local funcs = statFunctions[stat]
        if not funcs or not EntBaseStats[ent] then return end

        funcs.set(ent, EntBaseStats[ent][stat])

        if GetConVar("SEF_LoggingMode"):GetBool() then
            print("[BaseStats System] Statistic " .. stat .. " has been reset on entity: " .. tostring(ent))
        end
    end

    function BaseStatResetAll(ent)
        if not EntBaseStats[ent] then return end

        for stat, funcs in pairs(statFunctions) do
            funcs.set(ent, EntBaseStats[ent][stat])
        end

        if GetConVar("SEF_LoggingMode"):GetBool() then
            print("[BaseStats System] All Statistics have been reset on entity: " .. tostring(ent))
        end
    end


    // STACK SYSTEM FUNCTIONS

    function ENTITY:AddSEFStacks(effect, amount)
        amount = amount or 1
    
        local effectData = StatusEffects[effect] or PassiveEffects[effect]
    
        -- Sprawdzenie, czy efekt/pasywka istnieje i czy jest stackowalna
        if not effectData or not effectData.Stackable then
            print("[Status Effect Framework] Effect or passive is not stackable or does not exist: ", effect)
            return
        end
    
        if StatusEffects[effect] then
            EntEffectStacks[self] = EntEffectStacks[self] or {}
            EntEffectStacks[self][effect] = (EntEffectStacks[self][effect] or 1) + amount

            if self:IsPlayer() then
                net.Start("SEF_StackSystem")
                net.WriteString("ADD")
                net.WriteString(effect)
                net.WriteInt(amount, 32)
                net.Send(self)
            end

        elseif PassiveEffects[effect] then
            EntPassiveStacks[self] = EntPassiveStacks[self] or {}
            EntPassiveStacks[self][effect] = (EntPassiveStacks[self][effect] or 1) + amount

            if self:IsPlayer() then
                net.Start("SEF_StackSystem")
                net.WriteString("ADD")
                net.WriteString(effect)
                net.WriteInt(amount, 32)
                net.Send(self)
            end
        else
            print("[Status Effect Framework] Effect or passive not found:", effect)
            return
        end
    end

    function ENTITY:SetSEFStacks(effect, amount)
        local effectData = StatusEffects[effect] or PassiveEffects[effect]
    
        -- Sprawdzenie, czy efekt/pasywka istnieje i czy jest stackowalna
        if not effectData or not effectData.Stackable then
            print("[Status Effect Framework] Effect or passive is not stackable or does not exist: ", effect)
            return
        end
    
        if StatusEffects[effect] then
            EntEffectStacks[self] = EntEffectStacks[self] or {}
            EntEffectStacks[self][effect] = amount

            if self:IsPlayer() then
                net.Start("SEF_StackSystem")
                net.WriteString("SET")
                net.WriteString(effect)
                net.WriteInt(amount, 32)
                net.Send(self)
            end

        elseif PassiveEffects[effect] then
            EntPassiveStacks[self] = EntPassiveStacks[self] or {}
            EntPassiveStacks[self][effect] = amount

            if self:IsPlayer() then
                net.Start("SEF_StackSystem")
                net.WriteString("SET")
                net.WriteString(effect)
                net.WriteInt(amount, 32)
                net.Send(self)
            end
        else
            print("[Status Effect Framework] Effect or passive not found:", effect)
            return
        end
    end
    
    
    
    function ENTITY:RemoveSEFStacks(effect, amount)
        amount = amount or 1

        local effectData = StatusEffects[effect] or PassiveEffects[effect]
        if not effectData or not effectData.Stackable then
            print("[Status Effect Framework] Effect or passive is not stackable or does not exist: ", effect)
            return
        end
    
        if StatusEffects[effect] then
            if EntEffectStacks[self] and EntEffectStacks[self][effect] then
                EntEffectStacks[self][effect] = EntEffectStacks[self][effect] - amount
                if EntEffectStacks[self][effect] <= 0 then
                    EntEffectStacks[self][effect] = nil
                end
            end

            if self:IsPlayer() then
                net.Start("SEF_StackSystem")
                net.WriteString("REMOVE")
                net.WriteString(effect)
                net.WriteInt(amount, 32)
                net.Send(self)
                net.Abort()
            end

        elseif PassiveEffects[effect] then
            if EntPassiveStacks[self] and EntPassiveStacks[self][effect] then
                EntPassiveStacks[self][effect] = EntPassiveStacks[self][effect] - amount
                if EntPassiveStacks[self][effect] <= 0 then
                    EntPassiveStacks[self][effect] = nil
                end
            end

            if self:IsPlayer() then
                net.Start("SEF_StackSystem")
                net.WriteString("REMOVE")
                net.WriteString(effect)
                net.WriteInt(amount, 32)
                net.Send(self)
                net.Abort()
            end
        else
            print("Effect or passive not found:", effect)
        end
    end
    
    function ENTITY:ResetSEFStacks(effect)

        local effectData = StatusEffects[effect] or PassiveEffects[effect]
        if not effectData or not effectData.Stackable then
            print("[Status Effect Framework] Effect or passive is not stackable or does not exist: ", effect)
            return
        end

        if StatusEffects[effect] then
            if EntEffectStacks[self] then
                EntEffectStacks[self][effect] = nil

                if self:IsPlayer() then
                    net.Start("SEF_StackSystem")
                    net.WriteString("CLEAR")
                    net.WriteString(effect)
                    net.WriteInt(0, 32)
                    net.Send(self)
                    net.Abort()
                end

            end
        elseif PassiveEffects[effect] then
            if EntPassiveStacks[self] then
                EntPassiveStacks[self][effect] = nil

                if self:IsPlayer() then
                    net.Start("SEF_StackSystem")
                    net.WriteString("CLEAR")
                    net.WriteString(effect)
                    net.WriteInt(0, 32)
                    net.Send(self)
                    net.Abort()
                end

            end
        else
            print("Effect or passive not found:", effect)
        end
    end
    
    function ENTITY:ClearSEFStacks()
        EntEffectStacks[self] = nil
        EntPassiveStacks[self] = nil

        if self:IsPlayer() then
            net.Start("SEF_StackSystem")
            net.WriteString("CLEARALL")
            net.WriteString("0")
            net.WriteInt(0, 32)
            net.Send(self)
            net.Abort()
        end
    end
    
    function ENTITY:GetSEFStacks(effect)

        local effectData = StatusEffects[effect] or PassiveEffects[effect]
        if not effectData or not effectData.Stackable then
            print("[Status Effect Framework] Effect or passive is not stackable or does not exist: ", effect)
            return
        end

        if StatusEffects[effect] then
            return (EntEffectStacks[self] and EntEffectStacks[self][effect]) or 0
        elseif PassiveEffects[effect] then
            return (EntPassiveStacks[self] and EntPassiveStacks[self][effect]) or 0
        else
            print("Effect or passive not found:", effect)
            return 0
        end
    end
    
    local function InitializeForEnt(ent)
        if not IsValid(ent) then return end
        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
            if not EntBaseStats[ent] then
                InitEntityBaseStats(ent)
                if GetConVar("SEF_LoggingMode"):GetBool() then
                    PrintMessage(HUD_PRINTTALK, "Created Base Stats for: " .. tostring(ent))
                end
            end
        end
    end

    hook.Add("OnEntityCreated", "InitBaseStatsOnSpawn", function(ent)
        timer.Simple(0, function()
            InitializeForEnt(ent)
        end)
    end)

    hook.Add("EntityRemoved", "RemoveEntityBaseStats", function(ent)
        if EntBaseStats[ent] then
            EntBaseStats[ent] = nil
            if GetConVar("SEF_LoggingMode"):GetBool() then
                PrintMessage(HUD_PRINTTALK, "Removed Base Stats for: " .. tostring(ent))
            end
        end
    end)

    timer.Simple(5, function()
        for _, ent in ipairs(ents.GetAll()) do
            InitializeForEnt(ent)
        end
    end)



    local function FindPlayerByName(name)
        name = string.lower(name)
        for _, ply in ipairs(player.GetAll()) do
            if string.find(string.lower(ply:Nick()), name, 1, true) then
                return ply
            end
        end
        return nil
    end

    -- Komenda do nakładania efektu
    concommand.Add("SEF_GiveEffect", function(ply, cmd, args)
        if #args < 3 then
            print("Usage: SEF_GiveEffect <effectName> <playerName> <time> [<arg1> <arg2> ...]")
            return
        end

        local effectName = args[1]
        local playerName = args[2]
        local time

        if args[3] == "inf" then
            time = math.huge
        else
            time = tonumber(args[3])
        end

        local effectArgs = {}
        for i = 4, #args do
            table.insert(effectArgs, tonumber(args[i]) or args[i])  -- Przekonwertuj na liczby lub zachowaj stringi
        end

        local targetPlayer = FindPlayerByName(playerName)
        if IsValid(targetPlayer) and targetPlayer:IsPlayer() then
            if #args > 3 then
                targetPlayer:ApplyEffect(effectName, time, unpack(effectArgs))
                print(string.format("[Status Effect Framework] Applied effect '%s' to player '%s' for %d seconds with args: %s", effectName, targetPlayer:Nick(), time, table.concat(effectArgs, ", ")))
            else
                targetPlayer:ApplyEffect(effectName, time)
                print(string.format("[Status Effect Framework] Applied effect '%s' to player '%s' for %d seconds",  effectName, targetPlayer:Nick(), time))
            end
        else
            print("[Status Effect Framework] Player not found or invalid player name:", playerName)
        end
    end)

    concommand.Add("SEF_GivePassive", function(ply, cmd, args)
        if #args < 2 then
            print("Usage: SEF_GivePassive <passiveName> <playerName>")
            return
        end

        local passiveName = args[1]
        local playerName = args[2]

        local targetPlayer = FindPlayerByName(playerName)
        if IsValid(targetPlayer) and targetPlayer:IsPlayer() then
            if #args > 1 then
                targetPlayer:ApplyPassive(passiveName)
                print(string.format("[Status Effect Framework] Applied Passive Effect '%s' to player '%s'", passiveName, targetPlayer:Nick()))
            end
        else
            print("[Status Effect Framework] Player not found or invalid player name:", playerName)
        end
    end)

    concommand.Add("SEF_RemovePassive", function(ply, cmd, args)
        if #args < 2 then
            print("Usage: SEF_RemovePassive <passiveName> <playerName>")
            return
        end

        local passiveName = args[1]
        local playerName = args[2]

        local targetPlayer = FindPlayerByName(playerName)
        if IsValid(targetPlayer) and targetPlayer:IsPlayer() then
            if #args > 1 then
                targetPlayer:RemovePassive(passiveName)
                print(string.format("[Status Effect Framework] Removed Passive Effect '%s' from player '%s'", passiveName, targetPlayer:Nick()))
            end
        else
            print("[Status Effect Framework] Player not found or invalid player name:", playerName)
        end
    end)
else

    local PLAYERCLIENT = FindMetaTable("Player")
    local ENTITYCLIENT = FindMetaTable("Entity")

    function PLAYERCLIENT:HaveEffect(effectName)
        if ActiveEffects[effectName] then
            return true
        else
            return false
        end
    end

    function PLAYERCLIENT:HavePassive(effectName)
        if ActivePassives[effectName] then
            return true
        else
            return false
        end
    end

    function PLAYERCLIENT:GetTimeLeft(effectName)
        if ActiveEffects[effectName] then
            local effectData = ActiveEffects[effectName]
            local elapsedTime = CurTime() - effectData.StartTime
            local remainingTime = effectData.Duration - elapsedTime
            return math.max(remainingTime, 0)
        else
            return 0 
        end
    end

    function ENTITYCLIENT:GetEntTimeLeft(effectName)
        if AllEntEffects[self][effectName] then
            local effectData = AllEntEffects[self][effectName]
            local elapsedTime = CurTime() - effectData.StartTime
            local remainingTime = effectData.Duration - elapsedTime
            return math.max(remainingTime, 0)
        else
            return 0 
        end
    end

    function PLAYERCLIENT:GetSEFStacks(effectName)

        if PlayerEffectStacks[effectName] then
            return PlayerEffectStacks[effectName]
        end

        if PlayerPassiveStacks[effectName] then
            return PlayerPassiveStacks[effectName]
        end
        
        return 0
    end
end
