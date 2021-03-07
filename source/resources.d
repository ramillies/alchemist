import std.stdio;
import std.string;
import std.json;

import dsfml.graphics;

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

		File listfile = File("data/textures.json", "r");
		auto list = listfile.byLine.join("\n").parseJSON;
		foreach(name, file; list.get!(JSONValue[string]))
		{
			textures[name] = new Texture;
			textures[name].loadFromFile("data/" ~ file.get!string);
			textures[name].setSmooth(false);
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
