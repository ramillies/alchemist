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
		onInit = function (self)
			self.cooldown = math.random(1, 14)
			self.forHire = ""
		end,
		onNewDay = function (self)
			if self.cooldown > 1 then
				self.cooldown = self.cooldown - 1
			elseif self.cooldown == 1 then
				self.cooldown = 0
				local allowed = { "knight", "barbarian", "rogue", "ranger", "assassin", "fire wizard", "water wizard", "earth wizard", "air wizard" }
				self.forHire = allowed[math.random(1, #allowed)]
			end
		end,
		onVisit = function (self, player)
			if self.forHire == "" then
				messagebox("Inn", "You enjoy a good pint of ale in the local inn. However, there is nobody to be hired.")
			else
				choicebox("Hire", string.format("You find a %s who is offering his services for a pay. Would you like to recruit him for 200 gold?", Units[self.forHire].name),
				{
					{ text = "Hire him", disabled = player:getCoins() < 200, callback = function()
						if player:addUnit(self.forHire) then
							messagebox("Hire", "You hired him and he has entered your party immediately.")
							player:giveCoins(-200)
							self.forHire = ""
							self.cooldown = math.random(24, 34)
						else
							messagebox("Hire", "Sadly, you don't have space for him in your party.")
						end
					end },
					{ text = "Do not hire him" }
				})
			end
		end
	},
	["shipyard"] = {
		name = "Shipyard",
		description = "Sail to another city with shipyard",
		onInit = function (self)
			self.costPerSquare = math.random(15, 25)
		end,
		onVisit = function (self, player)
			teleportscreen(World, player, "Set Sail", "Bla bla", function (x, y)
					local f = World:featureAt(x, y)
					local dist = math.abs(x - place:getX()) + math.abs(y - place:getY());
					local cost = place:adjustedCost(dist*self.costPerSquare)
					if (f == "castle" or f == "city" or f == "village") then
						local r = World:placeAtString(x, y, 'return tostring(place:hasBuilding("Shipyard"))')
						if r == "true" then
							if player:getCoins() < cost then
								return {
									allowed = false,
									text = string.format("It is possible to sail to %s for %d gold (%d days), but you don't have enough gold.", World:placeAtString(x, y, "return place:getName()"), dist*self.costPerSquare, dist/2)
								}
							else
								return {
									allowed = true,
									text = string.format("Sail to %s for %d gold (%d days).", World:placeAtString(x, y, "return place:getName()"), dist*self.costPerSquare, dist/2)
								}
							end
						else
							return { allowed = false, text = "You cannot sail here." }
						end
					else
						return { allowed = false, text = "You cannot sail here." }
					end
				end,
				function (x, y, travel)
					if travel then
						local dist = math.abs(x - place:getX()) + math.abs(y - place:getY());
						player:giveCoins(-place:adjustedCost(dist*self.costPerSquare))
						Time:advance(dist/2)
						player:setPosition(x, y)
					end
				end
			)
		end
	},
	["guardhouse"] = {
		name = "Guard House",
		allowedIn = "city",
	},
	["thieves guild"] = {
		name = "Thieves' Guild",
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
		onInit = function (self)
			self.entryFee = 100
			self.hasInfo = math.random(1, 3)
			self.days = 10
		end,
		onVisit = function (self, player)
			if self.hasInfo < 1 then
				messagebox("Library", "There are some nice books in this library, but nothing that would tell you anything interesting about alchemy.")
			else
				choicebox("Library",
				string.format("Many obscure books are kept within the walls of this library, and some of them perhaps talk about alchemical secrets. Do you want to search the books?\nYou will need to pay a fee of %d coins and the search will take %d days.", self.entryFee, self.days),
				{
					{ text = "Search the books", disabled = player:getCoins() < self.entryFee, callback = function()
						local knowledge = PotionTable:giveRandomKnowledge("medium")
						Time:advance(self.days)
						self.days = self.days * 2
						self.hasInfo = self.hasInfo - 1
						if knowledge == "" then
							messagebox("Bad Luck", "Your knowledge is already so vast that you couldn't find anything new in this library.")
						else
							messagebox("Great!", string.format("You found an old book about alchemy, and there were some stories about people who tried to make a Potion of Youth. Sadly, they were all unsuccessful, but at least you manage to deduce that the potion is NOT made %s, and you put that down into your notebook.", knowledge))
						end
				end },
					{ text = "Go away" }
				})
			end
		end,
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
							text = string.format("Buy %d?? %s for %d gold", n, Ingredients[k].name, cost),
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
			if #choices > 1 then
				choicebox("Adventurers' Guild", "This is one of the guilds that adventurers found to help them sell the more obscure pieces of their loot. Obviously it is often possible to get decent alchemical ingredients there... for a price.\nWhat would you like to buy?", choices)
			else
				messagebox("Adventurers' Guild", "The merchantmen of the guild show you various pieces of loot, but nothing of it has any alchemical value. You will have to come later.")
			end
		end,
		onNewDay = function (self)
			if math.random() < 0.04 then
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
		onInit = function (self)
			self.costPerPart = math.random(10, 20)
			self.herbs = 0
			self.maxHerbs = math.random(9, 13)
			local keys = {}
			for k, v in pairs(Herbs) do
				if not loadstring(v.placeCondition)() then
					table.insert(keys, k)
				end
			end
			self.herbType = keys[math.random(1, #keys)]
		end,
		onVisit = function (self, player)
			choices = { { text = "Nothing" } }
			if self.herbs > 0 then
				local n = self.herbs
				while n >= 1 do
					local cost = place:adjustedCost(n*self.costPerPart, -1)
					local num = n
					table.insert(choices, {
						text = string.format("Buy %d?? %s for %d gold", n, Herbs[self.herbType].name, cost),
						disabled = player:getCoins() < cost,
						tileset = Herbs[self.herbType].tileset,
						tilenumber = Herbs[self.herbType].tilenumber,
						callback = function ()
							messagebox("Herbs Purchased",
								string.format("You purchased %d %s for %d gold.", num, Herbs[self.herbType].name, cost))
							player:giveItems{[self.herbType] = num}
							player:giveCoins(-cost)
							self.herbs = self.herbs - num
						end
					})
					n = math.floor(n/2)
				end
			end
			if #choices > 1 then
				choicebox("Secluded Shack", string.format("An evil witch lives in this lonely shack, growing various fantastic herbs for her wicked experiments. Fortunately she is willing to part with some of her %s, of course for a price.\nWhat would you like to buy?", Herbs[self.herbType].name), choices)
			else
				messagebox("Secluded Shack", "The old witch sneers: \"Do you expect me to give everything I have to some upstart alchemist? Just go away! I'm not going to sell you anything!\".")
			end
		end,
		onNewDay = function (self)
			if math.random() < 0.1 then
				self.herbs = self.herbs + math.random(1, 4)
				if self.herbs > self.maxHerbs then self.herbs = self.maxHerbs end
			end
		end
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
