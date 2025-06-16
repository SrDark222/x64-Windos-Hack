local redzlib = loadstring(game:HttpGet("https://raw.githubusercontent.com/SrDark222/SH_0001/refs/heads/main/inject%20R.Hub.lua"))()
local Window = redzlib:MakeWindow({
	Title = "T.C.C H4x V16",
	SubTitle = "by DKZIN",
	SaveFolder = "pathv16.lua"
})
Window:AddMinimizeButton({Button = {Image = "rbxassetid://14041446096"}, Corner = {CornerRadius = UDim.new(0.3, 1)}})
local PathTab = Window:MakeTab({"menu", "wifi"})
PathTab:AddSection({"OPCOES - PRINCIPAIS"})

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local following, autoFollow, autoJump, noSit = false, false, false, false
local targetName = ""
local currentLines, headLine, lastHighlight = {}, nil, nil
local lastJumpTime = 0
local jumpCooldown = 1.0

local function getRoot(c) return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart) end
local function getHumanoid(c) return c and c:FindFirstChildWhichIsA("Humanoid") end

local function clearVisuals()
	for _, v in pairs(currentLines) do if v and v.Parent then v:Destroy() end end
	currentLines = {}
	if lastHighlight then lastHighlight:Destroy() lastHighlight = nil end
	if headLine and headLine.Parent then headLine:Destroy() headLine = nil end
end

local function createPathLines(waypoints, color)
	clearVisuals()
	for i = 1, #waypoints - 1 do
		local a, b = waypoints[i].Position + Vector3.new(0,3,0), waypoints[i+1].Position + Vector3.new(0,3,0)
		local dist = (b - a).Magnitude
		local part = Instance.new("Part", workspace)
		part.Anchored = true part.CanCollide = false part.Transparency = 0
		part.Color = color part.Material = Enum.Material.Neon
		part.Size = Vector3.new(0.1, 0.1, dist)
		part.CFrame = CFrame.new(a, b) * CFrame.new(0, 0, -dist/2)
		table.insert(currentLines, part)
		local hl = Instance.new("Highlight", part)
		hl.FillColor = color hl.OutlineColor = Color3.new(0, 0, 0)
		hl.FillTransparency = 0.3 hl.OutlineTransparency = 0.2
	end
end

local function createHeadLine(target)
	if headLine and headLine.Parent then headLine:Destroy() end
	local myHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
	local hisHead = target.Character and target.Character:FindFirstChild("Head")
	if myHead and hisHead then
		local att0 = Instance.new("Attachment", myHead)
		local att1 = Instance.new("Attachment", hisHead)
		local beam = Instance.new("Beam", myHead)
		beam.Attachment0 = att0 beam.Attachment1 = att1
		beam.FaceCamera = true beam.Width0 = 0.1 beam.Width1 = 0.1
		beam.Color = ColorSequence.new(Color3.fromRGB(255,255,0))
		beam.LightEmission = 1 beam.Transparency = NumberSequence.new(0.1)
		headLine = beam
	end
end

local function highlightTarget(char, color)
	if lastHighlight then lastHighlight:Destroy() end
	local hl = Instance.new("Highlight", workspace)
	hl.Adornee = char hl.FillColor = color hl.OutlineColor = color
	hl.FillTransparency = 0.3 hl.OutlineTransparency = 0
	lastHighlight = hl
end

local function moveTo(hum, root, pos)
	hum:MoveTo(pos)
	local done, timeout = false, tick() + 2
	local conn = hum.MoveToFinished:Connect(function(ok) done = ok end)
	while not done and tick() < timeout and root.Parent do task.wait(0.01) end
	conn:Disconnect()
	return done
end

