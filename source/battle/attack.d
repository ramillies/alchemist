import std.algorithm, std.array, std.range;
import std.json;

import stats;
import effect;

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

	static Attack fromJSON(JSONValue x)
	{
		auto ret = new Attack(
			cast(AttackType) x["type"].str,
			x["strength"].get!int,
			x["chanceToHit"].get!double / 100,
			x["usedOnEnemies"].boolean
		);
		auto targetCode = x["targets"].str;
		ret.targets = (int x, bool[] a, bool[] b) => ret.lua.loadString(targetCode).call!(int[][])(x, a, b);
		return ret;
	}

}
