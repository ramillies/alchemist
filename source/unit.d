import std.algorithm, std.array, std.range;
import std.typecons;
import std.format;
import std.json;
import std.conv;
import std.stdio;
import std.string;

import coolsprite;
import reacttext;
import stats;
import battletime;
import battlescreen;
import attack;
import resources;
import util;
import settings;
import flyingtext;

import luad.all;
import dsfml.graphics;
import boilerplate;

class Unit: TimeRegistrable, Transformable, Drawable
{
	string name, description;
	private Stats baseStats, checkpointStats;
	private Stats stats;
	private CoolSprite sprite;
	private bool battle;
	@(ToString.Exclude) private BattleTime time;
	@(ToString.Exclude) private BattleScreen screen;
	@(ToString.Exclude) private Unit[] friends, enemies;
	private ReactiveText hpText, speedText;
	bool dead, fled;
	int squadPosition;
	LuaState lua;
	private string unitScript;
	int monthlyPay;

	mixin(GenerateToString);

	this(string n, string d, Stats s, string scr)
	{
		name = n;
		description = d;
		baseStats = s;
		checkpointStats = s;
		stats = s;
		unitScript = scr;
		sprite = new CoolSprite;
		dead = false;
		fled = false;
		squadPosition = -1;
		monthlyPay = 0;

		hpText = new ReactiveText;
		with(hpText)
		{
			setCharacterSize(25);
			setFont(Fonts.text);
			setColor(Color.White);
			setRelativeOrigin(Vector2f(.5f, 0f));
			stringCallback = () => format("%s / %s", stats.hp, stats.maxhp);
		}		
		speedText = new ReactiveText;
		with(speedText)
		{
			setCharacterSize(25);
			setFont(Fonts.text);
			setColor(Color.White);
			setRelativeOrigin(Vector2f(.5f, 1f));
			stringCallback = () => battle
				? ((cooldowns.keys.length > 1)
					? format("%s = %(%s+%)", cooldowns.values.sum.to!int, cooldowns.values.map!`a.to!int`.array)
					: format("%s", cooldowns.values.sum.to!int))
				: "";
		}		
	}

	void setTextureByName(string name) { sprite.setTextureByName(name); }
	void setRelativeOrigin(Vector2f o) { sprite.setRelativeOrigin(o); }
	@property void tilenumber(int x) { sprite.tilenumber = x; }

	override @property double speed() { return stats.speed; }

	void applyAttack(Attack attack)
	{
		auto hp = stats.hp;
		auto result = stats.takeHit(attack);
		auto damageSuffered = hp - stats.hp;
		baseStats.hp = baseStats.hp - damageSuffered;
		baseStats.effects = stats.effects;
		if(stats.hp <= 0)
		{
			dead = true;
			time.unregister(this);
		}

		auto msg = new FlyingText;
		with(msg)
		{
			setColor(Color(255, 255, 0));
			if(result == AttackResult.Hit)
			{
				setString(damageSuffered.to!string);
				setColor(Color.Red);
			}
			else if(result == AttackResult.Miss)
				setString("Dodged!");
			else if(result == AttackResult.Ward)
				setString("Ward!");
			else if(result == AttackResult.Immunity)
				setString("Immunity!");

			setFont(Fonts.text);
			setCharacterSize(40);
			setStyle(Text.Style.Bold);
			setRelativeOrigin(Vector2f(.5f, .5f));
			auto bounds = sprite.getGlobalBounds;
			position = Vector2f(bounds.left, bounds.top);
			initAnimation(Vector2f(20f, -20f), 100.);
		}
		screen.animations ~= msg;
	}

	void update()
	{
		stats = baseStats.applyEffects();
	}

	void startBattle(BattleScreen s, BattleTime t, Unit[] f, Unit[] e)
	{
		time = t;
		screen = s;
		battle = true;
		friends = f;
		enemies = e;
		saveCheckpoint;
		lua = new LuaState;
		lua.openLibs;
		lua.doString(`unit = {}`);
		luaPutInto(lua.get!LuaTable("unit"));
		lua.doString(`friends = { {}, {}, {}, {}, {}, {} }`);
		lua.doString(`enemies = { {}, {}, {}, {}, {}, {} }`);
		foreach(n; 0 .. 6)
		{
			auto obj = lua.get!(LuaTable[])("friends")[n];
			if(friends[n] !is null)
				friends[n].luaPutInto(obj);
		}
		foreach(n; 0 .. 6)
		{
			auto obj = lua.get!(LuaTable[])("enemies")[n];
			if(enemies[n] !is null)
				enemies[n].luaPutInto(obj);
		}
		lua.doString(unitScript);
		lua.doString(`unit:init()`);
	}

