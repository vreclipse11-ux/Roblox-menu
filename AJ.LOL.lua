local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local THEME = {
	Window = Color3.fromRGB(11, 9, 15),
	Panel = Color3.fromRGB(13, 11, 17),
	Row = Color3.fromRGB(18, 15, 23),
	RowBorder = Color3.fromRGB(38, 38, 48),
	Line = Color3.fromRGB(30, 30, 38),
	Card = Color3.fromRGB(21, 17, 28),
	CardLine = Color3.fromRGB(36, 31, 46),
	Accent = Color3.fromRGB(124, 58, 237),
	AccentSoft = Color3.fromRGB(139, 92, 246),
	AccentText = Color3.fromRGB(170, 88, 247),
	Text = Color3.fromRGB(243, 243, 248),
	TextDim = Color3.fromRGB(198, 198, 210),
	TextFaint = Color3.fromRGB(132, 132, 146),
	Track = Color3.fromRGB(46, 46, 56),
	Knob = Color3.fromRGB(255, 255, 255),
	KnobOff = Color3.fromRGB(206, 206, 216),
	Field = Color3.fromRGB(23, 20, 30),
	Font = Enum.Font.Gotham,
	FontMed = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
}

local vp = (Camera and Camera.ViewportSize) or Vector2.new(390, 844)
local compact = vp.X < 560

local M
if compact then
	M = {
		winW = math.floor(vp.X * 0.94),
		winH = math.floor(vp.Y * 0.74),
		headerH = 50,
		sidebarW = 118,
		tabH = 40,
		tabText = 13,
		titleSize = 22,
		sectionSize = 12,
		labelSize = 12,
		rowH = 40,
		rowPad = 11,
		gap = 6,
		boxW = 46,
		boxH = 24,
		btnW = 48,
		btnH = 24,
		toggleW = 38,
		toggleH = 20,
		radius = 8,
	}
else
	M = {
		winW = math.min(860, math.floor(vp.X * 0.86)),
		winH = math.min(500, math.floor(vp.Y * 0.76)),
		headerH = 66,
		sidebarW = 206,
		tabH = 52,
		tabText = 17,
		titleSize = 32,
		sectionSize = 15,
		labelSize = 15,
		rowH = 50,
		rowPad = 16,
		gap = 8,
		boxW = 62,
		boxH = 32,
		btnW = 66,
		btnH = 32,
		toggleW = 46,
		toggleH = 24,
		radius = 10,
	}
end

local function new(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function corner(px)
	return new("UICorner", { CornerRadius = UDim.new(0, px or M.radius) })
end

local function stroke(color, thickness, transparency)
	return new("UIStroke", {
		Color = color or THEME.RowBorder,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function pad(px, tb)
	local p = px or M.rowPad
	return new("UIPadding", {
		PaddingTop = UDim.new(0, tb or 0),
		PaddingBottom = UDim.new(0, tb or 0),
		PaddingLeft = UDim.new(0, p),
		PaddingRight = UDim.new(0, p),
	})
end

local function guard(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[aj.lol] " .. tostring(err))
	end
	return ok
end

local function wrapClosure(fn)
	if typeof(newcclosure) == "function" then
		return newcclosure(fn)
	end
	return fn
end

local function findHook()
	if typeof(hookfunction) == "function" then
		return hookfunction
	end
	if typeof(replaceclosure) == "function" then
		return replaceclosure
	end
	if typeof(hookfunc) == "function" then
		return hookfunc
	end
	return nil
end

local function hookMeta(instance, metamethod, factory)
	local original = nil
	if typeof(getrawmetatable) == "function" then
		local okGet, mt = pcall(getrawmetatable, instance)
		if okGet and mt then
			local okOld, found = pcall(function()
				return rawget(mt, metamethod)
			end)
			if okOld and typeof(found) == "function" then
				original = found
			end
		end
	end
	local ref = { fn = original }
	if typeof(hookmetamethod) == "function" then
		local replacement = wrapClosure(factory(function(...)
			return ref.fn(...)
		end))
		local ok, handle = pcall(hookmetamethod, instance, metamethod, replacement)
		if ok then
			if typeof(handle) == "function" then
				ref.fn = handle
			end
			return ref.fn, function()
				pcall(hookmetamethod, instance, metamethod, ref.fn)
			end
		end
	end
	if not original then
		return nil, nil
	end
	local ok, mt = pcall(getrawmetatable, instance)
	if not ok or not mt then
		return nil, nil
	end
	local replacement = wrapClosure(factory(function(...)
		return original(...)
	end))
	if typeof(setreadonly) == "function" then
		pcall(setreadonly, mt, false)
	end
	local wrote = pcall(function()
		mt[metamethod] = replacement
	end)
	if typeof(setreadonly) == "function" then
		pcall(setreadonly, mt, true)
	end
	if not wrote then
		return nil, nil
	end
	return original, function()
		if typeof(setreadonly) == "function" then
			pcall(setreadonly, mt, false)
		end
		pcall(function()
			mt[metamethod] = original
		end)
		if typeof(setreadonly) == "function" then
			pcall(setreadonly, mt, true)
		end
	end
end

local function getHumanoid()
	local char = LocalPlayer.Character
	if not char then
		return nil
	end
	return char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local char = LocalPlayer.Character
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart")
end

local function resolveParent()
	if typeof(gethui) == "function" then
		local ok, handle = pcall(gethui)
		if ok and handle then
			return handle
		end
	end
	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and coreGui then
		return coreGui
	end
	return PlayerGui
end

if getgenv then
	local previous = getgenv().AJLOL
	if previous and typeof(previous.destroy) == "function" then
		pcall(previous.destroy)
	end
	getgenv().AJLOL = nil
end

guard(function()
	local old = resolveParent():FindFirstChild("AJLOL")
	if old then
		old:Destroy()
	end
end)

local gui = new("ScreenGui", {
	Name = "AJLOL",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 2 ^ 20,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local ui = {}

local window = new("Frame", {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.46, 0),
	Size = UDim2.fromOffset(M.winW, M.winH),
	BackgroundColor3 = THEME.Window,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Active = true,
}, { corner(M.radius + 2), stroke(THEME.AccentSoft, 1, 0.15) })

local windowScale = new("UIScale", { Scale = 0.9 })
windowScale.Parent = window

local glow = new("Frame", {
	Name = "Glow",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 0,
}, { stroke(THEME.AccentSoft, 3, 0.82) })
glow.Parent = window

local body = new("Frame", {
	Name = "Body",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = THEME.Window,
	BorderSizePixel = 0,
})
body.Parent = window

local sidebar = new("ScrollingFrame", {
	Name = "Sidebar",
	Position = UDim2.fromOffset(0, M.headerH),
	Size = UDim2.new(0, M.sidebarW, 1, -M.headerH),
	BackgroundColor3 = THEME.Panel,
	BorderSizePixel = 0,
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = THEME.CardLine,
	ScrollBarImageTransparency = 0.15,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 1,
}, {
	new("UIListLayout", {
		Padding = UDim.new(0, compact and 4 or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}),
	new("UIPadding", {
		PaddingTop = UDim.new(0, compact and 8 or 12),
		PaddingBottom = UDim.new(0, compact and 12 or 16),
		PaddingLeft = UDim.new(0, compact and 6 or 10),
		PaddingRight = UDim.new(0, compact and 6 or 10),
	}),
})
sidebar.Parent = body

local header = new("Frame", {
	Name = "Brand",
	Size = UDim2.new(1, 0, 0, M.headerH),
	BackgroundTransparency = 1,
	ZIndex = 4,
	Active = true,
}, {
	new("UIPadding", { PaddingLeft = UDim.new(0, compact and 14 or 22) }),
})
header.Parent = body

local title = new("TextLabel", {
	Name = "Title",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = THEME.FontBold,
	Text = "aj.lol",
	TextSize = M.titleSize,
	TextColor3 = THEME.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
	ZIndex = 4,
})
title.Parent = header

new("Frame", {
	Name = "Divider",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, 0),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = THEME.CardLine,
	BorderSizePixel = 0,
	ZIndex = 4,
}).Parent = header

local buttonSize = compact and 26 or 34

local function headerButton(glyph, offsetX, size)
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, offsetX, 0.5, 0),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = THEME.Row,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Font = THEME.FontMed,
		Text = glyph,
		TextSize = math.floor(size * 0.62),
		TextColor3 = THEME.Text,
		AutoButtonColor = false,
		ZIndex = 3,
	}, { corner(math.floor(size * 0.3)), stroke(THEME.RowBorder, 1, 0.2) })
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = THEME.Accent, BackgroundTransparency = 0.15 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = THEME.Row, BackgroundTransparency = 0.4 }):Play()
	end)
	return b
end

local btnSize = buttonSize
local controls = new("Frame", {
	Name = "Controls",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -(compact and 10 or 16), 0, (M.headerH - btnSize) / 2),
	Size = UDim2.fromOffset(btnSize * 2 + 10, btnSize),
	BackgroundTransparency = 1,
	ZIndex = 6,
})
controls.Parent = window

local closeBtn = headerButton("x", -2, btnSize)
local minBtn = headerButton("-", -(btnSize + 8), btnSize)
closeBtn.Parent = controls
minBtn.Parent = controls

local contentPadding = new("UIPadding", {
	PaddingTop = UDim.new(0, compact and 10 or 14),
	PaddingBottom = UDim.new(0, compact and 14 or 18),
	PaddingLeft = UDim.new(0, compact and 10 or 16),
	PaddingRight = UDim.new(0, compact and 10 or 16),
})

local content = new("ScrollingFrame", {
	Name = "Content",
	Position = UDim2.fromOffset(M.sidebarW, M.headerH),
	Size = UDim2.new(1, -M.sidebarW, 1, -M.headerH),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = THEME.AccentSoft,
	ScrollBarImageTransparency = 0.35,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 1,
}, {
	new("UIListLayout", { Padding = UDim.new(0, compact and 10 or 14), SortOrder = Enum.SortOrder.LayoutOrder }),
	contentPadding,
})
content.Parent = body

ui.contentScale = new("UIScale", { Scale = 1 })
ui.contentScale.Parent = content
ui.contentPos = UDim2.fromOffset(M.sidebarW, M.headerH)

function ui.pageIn()
	ui.contentScale.Scale = 0.985
	content.Position = UDim2.fromOffset(M.sidebarW, M.headerH + 10)
	TweenService:Create(content, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = ui.contentPos,
	}):Play()
	TweenService:Create(ui.contentScale, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()
end

window.Parent = gui

if not pcall(function()
	gui.Parent = resolveParent()
end) then
	gui.Parent = PlayerGui
end

local order = 0
local function nextOrder()
	order = order + 1
	return order
end

local function section(parent, text)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, {
		new("UIListLayout", { Padding = UDim.new(0, M.gap), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, M.sectionSize + 6),
		BackgroundTransparency = 1,
		Font = THEME.FontBold,
		Text = text,
		TextSize = M.sectionSize,
		TextColor3 = THEME.AccentText,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	}).Parent = holder

	local box = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Card,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		ClipsDescendants = true,
	}, {
		corner(M.radius),
		stroke(THEME.CardLine, 1, 0.3),
		new("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", {
			PaddingTop = UDim.new(0, 0),
			PaddingBottom = UDim.new(0, 0),
			PaddingLeft = UDim.new(0, M.rowPad),
			PaddingRight = UDim.new(0, M.rowPad),
		}),
	})
	box.Parent = holder
	holder.Parent = parent
	return box
end

local function rowLine(parent)
	new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, -M.rowPad, 1, -1),
		Size = UDim2.new(1, M.rowPad * 2, 0, 1),
		BackgroundColor3 = THEME.CardLine,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ZIndex = 1,
	}).Parent = parent
end

local function rowLabel(parent, text, widthScale)
	return new("TextLabel", {
		Position = UDim2.fromOffset(0, 0),
		Size = widthScale and UDim2.new(widthScale, -8, 1, 0) or UDim2.new(0.46, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.Font,
		Text = text,
		TextSize = M.labelSize,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
	})
end

local function makeToggle(parent, text, default, callback)
	local state = default and true or false

	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, M.rowH),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	})
	rowLabel(row, text).Parent = row
	rowLine(row)

	local hit = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	})
	hit.Parent = row

	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -2, 0.5, 0),
		Size = UDim2.fromOffset(M.toggleW, M.toggleH),
		BackgroundColor3 = state and THEME.Accent or THEME.Track,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, { corner(M.toggleH / 2) })

	local inset = 3
	local knobSize = M.toggleH - inset * 2
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, state and (M.toggleW - knobSize - inset) or inset, 0.5, 0),
		Size = UDim2.fromOffset(knobSize, knobSize),
		BackgroundColor3 = state and THEME.Knob or THEME.KnobOff,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, { corner(knobSize / 2) })

	knob.Parent = track
	track.Parent = row

	local function render(animate)
		local targetX = state and (M.toggleW - knobSize - inset) or inset
		local target = UDim2.new(0, targetX, 0.5, 0)
		if animate then
			TweenService:Create(knob, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = target }):Play()
			TweenService:Create(track, TweenInfo.new(0.12), { BackgroundColor3 = state and THEME.Accent or THEME.Track }):Play()
			TweenService:Create(knob, TweenInfo.new(0.12), { BackgroundColor3 = state and THEME.Knob or THEME.KnobOff }):Play()
		else
			knob.Position = target
			track.BackgroundColor3 = state and THEME.Accent or THEME.Track
			knob.BackgroundColor3 = state and THEME.Knob or THEME.KnobOff
		end
	end

	hit.MouseButton1Click:Connect(function()
		state = not state
		render(true)
		guard(callback, state)
	end)

	row.Parent = parent

	local api = {}
	function api.set(value)
		state = value and true or false
		render(true)
	end
	function api.get()
		return state
	end
	return api
end

function ui.status(parent, text)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, M.rowH - 4),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	})
	local label = new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.Font,
		Text = text,
		TextSize = M.labelSize - 2,
		TextColor3 = THEME.TextFaint,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	label.Parent = row
	row.Parent = parent
	return label
end

