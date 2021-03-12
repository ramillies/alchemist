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
	ConfigFiles.load;
	Settings.load;
	auto win = new RenderWindow(VideoMode.getDesktopMode, "Alchemist", Settings.realFullscreen ? Window.Style.Fullscreen : Window.Style.None);
	win.setVerticalSyncEnabled(true);

	Mainloop.win = win;
	Mainloop.changeScreen(new LoadingScreen);
	Mainloop.mainloop;

	Fonts.unload;
	Images.unload;
}
