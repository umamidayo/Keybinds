local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local inputLayerChanged = Instance.new("BindableEvent")
inputLayerChanged.Name = "inputLayerChanged"

type Layer = "Default" | "Debug" | "Air" | "Manual" | "Ragdoll" | "Unmounted"
type InputCallback = {
	began: (() -> ())?,
	ended: (() -> ())?,
}

local Binds: { [Enum.KeyCode | Enum.UserInputType]: { [string]: InputCallback } } = {}

local Keybinds = {
	Layers = {
		Default = "Default",
		Debug = "Debug",
		Air = "Air",
		Manual = "Manual",
		Ragdoll = "Ragdoll",
		Unmounted = "Unmounted",
	},
	currentLayer = "Default",
	previousLayer = "Default",
}

-- Binds the input's began and ended events to a function in the specified layers.
function Keybinds.bind(
	input: Enum.KeyCode | Enum.UserInputType,
	layers: { Layer | string },
	callbackName: string,
	callbacks: InputCallback
)
	if not Binds[input] then
		Binds[input] = {}
	end

	for _, layer in ipairs(layers) do
		if not Binds[input][layer] then
			Binds[input][layer] = {}
		end

		if not Binds[input][layer][callbackName] then
			Binds[input][layer][callbackName] = {}
		end

		Binds[input][layer][callbackName] = callbacks
	end
end

-- Unbinds and cleans up the events for the input in the specified layers.
function Keybinds.unbind(input: Enum.KeyCode | Enum.UserInputType, layers: { Layer | string }, callbackName: string)
	if not Binds[input] then
		return
	end

	for _, layer in ipairs(layers) do
		Binds[input][layer][callbackName] = nil
	end
end

-- Changes the current layer name to listen for key mappings on that layer.
function Keybinds.setLayer(layerName: Layer | string)
	Keybinds.previousLayer = Keybinds.currentLayer
	Keybinds.currentLayer = layerName
	inputLayerChanged:Fire(Keybinds.previousLayer, layerName)
end

-- Gets the current layer name.
function Keybinds.getLayer(): Layer | string
	return Keybinds.currentLayer
end

-- Checks if the current layer is the given layer name.
function Keybinds.isLayer(layer: Layer | string): boolean
	return Keybinds.currentLayer == layer
end

-- Returns a table of all of the binds in the layer for mapping data or debugging.
function Keybinds.getLayerBinds(layerName: Layer | string): { [string]: string }
	local binds = {}
	for input, callbacks in Binds do
		if callbacks[layerName] then
			for callbackName, _ in pairs(callbacks[layerName]) do
				if not binds[callbackName] then
					binds[callbackName] = tostring(input)
				end
			end
		end
	end
	return binds
end

function Keybinds.init()
	if RunService:IsServer() then
		return
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		-- Check for keyboard input
		if input.KeyCode and Binds[input.KeyCode] then
			local layerCallbacks = Binds[input.KeyCode][Keybinds.currentLayer]
			if layerCallbacks then
				for _, callbacks in pairs(layerCallbacks) do
					if callbacks.began then
						task.spawn(callbacks.began)
					end
				end
			end
		end

		-- Check for mouse input
		if input.UserInputType and Binds[input.UserInputType] then
			local layerCallbacks = Binds[input.UserInputType][Keybinds.currentLayer]
			if layerCallbacks then
				for _, callbacks in pairs(layerCallbacks) do
					if callbacks.began then
						task.spawn(callbacks.began)
					end
				end
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		-- Check for keyboard input
		if input.KeyCode and Binds[input.KeyCode] then
			local layerCallbacks = Binds[input.KeyCode][Keybinds.currentLayer]
			if layerCallbacks then
				for _, callbacks in pairs(layerCallbacks) do
					if callbacks.ended then
						task.spawn(callbacks.ended)
					end
				end
			end
		end

		-- Check for mouse input
		if input.UserInputType and Binds[input.UserInputType] then
			local layerCallbacks = Binds[input.UserInputType][Keybinds.currentLayer]
			if layerCallbacks then
				for _, callbacks in pairs(layerCallbacks) do
					if callbacks.ended then
						task.spawn(callbacks.ended)
					end
				end
			end
		end
	end)
end

return Keybinds