function ui.dropdown(parent, text, options, defaultIndex, callback)
	local count = #options
	local headerH = M.rowH
	local itemH = math.max(26, M.rowH - 6)
	local listH = count * itemH + (count - 1) * 2 + 8
	local index = math.clamp(defaultIndex or 1, 1, count)
	local open = false

	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, headerH),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	})

	local head = new("TextButton", {
		Size = UDim2.new(1, 0, 0, headerH),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 2,
	})
	head.Parent = row
	rowLabel(head, text, 0.42).Parent = head
	rowLine(head)

	local pillW = M.boxW + 26

	local pill = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -2, 0.5, 0),
		Size = UDim2.fromOffset(pillW, M.boxH),
		BackgroundColor3 = THEME.Field,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, { corner(5), stroke(THEME.RowBorder, 1, 0.1) })
	pill.Parent = head

	local valueLabel = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = THEME.Font,
		Text = options[index],
		TextSize = M.labelSize - 1,
		TextColor3 = THEME.Text,
		ZIndex = 3,
	})
	valueLabel.Parent = pill

	local caret = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -(pillW + 14), 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Font = THEME.FontBold,
		Text = "v",
		TextSize = M.labelSize - 3,
		TextColor3 = THEME.TextFaint,
		ZIndex = 3,
	})
	caret.Parent = head

	local list = new("Frame", {
		Position = UDim2.fromOffset(0, headerH),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = THEME.Field,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 1,
	}, {
		corner(6),
		new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}),
	})
	list.Parent = row

	local items = {}
	for i, option in ipairs(options) do
		local item = new("TextButton", {
			Size = UDim2.new(1, 0, 0, itemH),
			BackgroundColor3 = THEME.Card,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = THEME.Font,
			Text = option,
			TextSize = M.labelSize - 1,
			TextColor3 = THEME.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = 1,
			AutoButtonColor = false,
			LayoutOrder = i,
			ZIndex = 2,
		}, { corner(4) })
		new("UIPadding", { PaddingLeft = UDim.new(0, 10) }).Parent = item
		item.Parent = list
		items[i] = item
	end

	local function paint(animate)
		for i, item in ipairs(items) do
			local active = i == index
			item.TextColor3 = active and THEME.AccentText or THEME.TextDim
			item.Font = active and THEME.FontBold or THEME.Font
			if animate then
				TweenService:Create(item, TweenInfo.new(0.14), {
					BackgroundTransparency = active and 0.84 or 1,
				}):Play()
			else
				item.BackgroundTransparency = active and 0.84 or 1
			end
		end
		valueLabel.Text = options[index]
	end

	local function setOpen(state)
		open = state
		if state then
			list.Visible = true
		end
		TweenService:Create(row, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, state and (headerH + listH) or headerH),
		}):Play()
		TweenService:Create(list, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, state and listH or 0),
		}):Play()
		TweenService:Create(list, TweenInfo.new(0.18), {
			BackgroundTransparency = state and 0.35 or 1,
		}):Play()
		TweenService:Create(caret, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Rotation = state and 180 or 0,
		}):Play()
		for _, item in ipairs(items) do
			TweenService:Create(item, TweenInfo.new(0.16), {
				TextTransparency = state and 0 or 1,
			}):Play()
		end
		if not state then
			task.delay(0.22, function()
				if not open then
					list.Visible = false
				end
			end)
		end
	end

	head.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)

	for i, item in ipairs(items) do
		item.MouseButton1Click:Connect(function()
			index = i
			paint(true)
			setOpen(false)
			guard(callback, options[i])
		end)
		item.MouseEnter:Connect(function()
			if i ~= index then
				TweenService:Create(item, TweenInfo.new(0.1), {
					BackgroundTransparency = 0.7,
					TextColor3 = THEME.Text,
				}):Play()
			end
		end)
		item.MouseLeave:Connect(function()
			if i ~= index then
				TweenService:Create(item, TweenInfo.new(0.1), {
					BackgroundTransparency = 1,
					TextColor3 = THEME.TextDim,
				}):Play()
			end
		end)
	end

	row.Parent = parent
	paint(false)

	local api = {}
	function api.set(value)
		for i, option in ipairs(options) do
			if option == value then
				index = i
				paint(true)
				return
			end
		end
	end
	function api.get()
		return options[index]
	end
	return api
end

local ESP_COLORS = {
	Color3.fromRGB(139, 92, 246),
	Color3.fromRGB(124, 58, 237),
	Color3.fromRGB(59, 130, 246),
	Color3.fromRGB(6, 182, 212),
	Color3.fromRGB(16, 185, 129),
	Color3.fromRGB(132, 204, 22),
	Color3.fromRGB(250, 204, 21),
	Color3.fromRGB(249, 115, 22),
	Color3.fromRGB(239, 68, 68),
	Color3.fromRGB(236, 72, 153),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(203, 213, 225),
	Color3.fromRGB(148, 163, 184),
	Color3.fromRGB(100, 116, 139),
	Color3.fromRGB(51, 65, 85),
	Color3.fromRGB(15, 23, 42),
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(0, 255, 128),
	Color3.fromRGB(0, 162, 255),
	Color3.fromRGB(255, 0, 255),
	Color3.fromRGB(255, 128, 0),
	Color3.fromRGB(0, 255, 255),
	Color3.fromRGB(128, 0, 255),
	Color3.fromRGB(255, 255, 0),
}

function ui.color(parent, text, initial, callback)
	local current = initial or ESP_COLORS[1]
	local open = false
	local headerH = M.rowH
	local cell = compact and 24 or 30
	local gap = 6
	local columns = 6
	local rows = math.ceil(#ESP_COLORS / columns)
	local gridH = rows * cell + (rows - 1) * gap + 12

	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, headerH),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	})

	local head = new("TextButton", {
		Size = UDim2.new(1, 0, 0, headerH),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 2,
	})
	head.Parent = row
	rowLabel(head, text, 0.42).Parent = head
	rowLine(head)

	local swatch = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -2, 0.5, 0),
		Size = UDim2.fromOffset(M.boxW, M.boxH),
		BackgroundColor3 = current,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, { corner(5), stroke(THEME.RowBorder, 1, 0.1) })
	swatch.Parent = head

	local palette = new("Frame", {
		Position = UDim2.fromOffset(0, headerH),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = THEME.Field,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 1,
	}, {
		corner(6),
		new("UIGridLayout", {
			CellSize = UDim2.fromOffset(cell, cell),
			CellPadding = UDim2.fromOffset(gap, gap),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		new("UIPadding", {
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}),
	})
	palette.Parent = row

	local function setOpen(state)
		open = state
		if state then
			palette.Visible = true
		end
		TweenService:Create(row, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, state and (headerH + gridH) or headerH),
		}):Play()
		TweenService:Create(palette, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, state and gridH or 0),
		}):Play()
		TweenService:Create(palette, TweenInfo.new(0.18), {
			BackgroundTransparency = state and 0.35 or 1,
		}):Play()
		if not state then
			task.delay(0.22, function()
				if not open then
					palette.Visible = false
				end
			end)
		end
	end

	local chips = {}
	for index, color in ipairs(ESP_COLORS) do
		local chip = new("TextButton", {
			Size = UDim2.fromOffset(cell, cell),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = index,
			ZIndex = 2,
		}, { corner(5) })
		if color == current then
			stroke(Color3.fromRGB(255, 255, 255), 2).Parent = chip
		end
		chip.MouseButton1Click:Connect(function()
			current = color
			swatch.BackgroundColor3 = color
			for _, other in ipairs(chips) do
				local old = other:FindFirstChildOfClass("UIStroke")
				if old then
					old:Destroy()
				end
			end
			stroke(Color3.fromRGB(255, 255, 255), 2).Parent = chip
			setOpen(false)
			guard(callback, color)
		end)
		chip.Parent = palette
		chips[index] = chip
	end

	head.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)

	row.Parent = parent

	local api = {}
	function api.set(color)
		for _, value in ipairs(ESP_COLORS) do
			if value == color then
				current = value
				swatch.BackgroundColor3 = value
				return
			end
		end
	end
	function api.get()
		return current
	end
	return api
end

local function makeSlider(parent, text, min, max, default, precision, callback)
	local value = math.clamp(default, min, max)
	local dragging = false

	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, M.rowH),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	})
	rowLabel(row, text, 0.42).Parent = row
	rowLine(row)

	local control = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -2, 0.5, 0),
		Size = UDim2.new(0.54, 0, 0, M.rowH),
		BackgroundTransparency = 1,
	})
	control.Parent = row

	local box = new("Frame", {
		Position = UDim2.fromOffset(0, (M.rowH - M.boxH) / 2),
		Size = UDim2.fromOffset(M.boxW, M.boxH),
		BackgroundColor3 = THEME.Field,
		BorderSizePixel = 0,
	}, { corner(5), stroke(THEME.RowBorder, 1, 0.1) })
	box.Parent = control

	local readout = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = THEME.Font,
		Text = tostring(value),
		TextSize = M.labelSize - 1,
		TextColor3 = THEME.Text,
	})
	readout.Parent = box

	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(1, -(M.boxW + M.gap + 2), 0, 6),
		BackgroundColor3 = THEME.Track,
		BorderSizePixel = 0,
	}, { corner(3) })
	track.Parent = control

	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = THEME.AccentSoft,
		BorderSizePixel = 0,
	}, { corner(3) })
	fill.Parent = track

	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = THEME.Knob,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, { corner(7) })
	knob.Parent = track

	local function format(v)
		if precision and precision > 0 then
			return string.format("%." .. precision .. "f", v)
		end
		return tostring(math.floor(v + 0.5))
	end

	local function apply(alpha, fire)
		alpha = math.clamp(alpha, 0, 1)
		local raw = min + (max - min) * alpha
		local step = precision and precision > 0 and 0.1 or 1
		value = math.floor(raw / step + 0.5) * step
		value = math.clamp(value, min, max)
		local ratio = (value - min) / (max - min)
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		readout.Text = format(value)
		if fire then
			guard(callback, value)
		end
	end

	local function alphaFrom(posX)
		local width = track.AbsoluteSize.X
		if width <= 0 then
			return 0
		end
		return (posX - track.AbsolutePosition.X) / width
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			apply(alphaFrom(input.Position.X), true)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			apply(alphaFrom(input.Position.X), true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	row.Parent = parent
	apply((value - min) / (max - min), false)

	local api = {}
	function api.set(v)
		apply((math.clamp(v, min, max) - min) / (max - min), false)
	end
	function api.get()
		return value
	end
	return api
end

local function makeAction(parent, text, callback)
	local row = new("TextButton", {
		Size = UDim2.new(1, 0, 0, M.rowH),
		BackgroundColor3 = THEME.Row,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = nextOrder(),
	})
	rowLabel(row, text).Parent = row
	rowLine(row)

	row.MouseEnter:Connect(function()
		row.BackgroundTransparency = 0.6
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundTransparency = 1
	end)
	row.MouseButton1Click:Connect(function()
		guard(callback)
	end)

	row.Parent = parent
	return row
end

local function makeInputAction(parent, text, placeholder, buttonText, callback)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, M.rowH),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	})
	rowLabel(row, text, 0.42).Parent = row
	rowLine(row)

	local control = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -2, 0.5, 0),
		Size = UDim2.new(0.54, 0, 0, M.rowH),
		BackgroundTransparency = 1,
	})
	control.Parent = row

	local field = new("Frame", {
		Size = UDim2.new(1, -(M.btnW + M.gap), 0, M.boxH),
		Position = UDim2.fromOffset(0, (M.rowH - M.boxH) / 2),
		BackgroundColor3 = THEME.Field,
		BorderSizePixel = 0,
	}, { corner(5), stroke(THEME.RowBorder, 1, 0.1) })
	field.Parent = control

	local input = new("TextBox", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = THEME.Font,
		Text = "",
		PlaceholderText = placeholder,
		PlaceholderColor3 = THEME.TextFaint,
		TextSize = M.labelSize - 1,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
	})
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 6),
	}).Parent = input
	input.Parent = field

	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(M.btnW, M.btnH),
		BackgroundColor3 = THEME.Accent,
		BorderSizePixel = 0,
		Font = THEME.FontBold,
		Text = buttonText,
		TextSize = M.labelSize - 1,
		TextColor3 = THEME.Text,
		AutoButtonColor = false,
	}, { corner(5) })
	btn.Parent = control

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = THEME.AccentSoft
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = THEME.Accent
	end)
	btn.MouseButton1Click:Connect(function()
		guard(callback, input.Text)
	end)

	row.Parent = parent
	return input
end

local function makeButtonRow(parent, text, buttonText, callback)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, M.rowH),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	})
	rowLabel(row, text, 0.62).Parent = row
	rowLine(row)

	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -2, 0.5, 0),
		Size = UDim2.fromOffset(M.btnW, M.btnH),
		BackgroundColor3 = THEME.Accent,
		BorderSizePixel = 0,
		Font = THEME.FontBold,
		Text = buttonText,
		TextSize = M.labelSize - 1,
		TextColor3 = THEME.Text,
		AutoButtonColor = false,
	}, { corner(5) })
	btn.Parent = row

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = THEME.AccentSoft
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = THEME.Accent
	end)
	btn.MouseButton1Click:Connect(function()
		guard(callback)
	end)

	row.Parent = parent
	return row
end

local pages = {}
local activePage

local function makePage(name)
	local page = new("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, compact and 10 or 14), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	page.Parent = content

	local tab = new("TextButton", {
		Name = name,
		Size = UDim2.new(1, 0, 0, M.tabH),
		BackgroundColor3 = THEME.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = THEME.FontMed,
		Text = name,
		TextSize = M.tabText,
		TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		LayoutOrder = nextOrder(),
		ZIndex = 2,
	}, { corner(M.radius) })

	new("UIPadding", { PaddingLeft = UDim.new(0, compact and 12 or 20) }).Parent = tab

	local hovered = false

	local function paint(active, animate)
		local target = {
			BackgroundTransparency = active and 0 or (hovered and 0.88 or 1),
			TextColor3 = active and THEME.Text or (hovered and THEME.Text or THEME.TextDim),
		}
		if animate then
			TweenService:Create(tab, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), target):Play()
		else
			tab.BackgroundTransparency = target.BackgroundTransparency
			tab.TextColor3 = target.TextColor3
		end
		tab.Font = active and THEME.FontBold or THEME.FontMed
	end

	local function select()
		for _, entry in pairs(pages) do
			local active = entry.page == page
			entry.page.Visible = active
			if active then
				entry.paint(true, true)
			else
				entry.paint(false, true)
			end
		end
		content.CanvasPosition = Vector2.new(0, 0)
		activePage = page
		ui.pageIn()
	end

	tab.MouseEnter:Connect(function()
		hovered = true
		if activePage ~= page then
			TweenService:Create(tab, TweenInfo.new(0.12), {
				TextColor3 = THEME.Text,
				BackgroundTransparency = 0.88,
			}):Play()
		end
	end)
	tab.MouseLeave:Connect(function()
		hovered = false
		if activePage ~= page then
			TweenService:Create(tab, TweenInfo.new(0.12), {
				TextColor3 = THEME.TextDim,
				BackgroundTransparency = 1,
			}):Play()
		end
	end)
	tab.MouseButton1Click:Connect(function()
		select()
	end)

	tab.Parent = sidebar
	table.insert(pages, { page = page, tab = tab, select = select, paint = paint })
	return page
