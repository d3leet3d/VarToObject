--https://github.com/d3leet3d/VarToObject
local VarToObject = {}

VarToObject.VarTypes = {
	["number"] = Instance.new("NumberValue"),
	["string"] = Instance.new("StringValue"),
	["boolean"] = Instance.new("BoolValue"),
	["table"] = Instance.new("Folder")
} :: { ValueBase }

function VarToObject.new(Name: string, Value: any): Instance
	local varType = type(Value)
	local VarTemplate = VarToObject.VarTypes[varType]

	if VarTemplate then
		local Var = VarTemplate:Clone()
		Var.Name = Name

		if varType == "table" then
			for key, val in pairs(Value) do
				local keyName = tostring(key)
				local child = VarToObject.new(keyName, val)
				if child then
					child.Parent = Var
				end
			end
		else
			Var.Value = Value
		end

		return Var
	else
		warn("Unsupported type: " .. varType)
		return nil
	end
end

return VarToObject
