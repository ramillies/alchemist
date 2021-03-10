--[[
-- Each building has:
-- 	name
-- 	description: short description displayed in the city dialog
-- 	allowedIn: where the building can be randomly generated
-- 	onInit: run once on initialization
-- 	onNewDay: run once for each new day
-- 	onVisit: run whenever player enters the building;
-- 		if missing, the building cannot be visited
]]--

buildings = {
	["city hall"] = {
		name = "City Hall",
	},
	["inn"] = {
		name = "Inn",
		description = "Recruit followers",
		onVisit = function () messagebox("Inn", "You enjoy a good pint of ale in the local inn.") end,
	},
	["shipyard"] = {
		name = "Shipyard",
		description = "Sail to another city with shipyard",
		onVisit = function () messagebox("Shipyard", "You enjoy the nice sight of sea and ships.") end,
	},
	["guardhouse"] = {
		name = "Guard House",
		allowedIn = "city",
	},
	["cathedral"] = {
		name = "Cathedral",
		allowedIn = "city",
	},
	["palace"] = {
		name = "Palace",
		allowedIn = "city",
	},
	["library"] = {
		name = "Library",
		allowedIn = "city",
		description = "Find potion-making lore",
		onVisit = function () messagebox("Library", "You enjoy a good read at the local library.") end,
	},
	["adventurers guild"] = {
		name = "Adventurers' Guild",
		allowedIn = "city",
		description = "Buy potion ingredients.",
		onInit = function (self)
			self.parts = {}
			self.keys = {}
			self.costPerPart = math.random(15, 25)
			for k, v in pairs(Ingredients) do
				self.parts[k] = 0
				table.insert(self.keys, k)
			end
		end,
		onVisit = function (self, player)
			choices = { { text = "Nothing" } }
			for k, v in pairs(self.parts) do
				if v > 0 then
					local n = v
					while n >= 1 do
						local cost = place:adjustedCost(n*self.costPerPart)
						local num = n
						table.insert(choices, {
							text = string.format("Buy %d× %s for %d gold", n, Ingredients[k].name, cost),
							disabled = player:getCoins() < cost,
							tileset = Ingredients[k].tileset,
							tilenumber = Ingredients[k].tilenumber,
							callback = function ()
								messagebox("Ingredients Purchased",
									string.format("You purchased %d %s for %d gold.", num, Ingredients[k].name, cost))
								player:giveItems{[k] = num}
								player:giveCoins(-cost)
								self.parts[k] = self.parts[k] - num
							end
						})
						n = math.floor(n/2)
					end
				end
			end
			choicebox("Adventurers' Guild", "This is one of the guilds that adventurers found to help them sell the more obscure pieces of their loot. Obviously it is often possible to get decent alchemical ingredients there... for a price.\nWhat would you like to buy?",
			choices)
		end,
		onNewDay = function (self)
			if math.random() < 0.01 then
				local loot = self.keys[math.random(1, #self.keys)]
				self.parts[loot] = self.parts[loot] + math.random(2, 5)
			end
		end
	},
	["foremans house"] = {
		name = "Foreman's House",
	},
	["hunters lodge"] = {
		name = "Hunter's Lodge",
		allowedIn = "village",
	},
	["mine"] = {
		name = "Mine",
		allowedIn = "village",
	},
	["farm"] = {
		name = "Farm",
		allowedIn = "village",
	},
	["smithy"] = {
		name = "Smithy",
		allowedIn = "village",
	},
	["church"] = {
		name = "Church",
		allowedIn = "village",
	},
	["secluded shack"] = {
		name = "Secluded Shack",
		allowedIn = "village",
		description = "Buy herbs",
		onVisit = function () messagebox("Secluded Shack", "You enjoy a good chat with the local evil witch.") end,
	},
	["central tower"] = {
		name = "Central Tower",
	},
	["barracks"] = {
		name = "Barracks",
		allowedIn = "castle",
	},
	["kitchen"] = {
		name = "Kitchen",
		allowedIn = "castle",
	}
}