end

local savedLighting = {
	brightness = Lighting.Brightness,
	outdoor = Lighting.OutdoorAmbient,
	ambient = Lighting.Ambient,
	fog = Lighting.FogEnd,
}

local function setFullbright(on)
	Lighting.Brightness = on and 3 or savedLighting.brightness
	Lighting.OutdoorAmbient = on and Color3.fromRGB(255, 255, 255) or savedLighting.outdoor
	Lighting.Ambient = on and Color3.fromRGB(200, 200, 200) or savedLighting.ambient
	Lighting.FogEnd = on and 1e6 or savedLighting.fog
end

local phase = {
	active = false,
	connection = nil,
	savedCFrame = nil,
	parts = {},
}

local function rememberPart(part)
	local entry = phase.parts[part]
	if entry == nil then
		entry = {
			transparency = part.Transparency,
			collide = part.CanCollide,
			modifier = part.LocalTransparencyModifier,
		}
		phase.parts[part] = entry
	end
	return entry
end

local function hidePart(part)
	rememberPart(part)
	part.CanCollide = false
	part.Transparency = 1
	part.LocalTransparencyModifier = 1
end

local function enterPhase()
	local root = getRoot()
	local char = LocalPlayer.Character
	if not root or not char then
		return
	end
	phase.savedCFrame = root.CFrame
	phase.parts = {}
	phase.connection = RunService.Stepped:Connect(function()
		local current = LocalPlayer.Character
		if not current then
			return
		end
		for _, part in ipairs(current:GetDescendants()) do
			if part:IsA("BasePart") then
				hidePart(part)
			end
		end
	end)
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			hidePart(part)
		end
	end
end

local function exitPhase()
	if phase.connection then
		phase.connection:Disconnect()
		phase.connection = nil
	end
	for part, entry in pairs(phase.parts) do
		if part and part.Parent then
			part.CanCollide = entry.collide
			part.Transparency = entry.transparency
			part.LocalTransparencyModifier = entry.modifier
		end
	end
	phase.parts = {}
	local saved = phase.savedCFrame
	phase.savedCFrame = nil
	if saved then
		local root = getRoot()
		if root then
			root.CFrame = saved
		end
	end
end

local function setNoclip(on)
	if on == phase.active then
		return
	end
	phase.active = on
	if on then
		enterPhase()
	else
		exitPhase()
	end
end

local infiniteJumpConnection
local function setInfiniteJump(on)
	if infiniteJumpConnection then
		infiniteJumpConnection:Disconnect()
		infiniteJumpConnection = nil
	end
	if not on then
		return
	end
	infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
		local humanoid = getHumanoid()
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end

local antiAfkConnection
local function setAntiAfk(on)
	if antiAfkConnection then
		antiAfkConnection:Disconnect()
		antiAfkConnection = nil
	end
	if not on then
		return
	end
	antiAfkConnection = LocalPlayer.Idled:Connect(function()
		guard(function()
			local vu = game:GetService("VirtualUser")
			vu:CaptureController()
			vu:ClickButton2(Vector2.new())
		end)
	end)
end

local silent

local weapon = {
	ammo = false,
	recoil = false,
	spread = false,
	rapid = false,
	trigger = false,
	firing = false,
	rate = 20,
	lastShot = 0,
	ammoTick = 0,
	scanTick = 0,
	anchor = nil,
	remote = nil,
	method = nil,
	shotArgs = nil,
	captured = 0,
	tables = {},
	hooked = false,
	castHooks = true,
	mouseSpoof = true,
	cameraSpoof = false,
	redirect = true,
	captureDeny = { "move", "walk", "camera", "look", "rotate", "sync", "position", "cframe", "update", "input", "mouse", "character", "humanoid", "state", "velocity", "anim", "spawn", "respawn", "weld", "ragdoll", "health" },
	castNames = {
		Raycast = true,
		FindPartOnRay = true,
		FindPartOnRayWithIgnoreList = true,
		FindPartOnRayWithWhitelist = true,
		Spherecast = true,
		Blockcast = true,
		ScreenPointToRay = true,
		ViewportPointToRay = true,
		GetMouseLocation = true,
	},
	aim = nil,
	keys = {
		ammo = true,
		ammunition = true,
		clip = true,
		magazine = true,
		mag = true,
		bullet = true,
		bullets = true,
		round = true,
		rounds = true,
		reserve = true,
		shot = true,
		shots = true,
	},
	deny = { "damage", "dmg", "speed", "rate", "time", "multiplier", "force", "power", "cost", "price", "attachment", "drop", "cooldown", "delay", "interval", "period", "reload" },
	verbs = { "fire", "shoot", "shot", "attack", "bullet", "hit", "gun", "weapon", "damage", "swing", "blast", "ray", "arrow", "bow", "laser", "beam", "projectile", "snipe", "rifle", "pistol", "shotgun", "smg", "lmg", "dmg", "pierce", "cast", "spell", "melee", "punch", "taser", "gunfire", "muzzle" },
}

function weapon.tool()
	local char = LocalPlayer.Character
	if char then
		local held = char:FindFirstChildOfClass("Tool")
		if held then
			return held
		end
	end
	local pack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if pack then
		return pack:FindFirstChildOfClass("Tool")
	end
	return nil
end

function weapon.matches(name)
	local raw = string.lower(tostring(name))
	for _, deny in ipairs(weapon.deny) do
		if string.find(raw, deny, 1, true) then
			return false
		end
	end
	local spaced = string.gsub(tostring(name), "(%l)(%u)", "%1 %2")
	for token in string.gmatch(string.lower(spaced), "[%a]+") do
		if weapon.keys[token] then
			return true
		end
	end
	return false
end

function weapon.isShot(name)
	for _, verb in ipairs(weapon.verbs) do
		if string.find(name, verb, 1, true) then
			return true
		end
	end
	return false
end

function weapon.overMenu(position)
	if window.Visible == false then
		return false
	end
	local origin = window.AbsolutePosition
	local size = window.AbsoluteSize
	return position.X >= origin.X and position.X <= origin.X + size.X
		and position.Y >= origin.Y and position.Y <= origin.Y + size.Y
end

function weapon.locked()
	local aim = weapon.aim
	if not aim or not aim.enabled then
		return nil
	end
	return aim.world
end

function weapon.shotActive()
	if weapon.firing or weapon.trigger then
		return true
	end
	return (weapon.shotUntil or 0) >= os.clock()
end

function weapon.direction()
	if weapon.redirect == false then
		return nil
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	local world = weapon.locked()
	if world then
		local delta = world - camera.CFrame.Position
		if delta.Magnitude > 0.05 then
			return delta.Unit
		end
	end
	if weapon.spread then
		return camera.CFrame.LookVector
	end
	return nil
end

weapon.dirs = {
	direction = true, dir = true, look = true, lookvector = true, aim = true,
	aimdir = true, aimdirection = true, vector = true, unit = true, normal = true,
	velocity = true, vel = true, shot = true, shotdir = true, projectile = true,
	trajectory = true, heading = true, forward = true,
}

weapon.frames = {
	cframe = true, lookcframe = true, aimcframe = true, rotation = true,
	orientation = true, orientationcframe = true,
}

function weapon.walk(container, here, look, dir, depth)
	if depth > 3 or type(container) ~= "table" then
		return 0
	end
	local changed = 0
	for key, value in pairs(container) do
		local kind = typeof(value)
		if kind == "Vector3" then
			local named = type(key) == "string" and weapon.dirs[string.lower(key)]
			local reach = value.Magnitude
			if named then
				container[key] = dir * (reach > 0.05 and reach or 1)
				changed = changed + 1
			else
				local offset = value - here
				if offset.Magnitude > 12 and offset.Unit:Dot(look) >= 0.6 then
					container[key] = dir * reach
					changed = changed + 1
				end
			end
		elseif kind == "CFrame" then
			local named = type(key) == "string" and weapon.frames[string.lower(key)]
			local facing = value.LookVector:Dot(look) >= 0.75
			if named or ((value.Position - here).Magnitude <= 10 and facing) then
				container[key] = CFrame.lookAt(value.Position, value.Position + dir)
				changed = changed + 1
			end
		elseif kind == "table" then
			changed = changed + weapon.walk(value, here, look, dir, depth + 1)
		end
	end
	return changed
end

function weapon.rewrite(pack)
	local dir = weapon.direction()
	if not dir then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local here = camera.CFrame.Position
	local look = camera.CFrame.LookVector
	local hasOrigin = false
	for index = 1, pack.n do
		local value = pack[index]
		if typeof(value) == "Vector3" and (value - here).Magnitude <= 8 then
			hasOrigin = true
		end
	end
	local changed = 0
	for index = 1, pack.n do
		local value = pack[index]
		local kind = typeof(value)
		if kind == "Vector3" then
			local reach = value.Magnitude
			local offset = value - here
			if offset.Magnitude > 12 then
				if offset.Unit:Dot(look) >= 0.6 then
					pack[index] = dir * reach
					changed = changed + 1
				end
			elseif reach >= 0.5 and reach <= 1.5 then
				if hasOrigin or value.Unit:Dot(look) >= 0.85 then
					pack[index] = dir * reach
					changed = changed + 1
				end
			end
		elseif kind == "CFrame" then
			if (value.Position - here).Magnitude <= 10 and value.LookVector:Dot(look) >= 0.75 then
				pack[index] = CFrame.lookAt(value.Position, value.Position + dir)
				changed = changed + 1
			end
		elseif kind == "table" then
			changed = changed + weapon.walk(value, here, look, dir, 1)
		end
	end
	if changed > 0 then
		silent.stats.remotes = silent.stats.remotes + changed
	end
end

function weapon.nearAimOrigin(origin)
	if typeof(origin) ~= "Vector3" then
		return false
	end
	local camera = workspace.CurrentCamera
	if camera and (origin - camera.CFrame.Position).Magnitude <= 60 then
		return true
	end
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and (origin - root.Position).Magnitude <= 30 then
		return true
	end
	return false
end

function weapon.looksLikeShot(pack)
	local camera = workspace.CurrentCamera
	if not camera or type(pack) ~= "table" then
		return false
	end
	local here = camera.CFrame.Position
	local look = camera.CFrame.LookVector
	for index = 1, math.min(pack.n or 0, 10) do
		local value = pack[index]
		local kind = typeof(value)
		if kind == "Vector3" then
			local reach = value.Magnitude
			if reach >= 0.5 and reach <= 1.5 and value:Dot(look) >= 0.6 then
				return true
			end
			local offset = value - here
			if offset.Magnitude > 12 and offset.Unit:Dot(look) >= 0.6 then
				return true
			end
		elseif kind == "CFrame" then
			if (value.Position - here).Magnitude <= 12 and value.LookVector:Dot(look) >= 0.6 then
				return true
			end
		end
	end
	return false
end

function weapon.captureShot(name, pack)
	if not weapon.firing or type(pack) ~= "table" then
		return false
	end
	local lower = string.lower(tostring(name or ""))
	for _, word in ipairs(weapon.captureDeny) do
		if string.find(lower, word, 1, true) then
			return false
		end
	end
	return weapon.looksLikeShot(pack)
end

function weapon.tryCast(target, method, original, ...)
	if type(method) ~= "string" or not weapon.castNames[method] then
		return nil
	end
	if weapon.castHooks == false or weapon.redirect == false then
		return nil
	end
	if not weapon.locked() then
		return nil
	end
	if not weapon.shotActive() then
		return nil
	end
	local dir = weapon.direction()
	if not dir then
		return nil
	end
	local camera = workspace.CurrentCamera
	local args = table.pack(...)

	if method == "Raycast" and typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
		local reach = args[2].Magnitude
		if reach > 0.01 and weapon.nearAimOrigin(args[1]) then
			args[2] = dir * reach
			return table.pack(original(target, table.unpack(args, 1, args.n)))
		end
		return nil
	end

	if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
		local ray = args[1]
		if typeof(ray) == "Ray" then
			local span = ray.Direction.Magnitude
			args[1] = Ray.new(ray.Origin, dir * (span > 0.01 and span or 1))
			return table.pack(original(target, table.unpack(args, 1, args.n)))
		end
		return nil
	end

	if method == "Spherecast" and typeof(args[1]) == "Vector3" and typeof(args[3]) == "Vector3" then
		local reach = args[3].Magnitude
		if reach > 0.01 and weapon.nearAimOrigin(args[1]) then
			args[3] = dir * reach
			return table.pack(original(target, table.unpack(args, 1, args.n)))
		end
		return nil
	end

	if method == "Blockcast" and typeof(args[1]) == "CFrame" and typeof(args[3]) == "Vector3" then
		local reach = args[3].Magnitude
		if reach > 0.01 and weapon.nearAimOrigin(args[1].Position) then
			args[3] = dir * reach
			return table.pack(original(target, table.unpack(args, 1, args.n)))
		end
		return nil
	end

	if method == "ScreenPointToRay" or method == "ViewportPointToRay" then
		local okCam, isCamera = pcall(function()
			return target:IsA("Camera")
		end)
		if not okCam or not isCamera then
			return nil
		end
		local results = table.pack(original(target, table.unpack(args, 1, args.n)))
		local ray = results[1]
		if typeof(ray) == "Ray" then
			local span = ray.Direction.Magnitude
			results[1] = Ray.new(ray.Origin, dir * (span > 0.01 and span or 1))
		end
		return results
	end

	if method == "GetMouseLocation" then
		if weapon.mouseSpoof == false then
			return nil
		end
		if target ~= UserInputService or not camera then
			return nil
		end
		local world = weapon.locked()
		if not world then
			return nil
		end
		local point = camera:WorldToViewportPoint(world)
		if point.Z <= 0 then
			return nil
		end
		return table.pack(Vector2.new(point.X, point.Y))
	end

	return nil
end

