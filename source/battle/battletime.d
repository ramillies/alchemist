import std.algorithm, std.range, std.array;
import std.random;
import std.typecons;
import std.stdio;
import std.format;

class TimeRegistrable
{
	string name;
	double[string] cooldowns;
	abstract @property double speed();

	abstract Tuple!(double, "cooldown", double, "speedFactor") takeTurn();
	final void advanceTime(double dt)
	{
		if(dt <= 0) return;
		auto minCool = cooldowns.byPair.minElement!`a.value`;
		if(minCool.value <= dt)
		{
			auto val = minCool.value;
			cooldowns.remove(minCool.key);
			advanceTime(dt - val);
		}
		else
			cooldowns[minCool.key] -= dt;
	}
	final void addCooldown(string name, double dt)
	{
		if(name in cooldowns)
			cooldowns[name] += dt;
		else
			cooldowns[name] = dt;
	}
}

class BattleTime
{
	private TimeRegistrable[] registered;
	double cooldown;

	this() { cooldown = 0; }

	void register(TimeRegistrable what)
	{
		what.cooldowns = [ "base":  what.speed * uniform(.85, 1.15) ];
		registered ~= what;
		registered.schwartzSort!`a.cooldowns.byValue.sum`;
	}
	void unregister(TimeRegistrable what)
	{
		foreach(k, v; registered)
			if(v is what)
				registered = registered.remove(k);
		registered.schwartzSort!`a.cooldowns.byValue.sum`;
	}

	void nextTurn()
	{
		registered.schwartzSort!`a.cooldowns.byValue.sum`;
		auto current = registered[0];
		auto dt = current.cooldowns.byValue.sum;
		foreach(reg; registered)
			reg.advanceTime(dt);
		auto next = current.takeTurn();
		cooldown = next.cooldown;
		current.cooldowns = [ "base": current.speed * next.speedFactor * uniform(.9, 1.1) ];
	}
}
