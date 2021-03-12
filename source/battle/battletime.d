import std.algorithm, std.range, std.array;
import std.random;
import std.typecons;
import std.stdio;

class TimeRegistrable
{
	double[string] cooldowns;
	double speed;

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

	this() { }

	void register(TimeRegistrable what) { registered ~= what; }
	void unregister(TimeRegistrable what)
	{
		foreach(k, v; registered)
			if(v is what)
				registered = registered.remove(k);
	}

	void initTimes()
	{
		foreach(reg; registered)
			reg.cooldowns["base"] = reg.speed * uniform(.85, 1.15);
	}

	void nextTurn()
	{
		auto index = registered.minIndex!((a, b) => a.cooldowns.byValue.sum < b.cooldowns.byValue.sum);
		if(index < 0)
		{
			writefln("WARNING! Nobody is registered!");
			cooldown = 1f;
			return;
		}
		auto current = registered[index];
		auto dt = current.cooldowns.byValue.sum;
		foreach(reg; registered)
			reg.advanceTime(dt);
		auto next = current.takeTurn();
		cooldown = next.cooldown;
		current.cooldowns = [ "base": current.speed * next.speedFactor * uniform(.9, 1.1) ];
	}
}