function weapon.handle(target, method, original, ...)
	local pack = table.pack(...)
	local name = ""
	pcall(function()
		name = string.lower(target.Name)
	end)
	if weapon.log and (weapon.logCount or 0) < 200 then
		weapon.logCount = (weapon.logCount or 0) + 1
		local parts = {}
		for index = 1, math.min(pack.n, 8) do
			local value = pack[index]
			local kind = typeof(value)
			if kind == "Vector3" then
				parts[#parts + 1] = string.format("V3(%.1f,%.1f,%.1f)", value.X, value.Y, value.Z)
			elseif kind == "CFrame" then
				parts[#parts + 1] = string.format("CF(%.1f,%.1f,%.1f)", value.Position.X, value.Position.Y, value.Position.Z)
			elseif kind == "table" then
				parts[#parts + 1] = "table"
			else
				parts[#parts + 1] = tostring(value)
			end
		end
		print("[aj.lol shot] " .. string.lower(tostring(name)) .. " / " .. method .. " / " .. table.concat(parts, " | "))
	end
	if weapon.isShot(name) then
		weapon.remote = target
		weapon.method = method
		weapon.captured = os.clock()
		weapon.shotArgs = table.pack(table.unpack(pack, 1, pack.n))
	elseif weapon.captureShot(name, pack)
		and (not weapon.remote or os.clock() - (weapon.captured or 0) > 0.35) then
		weapon.remote = target
		weapon.method = method
		weapon.captured = os.clock()
		weapon.shotArgs = table.pack(table.unpack(pack, 1, pack.n))
	end
	if weapon.locked() and (weapon.spread or weapon.isShot(name) or weapon.shotActive()) then
		weapon.rewrite(pack)
	end
	return original(target, table.unpack(pack, 1, pack.n))
end

function weapon.install()
	if weapon.hooked then
		return
	end
	if typeof(getnamecallmethod) ~= "function" then
		return
	end
	local original = hookMeta(game, "__namecall", function(base)
		return function(target, ...)
			local method = getnamecallmethod()
			if method == "FireServer" or method == "InvokeServer" then
				return weapon.handle(target, method, base, ...)
			end
			local cast = weapon.tryCast(target, method, base, ...)
			if cast then
				return table.unpack(cast, 1, cast.n)
			end
			return base(target, ...)
		end
	end)
	if typeof(original) == "function" then
		weapon.hooked = true
	end
end

function weapon.shoot()
	weapon.shotUntil = os.clock() + 0.4
	local fired = false
	local tool = weapon.tool()
	if tool then
		local ok = pcall(function()
			tool:Activate()
		end)
		fired = ok or fired
	end
	if weapon.remote and weapon.shotArgs and os.clock() - weapon.captured < 8 then
		local pack = table.pack(table.unpack(weapon.shotArgs, 1, weapon.shotArgs.n))
		weapon.rewrite(pack)
		local ok = pcall(function()
			weapon.remote[weapon.method](weapon.remote, table.unpack(pack, 1, pack.n))
		end)
		fired = ok or fired
	end
	return fired
end

function weapon.refill()
	local sources = { weapon.tool() }
	local char = LocalPlayer.Character
	if char then
		sources[#sources + 1] = char
	end
	local pack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if pack then
		sources[#sources + 1] = pack
	end
	for _, source in ipairs(sources) do
		if source then
			local ok, list = pcall(function()
				return source:GetDescendants()
			end)
			if ok and list then
				for _, entry in ipairs(list) do
					if (entry.ClassName == "IntValue" or entry.ClassName == "NumberValue")
						and entry.Value < 999 and weapon.matches(entry.Name) then
						entry.Value = 999
					end
				end
			end
			local okAttr, attrs = pcall(function()
				return source:GetAttributes()
			end)
			if okAttr and attrs then
				for name, value in pairs(attrs) do
					if type(value) == "number" and value < 999 and weapon.matches(name) then
						pcall(function()
							source:SetAttribute(name, 999)
						end)
					end
				end
			end
		end
	end
	for _, record in ipairs(weapon.tables) do
		local live = record[1][record[2]]
		if type(live) == "number" and live < 999 then
			record[1][record[2]] = 999
		end
	end
end

function weapon.scan()
	if typeof(getgc) ~= "function" then
		return
	end
	local ok, list = pcall(getgc, true)
	if not ok or type(list) ~= "table" then
		return
	end
	local found = {}
	local kept = 0
	for _, entry in ipairs(list) do
		if type(entry) == "table" and kept < 64
			and entry ~= weapon and entry ~= weapon.aim and entry ~= weapon.keys
			and entry ~= weapon.deny and entry ~= weapon.verbs and entry ~= weapon.tables then
			local hits = 0
			for key, value in pairs(entry) do
				if type(key) == "string" and type(value) == "number"
					and value >= 0 and value < 500 and weapon.matches(key) then
					entry[key] = 999
					found[#found + 1] = { entry, key }
					hits = hits + 1
					if hits >= 4 then
						break
					end
				end
			end
			if hits > 0 then
				kept = kept + 1
			end
		end
	end
	weapon.tables = found
end

function weapon.recoilStep()
	if not weapon.recoil or not weapon.firing then
		weapon.anchor = nil
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	if not weapon.anchor then
		weapon.anchor = camera.CFrame
		return
	end
	local anchorPitch = math.asin(math.clamp(weapon.anchor.LookVector.Y, -1, 1))
	local livePitch = math.asin(math.clamp(camera.CFrame.LookVector.Y, -1, 1))
	local fix = anchorPitch - livePitch
	if math.abs(fix) > 0.0005 then
		camera.CFrame = camera.CFrame * CFrame.Angles(fix, 0, 0)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	local kind = input.UserInputType
	if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
		return
	end
	if kind == Enum.UserInputType.Touch then
		if not processed or weapon.overMenu(input.Position) then
			return
		end
	elseif processed then
		return
	end
	weapon.firing = true
	weapon.anchor = nil
end)

UserInputService.InputEnded:Connect(function(input)
	local kind = input.UserInputType
	if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
		weapon.firing = false
		weapon.anchor = nil
	end
end)

RunService.Heartbeat:Connect(function()
	if not (weapon.ammo or weapon.rapid or weapon.trigger) then
		return
	end
	local now = os.clock()
	if weapon.ammo and now >= weapon.ammoTick then
		weapon.ammoTick = now + 0.1
		weapon.refill()
		if now >= weapon.scanTick then
			weapon.scanTick = now + 5
			pcall(weapon.scan)
		end
	end
	local want = false
	if weapon.rapid and weapon.firing then
		want = true
	end
	if weapon.trigger and weapon.locked() then
		want = true
	end
	if want and now - weapon.lastShot >= 1 / math.max(weapon.rate, 1) then
		weapon.lastShot = now
		weapon.shoot()
	end
end)

if not pcall(function()
	RunService:BindToRenderStep("AJLOL_Recoil", Enum.RenderPriority.Camera.Value + 2, weapon.recoilStep)
end) then
	RunService.RenderStepped:Connect(weapon.recoilStep)
end

weapon.install()

local autoClickConnection
local clickDelay = 100
local function setAutoClick(on)
	if autoClickConnection then
		autoClickConnection:Disconnect()
		autoClickConnection = nil
	end
	if not on then
		return
	end
	autoClickConnection = task.spawn(function()
		while true do
			guard(function()
				UserInputService:ClickButton1(Vector2.new(vp.X / 2, vp.Y / 2), Camera)
			end)
			task.wait(clickDelay / 1000)
		end
	end)
end

local esp = {
	enabled = false,
	objects = {},
	connections = {},
	loop = nil,
	color = Color3.fromRGB(139, 92, 246),
}

local function destroyEspObject(char)
	local obj = esp.objects[char]
	if not obj then
		return
	end
	if obj.highlight and obj.highlight.Parent then
		obj.highlight:Destroy()
	end
	if obj.billboard and obj.billboard.Parent then
		obj.billboard:Destroy()
	end
	if obj.bones then
		for _, frame in ipairs(obj.bones) do
			if frame.Parent then
				frame:Destroy()
			end
		end
	end
	if obj.box then
		for _, frame in ipairs(obj.box) do
			if frame.Parent then
				frame:Destroy()
			end
		end
	end
	if obj.tracer and obj.tracer.Parent then
		obj.tracer:Destroy()
	end
	esp.objects[char] = nil
end

local function clearEsp()
	for char in pairs(esp.objects) do
		destroyEspObject(char)
	end
	esp.objects = {}
	for _, conn in ipairs(esp.connections) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	esp.connections = {}
	if esp.loop then
		pcall(task.cancel, esp.loop)
		esp.loop = nil
	end
end

local function attachEsp(plr, char)
	if not char or esp.objects[char] then
		return
	end
	local anchor = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	local tint = esp.color
	local highlight = new("Highlight", {
		FillColor = tint,
		FillTransparency = 0.35,
		OutlineColor = tint:Lerp(Color3.new(1, 1, 1), 0.35),
		OutlineTransparency = 0.05,
		Adornee = char,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	})
	highlight.Parent = char

	local billboard
	local fill
	local distance
	if anchor then
		billboard = new("BillboardGui", {
			Name = "ajEsp",
			Adornee = anchor,
			AlwaysOnTop = true,
			Size = UDim2.fromOffset(120, 40),
			StudsOffsetWorldSpace = Vector3.new(0, 2.3, 0),
			MaxDistance = 5000,
			LightInfluence = 0,
			ResetOnSpawn = false,
		})

		local holder = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		})
		holder.Parent = billboard

		new("TextLabel", {
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 15),
			BackgroundTransparency = 1,
			Font = THEME.FontBold,
			Text = plr.Name,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextStrokeTransparency = 0.35,
			TextXAlignment = Enum.TextXAlignment.Center,
		}).Parent = holder

		local track = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 16),
			Size = UDim2.new(1, -40, 0, 4),
			BackgroundColor3 = Color3.fromRGB(24, 24, 30),
			BorderSizePixel = 0,
		}, { corner(2) })
		track.Parent = holder

		fill = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = tint,
			BorderSizePixel = 0,
		}, { corner(2) })
		fill.Parent = track

		distance = new("TextLabel", {
			Position = UDim2.fromOffset(0, 22),
			Size = UDim2.new(1, 0, 0, 13),
			BackgroundTransparency = 1,
			Font = THEME.Font,
			Text = "0m",
			TextSize = 11,
			TextColor3 = tint,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		distance.Parent = holder

		billboard.Parent = anchor
	end

	esp.objects[char] = {
		player = plr,
		highlight = highlight,
		billboard = billboard,
		fill = fill,
		distance = distance,
	}
end

local function startEspLoop()
	esp.loop = task.spawn(function()
		while esp.enabled do
			for char, obj in pairs(esp.objects) do
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				local root = char:FindFirstChild("HumanoidRootPart")
				if humanoid and obj.fill then
					local ratio = humanoid.Health / math.max(humanoid.MaxHealth, 1)
					obj.fill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
					obj.fill.BackgroundColor3 = ratio > 0.5 and esp.color
						or (ratio > 0.2 and Color3.fromRGB(226, 178, 66) or Color3.fromRGB(214, 74, 74))
				end
				if root and obj.distance and Camera then
					local d = (Camera.CFrame.Position - root.Position).Magnitude
					obj.distance.Text = string.format("%dm", math.floor(d))
				end
			end
			task.wait(0.2)
		end
	end)
end

local function setEsp(on)
	esp.enabled = on
	clearEsp()
	if not on then
		return
	end
	local function track(plr)
		if plr.Character then
			attachEsp(plr, plr.Character)
		end
		table.insert(esp.connections, plr.CharacterAdded:Connect(function(char)
			task.wait(0.4)
			if esp.enabled then
				attachEsp(plr, char)
			end
		end))
		table.insert(esp.connections, plr.CharacterRemoving:Connect(function(char)
			destroyEspObject(char)
		end))
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			track(plr)
		end
	end
	table.insert(esp.connections, Players.PlayerAdded:Connect(function(plr)
		if not esp.enabled or plr == LocalPlayer then
			return
		end
		task.spawn(function()
			local ok, char = pcall(function()
				return plr.CharacterAdded:Wait()
			end)
			if ok and char and esp.enabled then
				track(plr)
				attachEsp(plr, char)
			end
		end)
	end))
	table.insert(esp.connections, Players.PlayerRemoving:Connect(function(plr)
		if plr.Character then
			destroyEspObject(plr.Character)
		end
	end))
	startEspLoop()
end

local function applyEspColor(color)
	if typeof(color) ~= "Color3" then
		return
	end
	esp.color = color
	local outline = color:Lerp(Color3.new(1, 1, 1), 0.35)
	for _, obj in pairs(esp.objects) do
		if obj.highlight then
			obj.highlight.FillColor = color
			obj.highlight.OutlineColor = outline
		end
		if obj.distance then
			obj.distance.TextColor3 = color
		end
		if obj.bones then
			for _, frame in ipairs(obj.bones) do
				frame.BackgroundColor3 = color
			end
		end
		if obj.box then
			for _, frame in ipairs(obj.box) do
				frame.BackgroundColor3 = color
			end
		end
		if obj.tracer then
			obj.tracer.BackgroundColor3 = color
		end
	end
end

silent = {
	enabled = false,
	fov = 220,
	target = nil,
	locked = nil,
	screen = nil,
	world = nil,
	worldPart = nil,
	method = "silent",
	bone = "Head",
	stats = { rays = 0, remotes = 0 },
	bones = {
		Head = { "Head" },
		Chest = { "UpperTorso", "Torso" },
		Stomach = { "LowerTorso", "Torso" },
		Legs = { "LeftUpperLeg", "RightUpperLeg", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot" },
		Nearest = { "Head", "UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart" },
	},
}

weapon.aim = silent

local syncUi = {}

local espStyle = {
	skeleton = false,
	box = false,
	tracers = false,
	includeTeam = false,
	teamCheck = true,
	friendCheck = true,
}

local overlay = new("ScreenGui", {
	Name = "AJOverlay",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 2 ^ 20 - 1,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
if not pcall(function()
	overlay.Parent = resolveParent()
end) then
	overlay.Parent = PlayerGui
end

local notifGui = new("ScreenGui", {
	Name = "AJNotif",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 2 ^ 20 + 1,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
if not pcall(function()
	notifGui.Parent = resolveParent()
end) then
	notifGui.Parent = PlayerGui
end

local notifStack = new("Frame", {
	Name = "Stack",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 12),
	Size = UDim2.fromOffset(compact and 190 or 264, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
}, {
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}),
})
notifStack.Parent = notifGui

local notifOrder = 0

local function notify(titleText, bodyText, life)
	notifOrder = notifOrder + 1
	local width = compact and 190 or 264
	local height = bodyText and (compact and 46 or 54) or (compact and 32 or 38)
	local card = new("CanvasGroup", {
		Name = "Toast",
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = THEME.Window,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = notifOrder,
		GroupTransparency = 1,
	}, { corner(8), stroke(THEME.AccentSoft, 1, 0.4) })
	local bar = new("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = THEME.AccentSoft,
		BorderSizePixel = 0,
	})
	bar.Parent = card
	new("TextLabel", {
		Position = UDim2.fromOffset(12, bodyText and (compact and 6 or 8) or 0),
		Size = bodyText and UDim2.new(1, -22, 0, compact and 15 or 17) or UDim2.new(1, -22, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.FontBold,
		Text = titleText,
		TextSize = compact and 12 or 13,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}).Parent = card
	if bodyText then
		new("TextLabel", {
			Position = UDim2.fromOffset(12, compact and 22 or 27),
			Size = UDim2.new(1, -22, 0, compact and 16 or 18),
			BackgroundTransparency = 1,
			Font = THEME.Font,
			Text = bodyText,
			TextSize = compact and 10 or 11,
			TextColor3 = THEME.TextFaint,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}).Parent = card
	end
	card.Parent = notifStack

	TweenService:Create(card, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		GroupTransparency = 0,
	}):Play()

	task.delay(life or 3, function()
		if not card.Parent then
			return
		end
		local out = TweenService:Create(card, TweenInfo.new(0.25), { GroupTransparency = 1 })
		out:Play()
		out.Completed:Wait()
		if card.Parent then
			card:Destroy()
		end
	end)
	return card
end

local guiInset = Vector2.new(0, 0)

local function refreshInset()
	guiInset = Vector2.new(0, 0)
end

local function overlayPoint(point)
	return point
end

local function placeLine(frame, a, b, thickness)
	if not a or not b then
		frame.Visible = false
		return
	end
	local delta = b - a
	local length = math.max(delta.Magnitude, 1)
	frame.Visible = true
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	frame.Size = UDim2.fromOffset(length, thickness or 1)
	frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
end

local ring = new("Frame", {
	Name = "FovRing",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(silent.fov * 2, silent.fov * 2),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
}, {
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
	stroke(THEME.AccentSoft, 1, 0.2),
})
ring.Parent = overlay

local cross = new("Frame", {
	Name = "Crosshair",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(16, 16),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
})
cross.Parent = overlay

for _, angle in ipairs({ 45, -45 }) do
	new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(14, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Rotation = angle,
	}).Parent = cross
end

local aimLine = new("Frame", {
	Name = "AimLine",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(0, 2),
	BackgroundColor3 = THEME.AccentSoft,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 2,
})
aimLine.Parent = overlay

local aimDot = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(1, 0.5),
	Size = UDim2.fromOffset(6, 6),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	ZIndex = 3,
}, { corner(3) })
aimDot.Parent = aimLine

local protectedIds = {}
local protectedNames = {}
local friendIds = {}
local friendSyncStarted = false
local teamSplit = false

local function hasSplitTeams()
	if #Teams:GetTeams() > 1 then
		return true
	end
	local first = nil
	for _, plr in ipairs(Players:GetPlayers()) do
		local team = plr.Team
		if team then
			if not first then
				first = team
			elseif team ~= first then
				return true
			end
		end
	end
	return false
end

local function onSameTeam(plr)
	local mine = LocalPlayer.Team
	local theirs = plr.Team
	if not mine or not theirs or mine ~= theirs then
		return false
	end
	return teamSplit
end

local function syncFriends()
	if friendSyncStarted then
		return
	end
	friendSyncStarted = true
	task.spawn(function()
		local ok, pages = pcall(function()
			return Players:GetFriendsAsync(LocalPlayer.UserId)
		end)
		if not ok or not pages then
			friendSyncStarted = false
			return
		end
		while true do
			local okPage, items = pcall(function()
				return pages:GetCurrentPage()
			end)
			if not okPage then
				break
			end
			for _, item in ipairs(items) do
				friendIds[item.Id] = true
			end
			local okNext, moved = pcall(function()
				return pages:AdvanceToNextPageAsync()
			end)
			if not okNext or not moved or pages.IsFinished then
				break
			end
		end
	end)
end

local function isBlocked(plr)
	if not plr or plr == LocalPlayer then
		return true
	end
	if protectedIds[plr.UserId] then
		return true
	end
	if next(protectedNames) ~= nil and protectedNames[plr.Name:lower()] then
		return true
	end
	if espStyle.teamCheck and onSameTeam(plr) then
		return true
	end
	if espStyle.friendCheck and friendIds[plr.UserId] then
		return true
	end
	return false
end

local function stillValid(plr)
	if not plr or isBlocked(plr) then
		return false
	end
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	return root ~= nil and humanoid ~= nil and humanoid.Health > 0
end

local HEAD_FALLBACK_LIFT = 1.5

local function headWorld(plr)
	local char = plr.Character
	if not char then
		return nil
	end
	local camera = workspace.CurrentCamera
	local names = silent.bones[silent.bone] or silent.bones.Head
	local chosen = nil
	local nearest = nil
	local nearestDistance = math.huge
	for _, name in ipairs(names) do
		local part = char:FindFirstChild(name) or char:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			if silent.bone == "Nearest" then
				local distance = camera and (part.Position - camera.CFrame.Position).Magnitude or 0
				if distance < nearestDistance then
					nearestDistance = distance
					nearest = part
				end
			else
				chosen = part
				break
			end
		end
	end
	local target = chosen or nearest
	if not target then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and string.find(string.lower(part.Name), "head", 1, true) then
				target = part
				break
			end
		end
	end
	if target then
		silent.worldPart = target
		return target.Position
	end
	local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	if root and root:IsA("BasePart") then
		silent.worldPart = root
		return root.Position + Vector3.new(0, HEAD_FALLBACK_LIFT, 0)
	end
	silent.worldPart = nil
	return nil
end

local function inRing(camera, center, plr)
	if not stillValid(plr) then
		return nil
	end
	local world = headWorld(plr)
	if not world then
		return nil
	end
	local point, onScreen = camera:WorldToViewportPoint(world)
	if not onScreen or point.Z <= 0 then
		return nil
	end
	local screen = Vector2.new(point.X, point.Y)
	if (screen - center).Magnitude > silent.fov then
		return nil
	end
	local distance = (world - camera.CFrame.Position).Magnitude
	return screen, world, distance
end

local STICKY_MARGIN = 1.15

local function pickTarget(camera, center)
	teamSplit = hasSplitTeams()
	local best = nil
	local bestScreen = nil
	local bestWorld = nil
	local bestDistance = math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		local screen, world, distance = inRing(camera, center, plr)
		if screen and distance < bestDistance then
			best = plr
			bestScreen = screen
			bestWorld = world
			bestDistance = distance
		end
	end
	local held = silent.locked
	if held and held ~= best then
		local screen, world, distance = inRing(camera, center, held)
		if screen and distance <= bestDistance * STICKY_MARGIN then
			best = held
			bestScreen = screen
			bestWorld = world
		end
	end
	if best then
		headWorld(best)
	else
		silent.worldPart = nil
	end
	silent.locked = best
	return best, bestScreen, bestWorld
end

local function addProtect(name)
	local query = tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if query == "" then
		return
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Name:lower() == query then
			protectedIds[plr.UserId] = true
			protectedNames[plr.Name:lower()] = true
			notify("protected", plr.Name, 2)
			return
		end
	end
	protectedNames[query] = true
	notify("protected", name, 2)
end

local function clearProtect()
	protectedIds = {}
	protectedNames = {}
	notify("protect list cleared", "aim sees everyone again", 2.5)
end

local AIM_BIND = "AJLOL_AimLock"
local aimBound = false
local aimConnection = nil
local rayHooks = {}
local redirectOn = true
local cameraRays = { on = true }

local function aimDirection(origin)
	if not silent.enabled or not redirectOn then
		return nil
	end
	local world = silent.world
	if not world then
		return nil
	end
	local delta = world - origin
	local magnitude = delta.Magnitude
	if magnitude < 0.05 or magnitude ~= magnitude then
		return nil
	end
	return delta.Unit
end

local function installRayHooks()
	local hookFn = findHook()
	if not hookFn or #rayHooks > 0 then
		return false
	end
	weapon.hookFn = hookFn
	local function hook(host, name, builder, isCamera)
		local ok, target = pcall(function()
			return host[name]
		end)
		if not ok or typeof(target) ~= "function" then
			return
		end
		local ref = { fn = target }
		local okHook, handle = pcall(function()
			local replacement = builder(function(...)
				return ref.fn(...)
			end)
			if typeof(newcclosure) == "function" then
				replacement = newcclosure(replacement)
			end
			return hookFn(target, replacement)
		end)
		if okHook and handle then
			ref.fn = handle
			table.insert(rayHooks, { handle = handle, original = target, camera = isCamera })
		end
	end
	local function isShotOrigin(origin)
		if typeof(origin) ~= "Vector3" then
			return false
		end
		local camera = workspace.CurrentCamera
		if camera and (origin - camera.CFrame.Position).Magnitude <= 60 then
			return true
		end
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and (origin - root.Position).Magnitude <= 30 then
			return true
		end
		return false
	end
	local function isPlayerFilter(params)
		if typeof(params) ~= "RaycastParams" then
			return false
		end
		local okKind, kind = pcall(function()
			return params.FilterType
		end)
		if not okKind or kind ~= Enum.RaycastFilterType.Exclude then
			return false
		end
		local char = LocalPlayer.Character
		if not char then
			return false
		end
		local okList, list = pcall(function()
			return params.FilterDescendantsInstances
		end)
		if not okList or type(list) ~= "table" then
			return false
		end
		for _, entry in ipairs(list) do
			if entry == char then
				return true
			end
			local okDesc, isDesc = pcall(function()
				return entry:IsDescendantOf(char)
			end)
			if okDesc and isDesc then
				return true
			end
		end
		return false
	end
	local function shotDirection(origin, direction, params)
		if not weapon.shotActive() then
			return nil
		end
		if typeof(direction) ~= "Vector3" then
			return nil
		end
		local plausible = isShotOrigin(origin)
		if not plausible and params ~= nil then
			plausible = isPlayerFilter(params)
		end
		if not plausible then
			return nil
		end
		local reach = direction.Magnitude
		local longRay = reach >= 16
		local unitRay = reach >= 0.5 and reach <= 1.5 and isPlayerFilter(params)
		if not longRay and not unitRay then
			return nil
		end
		local dir = aimDirection(origin)
		if not dir and weapon.spread then
			local camera = workspace.CurrentCamera
			if camera then
				dir = camera.CFrame.LookVector
			end
		end
		if not dir then
			return nil
		end
		silent.stats.rays = silent.stats.rays + 1
		if longRay then
			return dir * reach
		end
		return dir
	end
	local function raycastBuilder(original)
		return function(self, origin, direction, params)
			local ok, redirected = pcall(shotDirection, origin, direction, params)
			if ok and redirected then
				return original(self, origin, redirected, params)
			end
			return original(self, origin, direction, params)
		end
	end
	local function findPartBuilder(original)
		return function(self, ray, ...)
			local ok, redirected = pcall(function()
				if typeof(ray) ~= "Ray" then
					return nil
				end
				local direction = shotDirection(ray.Origin, ray.Direction)
				if not direction then
					return nil
				end
				return Ray.new(ray.Origin, direction)
			end)
			if ok and redirected then
				return original(self, redirected, ...)
			end
			return original(self, ray, ...)
		end
	end
	local function spherecastBuilder(original)
		return function(self, origin, radius, direction, params)
			local ok, redirected = pcall(shotDirection, origin, direction, params)
			if ok and redirected then
				return original(self, origin, radius, redirected, params)
			end
			return original(self, origin, radius, direction, params)
		end
	end
	local function blockcastBuilder(original)
		return function(self, frame, size, direction, params)
			local ok, redirected = pcall(function()
				if typeof(frame) ~= "CFrame" then
					return nil
				end
				return shotDirection(frame.Position, direction, params)
			end)
			if ok and redirected then
				return original(self, frame, size, redirected, params)
			end
			return original(self, frame, size, direction, params)
		end
	end
	local function cameraRayBuilder(original)
		return function(self, x, y, depth)
			local base = original(self, x, y, depth)
			if not cameraRays.on or not redirectOn or not silent.enabled then
				return base
			end
			if not weapon.shotActive() then
				return base
			end
			if not silent.world or not silent.locked then
				return base
			end
			local ok, redirected = pcall(function()
				if typeof(base) ~= "Ray" then
					return nil
				end
				local dir = aimDirection(base.Origin)
				if not dir then
					return nil
				end
				local span = base.Direction.Magnitude
				if span <= 0.05 then
					span = 1
				end
				return Ray.new(base.Origin, dir * span)
			end)
			if ok and redirected then
				return redirected
			end
			return base
		end
	end
	hook(workspace, "Raycast", raycastBuilder)
	hook(workspace, "FindPartOnRay", findPartBuilder)
	hook(workspace, "FindPartOnRayWithIgnoreList", findPartBuilder)
	hook(workspace, "FindPartOnRayWithWhitelist", findPartBuilder)
	hook(workspace, "Spherecast", spherecastBuilder)
	hook(workspace, "Blockcast", blockcastBuilder)
	if Camera then
		hook(Camera, "ScreenPointToRay", cameraRayBuilder, true)
		hook(Camera, "ViewportPointToRay", cameraRayBuilder, true)
	end
	hook(UserInputService, "GetMouseLocation", function(original)
		return function(self, ...)
			local base = original(self, ...)
			if weapon.mouseSpoof == false then
				return base
			end
			if not weapon.shotActive() then
				return base
			end
			local world = weapon.locked()
			local camera = workspace.CurrentCamera
			if not world or not camera then
				return base
			end
			local point = camera:WorldToViewportPoint(world)
			if point.Z <= 0 then
				return base
			end
			return Vector2.new(point.X, point.Y)
		end
	end)
	return #rayHooks > 0
end

local function removeRayHooks()
	if #rayHooks == 0 then
		return
	end
	for _, entry in ipairs(rayHooks) do
		if typeof(restorefunction) == "function" then
			if not pcall(restorefunction, entry.original) then
				pcall(restorefunction, entry.handle)
			end
		elseif weapon.hookFn then
			pcall(weapon.hookFn, entry.handle, entry.original)
		end
	end
	table.clear(rayHooks)
end

local hooksWanted = true

local mouseHook = { installed = false, original = nil }

function mouseHook.value(key)
	if not silent.enabled or not silent.world or not silent.locked then
		return nil
	end
	if not weapon.shotActive() then
		return nil
	end
	if key == "X" or key == "Y" then
		if weapon.mouseSpoof == false then
			return nil
		end
		local camera = workspace.CurrentCamera
		if not camera then
			return nil
		end
		local point = camera:WorldToViewportPoint(silent.world)
		if point.Z <= 0 then
			return nil
		end
		return key == "X" and point.X or point.Y
	end
	if key == "UnitRay" then
		local camera = workspace.CurrentCamera
		if not camera then
			return nil
		end
		local dir = aimDirection(camera.CFrame.Position)
		if not dir then
			return nil
		end
		return Ray.new(camera.CFrame.Position, dir)
	end
	if key == "Hit" then
		local camera = workspace.CurrentCamera
		if camera then
			local from = camera.CFrame.Position
			local aim = silent.world - from
			if aim.Magnitude > 0.05 then
				local ok, frame = pcall(CFrame.lookAt, silent.world, silent.world + aim)
				if ok and frame then
					return frame
				end
			end
		end
		return CFrame.new(silent.world)
	end
	if key == "Target" then
		return silent.worldPart
	end
	return nil
end

function mouseHook.install()
	if mouseHook.installed then
		return false
	end
	local original, restore = hookMeta(game, "__index", function(base)
		return function(self, key)
			if key == "CFrame" and weapon.cameraSpoof and weapon.shotActive()
				and silent.enabled and silent.world then
				local camera = workspace.CurrentCamera
				if self == camera then
					local frame = base(self, key)
					local delta = silent.world - frame.Position
					if delta.Magnitude > 0.05 then
						return CFrame.lookAt(frame.Position, frame.Position + delta)
					end
					return frame
				end
			end
			if key == "Hit" or key == "UnitRay" or key == "Target" or key == "X" or key == "Y" then
				local okMouse, isMouse = pcall(function()
					return self:IsA("Mouse")
				end)
				if okMouse and isMouse then
					local okValue, value = pcall(mouseHook.value, key)
					if okValue and value ~= nil then
						return value
					end
				end
			end
			return base(self, key)
		end
	end)
	if typeof(original) == "function" then
		mouseHook.original = original
		mouseHook.restore = restore
		mouseHook.installed = true
	end
	return mouseHook.installed
end

function mouseHook.remove()
	if mouseHook.restore then
		pcall(mouseHook.restore)
		mouseHook.restore = nil
	end
	mouseHook.installed = false
	mouseHook.original = nil
end

local function resolveAimMethod()
	if not hooksWanted then
		return "off"
	end
	weapon.install()
	installRayHooks()
	mouseHook.install()
	local castCount = 0
	local camCount = 0
	for _, entry in ipairs(rayHooks) do
		if entry.camera then
			camCount = camCount + 1
		else
			castCount = castCount + 1
		end
	end
	local parts = {}
	if castCount > 0 then
		table.insert(parts, "cast")
	end
	if camCount > 0 and cameraRays.on then
		table.insert(parts, "cam")
	end
	if weapon.hooked then
		table.insert(parts, "call")
	end
	if mouseHook.installed then
		table.insert(parts, "mouse")
	end
	if #parts > 0 then
		return "silent " .. table.concat(parts, "+")
	end
	return "no hooks"
end

local function setHooks(on)
	hooksWanted = on and true or false
	weapon.castHooks = hooksWanted
	if not silent.enabled then
		return
	end
	removeRayHooks()
	mouseHook.remove()
	silent.method = resolveAimMethod()
	notify("silent hooks", silent.method, 2)
end

local function aimStep(dt)
	if not silent.enabled then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
	local target, screen, world = pickTarget(camera, center)
	silent.target = target
	silent.screen = screen
	silent.world = world
	refreshInset()
	local drawCenter = overlayPoint(center)
	ring.Position = UDim2.fromOffset(drawCenter.X, drawCenter.Y)
	cross.Position = UDim2.fromOffset(drawCenter.X, drawCenter.Y)
	if screen and world then
		local drawScreen = overlayPoint(screen)
		placeLine(aimLine, drawCenter, drawScreen, 2)
		aimDot.BackgroundTransparency = 0.1 + math.abs(math.sin(os.clock() * 5)) * 0.55
	else
		aimLine.Visible = false
	end
end

local function bindAim()
	if aimBound then
		return
	end
	aimBound = true
	local ok = pcall(function()
		RunService:BindToRenderStep(AIM_BIND, Enum.RenderPriority.Camera.Value + 1, aimStep)
	end)
	if not ok then
		aimBound = false
		aimConnection = RunService.RenderStepped:Connect(aimStep)
		aimBound = true
	end
end

local function unbindAim()
	if not aimBound then
		return
	end
	aimBound = false
	pcall(function()
		RunService:UnbindFromRenderStep(AIM_BIND)
	end)
	if aimConnection then
		aimConnection:Disconnect()
		aimConnection = nil
	end
end

local function setSilent(on)
	if on == silent.enabled then
		return
	end
	silent.enabled = on
	ring.Visible = on
	cross.Visible = on
	aimLine.Visible = false
	silent.target = nil
	silent.screen = nil
	silent.world = nil
	if on then
		silent.locked = nil
		silent.method = resolveAimMethod()
		bindAim()
		notify("silent aim on", silent.method .. " hit", 2)
	else
		removeRayHooks()
		mouseHook.remove()
		unbindAim()
		silent.locked = nil
		notify("silent aim off", "shots normal", 1.6)
	end
end

local BONE_SETS = {
	{
		{ "Head", "UpperTorso" },
		{ "UpperTorso", "LowerTorso" },
		{ "UpperTorso", "LeftUpperArm" },
		{ "LeftUpperArm", "LeftLowerArm" },
		{ "LeftLowerArm", "LeftHand" },
		{ "UpperTorso", "RightUpperArm" },
		{ "RightUpperArm", "RightLowerArm" },
		{ "RightLowerArm", "RightHand" },
		{ "LowerTorso", "LeftUpperLeg" },
		{ "LeftUpperLeg", "LeftLowerLeg" },
		{ "LeftLowerLeg", "LeftFoot" },
		{ "LowerTorso", "RightUpperLeg" },
		{ "RightUpperLeg", "RightLowerLeg" },
		{ "RightLowerLeg", "RightFoot" },
	},
	{
		{ "Head", "Torso" },
		{ "Torso", "Left Arm" },
		{ "Torso", "Right Arm" },
		{ "Torso", "Left Leg" },
		{ "Torso", "Right Leg" },
	},
}

local function bonePairsFor(char)
	local set = char:FindFirstChild("UpperTorso") and BONE_SETS[1] or BONE_SETS[2]
	local resolved = {}
	for _, pair in ipairs(set) do
		local a = char:FindFirstChild(pair[1])
		local b = char:FindFirstChild(pair[2])
		if a and b then
			table.insert(resolved, { a, b })
		end
	end
	return resolved
end

local function toScreen(camera, position)
	local point = camera:WorldToViewportPoint(position)
	if point.Z <= 0 then
		return nil
	end
	return Vector2.new(point.X, point.Y)
end

local function ensureEspExtras(obj)
	if espStyle.skeleton and not obj.bones then
		obj.bones = {}
		for i = 1, 16 do
			local f = new("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = esp.color,
				BorderSizePixel = 0,
				Visible = false,
				ZIndex = 2,
			})
			f.Parent = overlay
			obj.bones[i] = f
		end
	end
	if espStyle.box and not obj.box then
		obj.box = {}
		for i = 1, 4 do
			local f = new("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = esp.color,
				BorderSizePixel = 0,
				Visible = false,
				ZIndex = 2,
			})
			f.Parent = overlay
			obj.box[i] = f
		end
	end
	if espStyle.tracers and not obj.tracer then
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = esp.color,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 2,
		})
		f.Parent = overlay
		obj.tracer = f
	end
