import std.algorithm;
import std.array;
import std.stdio;
import std.json;
import std.range;
import std.traits;

import resources;
import mainloop;
import loadingscreen;
import settings;

import dsfml.graphics;

void main()
{
	Settings.load;
	auto win = new RenderWindow(VideoMode.getDesktopMode, "Alchemist");
	win.setVerticalSyncEnabled(true);

	Mainloop.win = win;
	Mainloop.changeScreen(new LoadingScreen);
	Mainloop.mainloop;

	Fonts.unload;
	Images.unload;
}