local function resetChar()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = getHumanoid(char)
	local root = getRoot(char)
	if hum then
		hum.WalkSpeed = 16
		hum.AutoRotate = true
		hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
	end
	clearVisuals()
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if not (following or autoFollow) then continue end
		local char = LocalPlayer.Character
		if not char then continue end
		local hum = getHumanoid(char)
		local root = getRoot(char)
		if not hum or not root then continue end

		hum.AutoRotate = false
		hum.WalkSpeed = 50
		if hum.SeatPart then hum.Sit = false end

		local bestTarget = nil
		local bestPathLength = math.huge
		local bestPathWaypoints = nil

		if following then
			if targetName == nil or targetName == "" then
				-- se nome alvo vazio, desliga o follow
				following = false
				hum.WalkSpeed = 16
				hum.AutoRotate = true
				clearVisuals()
				continue
			end
			for _, p in pairs(Players:GetPlayers()) do
				if p.Name:lower():find(targetName:lower()) and p ~= LocalPlayer and p.Character and getRoot(p.Character) then
					local pRoot = getRoot(p.Character)
					local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
					local success, err = pcall(function()
						path:ComputeAsync(root.Position, pRoot.Position)
					end)
					if success and path.Status == Enum.PathStatus.Success then
						local wps = path:GetWaypoints()
						local length = 0
						for i = 1, #wps - 1 do
							length += (wps[i].Position - wps[i+1].Position).Magnitude
						end
						if length < bestPathLength then
							bestPathLength = length
							bestTarget = p
							bestPathWaypoints = wps
						end
					end
				end
			end
		elseif autoFollow then
			for _, p in pairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and p.Character and getRoot(p.Character) then
					local pRoot = getRoot(p.Character)
					local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
					local success, err = pcall(function()
						path:ComputeAsync(root.Position, pRoot.Position)
					end)
					if success and path.Status == Enum.PathStatus.Success then
						local wps = path:GetWaypoints()
						local length = 0
						for i = 1, #wps - 1 do
							length += (wps[i].Position - wps[i+1].Position).Magnitude
						end
						if length < bestPathLength then
							bestPathLength = length
							bestTarget = p
							bestPathWaypoints = wps
						end
					end
				end
			end
		end

		if bestTarget and bestPathWaypoints then
			createPathLines(bestPathWaypoints, Color3.fromRGB(255,255,0))
			highlightTarget(bestTarget.Character, Color3.fromRGB(255,255,0))
			createHeadLine(bestTarget)

			for _, wp in ipairs(bestPathWaypoints) do
				if not (following or autoFollow) then break end
				if wp.Action == Enum.PathWaypointAction.Jump and tick() - lastJumpTime >= jumpCooldown then
					lastJumpTime = tick()
					local hum = getHumanoid(LocalPlayer.Character)
					if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
				end
				local char = LocalPlayer.Character
				local root = getRoot(char)
				if root then
					local look = Vector3.new(wp.Position.X, root.Position.Y, wp.Position.Z)
					if (look - root.Position).Magnitude > 5 then
						pcall(function() root.CFrame = CFrame.lookAt(root.Position, look) end)
					end
				end
				moveTo(getHumanoid(LocalPlayer.Character), getRoot(LocalPlayer.Character), wp.Position)
			end
		else
			clearVisuals()
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if not autoJump then return end
	local char = LocalPlayer.Character
	if not char then return end
	local root = getRoot(char)
	local hum = getHumanoid(char)
	if not root or not hum then return end

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {char}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist

	for _, dir in ipairs({Vector3.new(2, 0, 0), Vector3.new(-2, 0, 0), Vector3.new(0, 0, 2), Vector3.new(0, 0, -2)}) do
		local hit = workspace:Raycast(root.Position, dir, rayParams)
		if hit and tick() - lastJumpTime >= jumpCooldown then
			lastJumpTime = tick()
			if hum:GetState() ~= Enum.HumanoidStateType.Jumping then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
			break
		end
	end
end)

local killdropdown = nil
PathTab:AddTextBox({Name = "NICK DO ALVO", PlaceholderText = "ex: dkzin", Callback = function(v) targetName = v end})
killdropdown = PathTab:AddDropdown({Name = "LISTA DE JOGADORES", Options = {}, Callback = function(v) targetName = v end})
PathTab:AddButton({
	Name = "ATUALIZAR LISTA",
	Callback = function()
		local lista = {}
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then table.insert(lista, p.Name) end
		end
		for _, m in pairs({"Clear","Add","SetOptions","Update","Set","Refresh"}) do
			pcall(function() if killdropdown[m] then killdropdown[m](killdropdown, lista) end end)
		end
	end
})

PathTab:AddToggle({Name = "SEGUIR ALVO SELECIONADO", Default = false, Callback = function(v)
	if v then
		if targetName == nil or targetName == "" then
			following = false
			local hum = getHumanoid(LocalPlayer.Character)
			if hum then
				hum.WalkSpeed = 16
				hum.AutoRotate = true
			end
			clearVisuals()
			PathTab:SetToggle("SEGUIR ALVO SELECIONADO", false)
		else
			following = true
		end
	else
		following = false
		local hum = getHumanoid(LocalPlayer.Character)
		if hum then
			hum.WalkSpeed = 16
			hum.AutoRotate = true
		end
		clearVisuals()
	end
end})

PathTab:AddToggle({Name = "SEGUIR O MAIS PRÓXIMO", Default = false, Callback = function(v)
	autoFollow = v
	if not v then
		local hum = getHumanoid(LocalPlayer.Character)
		if hum then
			hum.WalkSpeed = 16
			hum.AutoRotate = true
		end
		clearVisuals()
	end
end})

PathTab:AddSection({"OPCOES - RECOMENDADA"})
PathTab:AddToggle({Name = "AUTO JUMP", Default = false, Callback = function(v)
	autoJump = v
	if not v then
		local hum = getHumanoid(LocalPlayer.Character)
		if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
	end
end})

PathTab:AddToggle({
	Name = "NÃO SENTAR",
	Default = false,
	Callback = function(state)
		noSit = state
		local hum = getHumanoid(LocalPlayer.Character)
		if hum then
			hum:SetStateEnabled(Enum.HumanoidStateType.Seated, not state)
			if state and hum.SeatPart then hum.Sit = false end
		end
		if not state then
			local hum = getHumanoid(LocalPlayer.Character)
			if hum then
				hum.WalkSpeed = 16
				hum.AutoRotate = true
			end
		end
	end
})


local InfoTab = Window:MakeTab({"info", "info"})
-- Convite no topo, chamando a atenção dos cria
InfoTab:AddSection("Convite Oficial")
InfoTab:AddDiscordInvite({
  Name = "T.C.C Hub",
  Description = "Cola no servidor pra updates, ajuda e novidades",
  Logo = "rbxassetid://18751483361",
  Invite = "discord.gg/fjZRjEcpwV"
})

local Section = InfoTab:AddSection({"developers"})
local Paragraph = InfoTab:AddParagraph({"CREDITOS", "- UI FEITA POR DK\n- CODIGO FEITO POR DK\n- T.C.C"})

local Paragraph = InfoTab:AddParagraph({"discord", "- Support & dúvidas no server do T.C.C Oficial\n- Qalquer dúvidas chame por prdavi_73322 --> MENOR DK"})

local Dialog = Window:Dialog({
  Title = "Aviso",
  Text = "Acesse nosso server do discord para mais scripts",
  Options = {
    {"ok", function()
      
    end},
  }
})
