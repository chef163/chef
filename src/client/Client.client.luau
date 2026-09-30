-- 🎮 Клиент: интерфейс, удары, звуки, мемы и эффекты.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local PetBuilder = require(Shared:WaitForChild("PetBuilder"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HitRemote = Remotes:WaitForChild("Hit")
local BuyRemote = Remotes:WaitForChild("BuySneaker")
local BuyPetRemote = Remotes:WaitForChild("BuyPet")
local RebirthRemote = Remotes:WaitForChild("Rebirth")
local StateRemote = Remotes:WaitForChild("State")
local NotifyRemote = Remotes:WaitForChild("Notify")

local map = workspace:WaitForChild("SneakerMap")
local wallsFolder = map:WaitForChild("Walls")
local displaysFolder = map:WaitForChild("Displays")

local FONT = Enum.Font.FredokaOne

local state = {
	power = 0,
	cash = 0,
	wins = 0,
	rebirths = 0,
	sneakers = {},
	pets = {},
	passes = {},
	broken = 0,
	currentHp = nil,
	gain = Config.BASE_GAIN,
}
local soundOn = true
local autoHit = false
local lastHit = 0
local lastHint = 0

---------------------------------------------------------------------
-- 🔊 Звуки
---------------------------------------------------------------------
local function pick(entry)
	if type(entry) == "table" then
		if #entry == 0 then
			return nil
		end
		return entry[math.random(1, #entry)]
	end
	return entry
end

local function playSound(entry, volume, speed)
	if not soundOn then
		return
	end
	local id = pick(entry)
	if not id or id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume or 0.7
	sound.PlaybackSpeed = speed or 1
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 10)
end

local music
if Config.Sounds.Music and Config.Sounds.Music ~= "" then
	music = Instance.new("Sound")
	music.SoundId = Config.Sounds.Music
	music.Looped = true
	music.Volume = 0.25
	music.Parent = SoundService
	music:Play()
end

---------------------------------------------------------------------
-- UI-помощники
---------------------------------------------------------------------
local function new(className, props, children)
	local inst = Instance.new(className)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

local function stroke(color, thickness)
	return new("UIStroke", {
		Color = color or Color3.new(0, 0, 0),
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function label(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or FONT
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextStrokeTransparency = props.TextStrokeTransparency or 0
	return new("TextLabel", props)
end

local function pressAnim(button)
	local scale = new("UIScale", { Parent = button })
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.92 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
end

local function button(props)
	props.Font = FONT
	props.TextScaled = true
	props.TextColor3 = Color3.new(1, 1, 1)
	props.TextStrokeTransparency = 0
	props.AutoButtonColor = true
	local btn = new("TextButton", props, { corner(12), stroke(Color3.new(0, 0, 0), 3) })
	pressAnim(btn)
	return btn
end

---------------------------------------------------------------------
-- Интерфейс
---------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "SneakerWallUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})
local uiScale = new("UIScale", { Parent = gui })
local function updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		uiScale.Scale = math.clamp(camera.ViewportSize.Y / 800, 0.55, 1.1)
	end
end
updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

-- Сила сверху по центру
local topPanel = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(380, 96),
	BackgroundColor3 = Color3.fromRGB(25, 25, 35),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { corner(16), stroke(Color3.fromRGB(255, 220, 60), 3) })
local powerLabel = label({
	Text = "⚡ 0",
	Size = UDim2.new(1, -20, 0.62, 0),
	Position = UDim2.fromOffset(10, 4),
	TextColor3 = Color3.fromRGB(255, 230, 60),
	Parent = topPanel,
})
local powerScale = new("UIScale", { Parent = powerLabel })
local gainLabel = label({
	Text = "+1 ⚡ / сек",
	Size = UDim2.new(1, -20, 0.3, 0),
	Position = UDim2.new(0, 10, 0.64, 0),
	TextColor3 = Color3.fromRGB(0, 255, 200),
	Parent = topPanel,
})

-- Левая панель: статы и кнопки
local leftPanel = new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.fromOffset(210, 480),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local statsBox = new("Frame", {
	Size = UDim2.fromOffset(210, 110),
	BackgroundColor3 = Color3.fromRGB(25, 25, 35),
	BackgroundTransparency = 0.15,
	LayoutOrder = 1,
	Parent = leftPanel,
}, { corner(14), stroke(Color3.new(0, 0, 0), 3) })
local cashLabel = label({
	Text = "💰 0",
	Size = UDim2.new(1, -16, 0, 36),
	Position = UDim2.fromOffset(8, 4),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(120, 255, 120),
	Parent = statsBox,
})
local winsLabel = label({
	Text = "🏆 0",
	Size = UDim2.new(1, -16, 0, 30),
	Position = UDim2.fromOffset(8, 42),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = statsBox,
})
local rebirthLabel = label({
	Text = "🔁 0",
	Size = UDim2.new(1, -16, 0, 30),
	Position = UDim2.fromOffset(8, 74),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = statsBox,
})

local shopButton = button({
	Text = "👟 Кроссовки",
	Size = UDim2.fromOffset(210, 50),
	BackgroundColor3 = Color3.fromRGB(255, 120, 40),
	LayoutOrder = 2,
	Parent = leftPanel,
})
local petButton = button({
	Text = "🐾 Питомцы",
	Size = UDim2.fromOffset(210, 50),
	BackgroundColor3 = Color3.fromRGB(240, 90, 160),
	LayoutOrder = 3,
	Parent = leftPanel,
})
local passButton = button({
	Text = "💎 Game Pass",
	Size = UDim2.fromOffset(210, 50),
	BackgroundColor3 = Color3.fromRGB(0, 170, 120),
	LayoutOrder = 4,
	Parent = leftPanel,
})
local rebirthButton = button({
	Text = "🔁 Ребёрт",
	Size = UDim2.fromOffset(210, 50),
	BackgroundColor3 = Color3.fromRGB(170, 80, 255),
	LayoutOrder = 5,
	Parent = leftPanel,
})
local autoButton = button({
	Text = "🤖 Авто: ВЫКЛ",
	Size = UDim2.fromOffset(210, 44),
	BackgroundColor3 = Color3.fromRGB(90, 90, 110),
	LayoutOrder = 6,
	Parent = leftPanel,
})
local soundButton = button({
	Text = "🔊 Звук: ВКЛ",
	Size = UDim2.fromOffset(210, 44),
	BackgroundColor3 = Color3.fromRGB(60, 150, 230),
	LayoutOrder = 7,
	Parent = leftPanel,
})

-- Большая кнопка удара снизу (для телефонов)
local hitButton = button({
	Text = "👊 УДАР!",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.fromOffset(230, 74),
	BackgroundColor3 = Color3.fromRGB(230, 50, 60),
	Parent = gui,
})

-- Слой для мемных надписей
local popupLayer = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 50,
	Parent = gui,
})

---------------------------------------------------------------------
-- Окно магазина
---------------------------------------------------------------------
local function makeWindow(title, height)
	local window = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(500, height),
		BackgroundColor3 = Color3.fromRGB(30, 30, 42),
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	}, { corner(18), stroke(Color3.fromRGB(255, 255, 255), 3) })
	label({
		Text = title,
		Size = UDim2.new(1, -80, 0, 50),
		Position = UDim2.fromOffset(16, 8),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
		Parent = window,
	})
	local close = button({
		Text = "X",
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.new(1, -56, 0, 10),
		BackgroundColor3 = Color3.fromRGB(230, 50, 60),
		ZIndex = 21,
		Parent = window,
	})
	close.MouseButton1Click:Connect(function()
		window.Visible = false
	end)
	return window
end

local function makeList(window)
	return new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 66),
		Size = UDim2.new(1, -24, 1, -78),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 21,
		Parent = window,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
