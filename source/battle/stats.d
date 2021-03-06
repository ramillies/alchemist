import std.algorithm;
import std.range;
import std.array;
import std.random;
import std.conv;
import std.json;

import attack;
import effect;

import boilerplate;

enum AttackType: string {
	Weapon = "weapon",
	Fire = "fire",
	Earth = "earh",
	Water = "water",
	Air = "air",
	Mind = "mind",
	Death = "death",
	Life = "life"
}

enum AttackResult: string {
	Hit = "hit",
	Miss = "miss",
	Ward = "ward",
	Immunity = "immunity"
}

struct Stats
{
	private
	{
		@Read int _hp, _maxhp;
		@Read int _armor;
		@Read int _speed;
		@Read @Write AttackType[] _wards, _immunities;
		@Read @Write Attack _attack;
		@Read @Write Effect[] _effects;
	}

	mixin(GenerateFieldAccessors);
	mixin(GenerateToString);

	@property void hp(int x) { _hp = min(_maxhp, x); }
	@property void armor(int x) { _armor = min(x, 90); }
	AttackResult tryHitWithType(AttackType type)
	{
		if(_immunities.canFind(type))
			return AttackResult.Immunity;
		if(_wards.canFind(type))
			return AttackResult.Ward;
		return AttackResult.Hit;
	}

	AttackResult hitWithType(AttackType type)
	{
		auto res = tryHitWithType(type);
		if(res == AttackResult.Ward)
			_wards = _wards.remove(_wards.countUntil(type));
		return res;
	}

	AttackResult takeHit(Attack attack)
	{
		AttackResult res = hitWithType(attack.type);
		if(res != AttackResult.Hit)
			return res;
		if(uniform01() >= attack.hitChance)
			return AttackResult.Miss;

		hp = hp - min(to!int(attack.strength * (1 - armor/100.) * uniform(1, 1.1)), 300);
		return AttackResult.Hit;
	}

	Stats applyEffects()
	{
		Stats result = this;
		foreach(eff; _effects)
			result = eff.applyStatsChange(result);
		return result;
	}

	bool addWard(AttackType type)
	{
		if(_wards.canFind(type))
			return false;
		_wards ~= type;
		return true;
	}

	bool addImmunity(AttackType type)
	{
		if(_immunities.canFind(type))
			return false;
		_immunities ~= type;
		return true;
	}

	static Stats fromJSON(JSONValue x)
	{
		auto hp = x["hp"].get!int;
		
		return Stats(hp, hp, x["armor"].get!int, x["speed"].get!int,
			x["wards"].array.map!((x) => cast(AttackType) x.str).array,
			x["immunities"].array.map!((x) => cast(AttackType) x.str).array,
			Attack.fromJSON(x["attack"])
		);
	}
}
