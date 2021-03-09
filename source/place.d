import std.algorithm;
import std.array;
import std.range;
import std.json;
import std.stdio;

import resources;
import util;
import gametime;

import boilerplate;
import luad.all;

class Place
{
	private
	{
		size_t _x, _y;
		string _name, _description;
	}
	LuaState lua;

	@property size_t x() { return _x; }
	@property size_t y() { return _y; }
	@property string name() { return _name; }
	@property string description() { return _description; }


	this(size_t x, size_t y, string n, string d)
	{
		_x = x; _y = y; _name = n; _description = d;
		lua = new LuaState;
		lua.openLibs;
	}

	void newDay(GameTime t) { lua.doString(`place:newDay()`); }
	void init() { lua.doString(`place:init()`); }

	void luaPutInto(LuaTable obj)
	{
		obj["ptr"] = ptr2string(cast(void *) this);
		obj["getX"] = delegate size_t(LuaTable t) { return string2ptr!Place(t.get!string("ptr"))._x; };
		obj["getY"] = delegate size_t(LuaTable t) { return string2ptr!Place(t.get!string("ptr"))._y; };
		obj["getName"] = delegate string(LuaTable t) { return string2ptr!Place(t.get!string("ptr"))._name; };
		obj["setName"] = delegate void(LuaTable t, string x) { string2ptr!Place(t.get!string("ptr"))._name = x; };
		obj["getDescription"] = delegate string(LuaTable t) { return string2ptr!Place(t.get!string("ptr"))._description; };
		obj["setDescription"] = delegate void(LuaTable t, string x) { string2ptr!Place(t.get!string("ptr"))._description = x; };
	}

	static Place byName(size_t x, size_t y, string name)
	{
		JSONValue jv = ConfigFiles.get("places")[name];
		Place result = new Place(x, y, jv["name"].str, jv["description"].str);
		result.lua.doString(`place = { }`);
		result.luaPutInto(result.lua.get!LuaTable("place"));
		ConfigFiles.luaPutInto(result.lua, ["places", "herbs", "movement"]);
		result.lua.doString(jv["script"].str);
		return result;
	}
}