end

local function espVisible(plr)
	if not plr or plr == LocalPlayer then
		return false
	end
	if espStyle.includeTeam then
		return true
	end
	return not onSameTeam(plr)
end

local function hideEspExtras(obj)
	if obj.bones then
		for _, frame in ipairs(obj.bones) do
			frame.Visible = false
		end
	end
	if obj.box then
		for _, frame in ipairs(obj.box) do
			frame.Visible = false
		end
	end
	if obj.tracer then
		obj.tracer.Visible = false
	end
end

RunService.RenderStepped:Connect(function()
	if not esp.enabled then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	teamSplit = hasSplitTeams()
	refreshInset()
	local viewport = camera.ViewportSize
	local feet = overlayPoint(Vector2.new(viewport.X / 2, viewport.Y))
	local drawStyles = espStyle.skeleton or espStyle.box or espStyle.tracers
	for char, obj in pairs(esp.objects) do
		if char.Parent then
			local show = espVisible(obj.player)
			if obj.highlight then
				obj.highlight.Enabled = show
			end
			if obj.billboard then
				obj.billboard.Enabled = show
			end
			if not show or not drawStyles then
				hideEspExtras(obj)
			else
				ensureEspExtras(obj)
				local head = char:FindFirstChild("Head")
				if obj.bones then
				if espStyle.skeleton and head then
					if not obj.bonePairs or #obj.bonePairs == 0 or not obj.bonePairs[1][1].Parent then
						obj.bonePairs = bonePairsFor(char)
					end
					for i, frame in ipairs(obj.bones) do
						local pair = obj.bonePairs[i]
						if pair and pair[1].Parent and pair[2].Parent then
							placeLine(frame, toScreen(camera, pair[1].Position), toScreen(camera, pair[2].Position))
						else
							frame.Visible = false
						end
					end
				else
					for _, frame in ipairs(obj.bones) do
						frame.Visible = false
					end
				end
			end
			if obj.box then
				if espStyle.box and head then
					local cf, size = char:GetBoundingBox()
					local top = toScreen(camera, cf.Position + Vector3.new(0, size.Y * 0.5, 0))
					local bottom = toScreen(camera, cf.Position - Vector3.new(0, size.Y * 0.5, 0))
					if top and bottom then
						local height = math.max(math.abs(bottom.Y - top.Y), 8)
						local width = math.max(height * 0.55, 8)
						local centerX = (top.X + bottom.X) * 0.5
						local topY = math.min(top.Y, bottom.Y)
						local bottomY = topY + height
						local left = centerX - width * 0.5
						local right = centerX + width * 0.5
						placeLine(obj.box[1], Vector2.new(left, topY), Vector2.new(right, topY))
						placeLine(obj.box[2], Vector2.new(left, bottomY), Vector2.new(right, bottomY))
						placeLine(obj.box[3], Vector2.new(left, topY), Vector2.new(left, bottomY))
						placeLine(obj.box[4], Vector2.new(right, topY), Vector2.new(right, bottomY))
					else
						for _, f in ipairs(obj.box) do
							f.Visible = false
						end
					end
				else
					for _, f in ipairs(obj.box) do
						f.Visible = false
					end
				end
			end
			if obj.tracer then
				if espStyle.tracers and head then
					placeLine(obj.tracer, feet, toScreen(camera, head.Position))
				else
					obj.tracer.Visible = false
				end
			end
			end
		end
	end
end)

