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
		@Read size_t _x, _y;
		@Read string _name, _description;
		LuaState lua;
	}

	mixin(GenerateAll);

	this(size_t x, size_t y, string n, string d)
	{
		_x = x; _y = y; _name = n; _description = d;
		lua = new LuaState;
		lua.openLibs;
	}

	void newDay(GameTime t) { lua.doString(`place:newDay()`); }

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
		result.lua.doString(jv["script"].str);
		result.lua.doString(`place:init()`);
		return result;
	}
}
