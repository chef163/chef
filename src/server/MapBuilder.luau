-- 🗺️ Строит карту кодом: спавн, витрины кроссовок, дорожку со стенами и финиш.
-- Ничего не нужно расставлять руками в Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local ShoeBuilder = require(Shared:WaitForChild("ShoeBuilder"))

local MapBuilder = {}

local wallParts = {}
local boards = {}
local spawnLocation

local FONT = Enum.Font.FredokaOne

local function makePart(props)
	local part = Instance.new(props.ClassName or "Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	for key, value in pairs(props) do
		if key ~= "ClassName" and key ~= "Parent" then
			part[key] = value
		end
	end
	part.Parent = props.Parent
	return part
end

local function makeLabel(parent, name, text, size, position, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = FONT
	label.Parent = parent
	return label
end

local function makeBillboard(parent, studsSize, offset, lines)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(studsSize.X, 0, studsSize.Y, 0)
	billboard.StudsOffset = offset
	billboard.LightInfluence = 0
	billboard.MaxDistance = 250
	billboard.Parent = parent

	local lineHeight = 1 / #lines
	for i, line in ipairs(lines) do
		makeLabel(
			billboard,
			"Line" .. i,
			line.text,
			UDim2.fromScale(1, lineHeight),
			UDim2.fromScale(0, (i - 1) * lineHeight),
			line.color
		)
	end
	return billboard
end

local function darken(color, amount)
	return color:Lerp(Color3.new(0, 0, 0), amount or 0.35)
end

local function wallZ(i)
	return Config.Map.FirstWallZ - (i - 1) * Config.Map.Spacing
end

function MapBuilder.build()
	local M = Config.Map
	local width = M.TrackWidth
	local wallCount = #Config.Walls
	local startZ = M.SpawnDepth
	local endZ = wallZ(wallCount) - M.FinishLength

	local old = workspace:FindFirstChild("SneakerMap")
	if old then
		old:Destroy()
	end

	local root = Instance.new("Folder")
	root.Name = "SneakerMap"

	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = root

	local wallsFolder = Instance.new("Folder")
	wallsFolder.Name = "Walls"
	wallsFolder.Parent = root

	local displays = Instance.new("Folder")
	displays.Name = "Displays"
	displays.Parent = root

	-- Пол: спавн, зона за каждой стеной, финиш
	local function floor(z1, z2, color, material)
		return makePart({
			Name = "Floor",
			Size = Vector3.new(width, 2, z1 - z2),
			Position = Vector3.new(0, -1, (z1 + z2) / 2),
			Color = color,
			Material = material or Enum.Material.SmoothPlastic,
			Parent = decor,
		})
	end

	floor(startZ, wallZ(1), Color3.fromRGB(60, 60, 80))
	for i = 2, wallCount do
		floor(wallZ(i - 1), wallZ(i), darken(Config.Walls[i - 1].color))
	end
	floor(wallZ(wallCount), endZ, Color3.fromRGB(255, 200, 40), Enum.Material.Neon)

	-- Невидимые границы, чтобы нельзя было обойти стены
	local length = startZ - endZ
	local centerZ = (startZ + endZ) / 2
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = "Barrier",
			Size = Vector3.new(2, 80, length),
			Position = Vector3.new(side * (width / 2 + 1), 40, centerZ),
			Transparency = 1,
			Parent = decor,
		})
		makePart({
			Name = "Rail",
			Size = Vector3.new(1, 1, length),
			Position = Vector3.new(side * (width / 2 - 0.5), 0.5, centerZ),
			Color = Color3.fromRGB(0, 255, 200),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = decor,
		})
	end
	for _, z in ipairs({ startZ + 1, endZ - 1 }) do
		makePart({
			Name = "Barrier",
			Size = Vector3.new(width + 4, 80, 2),
			Position = Vector3.new(0, 40, z),
			Transparency = 1,
			Parent = decor,
		})
	end

	-- Спавн
	spawnLocation = makePart({
		ClassName = "SpawnLocation",
		Name = "Spawn",
		Size = Vector3.new(14, 1, 14),
		Position = Vector3.new(0, 0.5, 15),
		Color = Color3.fromRGB(0, 255, 200),
		Material = Enum.Material.Neon,
		Neutral = true,
		Duration = 0,
		Parent = decor,
	})

	-- Большая вывеска над спавном
	local signAnchor = makePart({
		Name = "SignAnchor",
		Size = Vector3.new(1, 1, 1),
		Position = Vector3.new(0, 24, -25),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = decor,
	})
	makeBillboard(signAnchor, Vector2.new(46, 14), Vector3.zero, {
		{ text = "+1 ⚡ СИЛА КАЖДУЮ СЕКУНДУ", color = Color3.fromRGB(255, 230, 60) },
		{ text = "ЛОМАЙ СТЕНЫ 🧱 → ПОКУПАЙ КРОССЫ 👟", color = Color3.new(1, 1, 1) },
		{ text = "кликай по стене или жми УДАР", color = Color3.fromRGB(0, 255, 200) },
	})

	-- Витрины с кроссовками по бокам спавна
	for index, sneaker in ipairs(Config.Sneakers) do
		if index > 12 then
			break
		end
		local side = if index % 2 == 1 then -1 else 1
		local row = math.ceil(index / 2)
		local x = side * (width / 2 - 6)
		local z = 30 - (row - 1) * 15

		local pedestal = makePart({
			Name = "Pedestal",
			Size = Vector3.new(6, 3, 6),
			Position = Vector3.new(x, 1.5, z),
			Color = Color3.fromRGB(35, 35, 45),
			Parent = decor,
		})
		makePart({
			Name = "PedestalGlow",
			Size = Vector3.new(6.4, 0.3, 6.4),
			Position = Vector3.new(x, 3.1, z),
			Color = sneaker.accent or sneaker.color,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = decor,
		})
		makeBillboard(pedestal, Vector2.new(10, 4), Vector3.new(0, 9, 0), {
			{ text = sneaker.name, color = Color3.new(1, 1, 1) },
			{ text = "+" .. Format.num(sneaker.gain) .. " ⚡/сек", color = Color3.fromRGB(255, 230, 60) },
			{ text = "💰 от " .. Format.num(sneaker.price), color = Color3.fromRGB(120, 255, 120) },
		})

		local shoe = ShoeBuilder.build(sneaker, 3)
		local basePos = Vector3.new(x, 4, z)
		shoe:PivotTo(CFrame.new(basePos))
		shoe:SetAttribute("BasePos", basePos)
		shoe.Parent = displays
	end

	-- Стены
	for i, wallConfig in ipairs(Config.Walls) do
		local wall = makePart({
			Name = "Wall_" .. i,
			Size = Vector3.new(width, M.WallHeight, M.WallThickness),
			Position = Vector3.new(0, M.WallHeight / 2, wallZ(i)),
			Color = wallConfig.color,
			Material = wallConfig.material or Enum.Material.Brick,
			Parent = wallsFolder,
		})
		wall:SetAttribute("Index", i)

		local gui = Instance.new("SurfaceGui")
		gui.Name = "Info"
		gui.Face = Enum.NormalId.Back -- смотрит на игрока, который идёт со спавна
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 20
		gui.LightInfluence = 0
		gui.Parent = wall

		makeLabel(gui, "Number", "СТЕНА " .. i .. "/" .. wallCount, UDim2.fromScale(0.5, 0.1), UDim2.fromScale(0.25, 0.08))
		makeLabel(gui, "Title", wallConfig.name, UDim2.fromScale(0.9, 0.2), UDim2.fromScale(0.05, 0.2))
		makeLabel(
			gui,
			"HP",
			"❤ " .. Format.num(wallConfig.hp),
			UDim2.fromScale(0.8, 0.16),
			UDim2.fromScale(0.1, 0.43),
			Color3.fromRGB(255, 90, 90)
		)
		makeLabel(
			gui,
			"Reward",
			"💰 +" .. Format.num(wallConfig.reward),
			UDim2.fromScale(0.6, 0.12),
			UDim2.fromScale(0.2, 0.62),
			Color3.fromRGB(120, 255, 120)
		)
		makeLabel(
			gui,
			"Caption",
			wallConfig.caption or "",
			UDim2.fromScale(0.8, 0.1),
			UDim2.fromScale(0.1, 0.78),
			Color3.fromRGB(255, 240, 200)
		)

		wallParts[i] = wall
	end

	-- Табличка «Зона 2» перед первой стеной второй зоны
	for i, wallConfig in ipairs(Config.Walls) do
		if wallConfig.zone == 2 then
			local zoneSign = makePart({
				Name = "ZoneSign",
				Size = Vector3.new(1, 1, 1),
				Position = Vector3.new(0, M.WallHeight + 10, wallZ(i) + 4),
				Transparency = 1,
				CanCollide = false,
				CanQuery = false,
				Parent = decor,
			})
			makeBillboard(zoneSign, Vector2.new(40, 8), Vector3.zero, {
				{ text = "🌍 ЗОНА 2: МИР МЕМОВ", color = Color3.fromRGB(0, 255, 200) },
				{ text = "здесь стены по-настоящему толстые 💀", color = Color3.new(1, 1, 1) },
			})
			break
		end
	end

	-- Доски лидеров за спавном (повёрнуты к дорожке)
	for _, info in ipairs({
		{ key = "Wins", title = "🏆 ТОП ПОБЕД", x = -18 },
		{ key = "Power", title = "⚡ ТОП СИЛЫ", x = 18 },
	}) do
		local board = makePart({
			Name = "Leaderboard_" .. info.key,
			Size = Vector3.new(22, 18, 1),
			Position = Vector3.new(info.x, 12, startZ - 3),
			Color = Color3.fromRGB(25, 25, 35),
			Parent = decor,
		})
		makePart({
			Name = "BoardLeg",
			Size = Vector3.new(1, 3, 1),
			Position = Vector3.new(info.x, 1.5, startZ - 3),
			Color = Color3.fromRGB(25, 25, 35),
			Parent = decor,
		})
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Board"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 25
		gui.LightInfluence = 0
		gui.Parent = board
		makeLabel(gui, "Title", info.title, UDim2.fromScale(0.9, 0.12), UDim2.fromScale(0.05, 0.02), Color3.fromRGB(255, 230, 60))
		local rows = {}
		for row = 1, Config.LEADERBOARD_SIZE do
			rows[row] = makeLabel(
				gui,
				"Row" .. row,
				if row == 1 then "загрузка..." else "",
				UDim2.fromScale(0.9, 0.075),
				UDim2.fromScale(0.05, 0.16 + (row - 1) * 0.082)
			)
			rows[row].TextXAlignment = Enum.TextXAlignment.Left
		end
		boards[info.key] = rows
	end

	-- Финиш
	local trophy = makePart({
		Name = "Trophy",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(8, 8, 8),
		CFrame = CFrame.new(0, 4, endZ + 15) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 215, 0),
		Material = Enum.Material.Foil,
		Parent = decor,
	})
	makeBillboard(trophy, Vector2.new(30, 8), Vector3.new(0, 14, 0), {
		{ text = "🏆 ТЫ ЛЕГЕНДА КРОССОВОК 🏆", color = Color3.fromRGB(255, 230, 60) },
		{ text = "+1 победа • скоро телепорт на спавн", color = Color3.new(1, 1, 1) },
	})

	root.Parent = workspace
	return root
end

function MapBuilder.getWall(index)
	return wallParts[index]
end

-- строки доски лидеров: key = "Wins" или "Power"
function MapBuilder.getBoardRows(key)
	return boards[key]
end

function MapBuilder.getSpawn()
	return spawnLocation
end

return MapBuilder