end

-- строка товара: иконка, название, описание, кнопка
local function makeRow(list, index, title, icon, iconColor, iconStroke, onBuy)
	local row = new("Frame", {
		Size = UDim2.new(1, -12, 0, 76),
		BackgroundColor3 = Color3.fromRGB(45, 45, 60),
		LayoutOrder = index,
		ZIndex = 22,
		Parent = list,
	}, { corner(12) })
	new("Frame", {
		Size = UDim2.fromOffset(60, 60),
		Position = UDim2.fromOffset(8, 8),
		BackgroundColor3 = iconColor,
		ZIndex = 23,
		Parent = row,
	}, {
		corner(10),
		stroke(iconStroke or Color3.new(1, 1, 1), 3),
		label({ Text = icon, Size = UDim2.fromScale(1, 1), ZIndex = 24 }),
	})
	label({
		Text = title,
		Size = UDim2.new(1, -230, 0, 32),
		Position = UDim2.fromOffset(78, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 23,
		Parent = row,
	})
	local info = label({
		Text = "",
		Size = UDim2.new(1, -230, 0, 26),
		Position = UDim2.fromOffset(78, 42),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 230, 60),
		ZIndex = 23,
		Parent = row,
	})
	local buy = button({
		Text = "",
		Size = UDim2.fromOffset(130, 56),
		Position = UDim2.new(1, -140, 0, 10),
		BackgroundColor3 = Color3.fromRGB(60, 200, 90),
		ZIndex = 23,
		Parent = row,
	})
	buy.MouseButton1Click:Connect(onBuy)
	return { info = info, buy = buy }
