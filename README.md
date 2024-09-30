# VarToObject
Converts an lua table to an Roblox Folder with Roblox objects
```lua
local VarToObject = require(path.to.VarToObject)

local data = {
    Health = 100,
    Name = "Player",
    IsAlive = true,
    Stats = {
        Strength = 50,
        Agility = 40,
        Equipment = {
            Sword = "Excalibur",
            Shield = "Aegis"
        }
    }
}
local root = VarToObject.new("PlayerData", data)
root.Parent = workspace  -- Or any other appropriate parent
```
```yaml
PlayerData (Folder)
├── Health (NumberValue) -- Value: 100
├── Name (StringValue) -- Value: "Player"
├── IsAlive (BoolValue) -- Value: true
├── Stats (Folder)
│   ├── Strength (NumberValue) -- Value: 50
│   ├── Agility (NumberValue) -- Value: 40
│   └── Equipment (Folder)
│       ├── Sword (StringValue) -- Value: "Excalibur"
│       └── Shield (StringValue) -- Value: "Aegis"
```
