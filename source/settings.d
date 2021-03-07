import std.stdio;
import std.string;
import std.json;
import std.exception;

class Settings
{
	static bool drawGrid = true;
	static bool gameLogShown = true;

	static void load()
	{
		File listfile;
		try
		{
			listfile = File("settings.json", "r");
		}
		catch(std.exception.ErrnoException e)
		{
			return;
		}
		auto list = listfile.byLine.join("\n").parseJSON;

		drawGrid = list["drawGrid"].get!bool;
		gameLogShown = list["gameLogShown"].get!bool;
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