end

local shopWindow = makeWindow("👟 МАГАЗИН КРОССОВОК", 470)
local shopList = makeList(shopWindow)
local shopRows = {}
for index, sneaker in ipairs(Config.Sneakers) do
	shopRows[sneaker.id] = makeRow(shopList, index, sneaker.name, "👟", sneaker.color, sneaker.accent, function()
		BuyRemote:FireServer(sneaker.id)
	end)
end

local petWindow = makeWindow("🐾 ПИТОМЦЫ", 470)
local petList = makeList(petWindow)
local petRows = {}
for index, pet in ipairs(Config.Pets) do
	petRows[pet.id] = makeRow(petList, index, pet.name, pet.emoji, pet.color, nil, function()
		BuyPetRemote:FireServer(pet.id)
	end)
end

local passWindow = makeWindow("💎 GAME PASS", 340)
local passList = makeList(passWindow)
local passRows = {}
local popup -- объявлен ниже
for index, pass in ipairs(Config.GamePasses) do
	passRows[pass.key] = makeRow(passList, index, pass.name, "💎", Color3.fromRGB(0, 170, 120), nil, function()
		if state.passes[pass.key] then
			return
		end
		if not pass.id or pass.id <= 0 then
			popup("Game Pass ещё не создан — впиши ID в Config 🛠️", Color3.fromRGB(255, 200, 120))
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, pass.id)
	end)
	passRows[pass.key].info.Text = pass.desc
end

---------------------------------------------------------------------
-- Окно перерождения
---------------------------------------------------------------------
local rebirthWindow = makeWindow("🔁 ПЕРЕРОЖДЕНИЕ", 300)
local rebirthInfo = label({
	Text = "",
	Size = UDim2.new(1, -40, 0, 130),
	Position = UDim2.fromOffset(20, 66),
	TextColor3 = Color3.fromRGB(230, 230, 255),
	ZIndex = 21,
	Parent = rebirthWindow,
})
local rebirthConfirm = button({
	Text = "",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 212),
	Size = UDim2.fromOffset(300, 64),
	BackgroundColor3 = Color3.fromRGB(170, 80, 255),
	ZIndex = 21,
	Parent = rebirthWindow,
})
rebirthConfirm.MouseButton1Click:Connect(function()
	RebirthRemote:FireServer()
	rebirthWindow.Visible = false
end)

---------------------------------------------------------------------
-- Мемные попапы и эффекты
---------------------------------------------------------------------
function popup(text, color, big)
	local size = if big then UDim2.fromOffset(700, 130) else UDim2.fromOffset(420, 70)
	local popupLabel = label({
		Text = text,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5 + (math.random() - 0.5) * 0.3, if big then 0.35 else 0.45 + (math.random() - 0.5) * 0.2),
		Size = size,
		Rotation = math.random(-12, 12),
		TextColor3 = color or Color3.new(1, 1, 1),
		ZIndex = 60,
		Parent = popupLayer,
	})
	local scale = new("UIScale", { Scale = 0, Parent = popupLabel })
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(if big then 1.8 else 0.9, function()
		local info = TweenInfo.new(0.5)
		TweenService:Create(popupLabel, info, {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			Position = popupLabel.Position - UDim2.fromOffset(0, 60),
		}):Play()
		Debris:AddItem(popupLabel, 0.6)
	end)
end

local function hint(text)
	if os.clock() - lastHint < 2 then
		return
	end
	lastHint = os.clock()
	popup(text, Color3.fromRGB(255, 200, 200))
end

local function getRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getWall(index)
	return wallsFolder:FindFirstChild("Wall_" .. index)
end

local function shake(power)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local p = power or 0.3
	humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * p, (math.random() - 0.5) * p, 0)
	TweenService:Create(humanoid, TweenInfo.new(0.12), { CameraOffset = Vector3.zero }):Play()
end

