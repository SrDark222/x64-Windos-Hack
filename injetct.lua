-- INICIA UI  
local redzlib = loadstring(game:HttpGet("https://raw.githubusercontent.com/tbao143/Library-ui/refs/heads/main/Redzhubui"))()  
local Window = redzlib:MakeWindow({  
	Title = "T.C.C H4x V16",  
	SubTitle = "by DKZIN",  
	SaveFolder = "pathv16.lua"  
})  
Window:AddMinimizeButton({Button = {Image = "rbxassetid://71014873973869"}, Corner = {CornerRadius = UDim.new(0.5, 1)}})  
local PathTab = Window:MakeTab({"menu", "wifi"})  
PathTab:AddSection({"OPCOES - PRINCIPAIS"})  
  
-- UI VARS  
local targetName, killdropdown = "", nil  
local following, autoFollow, autoJump, noSit = false, false, false, false  
  
-- SERVIÇOS BASE  
local Players = game:GetService("Players")  
local PathfindingService = game:GetService("PathfindingService")  
local RunService = game:GetService("RunService")  
local UserInputService = game:GetService("UserInputService")  
local LocalPlayer = Players.LocalPlayer  
local currentLines, headLine, lastHighlight = {}, nil, nil  
local debouncePath = false  
local maxDistance = math.huge  
  
-- CONTROLE DE PULO  
local lastJumpTime = 0  
local jumpCooldown = 1.2 -- segundos entre pulos  
  
-- FUNÇÕES ÚTEIS  
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
	local done = false local timeout = tick() + 3  
	local conn = hum.MoveToFinished:Connect(function(ok) done = ok end)  
	while not done and tick() < timeout and root.Parent do task.wait(0.003) end  
	conn:Disconnect()  
	return done  
end  
  
local function canReachPath(startPos, endPos)  
	local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})  
	local success, err = pcall(function() path:ComputeAsync(startPos, endPos) end)  
	if not success then return false end  
	return path.Status == Enum.PathStatus.Success  
end  
  
local function loopFollow(getTargetFunc)  
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()  
	local hum = getHumanoid(char) local root = getRoot(char)  
	if not root or not hum then return end  
	hum.AutoRotate = false hum.WalkSpeed = 50  
	if hum.SeatPart then hum.Sit = false end  
  
	while (following or autoFollow) and char.Parent do  
		if debouncePath then task.wait(0.0003) continue end  
		debouncePath = true  
  
		local target = getTargetFunc()  
		if target and target.Character and getRoot(target.Character) then  
			local tRoot = getRoot(target.Character)  
			local dist = (root.Position - tRoot.Position).Magnitude  
  
			if dist > maxDistance then  
				clearVisuals()  
				highlightTarget(char, Color3.fromRGB(255, 0, 0))  
				task.wait(0.001)  
				debouncePath = false  
				continue  
			end  
  
			local color = Color3.fromRGB(255, 255, 0)  
			highlightTarget(target.Character, color)  
			createHeadLine(target)  
  
			local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})  
			pcall(function() path:ComputeAsync(root.Position, tRoot.Position) end)  
  
			if path.Status == Enum.PathStatus.Success then  
				local waypoints = path:GetWaypoints()  
				createPathLines(waypoints, color)  
				for _, wp in ipairs(waypoints) do  
					if not (following or autoFollow) then break end  
					if wp.Action == Enum.PathWaypointAction.Jump then  
						local now = tick()  
						if now - lastJumpTime >= jumpCooldown then  
							lastJumpTime = now  
							hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)  
							hum:ChangeState(Enum.HumanoidStateType.Jumping)  
						end  
					end  
					local lookPos = Vector3.new(wp.Position.X, root.Position.Y, wp.Position.Z)  
					if (lookPos - root.Position).Magnitude > 5 then  
						pcall(function() root.CFrame = CFrame.lookAt(root.Position, lookPos) end)  
					end  
					if not moveTo(hum, root, wp.Position) then break end  
				end  
			else  
				if dist <= maxDistance then hum:MoveTo(tRoot.Position)  
				else clearVisuals() highlightTarget(char, Color3.fromRGB(255, 0, 0)) end  
			end  
		else clearVisuals() end  
		task.delay(0.0005, function() debouncePath = false end)  
		task.wait(0.0003)  
	end  
  
	hum.WalkSpeed = 16 hum.AutoRotate = true clearVisuals()  
