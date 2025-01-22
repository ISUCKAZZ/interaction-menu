if SERVER then
    util.AddNetworkString("MugNotification")
    util.AddNetworkString("WarnNotification")
    util.AddNetworkString("RequestPlayerStatus")
    util.AddNetworkString("SendPlayerStatus")

    local mugCooldowns = {}
    local MAX_MUG_AMOUNT = 15000
    local DEFAULT_MUG_COOLDOWN = 300

    local function CanMug(target)
        return not mugCooldowns[target] or CurTime() > mugCooldowns[target]
    end

    local function SetMugCooldown(target, cooldown)
        mugCooldowns[target] = CurTime() + (cooldown or DEFAULT_MUG_COOLDOWN)
    end

    net.Receive("WarnNotification", function(len, ply)
        local target = net.ReadEntity()

        if IsValid(target) and target:IsPlayer() then
            target:SendLua("notification.AddLegacy('" .. ply:Nick() .. " is warning you about a mugging!', NOTIFY_HINT, 5)")
        end
    end)

    net.Receive("MugNotification", function(len, ply)
        local target = net.ReadEntity()
        local amount = net.ReadInt(32)
        local cooldown = net.ReadInt(32)
        local MAX_DISTANCE = 75 -- Define the max distance allowed for mugging
    
        
        if IsValid(target) and target:IsPlayer() and ply:GetPos():Distance(target:GetPos()) <= MAX_DISTANCE then
            if CanMug(target) then
                if amount > MAX_MUG_AMOUNT then
                    ply:SendLua("notification.AddLegacy('You cannot mug more than $" .. MAX_MUG_AMOUNT .. ".', NOTIFY_ERROR, 5)")
                    return
                end
    
                if target:canAfford(amount) then
                    target:addMoney(-amount)
                    ply:addMoney(amount)
                    SetMugCooldown(target, cooldown)
    
                    target:SendLua("notification.AddLegacy('You were mugged by " .. ply:Nick() .. " for $" .. amount .. "!', NOTIFY_ERROR, 5)")
                    ply:SendLua("notification.AddLegacy('You successfully mugged " .. target:Nick() .. " for $" .. amount .. "!', NOTIFY_GENERIC, 5)")
                else
                    ply:SendLua("notification.AddLegacy('" .. target:Nick() .. " cannot afford to pay your mugging demand.', NOTIFY_ERROR, 5)")
                end
            else
                ply:SendLua("notification.AddLegacy('You cannot mug " .. target:Nick() .. " yet. Cooldown active.', NOTIFY_ERROR, 5)")
            end
        else
            ply:SendLua("notification.AddLegacy('You are too far away to mug " .. (IsValid(target) and target:Nick() or "this player") .. ".', NOTIFY_ERROR, 5)")
        end
    end)
    
    net.Receive("RequestPlayerStatus", function(len, ply)
        local target = net.ReadEntity()

        if IsValid(target) and target:IsPlayer() then
            local hasGunLicense = target:getDarkRPVar("HasGunlicense") or false
            local gunLicenseGiver = target:getDarkRPVar("GunLicenseGiver") or "Unknown"

            net.Start("SendPlayerStatus")
            net.WriteEntity(target)
            net.WriteBool(hasGunLicense)
            net.WriteString(gunLicenseGiver)
            net.Send(ply)
        end
    end)
end