local function setRedirect(on)
	redirectOn = on and true or false
	weapon.redirect = redirectOn
	if syncUi.redirectCombat then
		syncUi.redirectCombat.set(redirectOn)
	end
end

local function refreshLock()
	if not silent.enabled then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
	local target, screen, world = pickTarget(camera, center)
	silent.target = target
	silent.screen = screen
	silent.world = world
end

local function onFire()
	if not silent.enabled or not redirectOn then
		return
	end
	refreshLock()
	weapon.shotUntil = os.clock() + 0.4
end

local fireConnection = UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		onFire()
	end
end)

local fireConnections = {}

local function watchTool(tool)
	if not tool:IsA("Tool") then
		return
	end
	table.insert(fireConnections, tool.Activated:Connect(onFire))
end

local function watchCharacter(char)
	for _, child in ipairs(char:GetChildren()) do
		watchTool(child)
	end
	table.insert(fireConnections, char.ChildAdded:Connect(watchTool))
end

if LocalPlayer.Character then
	watchCharacter(LocalPlayer.Character)
end
table.insert(fireConnections, LocalPlayer.CharacterAdded:Connect(watchCharacter))

local function teleportTo(position)
	local root = getRoot()
	if root then
		root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	end
end

local function teleportToSpawn()
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		teleportTo(spawn.Position)
	else
		local root = getRoot()
		if root then
			root.CFrame = CFrame.new(0, 60, 0)
		end
	end
end