-- точка на стене напротив игрока
local function wallFacePoint(wall)
	local root = getRoot()
	local x = if root then math.clamp(root.Position.X, -wall.Size.X / 2 + 2, wall.Size.X / 2 - 2) else 0
	local y = if root then root.Position.Y + 1 else 4
	return Vector3.new(x, y, wall.Position.Z + wall.Size.Z / 2 + 0.5)
end

local function damageNumber(wall, text, color)
	local position = wallFacePoint(wall) + Vector3.new((math.random() - 0.5) * 6, (math.random() - 0.5) * 3, 0)
	local anchor = new("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(0.2, 0.2, 0.2),
		Position = position,
		Parent = workspace,
	})
	local billboard = new("BillboardGui", {
		Size = UDim2.fromOffset(180, 60),
		AlwaysOnTop = true,
		LightInfluence = 0,
		Parent = anchor,
	})
	local text3d = label({
		Text = text,
		Size = UDim2.fromScale(1, 1),
		TextColor3 = color or Color3.fromRGB(255, 230, 60),
		Parent = billboard,
	})
	TweenService:Create(anchor, TweenInfo.new(0.8), { Position = position + Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(text3d, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 0.9)
end

local function explodeWall(wall)
	local origin = wallFacePoint(wall)
	for _ = 1, 16 do
		local size = 0.8 + math.random() * 1.8
		local chunk = new("Part", {
			Size = Vector3.new(size, size, size),
			Position = origin + Vector3.new((math.random() - 0.5) * 10, (math.random() - 0.5) * 6, 0),
			Color = wall.Color,
			Material = wall.Material,
			CanQuery = false,
			CanTouch = false,
			Parent = workspace,
		})
		chunk.AssemblyLinearVelocity = Vector3.new((math.random() - 0.5) * 60, 20 + math.random() * 40, 10 + math.random() * 30)
		chunk.AssemblyAngularVelocity = Vector3.new(math.random() * 10, math.random() * 10, math.random() * 10)
		Debris:AddItem(chunk, 3)
	end
end

---------------------------------------------------------------------
-- Обновление UI и стен
---------------------------------------------------------------------
local function updateWalls()
	for index, wallConfig in ipairs(Config.Walls) do
		local wall = getWall(index)
		if wall then
			local isBroken = index <= state.broken
			-- меняем только у себя: другие игроки видят свои стены
			wall.CanCollide = not isBroken
			wall.Transparency = if isBroken then 0.85 else 0
			local info = wall:FindFirstChild("Info")
			local hpLabel = info and info:FindFirstChild("HP")
			if hpLabel then
				if isBroken then
					hpLabel.Text = "✅ СЛОМАНА"
				else
					local hp = if index == state.broken + 1 and state.currentHp then state.currentHp else wallConfig.hp
					hpLabel.Text = "❤ " .. Format.num(math.max(0, hp)) .. " / " .. Format.num(wallConfig.hp)
				end
			end
		end
	end
end

local function updateShop()
	for _, sneaker in ipairs(Config.Sneakers) do
		local row = shopRows[sneaker.id]
		local level = state.sneakers[sneaker.id] or 0
		local price = Config.getPrice(sneaker, level)
		row.info.Text = "+" .. Format.num(sneaker.gain) .. " ⚡/сек • у тебя: " .. level
		row.buy.Text = "💰 " .. Format.num(price)
		row.buy.BackgroundColor3 = if state.cash >= price then Color3.fromRGB(60, 200, 90) else Color3.fromRGB(110, 110, 120)
	end
end

local function updatePets()
	local best = Config.getBestPet(state.pets)
	for _, pet in ipairs(Config.Pets) do
		local row = petRows[pet.id]
		row.info.Text = "x" .. pet.mult .. " к приросту силы"
		if best and best.id == pet.id then
			row.buy.Text = "⭐ Летает"
			row.buy.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
		elseif state.pets[pet.id] then
			row.buy.Text = "✅ Есть"
			row.buy.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
		else
			row.buy.Text = "💰 " .. Format.num(pet.price)
			row.buy.BackgroundColor3 = if state.cash >= pet.price then Color3.fromRGB(60, 200, 90) else Color3.fromRGB(110, 110, 120)
		end
	end
end

local function updatePasses()
	for _, pass in ipairs(Config.GamePasses) do
		local row = passRows[pass.key]
		if state.passes[pass.key] then
			row.buy.Text = "✅ Куплено"
			row.buy.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
		else
			row.buy.Text = "R$ Купить"
			row.buy.BackgroundColor3 = Color3.fromRGB(0, 170, 120)
		end
	end
end

local function updateRebirth()
	local cost = Config.getRebirthCost(state.rebirths)
	local nextBonus = math.floor((1 + (state.rebirths + 1) * Config.REBIRTH_BONUS) * 100)
	rebirthInfo.Text = "Сбросит силу, деньги и кроссовки,\nно навсегда даст x"
		.. string.format("%.1f", nextBonus / 100)
		.. " к приросту силы!\nЦена: 💰 "
		.. Format.num(cost)
	rebirthConfirm.Text = if state.cash >= cost then "ПЕРЕРОДИТЬСЯ 🔁" else "Нужно 💰 " .. Format.num(cost)
	rebirthConfirm.BackgroundColor3 = if state.cash >= cost then Color3.fromRGB(170, 80, 255) else Color3.fromRGB(110, 110, 120)
end

local function updateUI()
	powerLabel.Text = "⚡ " .. Format.num(state.power)
	gainLabel.Text = "+" .. Format.num(state.gain) .. " ⚡ / сек"
	cashLabel.Text = "💰 " .. Format.num(state.cash)
	winsLabel.Text = "🏆 Победы: " .. Format.num(state.wins)
	rebirthLabel.Text = "🔁 Ребёрты: " .. Format.num(state.rebirths)
	updateShop()
	updatePets()
	updatePasses()
	updateRebirth()
end

---------------------------------------------------------------------
-- Удар
---------------------------------------------------------------------
local function tryHit()
	local root = getRoot()
	if not root then
		return
	end
	local index = state.broken + 1
	local wall = getWall(index)
	if not wall then
		return
	end
	local distance = math.abs(root.Position.Z - wall.Position.Z) - wall.Size.Z / 2
	if distance > Config.HIT_RANGE then
		hint("Подойди к стене! 🧱")
		return
	end
	if os.clock() - lastHit < Config.HIT_COOLDOWN then
		return
	end
	lastHit = os.clock()
	HitRemote:FireServer(index)
	playSound(Config.Sounds.Hit, 0.5, 0.9 + math.random() * 0.3)
	shake(0.25)
end

hitButton.MouseButton1Click:Connect(tryHit)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.F
	then
		tryHit()
	end
end)

task.spawn(function()
	while true do
		task.wait(if state.passes.FastAuto then Config.AUTO_HIT_FAST_INTERVAL else Config.AUTO_HIT_INTERVAL)
		if autoHit then
			local root = getRoot()
			local wall = getWall(state.broken + 1)
			if root and wall and math.abs(root.Position.Z - wall.Position.Z) - wall.Size.Z / 2 <= Config.HIT_RANGE then
				tryHit()
			end
		end
	end
end)

---------------------------------------------------------------------
-- Кнопки
---------------------------------------------------------------------

local windows = { shopWindow, petWindow, passWindow, rebirthWindow }
local function toggleWindow(window)
	local show = not window.Visible
	for _, other in ipairs(windows) do
		other.Visible = false
	end
	window.Visible = show
end

rebirthButton.MouseButton1Click:Connect(function()
	toggleWindow(rebirthWindow)
end)
petButton.MouseButton1Click:Connect(function()
	toggleWindow(petWindow)
end)
passButton.MouseButton1Click:Connect(function()
	toggleWindow(passWindow)
end)

shopButton.MouseButton1Click:Connect(function()
	toggleWindow(shopWindow)
end)

autoButton.MouseButton1Click:Connect(function()
	autoHit = not autoHit
	autoButton.Text = if autoHit then "🤖 Авто: ВКЛ" else "🤖 Авто: ВЫКЛ"
	autoButton.BackgroundColor3 = if autoHit then Color3.fromRGB(60, 200, 90) else Color3.fromRGB(90, 90, 110)
end)

soundButton.MouseButton1Click:Connect(function()
	soundOn = not soundOn
	soundButton.Text = if soundOn then "🔊 Звук: ВКЛ" else "🔇 Звук: ВЫКЛ"
	if music then
		music.Volume = if soundOn then 0.25 else 0
	end
end)

---------------------------------------------------------------------
-- События от сервера
---------------------------------------------------------------------
StateRemote.OnClientEvent:Connect(function(newState)
	local oldPower = state.power
	state = newState
	state.sneakers = state.sneakers or {}
	state.pets = state.pets or {}
	state.passes = state.passes or {}
	updateUI()
	updateWalls()
	if state.power > oldPower then
		powerScale.Scale = 1.15
		TweenService:Create(powerScale, TweenInfo.new(0.2), { Scale = 1 }):Play()
	end
end)

NotifyRemote.OnClientEvent:Connect(function(kind, data)
	if kind == "hit" then
		state.currentHp = data.hp
		updateWalls()
		local wall = getWall(data.wall)
		if wall then
			damageNumber(wall, "-" .. Format.num(data.damage))
		end
	elseif kind == "break" then
		local wall = getWall(data.wall)
		if wall then
			damageNumber(wall, "-" .. Format.num(data.damage))
			explodeWall(wall)
		end
		shake(1.2)
		playSound(Config.Sounds.WallBreak, 1)
		task.delay(0.3, playSound, Config.Sounds.Memes, 0.8)
		popup(pick(Config.MemeTexts), Color3.fromRGB(255, 230, 60), true)
		popup("+💰 " .. Format.num(data.reward), Color3.fromRGB(120, 255, 120))
	elseif kind == "win" then
		playSound(Config.Sounds.Win, 1)
		popup("🏆 ПОБЕДА! +1 🏆", Color3.fromRGB(255, 215, 0), true)
	elseif kind == "buy" then
		local sneaker = Config.getSneaker(data.id)
		playSound(Config.Sounds.Buy, 0.9)
		popup("👟 " .. (sneaker and sneaker.name or "Кроссы") .. " (ур. " .. data.level .. ")", Color3.fromRGB(0, 255, 200))
	elseif kind == "pet" then
		local pet = Config.getPet(data.id)
		playSound(Config.Sounds.Buy, 0.9)
		if pet then
			popup(pet.emoji .. " " .. pet.name .. " теперь с тобой! x" .. pet.mult, Color3.fromRGB(255, 150, 220), true)
		end
	elseif kind == "pass" then
		playSound(Config.Sounds.Win, 1)
		popup("💎 " .. data.name .. " активирован!", Color3.fromRGB(0, 255, 200), true)
	elseif kind == "rebirth" then
		playSound(Config.Sounds.Rebirth, 1)
		popup("🔁 ПЕРЕРОЖДЕНИЕ #" .. data.rebirths .. " — ТЫ СТАЛ СИЛЬНЕЕ", Color3.fromRGB(200, 140, 255), true)
	elseif kind == "error" then
		playSound(Config.Sounds.Error, 0.8)
		popup(data.text or "BRUH 💀", Color3.fromRGB(255, 90, 90))
	end
end)

-- стены могут подгружаться позже (StreamingEnabled) — обновляем, когда появляются
wallsFolder.ChildAdded:Connect(function()
	task.defer(updateWalls)
end)

---------------------------------------------------------------------
-- Крутящиеся кроссовки на витринах
---------------------------------------------------------------------
local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
	elapsed += dt
	for _, model in ipairs(displaysFolder:GetChildren()) do
		local base = model:GetAttribute("BasePos")
		if model:IsA("Model") and base then
			model:PivotTo(CFrame.new(base + Vector3.new(0, math.sin(elapsed * 2) * 0.4, 0)) * CFrame.Angles(0, elapsed, 0))
		end
	end
end)