end  
  
RunService.Heartbeat:Connect(function()  
	if not autoJump then return end  
	local char = LocalPlayer.Character if not char then return end  
	local root = getRoot(char) local hum = getHumanoid(char) if not root or not hum then return end  
  
	local rayParams = RaycastParams.new()  
	rayParams.FilterDescendantsInstances = {char}  
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist  
  
	local directions = {  
		Vector3.new(2, 0, 0),  
		Vector3.new(-2, 0, 0),  
		Vector3.new(0, 0, 2),  
		Vector3.new(0, 0, -2)  
	}  
  
	local canJump = false  
	for _, dir in ipairs(directions) do  
		local result = workspace:Raycast(root.Position, dir, rayParams)  
		if result and result.Instance and result.Instance.CanCollide then  
			canJump = true  
			break  
		end  
	end  
  
	if canJump then  
		local now = tick()  
		if now - lastJumpTime >= jumpCooldown then  
			lastJumpTime = now  
			if hum:GetState() ~= Enum.HumanoidStateType.Jumping then  
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)  
				hum:ChangeState(Enum.HumanoidStateType.Jumping)  
			end  
		end  
	end  
end)  
  
task.spawn(function()  
	while true do  
		task.wait(2.4)  
		if not (following or autoFollow) then continue end  
		local hum = getHumanoid(LocalPlayer.Character)  
		if hum and hum:GetState() == Enum.HumanoidStateType.Swimming then  
			hum:ChangeState(Enum.HumanoidStateType.Jumping)  
		end  
	end  
end)  
  
PathTab:AddTextBox({  
	Name = "NICK DO ALVO",  
	PlaceholderText = "ex: dkzin",  
	Callback = function(v) targetName = v end  
})  
  
killdropdown = PathTab:AddDropdown({  
	Name = "LISTA DE JOGADORES ATUALIZADA",  
	Options = {},  
	Callback = function(v) targetName = v end  
})  
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
  
PathTab:AddToggle({  
	Name = "SEGUIR ALVO SELECIONADO",  
	Default = false,  
	Callback = function(state)  
		following = state  
		if state then  
			coroutine.wrap(function()  
				loopFollow(function()  
					for _, p in pairs(Players:GetPlayers()) do  
						if p.Name:lower():find(targetName:lower()) and p ~= LocalPlayer then  
							local char = p.Character  
							if char and getRoot(char) then  
								if (getRoot(LocalPlayer.Character).Position - getRoot(char).Position).Magnitude <= maxDistance then  
									if canReachPath(getRoot(LocalPlayer.Character).Position, getRoot(char).Position) then  
										return p  
									end  
								end  
							end  
						end  
					end  
				end)  
			end)()  
		else clearVisuals() end  
	end  
})  
  
PathTab:AddToggle({  
	Name = "SEGUIR O MAIS PRÓXIMO",  
	Default = false,  
	Callback = function(state)  
		autoFollow = state  
		if state then  
			coroutine.wrap(function()  
				loopFollow(function()  
					local minDist, closest = math.huge, nil  
					for _, p in pairs(Players:GetPlayers()) do  
						if p ~= LocalPlayer and p.Character and getRoot(p.Character) then  
							local dist = (getRoot(LocalPlayer.Character).Position - getRoot(p.Character).Position).Magnitude  
							if dist <= maxDistance and canReachPath(getRoot(LocalPlayer.Character).Position, getRoot(p.Character).Position) then  
								if dist < minDist then minDist, closest = dist, p end  
							end  
						end  
					end  
					return closest  
				end)  
			end)()  
		else clearVisuals() end  
	end  
})  
  
PathTab:AddSection({"OPCOES - RECOMENDADA"})  
PathTab:AddToggle({  
	Name = "AUTO JUMP",  
	Default = false,  
	Callback = function(state) autoJump = state end  
})  
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
	end  
})
