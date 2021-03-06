dofile("data/scripts/city-buildings.lua")
dofile("data/scripts/city-names.lua")
dofile("data/scripts/city-customers.lua")
dofile("data/scripts/deepcopy.lua")

function place:init()
	self.reputation = 0
	self.buildings = { }
	local feature = World:featureAt(self:getX(), self:getY())
	self.settlementType = feature
	table.insert(self.buildings, buildings.inn)
	if feature == "city" then
		table.insert(self.buildings, buildings["city hall"])
	elseif feature == "village" then
		table.insert(self.buildings, buildings["foremans house"])
	elseif feature == "castle" then
		table.insert(self.buildings, buildings["central tower"])
	end

	if feature == "city" or feature == "village" then
		local shipyard = false
		for k = -1, 1 do
			for l = -1, 1 do
				if k^2 + l^2 == 1 and World:featureAt(self:getX() + k, self:getY() + l) == "water" then
					shipyard = true
				end
			end
		end
		if shipyard then table.insert(self.buildings, buildings.shipyard) end
	end
	local allowedBuildings = { }
	for k, v in pairs(buildings) do
		if v.allowedIn == feature then
			table.insert(allowedBuildings, v)
		end
	end
	local giveBuildings = math.random(2, 3)
	if feature == "castle" then
		giveBuildings = math.random(1, 2)
	end
	for i = 1, giveBuildings do
		local index = math.random(1, #allowedBuildings)
		table.insert(self.buildings, allowedBuildings[index])
		table.remove(allowedBuildings, index)
	end

	for k, v in pairs(self.buildings) do
		if type(v.onInit) == "function" then
			v:onInit()
		end
	end
		
	self.name = cityNames[math.random(1, #cityNames)]
	self:setName(self.name)
	self:updateDescription()

	self.customers = { }
end

function place:newDay()
	for k, v in pairs(customerTable) do
		if v.appear(self) then
			local customer = table.deepcopy(v)
			customer:init(self)
			table.insert(self.customers, customer)
			break
		end
	end
	for k, v in pairs(self.buildings) do
		if type(v.onNewDay) == "function" then
			v:onNewDay()
		end
	end
end

function place:enter(player)
	local choices = {
		{ text = "Try to sell your potions to the locals.", callback = function () self:sellStuff(player) end, popBox = false }
	}
	for k, v in pairs(self.buildings) do
		table.insert(choices, {
			text = string.format("Visit %s%s.", v.name, v.description and " (" .. v.description .. ")" or ""),
			disabled = v.onVisit == nil,
			callback = function () v:onVisit(player) end,
			popBox = false
		})
	end
	table.insert(choices, { text = "Go away." })
	choicebox(self.name, string.format("You entered the %s of %s.\n\nWhat would you like to do here?", self.settlementType, self.name), choices)
end

function place:updateDescription()
	local intro = { city = "This is a proud city with these buildings:",
	village = "This is a quiet village with these buildings:", 
	castle = "This is a strong castle with these buildings:" }
	local desc = intro[self.settlementType] .. "\n"
	for n = 1, #self.buildings do
		desc = desc .. string.format("      %s\n", self.buildings[n].name)
	end
	local repRank = ""
	if self.reputation < -78 then repRank = "Hated"
	elseif self.reputation < -46 then repRank = "Feared"
	elseif self.reputation < -14 then repRank = "Disliked"
	elseif self.reputation < 14 then repRank = "Ignored"
	elseif self.reputation < 46 then repRank = "Liked"
	elseif self.reputation < 78 then repRank = "Loved"
	else repRank = "Adored" end
	desc = desc .. "\n" .. string.format("You are %s here (%d).", repRank, self.reputation);
	self:setDescription(desc)
end

function place:sellStuff(player)
	place:removeAwayCustomers()
	if #self.customers == 0 then
		messagebox("Nobody here", "Nobody is currently interested in buying potions.")
	else
		choices = { }
		for k, v in pairs(self.customers) do
			table.insert(choices, {
				text = v.name,
				callback = function () v:talk(self, player) end,
				tileset = v.tileset,
				tilenumber = v.tilenumber
			})
		end
		table.insert(choices, { text = "Nobody ??? I changed my mind" })
		choicebox("Customers", "There are some people that would be interested in buying potions... if they meet their needs, of course. Who do you want to talk with?", choices)
	end
end

function place:removeAwayCustomers()
	for k, v in pairs(self.customers) do
		if v.goAway then
			table.remove(self.customers, k)
			self:removeAwayCustomers()
			break
		end
	end
end

function place:hasBuilding(name)
	for k, v in pairs(self.buildings) do
		if v.name == name then
			return true
		end
	end
	return false
end

function place:numberOfCustomers(name)
	local count = 0
	for k, v in pairs(self.customers) do
		if v.name == name then
			count = count + 1
		end
	end
	return count
end

function place:addReputation(x)
	self.reputation = self.reputation + x
	if self.reputation > 100 then
		self.reputation = 100
	elseif self.reputation < -100 then
		self.reputation = -100
	end
	place:updateDescription()
end

function place:adjustedCost(cost, modifier)
	if modifier == nil then modifier = 1 end
	return cost * 3 ^ (-self.reputation*modifier/100)
end
