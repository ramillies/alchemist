function randomTalk(lines)
	return lines[math.random(1, #lines)]
end

function isInList(what, list)
	for k, v in pairs(list) do
		if v == what then
			return true
		end
	end
	return false
end

customerTable = {
	{
		name = "Fisherman",
		tileset = "people",
		tilenumber = 0,
		appear = function(city)
			return city:numberOfCustomers("Fisherman") < 3 and #city.customers < 10 and
				city:hasBuilding("Shipyard") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"Greetings potion maker, I will soon set sail to the sea and I fear some storm could wreck my boat and leave me swimming in the middle of the endless waters, do you have something that could help me out there?",
				"Hello master alchemist, I can navigate even the rockiest coasts and fight sharks with just a pencil, but I cannot control the ocean and no one can be overprepared when setting sail there. Do you have some alchemical concoction that could come handy at sea?",
				"Hello there, some unintelligent blacksmith started spreading rumors that my fish aren’t fresh and that they stink, so I must set sail in the hurry to get a new batch before the morning market starts. Could some of your potions help me do it safely?"
			}
			choicebox("Fisherman",
				line,
				{
					{ text = "Yeah, I can give you some", callback = function ()
						inventorybox(player, "Fisherman", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "No way." }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "water resistance potion", "water walk potion", "levitation potion", "underwater breathing potion" }) then
				local reward = math.random(75, 125)
				player:giveCoins(reward)
				player:giveItems({ [self.want] = -1 })
				messagebox("Great!", randomTalk {
					"With help of this potion, I could catch even a Kraken, here is your payment.",
					"This looks very useful, I could pay you three nets of fish, but you look like the kind that wants money more, so here it is.",
					"Wow, with this, I even don’t need my boat, quick, take your money, I want to try it as soon as possible. "
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"This is useless to me, do you even understand how fishing works? ",
					"I don’t think I could use it at the sea. Thanks but I must set sail",
				})
			end
		end
	}
}
