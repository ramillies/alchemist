import std.stdio;
import std.algorithm;
import std.array;

import mainloop;
import messagebox;
import choicebox;
import util;
import player;
import world;
import teleportscreen;

import luad.all;

void putPopupsIntoLua(LuaState lua)
{
	lua["messagebox"] = delegate void(string header, string msg) { Mainloop.pushScreen(new MessageBox(header, msg)); };
	lua["messageboxWithSize"] = delegate void(string header, string msg, double bw, double bh) { Mainloop.pushScreen(new MessageBox(header, msg, bw, bh)); };
	lua["choicebox"] = delegate void(string header, string msg, LuaTable[] choiceTables)
	{
		auto choices = choiceTables.map!((c) => Choice.fromLuaTable(c)).array;
		Mainloop.pushScreen(new ChoiceBox(header, msg, choices));
	};
	lua["teleportscreen"] = delegate void (LuaTable world, LuaTable player, string heading, string msg, LuaTable delegate(size_t, size_t) infoCallback, void delegate(size_t, size_t, bool) resultCallback)
	{
		writefln("getting player ptr");
		auto p = string2ptr!Player(player.get!string("ptr"));
		writefln("getting world ptr");
		auto w = string2ptr!World(world.get!string("ptr"));
		writefln("pushing screen");
		Mainloop.pushScreen(new TeleportScreen(w, p, heading, msg, infoCallback, resultCallback));
	};
}
