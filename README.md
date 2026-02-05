# Keybinds

A layer-based keybinding management library for Roblox that provides a flexible and organized way to handle user input across different game states.

## Uses

Keybinds is ideal for managing input in games with multiple interaction contexts:

- **Context-sensitive controls** - Different keybindings for different game states (flying, driving, swimming, etc.)
- **Debug modes** - Separate layer for development/testing keybinds that don't conflict with gameplay
- **Modal interfaces** - Easily switch input handling when opening menus, inventories, or dialogue
- **Rebindable controls** - Allow players to customize their keybindings
- **State management** - Organize input logic by game state without messy conditional checks

## Getting Started

### Installation

Copy `Keybinds.luau` into your project's source directory.

### Initialization
Keybinds is designed to be initialized in your game's startup script. Typically, you would include it in your main initializer, but you can also initialize it separately as shown below:

```lua
local Keybinds = require(path.to.Keybinds)
Keybinds.init()
```

**Important:** Keybinds only works on the client and automatically returns early if called on the server.

## Basic Example

```lua
local Keybinds = require(path.to.Keybinds)

-- Initialize the keybinding system
Keybinds.init()

-- Bind the space key to jump in the Default layer
Keybinds.bind(
    Enum.KeyCode.Space,
    { Keybinds.Layers.Default },
    "Jump",
    {
        began = function()
            print("Jump started!")
            -- Your jump logic here
        end,
        ended = function()
            print("Jump ended!")
        end
    }
)

-- Bind a different key for when the player is in the air
Keybinds.bind(
    Enum.KeyCode.Space,
    { Keybinds.Layers.Air },
    "DoubleJump",
    {
        began = function()
            print("Double jump!")
        end
    }
)

-- Switch to the Air layer when player is airborne
Keybinds.setLayer(Keybinds.Layers.Air)

-- Check current layer
if Keybinds.isLayer(Keybinds.Layers.Air) then
    print("Player is in Air layer")
end

-- Rebind the jump to a different key
Keybinds.rebind("Jump", Enum.KeyCode.W)

-- Unbind a specific callback
Keybinds.unbind("Jump")
```

## API Reference

### Layers

Built-in layers are available through `Keybinds.Layers`:
- `Default` - Standard gameplay
- `Debug` - Development/testing
- `Air` - Airborne state
- `Manual` - Manual control mode
- `Ragdoll` - Ragdoll state
- `Unmounted` - Not mounted/sitting

You can also use custom layer names as strings.

### Methods

#### `Keybinds.init()`
Initializes the keybinding system. Must be called on the client before using any other methods.

#### `Keybinds.bind(input, layers, callbackName, callbacks)`
Binds an input to callbacks in specific layers.

**Parameters:**
- `input` - `Enum.KeyCode` or `Enum.UserInputType`
- `layers` - Array of layer names
- `callbackName` - Unique identifier for this binding
- `callbacks` - Table with optional `began` and `ended` functions

**Example:**
```lua
Keybinds.bind(
    Enum.KeyCode.E,
    { Keybinds.Layers.Default },
    "Interact",
    {
        began = function()
            -- Interact logic
        end
    }
)
```

#### `Keybinds.unbind(callbackName, layers?)`
Unbinds a callback from specified layers or all layers if none specified.

**Parameters:**
- `callbackName` - Name of the callback to unbind
- `layers` - Optional array of layers to unbind from

#### `Keybinds.rebind(callbackName, newInput)`
Changes the input key for an existing callback across all its layers.

**Parameters:**
- `callbackName` - Name of the callback to rebind
- `newInput` - New `Enum.KeyCode` or `Enum.UserInputType`

#### `Keybinds.setLayer(layerName)`
Switches to a different input layer.

**Parameters:**
- `layerName` - Name of the layer to activate

#### `Keybinds.getLayer()`
Returns the current active layer name.

#### `Keybinds.isLayer(layerName)`
Checks if the current layer matches the given layer name.

**Parameters:**
- `layerName` - Layer name to check

**Returns:** `boolean`

#### `Keybinds.getLayerBinds(layerName)`
Returns all bindings in a specific layer for debugging or UI display.

**Parameters:**
- `layerName` - Layer to query

**Returns:** `{ [callbackName]: inputString }`

## Advanced Example

```lua
local Keybinds = require(path.to.Keybinds)
Keybinds.init()

-- Movement bindings for default gameplay
local movementBinds = {
    { key = Enum.KeyCode.W, name = "MoveForward" },
    { key = Enum.KeyCode.A, name = "MoveLeft" },
    { key = Enum.KeyCode.S, name = "MoveBackward" },
    { key = Enum.KeyCode.D, name = "MoveRight" },
}

for _, bind in ipairs(movementBinds) do
    Keybinds.bind(
        bind.key,
        { Keybinds.Layers.Default },
        bind.name,
        {
            began = function()
                -- Start movement
            end,
            ended = function()
                -- Stop movement
            end
        }
    )
end

-- Switch to Ragdoll layer when player ragdolls
-- Movement keys won't work in this layer
local function onRagdoll()
    Keybinds.setLayer(Keybinds.Layers.Ragdoll)
end

-- Return to default when recovered
local function onRecovered()
    Keybinds.setLayer(Keybinds.Layers.Default)
end
```

## License

This package is provided as-is for use in Roblox projects.
