import std.algorithm;
import std.stdio;
import std.string;
import std.json;
import std.exception;
import std.regex;

import luad.all;

import dsfml.graphics;

class ConfigFiles
{
	private static JSONValue[string] files;
	private static JSONValue missing;

	static void load()
	{
		missing = parseJSON("{}");

		foreach(name, path; [
			"textures" : "data/textures",
			"overworld tiles" : "data/overworld-tiles",
			"settings" : "settings",
			"world terrain" : "data/world-gen",
			"movement" : "data/movement",
			"places" : "data/places",
			"world places" : "data/world-places",
			"herbs" : "data/herbs"
		])
		{
			File f;
			try
			{
				f = File(path ~ ".json", "r");
			}
			catch(std.exception.ErrnoException e)
			{
				writefln("ERROR! Could not open configuration file '%s.json'!", path);
				continue;
			}
			files[name] = f.byLine.join("\n").parseJSON;
		}
	}

	static void luaPutInto(LuaState lua, string[] includeFiles)
	{
		foreach(file; includeFiles)
		{
			if(!(file in files))
			{
				writefln("WARNING! Tried to include a nonexistent config file '%s' into lua.", file);
				continue;
			}
			auto re = ctRegex!(`"[^"]+":`, "g");
			lua.doString(format(`%s = %s`,
				file.split.map!`a.capitalize`.join, // world terrain => WorldTerrain etc.
				// rewrite the keys to agree with Lua table syntax
				files[file].toString.replaceAll!((c) => format("[%s] = ", c.hit.strip(":")))(re)
			));
		}
	}

	static JSONValue[string] get(string name) { return files.get(name, missing).object; }
	static void unload() { }
}

class Fonts
{
	static Font text, heading;

	static void load()
	{
		text = new Font;
		text.loadFromFile("data/fonts/EBGaramond08-Regular.ttf");
		heading = new Font;
		heading.loadFromFile("data/fonts/EBGaramondSC08-Regular.ttf");
	}

	static void unload() { }
}

class Images
{
	private static Texture[string] textures;
	private static Texture missing;

	static void load()
	{
		RenderTexture miss = new RenderTexture;
		miss.create(64, 64);
		miss.clear(Color(255,0,0));
		miss.display;
		missing = cast(Texture) miss.getTexture;

		foreach(name, file; ConfigFiles.get("textures"))
		{
			textures[name] = new Texture;
			textures[name].loadFromFile("data/" ~ file.get!string);
			textures[name].setSmooth(false);
		}
		writefln("Loaded textures: %s", textures.byKey);
	}

	static Texture texture(string name) { return textures.get(name, missing); }
	static void unload() { }
}
