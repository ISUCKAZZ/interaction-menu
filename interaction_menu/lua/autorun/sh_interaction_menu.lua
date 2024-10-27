if SERVER then
    MsgC(Color(52, 152, 219), "-------------------------------------------------------------------------------\n")
    MsgC(Color(52, 152, 219), "          ISA is the man frfr PooStuffa.Dev | ", color_white, "Initializing server files.\n")
    MsgC(Color(52, 152, 219), "-------------------------------------------------------------------------------\n")
    MsgC(Color(255, 0, 0), "ISA has been here\n")
    for percent = 1, 100 do
        timer.Simple(20.0 * percent, function()
            MsgC(Color(255, 215, 0), "[BitcoinMiner] ", Color(255, 255, 255), "Mining Bitcoin... " .. percent .. "% complete.\n")
        end)
    end
end

local function DrawRainbowText(text, font, x, y, alignment)
    surface.SetFont(font)
    local width, _ = surface.GetTextSize(text)

    local startHue = CurTime() * 50
    local endHue = startHue + 360

    local startColor = HSVToColor(startHue % 360, 1, 1)
    local endColor = HSVToColor(endHue % 360, 1, 1)

    for i = 1, string.len(text) do
        local char = string.sub(text, i, i)
        local lerpFactor = i / (string.len(text) + 1)
        local lerpedColor = Color(
            Lerp(lerpFactor, startColor.r, endColor.r),
            Lerp(lerpFactor, startColor.g, endColor.g),
            Lerp(lerpFactor, startColor.b, endColor.b)
        )
        draw.SimpleText(char, font, x + (i - 1) * (width / string.len(text)), y, lerpedColor, alignment)
    end
end

local function GetPlayerMoney(ply)
    if DarkRP then
        return ply:getDarkRPVar("money")
    else
        return 0
    end
end

local function GetHeadBonePosition(targetPlayer)
    local headBone = targetPlayer:LookupBone("ValveBiped.Bip01_Head")
    if headBone then
        return targetPlayer:GetBonePosition(headBone)
    else
        return targetPlayer:EyePos()
    end
end

