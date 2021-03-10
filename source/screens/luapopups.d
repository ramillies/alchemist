import std.algorithm;
import std.array;

import mainloop;
import messagebox;
import choicebox;

import luad.all;

void putPopupsIntoLua(LuaState lua)
{
	lua["messagebox"] = delegate void(string header, string msg) { Mainloop.pushScreen(new MessageBox(header, msg)); };
	lua["choicebox"] = delegate void(string header, string msg, LuaTable[] choiceTables)
	{
		auto choices = choiceTables.map!((c) => Choice.fromLuaTable(c)).array;
		Mainloop.pushScreen(new ChoiceBox(header, msg, choices));
	};
}
