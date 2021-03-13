import std.algorithm, std.array, std.range;
import std.json;
import std.format;
import std.conv;
import std.string;

import stats;
import effect;
import util;

import boilerplate;
import luad.all;

class Attack
{
	private
	{
		@Read AttackType _type;
		@Read int _strength;
		@Read double _hitChance;
		@(This.Exclude) @Read Effect[] _effectsToAdd;
		@Read bool _useOnEnemies;
		@(This.Exclude) @Write int[][] delegate(int, bool[], bool[]) _targets;
		@(This.Init!(() => new LuaState)) @Read LuaState _lua;
		@Read @(This.Default!"") string _name, _targetName, _typeName, _strengthName;
	}

	mixin(GenerateAll);

	int[][] validTargets(int selfPos, bool[] friends, bool[] enemies)
	{
		return _targets(selfPos, friends, enemies);
	}

	static Attack fromJSON(JSONValue x)
	{
		auto description = x["description"].object;
		auto ret = new Attack(
			cast(AttackType) x["type"].str,
			x["strength"].get!int,
			x["chanceToHit"].get!double / 100,
			x["usedOnEnemies"].boolean,
			description.get("name", JSONValue("")).str,
			description.get("target", JSONValue("")).str,
			description.get("type", JSONValue("")).str,
			description.get("strength", JSONValue("")).str,
		);
		auto targetCode = x["targets"].str;
		ret.lua.openLibs;
		ret.targets = ret.lua.loadString(targetCode).call!(int[][] delegate(int, bool[], bool[]))();
		return ret;
	}

	string description()
	{
		return format("Attack: %s (%s)\nChance to hit: %d%%\nStrength: %s\nRange: %s%s",
			_name, _typeName == "" ? (cast(string) _type).capitalize : _typeName,
			to!int(100*_hitChance), _strengthName == "" ? _strength.to!string : _strengthName,
			_targetName, _useOnEnemies ? "" : " (use on friends)");

	}
	
	void luaPutInto(LuaTable obj)
	{
		obj["ptr"] = ptr2string(cast(void *) this);
		obj["getType"] = delegate string(LuaTable t) { return cast(string) string2ptr!Attack(t.get!string("ptr")).type; };
		obj["getStrength"] = delegate int(LuaTable t) { return string2ptr!Attack(t.get!string("ptr")).strength; };
		obj["getChanceToHit"] = delegate double(LuaTable t) { return string2ptr!Attack(t.get!string("ptr")).hitChance; };
		obj["isUsedOnEnemies"] = delegate bool(LuaTable t) { return string2ptr!Attack(t.get!string("ptr")).useOnEnemies; };
		obj["getTargets"] = delegate int[][](LuaTable t, int pos, bool[] friends, bool[] enemies)
		{
			return string2ptr!Attack(t.get!string("ptr")).validTargets(pos, friends, enemies);
		};
	}

}