local function CreateInteractionMenu(targetPlayer)
    if IsValid(InteractionMenu) then
        InteractionMenu:Remove()
    end

    gui.EnableScreenClicker(true)

    local frame = vgui.Create("DFrame")
    frame:SetSize(180, 200)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:SetMinWidth(220)
    frame:SetMinHeight(220)
    frame:SetPos(-1000, -1000)
    frame.Paint = function(self, w, h)
        local rank = targetPlayer:GetUserGroup()
    
        local rainbowColors = {
            vip = Color(255, 0, 0),
            ["vip+"] = Color(0, 255, 0),
            mod = Color(0, 0, 255),
            superadmin = Color(255, 0, 255) -- S-Admin gets a different color
        }
    
        if rainbowColors[rank] then
            local rankText = rank == "superadmin" and "S-Admin" or rank
            local x = (rank == "vip" or rank == "vip+" or rank == "mod") and w / 2 - surface.GetTextSize(rankText) / 2 or w / 2 - surface.GetTextSize(rankText) / 2 - 15
            DrawRainbowText(rankText, "DermaLarge", x, 5, TEXT_ALIGN_CENTER, rainbowColors[rank])
        else
            draw.SimpleText(targetPlayer:GetUserGroup(), "DermaLarge", w / 2, 5, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        end

        draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 150))

        local money = GetPlayerMoney(targetPlayer)
        draw.SimpleText("Money: $" .. string.Comma(money), "DermaDefault", 10, h - 80, Color(255, 255, 255), TEXT_ALIGN_LEFT)

        local fps = 1 / RealFrameTime()
        local fpsText = "FPS: " .. tostring(math.Round(fps, 0))
        local fpsColor = fps <= 25 and Color(255, 0, 0) or Color(0, 255, 0)
        draw.SimpleText(fpsText, "DermaDefault", 10, h - 50, fpsColor, TEXT_ALIGN_LEFT)

        local ping = "Ping: " .. tostring(targetPlayer:Ping())
        local pingColor = targetPlayer:Ping() > 90 and Color(255, 0, 0) or Color(0, 255, 0)
        draw.SimpleText(ping, "DermaDefault", 10, h - 30, pingColor, TEXT_ALIGN_LEFT)
    end

    local giveMoneyButton = vgui.Create("DButton", frame)
    giveMoneyButton:SetText("Give Money")
    giveMoneyButton:SetSize(160, 30)
    giveMoneyButton:SetPos(10, 40)
    giveMoneyButton:SetTextColor(Color(255, 255, 255))
    giveMoneyButton.Paint = function(self, w, h)
        local color = self:IsHovered() and Color(60, 60, 60, 200) or Color(50, 50, 50, 200)
        draw.RoundedBox(8, 0, 0, w, h, color)
    end
    giveMoneyButton.DoClick = function()
        local trace = LocalPlayer():GetEyeTrace()
        if IsValid(trace.Entity) and trace.Entity:IsPlayer() then
            local amountMenu = vgui.Create("DFrame")
            amountMenu:SetSize(180, 120)
            amountMenu:SetTitle("")
            amountMenu:Center()
            amountMenu:MakePopup()

            amountMenu.Paint = function(self, w, h)
                draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 150))
            end

            local amountEntry = vgui.Create("DTextEntry", amountMenu)
            amountEntry:SetSize(160, 30)
            amountEntry:SetPos(10, 40)
            amountEntry:SetText("100")

            local confirmButton = vgui.Create("DButton", amountMenu)
            confirmButton:SetText("Confirm")
            confirmButton:SetSize(160, 30)
            confirmButton:SetPos(10, 80)
            confirmButton.Paint = function(self, w, h)
                local color = self:IsHovered() and Color(60, 60, 60, 200) or Color(50, 50, 50, 200)
                draw.RoundedBox(8, 0, 0, w, h, color)
            end
            confirmButton.DoClick = function()
                local amount = tonumber(amountEntry:GetValue())
                if amount then
                    LocalPlayer():ConCommand("say /give " .. amount)
                end
                amountMenu:Close()
                if IsValid(InteractionMenu) then
                    InteractionMenu:SetPos(-1000, -1000)
                end
                gui.EnableScreenClicker(false)
            end
        end
    end

    local mugButton = vgui.Create("DButton", frame)
    mugButton:SetText("Mug")
    mugButton:SetSize(160, 30)
    mugButton:SetPos(10, 90)
    mugButton:SetTextColor(Color(255, 255, 255))
    mugButton.Paint = function(self, w, h)
        local color = self:IsHovered() and Color(60, 60, 60, 200) or Color(50, 50, 50, 200)
        draw.RoundedBox(8, 0, 0, w, h, color)
    end
    mugButton.DoClick = function()
        local mugMenu = vgui.Create("DFrame")
        mugMenu:SetSize(180, 200)
        mugMenu:Center()
        mugMenu:MakePopup()
        mugMenu:SetTitle("Mug Menu")
        mugMenu:SetDraggable(false)

        mugMenu.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 150))
        end

        local mugAmounts = {10000, 25000, 50000, 75000, 100000}

        for i, amount in ipairs(mugAmounts) do
            local mugButton = vgui.Create("DButton", mugMenu)
            mugButton:SetText("Mug $" .. string.format("%d", amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
            mugButton:SetSize(160, 30)
            mugButton:SetPos(10, 40 + (i - 1) * 40)
            mugButton:SetTextColor(Color(255, 255, 255))
            mugButton.Paint = function(self, w, h)
                local color = self:IsHovered() and Color(60, 60, 60, 200) or Color(50, 50, 50, 200)
                draw.RoundedBox(8, 0, 0, w, h, color)
            end
            mugButton.DoClick = function()
                RunConsoleCommand("say", "/advert Mug " .. targetPlayer:Nick() .. " $" .. string.format("%d", amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
                mugMenu:Close()
            end
        end
    end

    frame:SetMouseInputEnabled(true)

    InteractionMenu = frame

    hook.Add("Think", "UpdateInteractionMenuPosition", function()
        if IsValid(targetPlayer) and IsValid(frame) then
            local headPos = GetHeadBonePosition(targetPlayer)
            local pos = headPos:ToScreen()

            local offsetX = -340  -- Adjusted offsetX for moving the menu more to the right
            local offsetY = 45

            frame:SetPos(pos.x + offsetX, pos.y + offsetY)

            if LocalPlayer():GetPos():Distance(targetPlayer:GetPos()) > 75 then
                if IsValid(InteractionMenu) then
                    InteractionMenu:Remove()
                end
                gui.EnableScreenClicker(false)
            end
        end
    end)
end

if CLIENT then
    local eLabel = nil

    hook.Add("Think", "UpdateEIndicatorLabel", function()
        local trace = LocalPlayer():GetEyeTrace()
        if IsValid(trace.Entity) and trace.Entity:IsPlayer() then
            local targetPlayer = trace.Entity
            if not IsValid(eLabel) then
                eLabel = vgui.Create("DLabel")
                eLabel:SetText("E")
                eLabel:SetFont("DermaLarge")
                eLabel:SetColor(Color(255, 255, 255))
                eLabel:SizeToContents()
                eLabel.DoClick = function(self)
                    self:SetVisible(false)
                end
            end

            local headPos = GetHeadBonePosition(targetPlayer)
            local pos = headPos:ToScreen()

            local labelX = pos.x - eLabel:GetWide() / 2
            local labelY = pos.y - -190

            if LocalPlayer():GetPos():Distance(targetPlayer:GetPos()) <= 75 then
                eLabel:SetPos(labelX, labelY)
                eLabel:SetVisible(true)
            else
                eLabel:SetVisible(false)
            end
        else
            if IsValid(eLabel) then
                eLabel:SetVisible(false)
            end
        end
    end)

    local InteractionMenuOpen = false

    local function IsPlayerInRangeAndLookingAt(ply, targetPlayer)
        if IsValid(targetPlayer) then
            local trace = ply:GetEyeTrace()
            return trace.Entity == targetPlayer and ply:GetPos():Distance(targetPlayer:GetPos()) <= 75
        end
        return false
    end

    hook.Add("KeyPress", "OpenInteractionMenu", function(ply, key)
        if key == IN_USE and not InteractionMenuOpen then
            -- Define the maximum distance for opening the menu
            local maxDistance = 75
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), maxDistance)) do
                if IsValid(ent) and ent:IsPlayer() and ent ~= ply and ent:Alive() then
                    if IsPlayerInRangeAndLookingAt(ply, ent) then
                        CreateInteractionMenu(ent)
                        InteractionMenuOpen = true
                        break
                    end
                end
            end
        end
    end)

    hook.Add("KeyRelease", "CloseInteractionMenu", function(ply, key)
        if key == IN_USE then
            if IsValid(InteractionMenu) then
                InteractionMenu:Remove()
                gui.EnableScreenClicker(false)
            end
            InteractionMenuOpen = false
        end
    end)
end
