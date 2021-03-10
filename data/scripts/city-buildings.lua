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
		description = "You can recruit followers here.",
		onVisit = function () messagebox("Inn", "You enjoy a good pint of ale in the local inn.") end,
	},
	["shipyard"] = {
		name = "Shipyard",
		description = "You can move to another city with shipyard from here.",
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
		description = "You can find some potion-making information here.",
		onVisit = function () messagebox("Library", "You enjoy a good read at the local library.") end,
	},
	["adventurers guild"] = {
		name = "Adventurer's Guild",
		allowedIn = "city",
		description = "Sells potion ingredients.",
		onVisit = function () messagebox("Adventurers' Guild", "You enjoy a good chat with the local adventurers.") end,
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
		description = "Sells herbs.",
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