if CLIENT then
    local function GetChestBonePosition(targetPlayer)
        local chestBone = targetPlayer:LookupBone("ValveBiped.Bip01_Spine2")
        if chestBone then
            return targetPlayer:GetBonePosition(chestBone)
        else
            return targetPlayer:EyePos() - Vector(0, 0, 10)
        end
    end

    local InteractionMenu = nil
    local warnedPlayers = {}
    local eLabel = nil
    local mugCooldown = {}
    local IsAmountMenuOpen = false 

    local targetPlayerStatus = {
        gunLicense = false,
        gunLicenseGiver = "Unknown"
    }

    net.Receive("SendPlayerStatus", function()
        local target = net.ReadEntity()
        local hasGunLicense = net.ReadBool()
        local gunLicenseGiver = net.ReadString()

        if IsValid(target) then
            targetPlayerStatus.gunLicense = hasGunLicense
            targetPlayerStatus.gunLicenseGiver = gunLicenseGiver
        end
    end)

    local function GetRankColor(rank)
        local rainbowRanks = {"superadmin", "vip", "vip+", "vip++"}
        if table.HasValue(rainbowRanks, string.lower(rank)) then
            return HSVToColor((CurTime() * 50) % 360, 1, 1)
        end
        return Color(255, 255, 255)
    end

    local function CreateAmountMenu(title, prompt, maxAmount, onSubmit)
        if IsAmountMenuOpen then return end 
        IsAmountMenuOpen = true 

        local frame = vgui.Create("DFrame")
        frame:SetSize(300, 150)
        frame:SetTitle("")
        frame:ShowCloseButton(false)
        frame:SetDraggable(false)
        frame:Center()
        frame:MakePopup()
        frame.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(40, 40, 40, 230))
            draw.SimpleText(title, "DermaLarge", w / 2, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            draw.SimpleText(prompt, "DermaDefaultBold", w / 2, 50, Color(200, 200, 200), TEXT_ALIGN_CENTER)
        end

        local textEntry = vgui.Create("DTextEntry", frame)
        textEntry:SetSize(280, 30)
        textEntry:SetPos(10, 70)
        textEntry:SetFont("DermaDefault")
        textEntry:SetPlaceholderText("Enter amount here...")

        local okButton = vgui.Create("DButton", frame)
        okButton:SetSize(135, 30)
        okButton:SetPos(10, 110)
        okButton:SetText("OK")
        okButton:SetFont("DermaDefaultBold")
        okButton:SetTextColor(Color(255, 255, 255))
        okButton.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(0, 150, 0, 200))
        end
        okButton.DoClick = function()
            local amount = tonumber(textEntry:GetValue())
            if amount and amount > 0 and (not maxAmount or amount <= maxAmount) then
                onSubmit(amount)
                frame:Close()
            else
                chat.AddText(Color(255, 0, 0), "Invalid amount.")
            end
        end

        local cancelButton = vgui.Create("DButton", frame)
        cancelButton:SetSize(135, 30)
        cancelButton:SetPos(155, 110)
        cancelButton:SetText("Cancel")
        cancelButton:SetFont("DermaDefaultBold")
        cancelButton:SetTextColor(Color(255, 255, 255))
        cancelButton.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(150, 0, 0, 200))
        end
        cancelButton.DoClick = function()
            frame:Close()
        end

        frame.OnClose = function()
            IsAmountMenuOpen = false 
        end
    end

    local function CreateInteractionMenu(targetPlayer)
        if IsValid(InteractionMenu) then
            InteractionMenu:Remove()
        end

        gui.EnableScreenClicker(true)
        if IsValid(eLabel) then eLabel:SetVisible(false) end

        
        net.Start("RequestPlayerStatus")
        net.WriteEntity(targetPlayer)
        net.SendToServer()

        local frame = vgui.Create("DFrame")
        frame:SetSize(200, 180)
        frame:SetTitle("")
        frame:ShowCloseButton(false)
        frame:SetDraggable(false)
        frame:SetAlpha(0)
        frame:AlphaTo(255, 0.5, 0)
        frame.Paint = function(self, w, h)
            draw.RoundedBox(12, 0, 0, w, h, Color(0, 0, 0, 200))
            surface.SetDrawColor(50, 50, 50, 200)
            surface.DrawOutlinedRect(0, 0, w, h)

            local rank = targetPlayer:GetUserGroup() or "Unknown Rank"
            local rankColor = GetRankColor(rank)
            draw.SimpleText(rank, "DermaLarge", w / 2, 10, rankColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        
        local function CreateButton(parent, text, posY, callback)
            local btn = vgui.Create("DButton", parent)
            btn:SetText(text)
            btn:SetSize(180, 35)
            btn:SetPos(10, posY)
            btn:SetFont("DermaDefaultBold")
            btn:SetTextColor(Color(255, 255, 255))
            btn.Paint = function(self, w, h)
                local bgColor = self:IsHovered() and Color(50, 50, 50, 200) or Color(30, 30, 30, 200)
                draw.RoundedBox(10, 0, 0, w, h, bgColor)
            end
            btn.DoClick = callback
        end

        CreateButton(frame, "Give Money", 50, function()
            CreateAmountMenu(
                "Give Money",
                "Enter the amount to give:",
                nil,
                function(amount)
                    LocalPlayer():ConCommand("say /give " .. amount)
                end
            )
        end)

        CreateButton(frame, "Mug", 100, function()
            local playerId = targetPlayer:SteamID()
            local currentTime = CurTime()

            if mugCooldown[playerId] and currentTime < mugCooldown[playerId] then
                local remainingTime = math.ceil(mugCooldown[playerId] - currentTime)
                chat.AddText(Color(255, 0, 0), "You must wait " .. remainingTime .. " seconds before mugging again.")
                return
            end

            if not warnedPlayers[targetPlayer] then
                net.Start("WarnNotification")
                net.WriteEntity(targetPlayer)
                net.SendToServer()
                warnedPlayers[targetPlayer] = true
            else
                CreateAmountMenu(
                    "Mugging Amount",
                    "Enter the amount to mug (Max: $15,000):",
                    15000,
                    function(amount)
                        net.Start("MugNotification")
                        net.WriteEntity(targetPlayer)
                        net.WriteInt(amount, 32)
                        net.SendToServer()

                        mugCooldown[playerId] = currentTime + 135 -- Custom cooldown
                    end
                )
            end
        end)

      
        local licenseIcon = vgui.Create("DImage", frame)
        licenseIcon:SetSize(16, 16)
        licenseIcon:SetPos(10, 145)

        if targetPlayerStatus.gunLicense then
            licenseIcon:SetImage("icon16/gun.png")
            licenseIcon:SetToolTip("Gun License given by: " .. targetPlayerStatus.gunLicenseGiver)
        else
            licenseIcon:SetImage("icon16/cross.png")
            licenseIcon:SetToolTip("No Gun License")
        end

       
        net.Receive("SendPlayerStatus", function()
            local receivedTarget = net.ReadEntity()
            if receivedTarget == targetPlayer then
                targetPlayerStatus.gunLicense = net.ReadBool()
                targetPlayerStatus.gunLicenseGiver = net.ReadString()

                
                if targetPlayerStatus.gunLicense then
                    licenseIcon:SetImage("icon16/gun.png")
                    licenseIcon:SetToolTip("Gun License given by: " .. targetPlayerStatus.gunLicenseGiver)
                else
                    licenseIcon:SetImage("icon16/cross.png")
                    licenseIcon:SetToolTip("No Gun License")
                end
            end
        end)

        hook.Add("Think", "UpdateInteractionMenuPosition", function()
            if IsValid(targetPlayer) and IsValid(frame) then
                local chestPos = GetChestBonePosition(targetPlayer)
                local pos = chestPos:ToScreen()
                frame:SetPos(pos.x - frame:GetWide() - 200, pos.y - 180)

                if LocalPlayer():GetPos():Distance(targetPlayer:GetPos()) > 75 then
                    frame:AlphaTo(0, 0.5, 0, function()
                        frame:Remove()
                    end)
                    gui.EnableScreenClicker(false)
                    hook.Remove("Think", "UpdateInteractionMenuPosition")
                end
            end
        end)

        InteractionMenu = frame
    end

    hook.Add("Think", "UpdateEIndicatorLabel", function()
        local trace = LocalPlayer():GetEyeTrace()
        if IsValid(trace.Entity) and trace.Entity:IsPlayer() and not IsValid(InteractionMenu) then
            local targetPlayer = trace.Entity
            if not IsValid(eLabel) then
                eLabel = vgui.Create("DLabel")
                eLabel:SetText("Press E")
                eLabel:SetFont("DermaDefaultBold")
                eLabel:SetColor(Color(255, 255, 255))
                eLabel:SizeToContents()
            end

            local chestPos = GetChestBonePosition(targetPlayer)
            local pos = chestPos:ToScreen()

            eLabel:SetPos(pos.x - eLabel:GetWide() / 2, pos.y - 20)
            eLabel:SetVisible(LocalPlayer():GetPos():Distance(targetPlayer:GetPos()) <= 75)
        elseif IsValid(eLabel) then
            eLabel:SetVisible(false)
        end
    end)

    hook.Add("KeyPress", "OpenInteractionMenu", function(ply, key)
        if key == IN_USE then
            local trace = ply:GetEyeTrace()
            if IsValid(trace.Entity) and trace.Entity:IsPlayer() and ply:GetPos():Distance(trace.Entity:GetPos()) <= 75 then
                CreateInteractionMenu(trace.Entity)
            end
        end
    end)

    hook.Add("KeyRelease", "CloseInteractionMenu", function(ply, key)
        if key == IN_USE and IsValid(InteractionMenu) then
            InteractionMenu:AlphaTo(0, 0.5, 0, function()
                InteractionMenu:Remove()
            end)
            gui.EnableScreenClicker(false)
        end
    end)
end
