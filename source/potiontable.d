import std.array;
import std.algorithm;
import std.json;
import std.random;
import std.typecons;
import std.stdio;
import std.format;
import std.range;

import resources;
import util;

import luad.all;

struct SmallInfo
{
	Tuple!(string,string) inputs;
	string output;
	string description;
	bool known = false;

	bool inputMatches(string a, string b) { return (a == inputs[0] && b == inputs[1] ) || (a == inputs[1] && b == inputs[0]); }
}

struct MediumInfo
{
	Tuple!(string,string) inputs;
	string description;
	bool known = false;
	bool obsolete = false;

	bool inputMatches(string a, string b) { return (a == inputs[0] && b == inputs[1] ) || (a == inputs[1] && b == inputs[0]); }
}

struct LargeInfo
{
	string excluded;
	string description;
	bool known = false;
}

class PotionTable
{
	string[Tuple!(string,string)] table;
	
	SmallInfo[] smallInfo;
	MediumInfo[] medInfo;
	LargeInfo[] largeInfo;

	this() { }

	void init()
	{
		foreach(entry; ConfigFiles.get("potion table")["potion table"].array)
		{
			string[] inputs;
			string output;
			try
			{
				inputs = entry["inputs"].array.map!((x) => x.str).array;
				output = entry["output"].str;
			}
			catch(JSONException e) { writefln("WARNING! Bad JSON encountered in %s:%s: %s", e.file, e.line, e.msg); continue; }
			if(inputs.length != 2) { writefln("A table entry must have exactly 2 entries, skipping."); continue; }
			table[tuple(inputs[0], inputs[1])] = output;
		}
		foreach(key, val; ConfigFiles.get("ingredients"))
		{
			auto herbs = ConfigFiles.get("herbs").keys.randomCover.array;
			foreach(n; 0 .. 2)
			{
				auto inputs = tuple(herbs[n], key);
				auto output = val["goodPotion"].str;
				table[inputs] = output;
				smallInfo ~= SmallInfo(inputs, output, format("a %s together with a %s makes a %s", ConfigFiles.get("ingredients")[inputs[1]]["name"].str, ConfigFiles.get("herbs")[inputs[0]]["name"].str, ConfigFiles.get("potions")[output]["name"].str));
			}
			foreach(n; 2 .. 4)
			{
				auto inputs = tuple(herbs[n], key);
				auto output = val["evilPotion"].str;
				table[inputs] = output;
				smallInfo ~= SmallInfo(inputs, output, format("a %s together with a %s makes a %s", ConfigFiles.get("ingredients")[inputs[1]]["name"].str, ConfigFiles.get("herbs")[inputs[0]]["name"].str, ConfigFiles.get("potions")[output]["name"].str));
			}
			foreach(n; 4 .. 6)
			{
				auto inputs = tuple(herbs[n], key);
				smallInfo ~= SmallInfo(inputs, "", format("a %s together with a %s does not make anything useful", ConfigFiles.get("ingredients")[inputs[1]]["name"].str, ConfigFiles.get("herbs")[inputs[0]]["name"].str));
			}
		}
		auto greatPotions = ConfigFiles.get("potions").byPair.filter!((x) => x.value["level"].get!int == 4).array;
		auto youthPotion = greatPotions.randomSample(2).array;
		table[tuple(youthPotion[0].key, youthPotion[1].key)] = "youth potion";
		foreach(k; 0 .. greatPotions.length-1)
			foreach(l; k+1 .. greatPotions.length)
				if(!((greatPotions[k].key == youthPotion[0].key && greatPotions[l].key == youthPotion[1].key) ||
					(greatPotions[k].key == youthPotion[1].key && greatPotions[l].key == youthPotion[0].key)))
					medInfo ~= MediumInfo(tuple(greatPotions[k].key, greatPotions[l].key), format("by mixing a %s with a %s", greatPotions[k].value["name"].str, greatPotions[l].value["name"].str));
		foreach(pot; greatPotions)
			if(pot.key != youthPotion[0].key && pot.key != youthPotion[1].key)
				largeInfo ~= LargeInfo(pot.key, format("by mixing a %s with anything", pot.value["name"].str));

	}

	string tableLookup(string a, string b)
	{
		return table.get(tuple(a, b), table.get(tuple(b, a), ""));
	}

	Tuple!(string, "result", string, "infoType", int, "infoIndex") mixResult(string a, string b)
	{
		if((tuple(a, b) in table) || (tuple(b, a) in table))
		{
			auto output = table.get(tuple(a,b), table.get(tuple(b,a), ""));
			foreach(k, ref info; smallInfo)
				if((tuple(a,b) == info.inputs || tuple(b,a) == info.inputs) && !info.known)
				{
					info.known = true;
					chainDiscoveries();
					return tuple!("result", "infoType", "infoIndex")(output, "small", cast(int) k);
				}
			return tuple!("result", "infoType", "infoIndex")(output, "none", cast(int) 0);
		}
		else
		{
			foreach(k, ref info; smallInfo)
				if((tuple(a,b) == info.inputs || tuple(b,a) == info.inputs) && !info.known)
				{
					info.known = true;
					chainDiscoveries();
					return tuple!("result", "infoType", "infoIndex")("", "small", cast(int) k);
				}
			foreach(k, ref info; medInfo)
				if((tuple(a,b) == info.inputs || tuple(b,a) == info.inputs) && !info.known)
				{
					info.known = true;
					chainDiscoveries();
					return tuple!("result", "infoType", "infoIndex")("", "medium", cast(int) k);
				}
			return tuple!("result", "infoType", "infoIndex")("", "none", cast(int) 0);
		}
	}

	private void chainDiscoveries()
	{
		foreach(ref large; largeInfo)
		{
			auto f = medInfo.filter!((inf) => inf.inputs[0] == large.excluded || inf.inputs[1] == large.excluded);
			if(!f.empty && f.all!`a.known`)
				large.known = true;
			if(large.known)
				foreach(ref med; f)
					med.obsolete = true;
		}
	}

	void luaPutInto(LuaState lua)
	{
		lua.doString(`PotionTable = {}`);
		auto obj = lua.get!LuaTable("PotionTable");
		obj["ptr"] = ptr2string(cast(void *) this);
		obj["lookup"] = delegate string(LuaTable t, string a, string b)
		{
			return string2ptr!PotionTable(t.get!string("ptr")).tableLookup(a, b);
		};
		obj["giveRandomKnowledge"] = delegate string(LuaTable t, string type)
		{
			string ret;
			if(type == "medium")
			{
				auto usefulInfo = medInfo.length.iota.filter!((n) => !medInfo[n].known && !medInfo[n].obsolete).array;
				if(usefulInfo.empty) return "";
				auto index = usefulInfo.choice;
				medInfo[index].known = true;
				ret = medInfo[index].description;
			}
			else if(type == "large")
			{
				auto usefulInfo = largeInfo.length.iota.filter!((n) => !largeInfo[n].known).array;
				if(usefulInfo.empty) return "";
				auto index = usefulInfo.choice;
				largeInfo[index].known = true;
				ret = largeInfo[index].description;
			}
			else
			{
				auto usefulInfo = smallInfo.length.iota.filter!((n) => !smallInfo[n].known).array;
				if(usefulInfo.empty) return "";
				auto index = usefulInfo.choice;
				smallInfo[index].known = true;
				ret = smallInfo[index].description;
			}
			chainDiscoveries();
			return ret;
		};
	}
}
