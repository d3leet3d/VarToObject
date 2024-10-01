local VarToObject = {}
VarToObject.__index = VarToObject


VarToObject.VarTypes = {
	["number"] = "IntValue",
	["string"] = "StringValue",
	["boolean"] = "BoolValue",
	["table"] = "Folder"
}

function VarToObject.new(Name: string, Value: any)
	local self = setmetatable({}, VarToObject)
	self.Connections = {}
	self.InstanceToPathMap = {}
	self.RootInstance = self:CreateInstance(Name, Value, nil)
	return self
end

function VarToObject:CreateInstance(Name: string, Value: any, parentTableRef: table)
	local varType = type(Value)
	local className = self.VarTypes[varType]

	if not className then
		warn("Unsupported type: " .. varType)
		return nil
	end

	print("Creating Instance:", Name, "Type:", className)

	local Var = Instance.new(className)
	Var.Name = Name
	if varType == "table" then
		self.InstanceToPathMap[Var] = { Name = Name, tableRef = Value }

		for key, val in pairs(Value) do
			local keyName = tostring(key)
			local child = self:CreateInstance(keyName, val, Value)
			if child then
				child.Parent = Var
			end
		end
		self.Connections[self.InstanceToPathMap[Var]] = Var.ChildAdded:Connect(function(child)
			print("Child added:", child.Name, "to", Var.Name)
			self:OnChildAdded(Value, Var, child)
		end)

		self.Connections[self.InstanceToPathMap[Var]] = Var.ChildRemoved:Connect(function(child)
			print("Child removed:", child.Name, "from", Var.Name)
			self:OnChildRemoved(Value, Var, child)
		end)
	else
		Var.Value = Value
		self.InstanceToPathMap[Var] = { Name = Name, tableRef = parentTableRef }

		self.Connections[self.InstanceToPathMap[Var]] = Var.Changed:Connect(function()
			print("Instance value changed:", Var.Name, "New Value:", Var.Value)
			self:UpdateTable(Value, Var)
		end)

		if parentTableRef then
			parentTableRef[Name] = Value
		end
	end

	return Var
end

function VarToObject:OnChildAdded(parentTableRef: table, parentInstance: Instance, child: Instance)
	local childName = child.Name

	if child:IsA("Folder") then
		parentTableRef[childName] = {}
	elseif child:IsA("ValueBase") then
		parentTableRef[childName] = child.Value
	end

	self.InstanceToPathMap[child] = { Name = childName, tableRef = parentTableRef[childName] }

	if child:IsA("ValueBase") then
		child.Changed:Connect(function()
			print("Value changed for", child.Name, "New Value:", child.Value)
			self:UpdateTable(child.Value, child)
		end)
	end
end

function VarToObject:OnChildRemoved(parentTableRef: table, parentInstance: Instance, child: Instance)
	local childName = child.Name
	parentTableRef[childName] = nil
	self.InstanceToPathMap[child] = nil

	print("Child removed:", childName, "from", parentInstance.Name)
end

function VarToObject:UpdateTable(_, instance: ValueBase)
	local pathData = self.InstanceToPathMap[instance]
	if not pathData then
		warn("No path data for instance:", instance.Name)
		return
	end

	local tableRef = pathData.tableRef

	local currentValue = instance.Value

	if tableRef then
		tableRef[instance.Name] = currentValue
		print("Updated table entry for", instance.Name, "with new value:", currentValue)
	else
		warn("No table reference for instance:", instance.Name)
	end
end

function VarToObject:Destroy()
	local self : typeof(VarToObject.new()) = self
	self.InstanceToPathMap = {}
	print(self.Connections)
	for i,v : RBXScriptConnection in pairs(self.Connections) do
		v:Disconnect()
		self.Connections[i] = nil
	end
	print(self.Connections)
	if self.RootInstance then
		self.RootInstance:Destroy()
		self.RootInstance = nil
	end
	setmetatable(self,nil)
	self = nil
end

return VarToObject
