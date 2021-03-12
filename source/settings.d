import std.stdio;
import std.string;
import std.json;
import std.exception;

import resources;

class Settings
{
	static bool drawGrid = true;
	static bool gameLogShown = true;
	static bool realFullscreen = false;

	static void load()
	{
		auto list = ConfigFiles.get("settings");
		drawGrid = list["drawGrid"].get!bool;
		gameLogShown = list["gameLogShown"].get!bool;
		realFullscreen = list["realFullscreen"].get!bool;
	}

	static void write()
	{
		JSONValue config = [
			"drawGrid": drawGrid,
			"gameLogShown": gameLogShown
		];
		File listfile = File("settings.json", "w");
		listfile.writeln(config.toPrettyString);
	}
}
