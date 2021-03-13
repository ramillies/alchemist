import std.algorithm, std.array, std.range;
import std.json;

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
	}

	mixin(GenerateAll);

	int[][] validTargets(int selfPos, bool[] friends, bool[] enemies)
	{
		return _targets(selfPos, friends, enemies);
	}

	static Attack fromJSON(JSONValue x)
	{
		auto ret = new Attack(
			cast(AttackType) x["type"].str,
			x["strength"].get!int,
			x["chanceToHit"].get!double / 100,
			x["usedOnEnemies"].boolean
		);
		auto targetCode = x["targets"].str;
		ret.lua.openLibs;
		ret.targets = ret.lua.loadString(targetCode).call!(int[][] delegate(int, bool[], bool[]))();
		return ret;
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
