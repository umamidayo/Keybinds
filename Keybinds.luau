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
}
Keybinds.currentLayer = Keybinds.Layers.Default

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

-- Helper function to find all locations of a callback
local function findCallback(callbackName: string)
	for input, layers in Binds do
		local foundLayers = {}
		local callbacks = nil

		for layer, callbacksInLayer in layers do
			if callbacksInLayer[callbackName] then
				table.insert(foundLayers, layer)
				callbacks = callbacksInLayer[callbackName]
			end
		end

		if #foundLayers > 0 then
			return input, foundLayers, callbacks
		end
	end

	return nil, {}, nil
end

local function cleanupBinds()
	for input, inputLayers in Binds do
		for layer, callbacksInLayer in inputLayers do
			local hasCallbacks = next(callbacksInLayer) ~= nil
			if not hasCallbacks then
				inputLayers[layer] = nil
			end
		end

		local hasLayers = next(inputLayers) ~= nil
		if not hasLayers then
			Binds[input] = nil
		end
	end
end

local function shouldUnbindLayer(layer: string, targetLayers: { string }?): boolean
	if not targetLayers then
		return true
	end

	for _, targetLayer in ipairs(targetLayers) do
		if layer == targetLayer then
			return true
		end
	end

	return false
end

-- Unbinds and cleans up the events for the callback in the specified layers.
function Keybinds.unbind(callbackName: string, layers: { Layer | string }?)
	for _, inputLayers in Binds do
		for layer, callbacksInLayer in inputLayers do
			if callbacksInLayer[callbackName] and shouldUnbindLayer(layer, layers) then
				callbacksInLayer[callbackName] = nil
			end
		end
	end

	cleanupBinds()
end

-- Rebinds a callback to a new input in all layers.
function Keybinds.rebind(queriedName: string, newInput: Enum.KeyCode | Enum.UserInputType)
	local oldInput, foundLayers, callbacks = findCallback(queriedName)

	if oldInput and callbacks and #foundLayers > 0 then
		Keybinds.unbind(queriedName, foundLayers)
		Keybinds.bind(newInput, foundLayers, queriedName, callbacks)
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