	void endBattle()
	{
		battle = false;
		dead = false; fled = false;
		restoreCheckpoint;
	}

	void saveCheckpoint() { checkpointStats = baseStats; }
	void restoreCheckpoint() { baseStats = checkpointStats; }

	static Unit byName(string name)
	{
		JSONValue x = ConfigFiles.get("units")[name].object;
		auto ret = new Unit(x["name"].str, x["description"].str,
			Stats.fromJSON(x), x["script"].str);
		if("tileset" in x)
			ret.setTextureByName(x["tileset"].str);
		if("tilenumber" in x)
			ret.tilenumber = x["tilenumber"].get!int;
		return ret;
	}
	

	override Tuple!(double, "cooldown", double, "speedFactor") takeTurn()
	{
		auto turn = lua.loadString(`return unit:takeTurn()`).call!LuaTable();
		double cool = 1., factor = 1.;
		if(!turn["cooldown"].isNil)
			cool = turn.get!double("cooldown");
		if(!turn["speedFactor"].isNil)
			factor = turn.get!double("speedFactor");
		if(!turn["actionDescription"].isNil)
		{
			auto msg = new FlyingText;
			with(msg)
			{
				setColor(Color.Blue);
				setString(turn.get!string("actionDescription"));
				setFont(Fonts.text);
				setCharacterSize(40);
				setStyle(Text.Style.Bold);
				setRelativeOrigin(Vector2f(.5f, .5f));
				auto bounds = sprite.getGlobalBounds;
				position = Vector2f(bounds.left, bounds.top);
				initAnimation(Vector2f(20f, -20f), 100.);
			}
			screen.animations ~= msg;
		}
		return tuple!("cooldown", "speedFactor")(cool * Settings.combatCooldown, factor);
	}

	mixin NormalTransformable;

	void luaPutInto(LuaTable obj)
	{
		obj["ptr"] = ptr2string(cast(void *) this);
		obj["getHP"] = delegate int(LuaTable t) { return string2ptr!Unit(t.get!string("ptr")).stats.hp; };
		obj["getArmor"] = delegate int(LuaTable t) { return string2ptr!Unit(t.get!string("ptr")).stats.armor; };
		obj["isAlive"] = delegate bool(LuaTable t)
		{
			auto me = string2ptr!Unit(t.get!string("ptr"));
			return !(me.dead || me.fled);
		};
		obj["attack"] = [ "blah": "blah" ];
		stats.attack.luaPutInto(obj.get!LuaTable("attack"));
		obj["attack", "blah"] = nil;
		obj["tryAttack"] = delegate string(LuaTable t, string type)
		{
			auto me = string2ptr!Unit(t.get!string("ptr"));
			return cast(string) me.stats.tryHitWithType(cast(AttackType) type);
		};
		obj["applyAttack"] = delegate void(LuaTable t, LuaTable attack)
		{
			string2ptr!Unit(t.get!string("ptr")).applyAttack(string2ptr!Attack(attack.get!string("ptr")));
		};
		obj["attackTargets"] = delegate int[][](LuaTable t)
		{
			auto me = string2ptr!Unit(t.get!string("ptr"));
			auto f = me.friends.map!((x) => x !is null && !x.dead && !x.fled).array;
			auto g = me.enemies.map!((x) => x !is null && !x.dead && !x.fled).array;
			auto ret = me.stats.attack.validTargets(me.squadPosition,
				f,
				g
			);
			writefln("Targets %s, %s, %s => %s", me.squadPosition, f, g, ret);
			return ret;
		};
	}

	string completeDescription()
	{
		return format("%s\n\nMonthly Pay: %s\nLife: %s\nArmor: %s\nWards: %(%s, %)\nImmunities: %(%s, %)\nSpeed: %s\n\n%s",
			description, monthlyPay, stats.hp, stats.armor, stats.wards.map!((x) => (cast(string) x).capitalize).array,
			stats.immunities.map!((x) => (cast(string) x).capitalize).array, stats.speed, stats.attack.description);
	}

	override void draw(RenderTarget target, RenderStates states)
	{
		hpText.update;
		speedText.update;
		sprite.position = position;
		sprite.rotation = rotation - (dead ? 90 : 0);
		sprite.scale = scale;

		auto bounds = sprite.getGlobalBounds();
		hpText.position = Vector2f(bounds.left + bounds.width/2, bounds.top + bounds.height + 5);
		speedText.position = Vector2f(bounds.left + bounds.width/2, bounds.top - 5);

		target.draw(sprite, states);
		if(!dead)
		{
			target.draw(hpText, states);
			target.draw(speedText, states);
		}
	}

}
