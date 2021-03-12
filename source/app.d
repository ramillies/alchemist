import std.algorithm;
import std.array;
import std.stdio;
import std.json;
import std.range;
import std.traits;
import std.string;
import std.conv;

import resources;
import mainloop;
import loadingscreen;
import settings;

import dsfml.graphics;

void main()
{
	ConfigFiles.load;
	Settings.load;
	RenderWindow win;
	if(Settings.resolution == "desktop")
		win = new RenderWindow(VideoMode.getDesktopMode, "Alchemist", Settings.realFullscreen ? Window.Style.Fullscreen : Window.Style.None);
	else
	{
		int[] res = Settings.resolution.split.map!`a.to!int`.array;
		win = new RenderWindow(VideoMode(res[0], res[1]), "Alchemist", Settings.realFullscreen ? Window.Style.Fullscreen : Window.Style.None);
	}
	win.setVerticalSyncEnabled(true);

	Mainloop.win = win;
	Mainloop.changeScreen(new LoadingScreen);
	Mainloop.mainloop;

	Fonts.unload;
	Images.unload;
}
