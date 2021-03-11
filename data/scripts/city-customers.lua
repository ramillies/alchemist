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
		tilenumber = 370,
		appear = function(city)
			return city:numberOfCustomers("Fisherman") < 3 and #city.customers < 10 and
				city:hasBuilding("Shipyard") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"Greetings potion maker, I will soon set sail to the sea and I fear some storm could wreck my boat and leave me swimming in the middle of the endless waters, do you have something that could help me out there?",
				"Hello master alchemist, I can navigate even the rockiest coasts and fight sharks with just a pencil, but I cannot control the ocean and no one can be overprepared when setting sail there. Do you have some alchemical concoctions that could come handy at sea?",
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
				player:giveItems({ [given] = -1 })
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
	
},
{
		name = "Pirate",
		tileset = "people",
		tilenumber = 273,
		appear = function(city)
			return city:numberOfCustomers("Pirate") < 1 and #city.customers < 10 and
				city:hasBuilding("Shipyard") and math.random() < 0.03
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"AHOY THERE MATEY, I heard ye have some useful drinks that could help me plund….. eh, I meant to trade at sea. Do ye have something that could be useful to me?",
				"YO HO HO AND BOTTLE OF YOUR FINEST POTION, my ship is leaving port and I thought I could spend some of me legally obtained booty to purchase something from yer stock, do ye have something that could interest old sea dog like me",
				"Land Ho, but not for long. If some landlubber like you could offer me something useful for me and me hearties, I could give ye some doubloons from me coffer."
			}
			choicebox("Pirate",
				line,
				{
					{ text = "Yar mate, try this", callback = function ()
						inventorybox(player, "Pirate", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "Narr mate, I cannot help you." }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "water resistance potion", "water walk potion", "battle frenzy potion", "tentacles potion", "courage potion" }) then
				local reward = math.random(125, 200)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"Prepare to walk the plank………….. back to the harbor, of course, this potion is great. Here is yer bounty.",
					"Shiver me timbers, All hand hoy and take a look at this! ye earned yer pay, catch this.",
					"Blimey! No broadside can't sink us now lad. Ye are great achlemoist or what ye say ye are, here is yer loot."
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"How could I use this? Get out of my ship before I keelhaul you.",
					"How could I use this? Get out of my ship before I maroon you somewhere far from here.",
					"How could I use this? Get out of my ship before I show you what we do with the drunken sailors."
				})
			end
		end
	
},
{
		name = "Guardsman",
		tileset = "people",
		tilenumber = 276,
		appear = function(city)
			return city:numberOfCustomers("Guardsman") < 3 and #city.customers < 10 and
				city:hasBuilding("Guard House") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"I used to be an adventurer before I realized that the pay of a guardsman is just better and the job is safer. Do you have some elixirs that could keep me even safer?",
				"Hey there, I heard you could sell some potions that can make you fly, but then I heard it is not just a metaphor for drugs, so instead of arresting you, I would like to know, if you have some potion that could be useful to guardsmen like me?",
				"I keep these streets clean from thugs and thieves, but I could use a little help in the form of your potions, could some of them help me do my job better?"
			}
			choicebox("Guardsman",
				line,
				{
					{ text = "Yeah, I have some potions for lawman like you", callback = function ()
						inventorybox(player, "Guardsman", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "I cannot help you, but Im sure you will be fine without my potions" }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "courage potion", "defense potion", "critical hit potion", "fire shield potion" }) then
				local reward = math.random(100, 125)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"No evildoer can stop me now, here is your reward, you earned it.",
					"Streets will be a safer place thanks to you, here is your coin."
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"Thanks for your offer, but this can hardly help me catch criminals.  ",
					"I see the usefulness of this potion, but not in the streets, thanks for your offer.",
                    "I do not need this, why would I buy something like this when I can buy something that could help me keep law and order."
				})
			end
		end
	
},
{
		name = "Capitan Of The Guard",
		tileset = "people",
		tilenumber = 284,
		appear = function(city)
			return city:numberOfCustomers("Capitan Of The Guard") < 1 and #city.customers < 10 and
				city:hasBuilding("Guard House") and math.random() < 0.05
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"As a captain of the guard, i have tons of cash to spend and very little to to spend it on, i have the best weapons and armor money can buy and i don't trust magical scrolls, so your potions could be my only option to gain upper hand in combat, can you offer me some?",
				"I heard your potions can do miracles inside and outside of combat, so i naturally want one. Do you have any that could help me fight a whole gang of enemies at once?",
			}
			choicebox("Capitan Of The Guard",
				line,
				{
					{ text = "I have something special for you, Capitan", callback = function ()
						inventorybox(player, "Capitan Of The Guard", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "Sorry Capitan, I dont have anything that would satisfy you." }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "dragon fury potion", "unleash kraken potion", "stasis potion", "steal attack potion", "petrify potion", "sleep potion" }) then
				local reward = math.random(225, 350)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"Ah, yes, yes, this is a very potent mixture that can surely make me nearly invincible, here is your coin. ",
					"Justice will surely celebrate another victory, now that i'm equipped with this potion, i consider it money well spent.",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"I don't think this option is worthy for someone so important as me. ",
					"I have no use for that potion, it couldn't even protect me from the first few bolts.",
				})
			end
		end
	
},  
{
		name = "Prisoner",
		tileset = "people",
		tilenumber = 368,
		appear = function(city)
			return city:numberOfCustomers("Prisoner") < 1 and #city.customers < 10 and
				city:hasBuilding("Guard House") and math.random() < 0.05
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"Please help me, I don't belong here, I just forgot to pay taxes and I ended up here, have mercy on poor father of three, just give me some of your potions and I will pay you up to double its cost, please",
			}
			choicebox("Prisoner",
				line,
				{
					{ text = "Im risking a lot by helping you, but take this", callback = function ()
						inventorybox(player, "Prisoner", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "You should have followed the law" }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "alchemist fire potion", "strength potion", "fear potion", "transform into frog potion", "hold potion" }) then
				local reward = math.random(200, 300)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"(as you give him the potion, he smiles and runs to the corner of his cell, a few minutes later you can hear a surprised scream from one of the guardsmen and then metal clinging of a short fight and a few minutes later, the prisoner walks through the jails main entrance and toses you a bag filled with money, before running away)",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"I can’t think of a way this could help me. Well, time to get back to digging through the floor with my spoon.",
				})
			end
		end
	
}, 
{
		name = "Bishop",
		tileset = "people",
		tilenumber = 154,
		appear = function(city)
			return city:numberOfCustomers("Bishop") < 2 and #city.customers < 10 and
				city:hasBuilding("Cathedral") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"Dolorem Ipsum quia dolor sit amet, or as we say in common language, Welcomed be the one who walks in the light of the Dolorem. Could any of your brews help me spread his message?",
			}
			choicebox("Bishop",
				line,
				{
					{ text = "Would this potion please Dolorem?", callback = function ()
						inventorybox(player, "Bishop", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "Im afraid my potions cant help you" }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "heal potion", "satiate potion", "regeneration potion", "panacea potion", "fire resistance potion", "water resistance potion", "earth resistance potion",  "air resistance potion" }) then
				local reward = math.random(100, 150)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"Blessed be the day of your arrival, this potion will help me spread the light even to the darkest corners.",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"I see your intentions were true, but Dolorem will find the way without this potion.",
				})
			end
		end
	
}, 
{
		name = "Crusader",
		tileset = "people",
		tilenumber = 284,
		appear = function(city)
			return city:numberOfCustomers("Crusader") < 2 and #city.customers < 10 and
				city:hasBuilding("Cathedral") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"Dolorem Ipsum brother, evil grasps these lands and I must purge it with the strength of Dolorem on my side, but I see no harm in helping myself with some of that stuff you are offering",
				}
			choicebox("Crusader",
				line,
				{
					{ text = "I have always some potions for knights in shining armor", callback = function ()
						inventorybox(player, "Crusader", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "None of my potions could enhance your holy talent" }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "defense potion", "courage potion", "strength potion", "battle frenzy potion" }) then
				local reward = math.random(100, 150)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"Dolorem Vult, now I’m ready to smite all heathens and purify their unholy abominations in righteous fire",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"Dolorem would be displeased if I would use this unchivalrous potion",
				})
			end
		end
	
},
{
	name = "Pope",
		tileset = "people",
		tilenumber = 163,
		appear = function(city)
			return city:numberOfCustomers("Pope") < 1 and #city.customers < 10 and
				city:hasBuilding("Cathedral") and math.random() < 0.05
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"Dolorem Ipsum quia dolor sit amet, your reputation precedes you like angels precede great events, I would like to buy one of your best potions and I don’t plan to skimp, show me what you have.",
			}
			choicebox("Pope",
				line,
				{
					{ text = "Would this be holy enough for you Holy one?", callback = function ()
						inventorybox(player, "Pope", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "Excuse my unpreparedness, I will return with some potion worhty of your time " }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "wings potion", "angel of death potion", "time loop potion", "stasis potion" }) then
				local reward = math.random(225, 350)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"Dolorem chose well when he gifted you the gift of a potion-making, here is your coin."
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"This is a remarkable elixir, but it’s not holy enough for someone like me",
				})
			end
		end
	
},
{
		name = "Nobleman",
		tileset = "people",
		tilenumber = 374,
		appear = function(city)
			return city:numberOfCustomers("Nobleman") < 2 and #city.customers < 10 and
				city:hasBuilding("Palace") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"A court is a dangerous place filled with all manners of backstabbing schemers and silver-tongued killers, could you sell me something that would save my life from them? ",
			}
			choicebox("Nobleman",
				line,
				{
					{ text = "Drink this when assassins come knocking or use it when you need someone gone", callback = function ()
						inventorybox(player, "Nobleman", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "Sorry, I cannot help you right now" }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "poison potion", "earth resistance potion", "speed potion", "defense potion", "hold potion", "wings potion" }) then
				local reward = math.random(150, 200)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"Impressing, this will surely come in handy one day, I just hope I won’t need to use it.",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					" I could use it perhaps at some village at the end of the world, but not here at court. "
				})
			end
		end
	
},
{
		name = "Lady In Waiting",
		tileset = "people",
		tilenumber = 188,
		appear = function(city)
			return city:numberOfCustomers("Lady In Waiting") < 1 and #city.customers < 10 and
				city:hasBuilding("Palace") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"Oh, how my heart akes for that man, I would kill just to have him by my side, mayhaps one of your vials could change his mind and allow him to see me in my dazzling beauty, don’t you agree?",
			}
			choicebox("Lady In Waiting",
				line,
				{
					{ text = "I have the cure for your hearths malady, my lady.", callback = function ()
						inventorybox(player, "Lady In Waiting", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "Not even my potions can help you with face THAT ugly" }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "love potion", }) then
				local reward = math.random(125, 200)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"He will be mine in the blink of an eye. Thank you old man and enjoy your money.",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"I knew the only useful thing alchemists can make are perfumes? ",
				})
			end
		end
	
},
{
		name = "Guild Enforcer",
		tileset = "people",
		tilenumber = 213,
		appear = function(city)
			return city:numberOfCustomers("Guild Enforcer") < 2 and #city.customers < 10 and
				city:hasBuilding("Thieves' Guild") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"One of the local shop owners refuses to pay us our protection fee, do you have something that could help me show him why should he pay us? ",
			}
			choicebox("Guild Enforcer",
				line,
				{
					{ text = "Say hello to your new little friend in the bottle", callback = function ()
						inventorybox(player, "Guild Enforcer", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "I cannot help you, sorry" }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "strength potion", "weakness potion", "fear potion", "alchemist fire potion" }) then
				local reward = math.random(200, 300)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"Well, you made me offer so good, that I cannot refuse it",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"Is this funny to you? If you will try to sell me something like this again, you will be sleeping with the fishes, capiche?",
				})
			end
		end
	
},
{
		name = "Assassin",
		tileset = "people",
		tilenumber = 186,
		appear = function(city)
			return city:numberOfCustomers("Assassin") < 1 and #city.customers < 10 and
				city:hasBuilding("Thieves' Guild") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"The unseen blade is the deadliest one, but a great potion can be an even greater asset. can you offer me some fit for men of my ehm.....expertise?",
			}
			choicebox("Assassin",
				line,
				{
					{ text = "With this, no man can stop you", callback = function ()
						inventorybox(player, "Assassin", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "Not really" }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "poison potion", "speed potion", "levitation potion", "accuracy potion", "critical hit potion" }) then
				local reward = math.random(200, 300)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"This is a masterpiece fit for a master of his craft like me, thank you.",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"I don’t need this, I will be better of with my sharp reflexes and uncanny agility",
				})
			end
		end
	
},
{
		name = "Hunter",
		tileset = "people",
		tilenumber = 205,
		appear = function(city)
			return city:numberOfCustomers("Hunter") < 3 and #city.customers < 10 and
				city:hasBuilding("Hunter's Lodge") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"I have the eyes of an eagle and the arms of a bear, but I want to bring more animal body parts home, so I can stuff them and display them like trophies, do you have something that could help me do that?",
				}
			choicebox("Hunter",
				line,
				{
					{ text = "Sure, I can find something for guy like you", callback = function ()
						inventorybox(player, "Hunter", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "I dont think so" }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "speed potion", "slowness potion", "accuracy potion ", "hold potion", "clumsy potion" }) then
				local reward = math.random(75, 125)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"Great, no prey shall escape me now, here is your payment.",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"I suppose you have no idea what you need to catch a deer, don’t you?",
				})
			end
		end
	
},    
{
		name = "Miner",
		tileset = "people",
		tilenumber = 364,
		appear = function(city)
			return city:numberOfCustomers("Miner") < 3 and #city.customers < 10 and
				city:hasBuilding("Mine") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"I spend my whole day underground smashing stones and pulling carts, suffice to say my life is in danger all the time, could some of your elixirs help me in the blackness of mine?",
			}
			choicebox("Miner",
				line,
				{
					{ text = "Yeah, I can give you some", callback = function ()
						inventorybox(player, "Miner", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "No way." }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "strength potion", "earth resistance potion", "alchemist fire potion", "fortitude potion" }) then
				local reward = math.random(75, 125)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"Well, well, well, I found the mother lode, this will surely be useful in the mines, take these golden nuggets.",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"This is useless like fools gold. I should get back to work.",
				})
			end
		end
	
},
{
		name = "Blacksmith",
		tileset = "people",
		tilenumber = 370,
		appear = function(city)
			return city:numberOfCustomers("Blacksmith") < 1 and #city.customers < 10 and
				city:hasBuilding("Smithy") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"You don’t look like someone that needs my services, but as an alchemist, I could use yours, if you have something useful to a blacksmith of course.",
}
			choicebox("Blacksmith",
				line,
				{
					{ text = " I have something for tough guy like you", callback = function ()
						inventorybox(player, "Blacksmith", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "I dont have anything useful to you at this time." }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "fire resistance potion", "strength potion", "courage potion" }) then
				local reward = math.random(100, 150)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"This potion will help me craft the best armor in the land, thank you.",
					"This potion will help me craft the best weapons in the land, thank you.",
					"This potion will help me craft the best horseshoes in the land, thank you."
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"I cant see the usefulness of this potion in the heat of the forge ",
				})
			end
		end
	
},
{
		name = "Priest",
		tileset = "people",
		tilenumber = 143,
		appear = function(city)
			return city:numberOfCustomers("Priest") < 1 and #city.customers < 10 and
				city:hasBuilding("Church") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"Dolorem Ipsum son, welcome to my humble church, I don’t have a lot of money but if you could sell me some potion that could help me feed the poor and tend to wounded, I will be happy to pay you.",
			}
			choicebox("Priest",
				line,
				{
					{ text = "Of course father, try this", callback = function ()
						inventorybox(player, "Priest", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "I cannot help you right now" }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "heal potion", "satiate potion", "regeneration potion", "panacea potion", "courage potion" }) then
				local reward = math.random(100, 150)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"Dolorem will surely remember your contribution to his great plan. Here is our money.",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"I’m sorry my son, but I can’t spend money from the church on this potion, perhaps some other day ",
				})
			end
		end
	
},
{
		name = "Old Hag",
		tileset = "monsters",
		tilenumber = 415,
		appear = function(city)
			return city:numberOfCustomers("Old Hag") < 1 and #city.customers < 10 and
				city:hasBuilding("Secluded Shack") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"Ah, who do we have here? Potion maker heh? Then we have a lot to talk about. If you have any potions that I could use to torment these townsfolk, I would pay you good coin and even some herbs from my garden, what do you think?",
			}
			choicebox("Old Hag",
				line,
				{
					{ text = "Would you be interested in this tool of harm and misfortune? ", callback = function ()
						inventorybox(player, "Old Hag", "This is your inventory. What you will give her?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "Ehhh, excuse me, I really need to go somewhere else" }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { " lower water resistance potion", "lower earth resistance potion", "lower fire resistance potion", "lower air resistance potion", "hunger potion", "poison potion", "vulnerability potion", "fear potion", "weakness potion", "inaccuracy potion", "slow potion", "depression potion", "critical miss potion", "critical miss potion",
            "lower penetration potion", "hold on ground potion", "hold potion", "transform into frog potion", "alchemist fire potion", "degeneration potion", "illness potion", "clumsy potion", "love potion", "sleep potion", "atrophy potion", "plague potion", "petrify potion", "smoke of hopelessness potion", "power drain potion", "paralysis potion", "mega curse potion", "death vortex potion" }) then
				local reward = math.random(200, 300)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"This is marvelous, I can do so many wicked thing things with this. Take this bag of gold and these herbs and come back, if you would like to sell me more",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"What is this? I want to HARM people, not HELP them, get out of here before I turn you into a frog",
				})
			end
		end
	
},
{
		name = "Witch Hunter",
		tileset = "people",
		tilenumber = 356,
		appear = function(city)
			return city:numberOfCustomers("Witch Hunter") < 1 and #city.customers < 10 and
				city:hasBuilding("Secluded Shack") and math.random() < 0.05
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"Greeting to you master of alchemy, I heard twisted woman stalks in this village and that she uses her eldritch magic to sow seeds of evil in the minds of townsfolk and animals alike. Could some of your potions help me fight that wretched thing?",
			}
			choicebox("Witch Hunter",
				line,
				{
					{ text = "This will surely help you purge evil from this land", callback = function ()
						inventorybox(player, "Witch Hunter", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "I cant help you" }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "fire breath potion", "fire shield potion", "alchemist fire potion", "mind resistance potion", "regeneration potion", "strenght potion", "courage potion", "speed potion" }) then
				local reward = math.random(150, 200)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"Now I’m ready to condemn that fowl creature to its doom.",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"Thanks for your offer but this is useless against evil the spells of that witch",
				})
			end
		end
	
},
{
		name = "Footman",
		tileset = "people",
		tilenumber = 235,
		appear = function(city)
			return city:numberOfCustomers("Footman") < 2 and #city.customers < 10 and
				city:hasBuilding("Barracks") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"As we soldiers often say, my favorite time of the year is March, but since we are stuck at this castle I could spend some of my money to prepare myself for the next one. Do you sell something interesting?",
			}
			choicebox("Footman",
				line,
				{
					{ text = "Yeah, I can give you some", callback = function ()
						inventorybox(player, "Footman", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "No way." }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "strength potion", "critical hit potion", "battle frenzy potion", "courage potion", "defense potion" }) then
				local reward = math.random(100, 150)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"Holy moly, this will help me a great deal, here is your money, I will get more anyway because nobles will never stop fighting between themselves.",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"Well, I don’t think this is useful in the middle of a battle, but thanks anyway.",
				})
			end
		end
	
},
{
		name = "Crossbowman",
		tileset = "people",
		tilenumber = 11,
		appear = function(city)
			return city:numberOfCustomers("Crossbowman") < 2 and #city.customers < 10 and
				city:hasBuilding("Barracks") and math.random() < 0.1
		end,
		init = function(self, city) end,
		talk = function (self, city, player)
			local line = randomTalk {
				"My job is simple, shoot an enemy, reload, repeat, but that doesn’t mean it’s an easy one. Would some of your potions help me do it better?",
	}
            choicebox("Crossbowman",
				line,
				{
					{ text = "Yeah, I can give you something", callback = function ()
						inventorybox(player, "Crossbowman", "This is your inventory. What you will give him?", function (x) return self:check(city, player, x) end)
					end },
					{ text = "No way." }
				}
			)
		end,
		check = function (self, city, player, given)
			self.goAway = true
			if isInList(given, { "speed potion", "accuracy potion", "penetrating potion", "fire breath potion" }) then
				local reward = math.random(100, 150)
				player:giveCoins(reward)
				player:giveItems({ [given] = -1 })
				messagebox("Great!", randomTalk {
					"This will very useful on the battlefield, I can’t wait for what crazy stunts will this allow me to do.",
				})
			elseif given == "" then
				self.goAway = false
			else
				messagebox("Uhmmm...", randomTalk {
					"This wouldn’t help me hit even the barns door, go away, please.",
				})
			end
		end
	
},
    }
