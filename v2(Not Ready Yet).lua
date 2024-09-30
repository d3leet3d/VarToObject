local VarToObject = {}
VarToObject.__index = VarToObject

VarToObject.VarTypes = {
	["number"] = "NumberValue",
	["string"] = "StringValue",
	["boolean"] = "BoolValue",
	["table"] = "Folder"
}

function VarToObject.new(Name: string, Value: any, parentTableRef: table)
	local self = setmetatable({}, VarToObject)
	self.InstanceToPathMap = {}
	self.TableToInstanceMap = {}
	self.RootInstance = self:CreateInstance(Name, Value, parentTableRef)
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
		self.TableToInstanceMap[Value] = Var
		self.InstanceToPathMap[Var] = { path = { Name }, tableRef = Value }

		for key, val in pairs(Value) do
			local keyName = tostring(key)
			local child = self:CreateInstance(keyName, val, Value)
			if child then
				child.Parent = Var
			end
		end

		Var.ChildAdded:Connect(function(child)
			print("Child added:", child.Name, "to", Var.Name)
			self:OnChildAdded(Value, Var, child)
		end)
		Var.ChildRemoved:Connect(function(child)
			print("Child removed:", child.Name, "from", Var.Name)
			self:OnChildRemoved(Value, child)
		end)
	else
		Var.Value = Value
		self.InstanceToPathMap[Var] = { path = { Name }, tableRef = parentTableRef }
		Var.Changed:Connect(function()
			print("Instance value changed:", Var.Name, "New Value:", Var.Value)
			self:OnValueChanged(Var)
		end)

		if parentTableRef then
			parentTableRef[Name] = Value
		end
	end

	return Var
end

function VarToObject:UpdateTableFromInstance(tableRef: table, path: {string}, newValue: any)
	local current = tableRef
	for i = 1, #path - 1 do
		local key = path[i]
		if current[key] == nil then
			current[key] = {}
		end
		current = current[key]
	end
	local lastKey = path[#path]
	current[lastKey] = newValue
end

function VarToObject:OnValueChanged(instance : ValueBase)
	local pathData = self.InstanceToPathMap[instance]
	if not pathData then return end

	local path = pathData.path
	local tableRef = pathData.tableRef

	if not tableRef then
		warn("No tableRef for Instance:", instance.Name)
		return
	end
	if instance:IsA("ValueBase") then
		self:UpdateTableFromInstance(tableRef, path, instance.Value)
	end
end

function VarToObject:OnChildAdded(tableRef: table, folder: Instance, child: Instance)
	local pathData = self.InstanceToPathMap[folder]
	if not pathData then
		warn("No path data for folder:", folder.Name)
		return end

	local path = pathData.path
	local newPath = { table.unpack(path) }
	table.insert(newPath, child.Name)
	self.InstanceToPathMap[child] = { path = newPath, tableRef = tableRef[child.Name] or tableRef }

	if child:IsA("Folder") then
		tableRef[child.Name] = {}
		for _, grandChild in ipairs(child:GetChildren()) do
			self:OnChildAdded(tableRef[child.Name], child, grandChild)
		end
		child.ChildAdded:Connect(function(newChild)
			self:OnChildAdded(tableRef[child.Name], child, newChild)
		end)
		child.ChildRemoved:Connect(function(oldChild)
			tableRef[child.Name][oldChild.Name] = nil
			self.InstanceToPathMap[oldChild] = nil
		end)
	else
		if child:IsA("ValueBase") then
			tableRef[child.Name] = child.Value
		end
		--if child:IsA("NumberValue") or child:IsA("IntValue") then
		--	tableRef[child.Name] = child.Value
		--elseif child:IsA("StringValue") then
		--	tableRef[child.Name] = child.Value
		--elseif child:IsA("BoolValue") then
		--	tableRef[child.Name] = child.Value
		--end
		child.Changed:Connect(function()
			self:OnValueChanged(child)
		end)
	end
end

function VarToObject:OnChildRemoved(tableRef: table, child: Instance)
	local pathData = self.InstanceToPathMap[child]
	if not pathData then return end

	local path = pathData.path
	local current = tableRef
	for i = 1, #path - 1 do
		local key = path[i]
		current = current[key]
	end
	local lastKey = path[#path]
	current[lastKey] = nil
	self.InstanceToPathMap[child] = nil
end

function VarToObject:Destroy()
	for instance, _ in pairs(self.InstanceToPathMap) do
		if instance:IsA("Folder") then
			instance.ChildAdded:Disconnect()
			instance.ChildRemoved:Disconnect()
		else
			instance.Changed:Disconnect()
		end
	end
	self.InstanceToPathMap = {}
	self.TableToInstanceMap = {}

	if self.RootInstance then
		self.RootInstance:Destroy()
		self.RootInstance = nil
	end
end

return VarToObject