local function findPlayer(query)
	query = tostring(query):lower():gsub("%s+", "")
	if query == "" then
		return nil
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local name = plr.Name:lower()
			local display = plr.DisplayName:lower():gsub("%s+", "")
			if name == query or display == query or name:sub(1, #query) == query then
				return plr
			end
		end
	end
	return nil
end

local function teleportToPlayer(query)
	local plr = findPlayer(query)
	if not plr then
		return
	end
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if root then
		teleportTo(root.Position)
	end
end

local function teleportToRandom()
	local candidates = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(candidates, plr)
		end
	end
	if #candidates == 0 then
		return
	end
	local pick = candidates[math.random(1, #candidates)]
	teleportTo(pick.Character.HumanoidRootPart.Position)
end

local function bringAll()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local root = plr.Character:FindFirstChild("HumanoidRootPart")
			local mine = getRoot()
			if root and mine then
				guard(function()
					root.CFrame = mine.CFrame * CFrame.new(math.random(-4, 4), 0, math.random(-4, 4))
				end)
			end
		end
	end
end

local savedPosition
local function savePosition()
	local root = getRoot()
	if root then
		savedPosition = root.Position
	end
end

local function loadPosition()
	if savedPosition then
		teleportTo(savedPosition)
	end
end

local dump
local startDump

do
dump = {
	running = false,
	links = {},
	folder = nil,
	count = 0,
	status = nil,
}

local UPLOAD_LIMIT = 2800000

local function urlEncode(str)
	return (tostring(str):gsub("[^%w%-%._~]", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

local function httpExec(opts)
	local fn = (syn and syn.request) or (http and http.request) or http_request or request
	if fn then
		local ok, res = pcall(fn, opts)
		if ok and type(res) == "table" and res.Body ~= nil then
			return res
		end
	end
	local ok, res = pcall(function()
		return HttpService:RequestAsync({
			Url = opts.Url,
			Method = opts.Method or "GET",
			Headers = opts.Headers or {},
			Body = opts.Body,
		})
	end)
	if ok and type(res) == "table" and res.Body ~= nil then
		return { StatusCode = res.StatusCode, Body = res.Body, Success = res.Success }
	end
	return nil
end

local function okCode(res)
	return res and type(res.StatusCode) == "number" and res.StatusCode >= 200 and res.StatusCode < 300
end

local function uploadPasteRs(body)
	local res = httpExec({
		Url = "https://paste.rs/",
		Method = "POST",
		Headers = { ["Content-Type"] = "text/plain; charset=utf-8" },
		Body = body,
	})
	if okCode(res) then
		return tostring(res.Body):match("https://paste%.rs/%S+")
	end
	return nil
end

local function uploadDpaste(body)
	local res = httpExec({
		Url = "https://dpaste.com/api/v2/",
		Method = "POST",
		Headers = { ["Content-Type"] = "application/x-www-form-urlencoded" },
		Body = "content=" .. urlEncode(body) .. "&syntax=text&expiry_days=7",
	})
	if okCode(res) then
		return tostring(res.Body):match("https://dpaste%.com/%S+")
	end
	return nil
end

local function uploadSourcebin(body)
	local payload
	local okPayload, encoded = pcall(function()
		return HttpService:JSONEncode({ files = { { name = "dump.txt", content = body } } })
	end)
	if not okPayload then
		return nil
	end
	payload = encoded
	local res = httpExec({
		Url = "https://sourceb.in/api/bins",
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = payload,
	})
	if okCode(res) then
		local okDecode, decoded = pcall(function()
			return HttpService:JSONDecode(res.Body)
		end)
		if okDecode and type(decoded) == "table" and decoded.key then
			return "https://sourceb.in/" .. tostring(decoded.key)
		end
	end
	return nil
end

local function uploadAny(body)
	for _, fn in ipairs({ uploadPasteRs, uploadDpaste, uploadSourcebin }) do
		local ok, link = pcall(fn, body)
		if ok and link then
			return link
		end
	end
	return nil
end

local function uploadSplit(label, content)
	local out = {}
	if #content == 0 then
		return out
	end
	if #content <= UPLOAD_LIMIT then
		local link = uploadAny(content)
		if link then
			table.insert(out, { label = label, url = link })
		end
		return out
	end
	local part = 0
	local index = 1
	while index <= #content and part < 8 do
		part = part + 1
		local link = uploadAny(content:sub(index, index + UPLOAD_LIMIT - 1))
		if link then
			table.insert(out, { label = label .. " part " .. part, url = link })
		end
		index = index + UPLOAD_LIMIT
		task.wait(0.1)
	end
	return out
end

local function fsWrite(path, content)
	if typeof(writefile) ~= "function" then
		return false
	end
	local ok = pcall(writefile, path, content)
	return ok
end

local function fsAppend(path, content)
	if typeof(appendfile) == "function" then
		return pcall(appendfile, path, content)
	end
	return false
end

local function fsFolder(path)
	if typeof(makefolder) == "function" then
		pcall(makefolder, path)
	end
end

local function fmt(value)
	local t = typeof(value)
	if t == "string" then
		return string.format("%q", value)
	elseif t == "number" then
		if value ~= value then
			return "nan"
		end
		return string.format("%.6g", value)
	elseif t == "boolean" then
		return tostring(value)
	elseif t == "Vector3" then
		return string.format("V3(%.3f, %.3f, %.3f)", value.X, value.Y, value.Z)
	elseif t == "Vector2" then
		return string.format("V2(%.3f, %.3f)", value.X, value.Y)
	elseif t == "CFrame" then
		local p = value.Position
		return string.format("CF(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
	elseif t == "Color3" then
		return string.format("C3(%d, %d, %d)", math.floor(value.R * 255 + 0.5), math.floor(value.G * 255 + 0.5), math.floor(value.B * 255 + 0.5))
	elseif t == "UDim2" then
		return string.format("U2(%g, %d, %g, %d)", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
	elseif t == "EnumItem" then
		return value.Name
	elseif t == "Instance" then
		return "@" .. value.ClassName
	end
	return nil
end

local PROP_SETS = {
	script = { "Enabled", "RunContext" },
	basePart = { "Position", "Size", "CFrame", "Anchored", "CanCollide", "CanTouch", "Transparency", "Material", "Color", "Shape" },
	humanoid = { "Health", "MaxHealth", "WalkSpeed", "JumpPower", "JumpHeight", "HipHeight", "RigType" },
	guiObject = { "Visible", "Position", "Size", "BackgroundColor3", "BackgroundTransparency", "Text", "TextColor3", "TextSize", "Image", "ZIndex" },
	value = { "Value" },
	light = { "Brightness", "Range", "Angle", "Color", "Enabled", "Shadows" },
	camera = { "FieldOfView", "CFrame", "CameraType" },
	model = { "PrimaryPart" },
	sound = { "SoundId", "Volume", "Playing", "Looped" },
	mesh = { "MeshId", "Texture", "Scale" },
	attachment = { "Position", "Orientation", "WorldPosition" },
	beam = { "Enabled", "Color", "Transparency" },
	particle = { "Enabled", "Rate", "Lifetime" },
}

local PROP_RULES = {
	{ "ModuleScript", "script" },
	{ "LocalScript", "script" },
	{ "Script", "script" },
	{ "Humanoid", "humanoid" },
	{ "Attachment", "attachment" },
	{ "BasePart", "basePart" },
	{ "GuiObject", "guiObject" },
	{ "ValueBase", "value" },
	{ "Light", "light" },
	{ "Camera", "camera" },
	{ "Model", "model" },
	{ "Sound", "sound" },
	{ "DataModelMesh", "mesh" },
	{ "Beam", "beam" },
	{ "ParticleEmitter", "particle" },
}

local function propsFor(inst)
	for _, rule in ipairs(PROP_RULES) do
		local ok, match = pcall(function()
			return inst:IsA(rule[1])
		end)
		if ok and match then
			return PROP_SETS[rule[2]]
		end
	end
	return nil
end

local function collectInstances()
	local list = {}
	local ok = pcall(function()
		local descendants = game:GetDescendants()
		for i = 1, #descendants do
			list[i] = descendants[i]
		end
	end)
	if ok and #list > 0 then
		return list
	end
	list = {}
	local stack = { game }
	while #stack > 0 do
		local node = table.remove(stack)
		list[#list + 1] = node
		local kids = node:GetChildren()
		for i = 1, #kids do
			stack[#stack + 1] = kids[i]
		end
		if #list % 4000 == 0 then
			task.wait()
		end
	end
	return list
end

local function dumpReport(text)
	if dump.status then
		dump.status.set(text)
	end
end

local function buildDump()
	local stamp
	local okDate = pcall(function()
		stamp = os.date("%Y%m%d-%H%M%S")
	end)
	if not stamp then
		stamp = tostring(math.floor(os.time and os.time() or tick()))
	end

	local folder = "AJLOL_Dump/" .. stamp
	fsFolder("AJLOL_Dump")
	fsFolder(folder)
	dump.folder = folder
	dump.links = {}

	dumpReport("walking game tree...")
	local list = collectInstances()
	dump.count = #list

	local tree = {}
	local scripts = {}
	local treeLines = 0
	local scriptCount = 0
	local sourceBlocked = 0
	local buffer = {}

	local function flush(force)
		if #buffer == 0 then
			return
		end
		if #buffer >= 200 or force then
			fsAppend(folder .. "/nodes.jsonl", table.concat(buffer))
			table.clear(buffer)
		end
	end

	for i = 1, #list do
		local inst = list[i]
		local okPath, path = pcall(function()
			return inst:GetFullName()
		end)
		if not okPath then
			path = inst.Name
		end

		local props = propsFor(inst)
		local propParts = {}
		if props then
			for _, name in ipairs(props) do
				local okRead, value = pcall(function()
					return inst[name]
				end)
				if okRead then
					local rendered = fmt(value)
					if rendered then
						table.insert(propParts, name .. "=" .. rendered)
					end
				end
			end
		end
		local propText = #propParts > 0 and (" " .. table.concat(propParts, " ")) or ""

		table.insert(tree, string.format("%s [%s]%s", path, inst.ClassName, propText))
		treeLines = treeLines + 1

		local record = { path = path, class = inst.ClassName }
		if #propParts > 0 then
			local kv = {}
			for _, entry in ipairs(propParts) do
				local key, value = entry:match("^(.-)=(.*)$")
				if key then
					kv[key] = value
				end
			end
			record.props = kv
		end
		local okJson, jsonLine = pcall(function()
			return HttpService:JSONEncode(record)
		end)
		if okJson then
			table.insert(buffer, jsonLine .. "\n")
		end
		flush(false)

		local isScript = inst:IsA("ModuleScript") or inst:IsA("LocalScript") or inst:IsA("Script")
		if isScript then
			local okSrc, src = pcall(function()
				return inst.Source
			end)
			if okSrc and type(src) == "string" and #src > 0 then
				scriptCount = scriptCount + 1
				table.insert(scripts, string.format("--==== %s [%s] ====%s\n\n%s\n\n", path, inst.ClassName, string.rep("=", math.max(0, 70 - #path)), src))
			else
				sourceBlocked = sourceBlocked + 1
			end
		end

		if i % 1500 == 0 then
			dumpReport(string.format("dumping %d / %d", i, #list))
			task.wait()
		end
	end
	flush(true)

	local treeText = table.concat(tree, "\n") .. "\n"
	local treePath = folder .. "/tree.txt"
	local treeSaved = fsWrite(treePath, treeText)

	local scriptsText = #scripts > 0 and table.concat(scripts, "") or "-- no script sources readable from this executor\n"
	local scriptsPath = folder .. "/scripts.lua"
	fsWrite(scriptsPath, scriptsText)

	dumpReport("uploading tree...")
	local links = {}
	local function addAll(extra)
		for _, entry in ipairs(extra) do
			table.insert(links, entry)
		end
	end
	addAll(uploadSplit("tree", treeText))
	dumpReport("uploading scripts...")
	if #scripts > 0 then
		addAll(uploadSplit("scripts", scriptsText))
	end
	dump.links = links

	local share = {}
	table.insert(share, "aj.lol game dump - " .. game.Name .. " - " .. stamp)
	table.insert(share, string.format("%d instances, %d script sources, %d blocked", treeLines, scriptCount, sourceBlocked))
	if treeSaved then
		table.insert(share, "local: " .. folder)
	end
	for _, entry in ipairs(links) do
		table.insert(share, entry.label .. ": " .. entry.url)
	end
	if #links == 0 then
		table.insert(share, "no upload - this executor has no http.request / request, dump is local only")
	end
	local shareText = table.concat(share, "\n")

	fsWrite(folder .. "/summary.txt", shareText)
	dump.share = shareText
	if dump.onFinish then
		dump.onFinish(shareText)
	end

	dumpReport(string.format("%d instances\n%s", treeLines, links[1] and links[1].url or ("saved: " .. folder)))

	if typeof(setclipboard) == "function" then
		pcall(setclipboard, shareText)
	end

	if links[1] then
		notify("dump done", links[1].url, 8)
	else
		notify("dump done", "saved to " .. folder, 8)
	end
end

function startDump()
	if dump.running then
		notify("dump running", "already working", 2)
		return
	end
	dump.running = true
	dumpReport("starting...")
	notify("dump started", "walking the game", 2.5)
	task.spawn(function()
		local ok, err = pcall(buildDump)
		dump.running = false
		if not ok then
			dumpReport("failed: " .. tostring(err):sub(1, 120))
			notify("dump failed", tostring(err):sub(1, 60), 6)
		end
	end)
end
end

local playerPage = makePage("Player")
local combatPage = makePage("Combat")
local visualsPage = makePage("Visuals")
local teleportsPage = makePage("Teleports")
local miscPage = makePage("Misc")
local settingsPage = makePage("Settings")

local function setFov(v)
	silent.fov = v
	ring.Size = UDim2.fromOffset(v * 2, v * 2)
	if syncUi.fovCombat then
		syncUi.fovCombat.set(v)
	end
end

local function silentChanged(on)
	setSilent(on)
	if syncUi.silentCombat then
		syncUi.silentCombat.set(on)
	end
end

local playerBox = section(playerPage, "Player")
makeToggle(playerBox, "Infinite Jump", false, setInfiniteJump)
makeToggle(playerBox, "Noclip", false, setNoclip)
makeSlider(playerBox, "Walk Speed", 8, 200, 16, 0, function(v)
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed = v
	end
end)
makeSlider(playerBox, "Jump Power", 20, 250, 50, 0, function(v)
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = v
	end
end)

local playerTp = section(playerPage, "Teleports")
makeAction(playerTp, "Teleport to Spawn", teleportToSpawn)
makeInputAction(playerTp, "Teleport to Player", "Player Name...", "TP", teleportToPlayer)
makeButtonRow(playerTp, "Teleport to Random Player", "TP", teleportToRandom)

local playerMisc = section(playerPage, "Misc")
makeToggle(playerMisc, "Bring All", false, function(on)
	if on then
		bringAll()
	end
end)
makeToggle(playerMisc, "Anti AFK", false, setAntiAfk)

local combatUtil = section(combatPage, "Combat")
syncUi.silentCombat = makeToggle(combatUtil, "Silent Aim", false, silentChanged)
syncUi.fovCombat = makeSlider(combatUtil, "Aim FOV", 60, 420, 220, 0, setFov)
syncUi.boneCombat = ui.dropdown(combatUtil, "Aim Bone", { "Head", "Chest", "Stomach", "Legs", "Nearest" }, 1, function(option)
	silent.bone = option
end)
syncUi.redirectCombat = makeToggle(combatUtil, "Shot Redirect", true, setRedirect)
makeToggle(combatUtil, "Camera Rays", true, function(on)
	cameraRays.on = on and true or false
end)
makeToggle(combatUtil, "Mouse Spoof", true, function(on)
	weapon.mouseSpoof = on and true or false
end)
makeToggle(combatUtil, "Camera Spoof", false, function(on)
	weapon.cameraSpoof = on and true or false
end)
syncUi.aimStatus = ui.status(combatUtil, "aim: idle")
makeToggle(combatUtil, "Log Remotes", false, function(on)
	weapon.log = on and true or false
	if on then
		weapon.logCount = 0
	end
end)
makeToggle(combatUtil, "Silent Hooks", true, setHooks)
makeToggle(combatUtil, "Team Check", espStyle.teamCheck, function(on)
	espStyle.teamCheck = on
end)
makeToggle(combatUtil, "Friend Check", espStyle.friendCheck, function(on)
	espStyle.friendCheck = on
	if on then
		syncFriends()
	end
end)
makeInputAction(combatUtil, "Protect Name", "Exact player name...", "ADD", addProtect)
makeAction(combatUtil, "Clear Protect List", clearProtect)
makeToggle(combatUtil, "Auto Clicker", false, setAutoClick)
makeSlider(combatUtil, "Click Delay", 20, 500, 100, 0, function(v)
	clickDelay = v
end)
makeAction(combatUtil, "Reset Character", function()
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.Health = 0
	end
end)

local weaponUtil = section(combatPage, "Weapon")
makeToggle(weaponUtil, "Infinite Ammo", false, function(on)
	weapon.ammo = on
end)
makeToggle(weaponUtil, "No Recoil", false, function(on)
	weapon.recoil = on
	weapon.anchor = nil
end)
makeToggle(weaponUtil, "No Spread", false, function(on)
	weapon.spread = on
end)
makeToggle(weaponUtil, "Rapid Fire", false, function(on)
	weapon.rapid = on
	weapon.lastShot = 0
end)
makeToggle(weaponUtil, "Trigger Bot", false, function(on)
	weapon.trigger = on
	weapon.lastShot = 0
end)
makeSlider(weaponUtil, "Rapid Rate", 5, 60, 20, 0, function(v)
	weapon.rate = v
end)

local visualEsp = section(visualsPage, "ESP")
makeToggle(visualEsp, "ESP", false, setEsp)
makeToggle(visualEsp, "Skeleton", false, function(on)
	espStyle.skeleton = on
end)
makeToggle(visualEsp, "Box", false, function(on)
	espStyle.box = on
end)
makeToggle(visualEsp, "Tracers", false, function(on)
	espStyle.tracers = on
end)
makeToggle(visualEsp, "Include Team", espStyle.includeTeam, function(on)
	espStyle.includeTeam = on
end)

local visualUtil = section(visualsPage, "Visuals")
makeToggle(visualUtil, "Fullbright", false, setFullbright)
makeSlider(visualUtil, "Camera FOV", 40, 120, 70, 0, function(v)
	if Camera then
		Camera.FieldOfView = v
	end
end)

local teleportUtil = section(teleportsPage, "Teleports")
makeAction(teleportUtil, "Teleport to Spawn", teleportToSpawn)
makeInputAction(teleportUtil, "Teleport to Player", "Player Name...", "TP", teleportToPlayer)
makeButtonRow(teleportUtil, "Teleport to Random Player", "TP", teleportToRandom)
makeAction(teleportUtil, "Save Position", savePosition)
makeAction(teleportUtil, "Load Position", loadPosition)

local dumpSection = section(miscPage, "Game Dump")
makeAction(dumpSection, "Dump Game", startDump)

local dumpStatusRow = new("Frame", {
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	LayoutOrder = nextOrder(),
})
local dumpStatusLabel = new("TextLabel", {
	Size = UDim2.new(1, -8, 0, 0),
	Position = UDim2.fromOffset(4, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Font = THEME.Font,
	Text = "idle - no dump yet",
	TextSize = M.labelSize - 1,
	TextColor3 = THEME.TextFaint,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
})
dumpStatusLabel.Parent = dumpStatusRow
dumpStatusRow.Parent = dumpSection
dump.status = {
	set = function(text)
		dumpStatusLabel.Text = text
	end,
}

local dumpLinkBox = new("TextBox", {
	Size = UDim2.new(1, 0, 0, compact and 56 or 64),
	BackgroundColor3 = THEME.Field,
	BorderSizePixel = 0,
	Font = THEME.Font,
	Text = "",
	PlaceholderText = "dump links show up here - tap to select",
	PlaceholderColor3 = THEME.TextFaint,
	TextSize = M.labelSize - 2,
	TextColor3 = THEME.TextDim,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	ClearTextOnFocus = false,
	MultiLine = true,
	LayoutOrder = nextOrder(),
}, { corner(6), stroke(THEME.RowBorder, 1, 0.15) })
new("UIPadding", {
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	PaddingTop = UDim.new(0, 6),
	PaddingBottom = UDim.new(0, 6),
}).Parent = dumpLinkBox
dumpLinkBox.Parent = dumpSection

dump.onFinish = function(text)
	dumpLinkBox.Text = text
end

makeAction(dumpSection, "Copy Dump Link", function()
	if not dump.share then
		notify("nothing to copy", "run Dump Game first", 2.5)
		return
	end
	if typeof(setclipboard) == "function" then
		pcall(setclipboard, dump.share)
		notify("copied", "dump link on clipboard", 2.5)
	end
end)

makeAction(dumpSection, "Open Dump Link", function()
	local entry = dump.links and dump.links[1]
	if not entry then
		notify("no link yet", "run Dump Game first", 2.5)
		return
	end
	local url = entry.url
	if typeof(openbrowser) == "function" then
		if pcall(openbrowser, url) then
			return
		end
	end
	if GuiService then
		if pcall(function()
			GuiService:OpenBrowserWindow(url)
		end) then
			return
		end
	end
	if typeof(setclipboard) == "function" then
		pcall(setclipboard, url)
	end
	notify("link copied", "paste it in Safari", 4)
end)

makeAction(dumpSection, "Copy Dump Path", function()
	if not dump.folder then
		notify("nothing to copy", "run Dump Game first", 2.5)
		return
	end
	local path = dump.folder
	if typeof(getworkspace) == "function" then
		local ok, ws = pcall(getworkspace)
		if ok and type(ws) == "string" then
			path = ws .. "/" .. path
		end
	end
	if typeof(setclipboard) == "function" then
		pcall(setclipboard, path)
	end
	notify("path copied", path:sub(-48), 4)
end)

local miscUtil = section(miscPage, "Misc")
makeToggle(miscUtil, "Anti AFK", false, setAntiAfk)
makeAction(miscUtil, "Copy Position", function()
	local root = getRoot()
	if root and typeof(setclipboard) == "function" then
		local p = root.Position
		guard(function()
			setclipboard(string.format("Vector3.new(%.1f, %.1f, %.1f)", p.X, p.Y, p.Z))
		end)
	end
end)
makeAction(miscUtil, "Rejoin Server", function()
	guard(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end)
end)

local settingsUtil = section(settingsPage, "Settings")
makeAction(settingsUtil, "Reset Window Position", function()
	window.Position = UDim2.new(0.5, 0, 0.46, 0)
	window.AnchorPoint = Vector2.new(0.5, 0.5)
end)
makeAction(settingsUtil, "Copy Script Link", function()
	if typeof(setclipboard) == "function" then
		setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/vreclipse11-ux/Roblox-menu/main/AJ.LOL.lua"))()')
	end
end)
makeToggle(settingsUtil, "Keep Menu On Respawn", true, function(on)
	gui.ResetOnSpawn = on
end)

local settingsEsp = section(settingsPage, "ESP")
ui.color(settingsEsp, "ESP Color", esp.color, applyEspColor)

for _, entry in pairs(pages) do
	if entry.page == playerPage then
		entry.select()
	end
end

local drag = { active = false, start = Vector2.new(), origin = UDim2.new() }

local function clampToViewport(pos)
	local size = window.AbsoluteSize
	local maxX = math.max(0, vp.X - size.X)
	local maxY = math.max(0, vp.Y - size.Y)
	return UDim2.fromOffset(math.clamp(pos.X.Offset, 0, maxX), math.clamp(pos.Y.Offset, 0, maxY))
end

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		drag.active = true
		drag.start = input.Position
		local abs = window.AbsolutePosition
		drag.origin = UDim2.fromOffset(abs.X, abs.Y)
		window.AnchorPoint = Vector2.new(0, 0)
		window.Position = drag.origin
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not drag.active then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - drag.start
		window.Position = clampToViewport(UDim2.fromOffset(
			drag.origin.X.Offset + delta.X,
			drag.origin.Y.Offset + delta.Y
		))
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		drag.active = false
	end
end)

local winState = { minimized = false, size = window.Size }

local function setMinimized(state)
	winState.minimized = state
	local target
	if state then
		winState.size = window.Size
		target = UDim2.new(winState.size.X.Scale, winState.size.X.Offset, 0, M.headerH + (compact and 12 or 18))
	else
		target = winState.size
	end
	content.Visible = not state
	controls.Visible = not state
	TweenService:Create(window, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = target,
	}):Play()
end

minBtn.MouseButton1Click:Connect(function()
	guard(setMinimized, not winState.minimized)
end)

local reopen = new("TextButton", {
	Name = "Reopen",
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.new(0, 12, 0, 90),
	Size = UDim2.fromOffset(compact and 40 or 52, compact and 26 or 32),
	BackgroundColor3 = THEME.Accent,
	BorderSizePixel = 0,
	Font = THEME.FontBold,
	Text = "aj",
	TextSize = compact and 12 or 14,
	TextColor3 = THEME.Text,
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 20,
}, { corner(8), stroke(THEME.AccentSoft, 1, 0.2) })
reopen.Parent = gui

ui.bubbleScale = new("UIScale", { Scale = 1 })
ui.bubbleScale.Parent = reopen

function ui.open()
	if window.Visible and not ui.closing then
		return
	end
	ui.closing = false
	windowScale.Scale = 0.9
	window.Visible = true
	reopen.Visible = false
	TweenService:Create(windowScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()
end

function ui.close()
	if not window.Visible or ui.closing then
		return
	end
	ui.closing = true
	local tween = TweenService:Create(windowScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Scale = 0.9,
	})
	tween.Completed:Connect(function()
		if not ui.closing then
			return
		end
		ui.closing = false
		window.Visible = false
		reopen.Visible = true
		windowScale.Scale = 1
		ui.bubbleScale.Scale = 0.6
		TweenService:Create(ui.bubbleScale, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
	end)
	tween:Play()
end

reopen.MouseEnter:Connect(function()
	if ui.bubbleMoved then
		return
	end
	TweenService:Create(ui.bubbleScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Scale = 1.08,
	}):Play()
end)

reopen.MouseLeave:Connect(function()
	if ui.bubbleMoved then
		return
	end
	TweenService:Create(ui.bubbleScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()
end)

reopen.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		ui.bubbleMoved = false
		ui.bubbleStart = input.Position
		local abs = reopen.AbsolutePosition
		ui.bubbleOrigin = Vector2.new(abs.X, abs.Y)
		TweenService:Create(ui.bubbleScale, TweenInfo.new(0.1), { Scale = 0.94 }):Play()
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not ui.bubbleStart then
		return
	end
	local kind = input.UserInputType
	if kind ~= Enum.UserInputType.MouseMovement and kind ~= Enum.UserInputType.Touch then
		return
	end
	local delta = input.Position - ui.bubbleStart
	if not ui.bubbleMoved then
		if delta.Magnitude < 4 then
			return
		end
		ui.bubbleMoved = true
	end
	local camera = workspace.CurrentCamera
	local view = (camera and camera.ViewportSize) or vp
	local size = reopen.AbsoluteSize
	local maxX = math.max(0, view.X - size.X)
	local maxY = math.max(0, view.Y - size.Y)
	reopen.Position = UDim2.fromOffset(
		math.clamp(ui.bubbleOrigin.X + delta.X, 0, maxX),
		math.clamp(ui.bubbleOrigin.Y + delta.Y, 0, maxY)
	)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		if ui.bubbleStart then
			ui.bubbleStart = nil
			TweenService:Create(ui.bubbleScale, TweenInfo.new(0.12), { Scale = 1 }):Play()
		end
	end
end)

reopen.MouseButton1Click:Connect(function()
	if ui.bubbleMoved then
		return
	end
	guard(ui.open)
end)

closeBtn.MouseButton1Click:Connect(function()
	guard(ui.close)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.RightControl then
		if window.Visible then
			guard(ui.close)
		else
			guard(ui.open)
		end
	end
end)

local handle = {}
handle.gui = gui
handle.window = window
handle.pages = pages
handle.notify = notify
handle.dump = startDump
handle.toggle = function()
	if window.Visible then
		ui.close()
	else
		ui.open()
	end
end
handle.destroy = function()
	setSilent(false)
	setNoclip(false)
	setInfiniteJump(false)
	setAntiAfk(false)
	setEsp(false)
	if fireConnection then
		fireConnection:Disconnect()
	end
	for _, conn in ipairs(fireConnections) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	fireConnections = {}
	if autoClickConnection then
		autoClickConnection = nil
	end
	setFullbright(false)
	if Camera then
		Camera.FieldOfView = 70
	end
	if overlay then
		overlay:Destroy()
	end
	if notifGui then
		notifGui:Destroy()
	end
	gui:Destroy()
	if getgenv then
		getgenv().AJLOL = nil
	end
end

if getgenv then
	getgenv().AJLOL = handle
end

if espStyle.friendCheck then
	syncFriends()
end

task.spawn(function()
	while true do
		task.wait(0.5)
		local label = syncUi.aimStatus
		if not label or not label.Parent then
			break
		end
		label.Text = string.format("hooks %d  rays %d  remotes %d  %s",
			#rayHooks, silent.stats.rays, silent.stats.remotes,
			silent.enabled and "armed" or "off")
	end
end)

notify("aj.lol  v2.0", "welcome - silent aim, esp, noclip", 4.5)

TweenService:Create(windowScale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Scale = 1,
}):Play()

task.spawn(function()
	local glowStroke = glow:FindFirstChildOfClass("UIStroke")
	if not glowStroke then
		return
	end
	while glow.Parent and window.Parent do
		TweenService:Create(glowStroke, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Transparency = 0.55,
		}):Play()
		task.wait(1.6)
		if not glow.Parent then
			return
		end
		TweenService:Create(glowStroke, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Transparency = 0.9,
		}):Play()
		task.wait(1.6)
	end
end)

print("[aj.lol] loaded 2.0")