---------------------------------------------------------------------
-- 🐾 Питомцы летают за всеми игроками (рисуются у каждого клиента)
---------------------------------------------------------------------
local petModels = {} -- [Player] = { id, model }
local petFolder = new("Folder", { Name = "LocalPets", Parent = workspace })

RunService.RenderStepped:Connect(function(dt)
	for _, other in ipairs(Players:GetPlayers()) do
		local petId = other:GetAttribute("PetId")
		local current = petModels[other]
		if current and current.id ~= petId then
			current.model:Destroy()
			petModels[other] = nil
			current = nil
		end
		local character = other.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local pet = petId and Config.getPet(petId)
		if pet and root then
			if not current then
				local model = PetBuilder.build(pet)
				model:PivotTo(root.CFrame)
				model.Parent = petFolder
				current = { id = petId, model = model }
				petModels[other] = current
			end
			local bob = math.sin(elapsed * 3 + other.UserId) * 0.4
			local target = root.CFrame * CFrame.new(3, 1.5 + bob, 3)
			current.model:PivotTo(current.model:GetPivot():Lerp(target, math.clamp(dt * 8, 0, 1)))
		elseif current then
			current.model:Destroy()
			petModels[other] = nil
		end
	end
end)

Players.PlayerRemoving:Connect(function(other)
	local current = petModels[other]
	if current then
		current.model:Destroy()
		petModels[other] = nil
	end
end)

updateUI()
updateWalls()
