import std.stdio;
import std.string;
import std.json;
import std.exception;

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
			"settings" : "settings"
		])
		{
			File f;
			try
			{
				f = File(path ~ ".json", "r");
			}
			catch(std.exception.ErrnoException e)
			{
				writefln("ERROR! Could not open configuration file '%s'!", path);
				continue;
			}
			files[name] = f.byLine.join("\n").parseJSON;
		}
	}

	static JSONValue[string] get(string name)
	{
		return files.get(name, missing).object;
	}

	static void unload()
	{
	}
}

class Fonts
{
	static Font gentium;

	static void load()
	{
		gentium = new Font;
		gentium.loadFromFile("data/fonts/gentium.ttf");
	}

	static void unload()
	{
	}
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
			textures[name].setSmooth(true);
		}
		writefln("Loaded textures: %s", textures.byKey);
	}

	static Texture texture(string name)
	{
		return textures.get(name, missing);
	}

	static void unload()
	{
	}
}

/*
class Things
{
	private static JSONValue[string] things;

	static void load()
	{
		File listfile = File("data/objects.json", "r");
		things = listfile.byLine.join("\n").parseJSON.object;
	}

	static JSONValue thing(string name)
	{
		return things.get(name, parseJSON(`{ "texture": "missing", "textureRect": [ 0, 0, 0, 0 ] }`));
	}

	static void unload()
	{
	}
}
*/
