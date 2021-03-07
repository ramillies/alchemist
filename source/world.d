import std.array;
import std.range;
import std.algorithm;
import std.random;
import std.conv;
import std.stdio;
import std.json;
import std.format;
import std.math;

import tilemap;
import resources;
import settings;

import boilerplate;
import dsfml.graphics;

alias Pos = Vector2!size_t;

class World: Drawable
{
	private
	{
		@Read size_t _width, _height;
		@Read double _landFraction;
		Tilemap tiles;

		int[][] tilenumbers;
	}

	const TILESIZE = 48;

	string[][] terrain;
	size_t[][] islandDivisions;

	mixin(GenerateAll);

	this(size_t w, size_t h, double landFrac)
	{
		_width = w;
		_height = h;
		_landFraction = landFrac;

		terrain = _height.iota.map!((x) => "water".repeat(_width).array).array;
		islandDivisions = _height.iota.map!((x) => (cast(size_t)0).repeat(_width).array).array;
	}

	string terrainAt(Pos pos) { return terrain[pos.y][pos.x]; }
	Vector2u pixelSize() { return Vector2u(cast(uint) (3*TILESIZE*width), cast(uint) (3*TILESIZE*height)); }

	private Pos[] adjacent(Pos pos)
	{
		Pos[] result;
		if(pos.x > 0) result ~= Pos(pos.x - 1, pos.y);
		if(pos.x < width-1) result ~= Pos(pos.x+1, pos.y);
		if(pos.y > 0) result ~= Pos(pos.x, pos.y-1);
		if(pos.y < height-1) result ~= Pos(pos.x, pos.y + 1);
		return result;
	}

	void makeTerrain()
	{
		size_t numCells = to!size_t(18/landFraction) + 1;
		Pos[] kernels = cartesianProduct(_width.iota, _height.iota)
				.map!((x) => Pos(x[0], x[1]))
				.randomSample(numCells, width*height).array;
		bool[] land = chain(true.repeat(18), false.repeat(numCells - 18)).array.randomCover.array;

		size_t[] snowLine = [ height/4 ];
		size_t[] sandLine = [ 3*height/4 ];
		foreach(y; 0 .. height)
			foreach(x; 0 .. width)
				terrain[y][x] = "water";

		foreach(y; 1 .. height-1)
			foreach(x; 1 .. width-1)
			{
				auto closest = kernels.map!((k) => (k.x - x)^^2 + (k.y - y)^^2).array.minIndex;
				islandDivisions[y][x] = closest;
				if(land[closest])
					terrain[y][x] = "land";
			}

		while(snowLine.length < width)
		{
			bool isCorner(size_t x, size_t y)
			{
				if(x == 0 || x == width-1 || y == 0 || y == height-1)
					return false;
				auto around = [terrain[y-1][x], terrain[y+1][x], terrain[y][x-1], terrain[y][x+1]];
				auto diagonalAround = [terrain[y-1][x-1], terrain[y+1][x-1], terrain[y-1][x+1], terrain[y+1][x+1]];
				return !around.canFind("water") && diagonalAround.canFind("water");
			}

			auto snow = snowLine[$-1];
			snowLine ~= snow;
			int attempts = 0;
			do
			{
				snowLine[$-1] = snow + [-1, 0, 1][dice([
					snow > height/6 ? 1 : 0, // Chance to go more north
					1, // Chance to stay
					snow < height/3 ? 1 : 0 // Chance to go more south
				])];
				attempts++;
			} while(isCorner(snowLine.length-1, snowLine[$-1]-1) && attempts < 10);

			auto sand = sandLine[$-1];
			sandLine ~= sand;
			do
			{
				sandLine[$-1] = sand + [-1, 0, 1][dice([
					sand > 2*height/3 ? 1 : 0, // Chance to go more north
					1, // Chance to stay
					sand < 5*height/6 ? 1 : 0 // Chance to go more south
				])];
				attempts++;
			} while(isCorner(sandLine.length-1, sandLine[$-1]) && attempts < 10);
		}

		foreach(y; 1 .. height-1)
			foreach(x; 1 .. width-1)
				if(terrain[y][x] == "land")
					terrain[y][x] = y.predSwitch!`a<b`(
						snowLine[x], "snow",
						sandLine[x], "grass",
						"sand"
					);
	}
	
	void addTerrainFeatures()
	{

	}

	private void updateTiles()
	{
		auto tileNames = ConfigFiles.get("overworld tiles");
		int getTile(string name)
		{
			return tileNames[name].get!int;
		}

		string[][] detailedMap = (3*height).iota.map!((y) => (3*height).iota.map!((x) => terrain[y/3][x/3]).array).array;
		tilenumbers = (3*height).iota.map!((x) => 335.repeat(3*width).array).array;
		foreach(y; 3 .. 3*(height-1))
			inner: foreach(x; 3 .. 3*(width-1))
			{
				auto here = detailedMap[y][x];
				auto around = [ detailedMap[y-1][x], detailedMap[y][x+1], detailedMap[y+1][x], detailedMap[y][x-1] ];
				auto otherTerrains = around.filter!((x) => x != here).group.array;

				if(otherTerrains.length == 0)
				{
					around = [ detailedMap[y-1][x-1], detailedMap[y-1][x+1], detailedMap[y+1][x+1], detailedMap[y+1][x-1] ];
					otherTerrains = around.filter!((x) => x != here).group.array;

					if(otherTerrains.length != 1)
					{
						tilenumbers[y][x] = getTile(here);
						continue;
					}
					foreach(k, v; around)
						if(v != here)
						{
							auto supposedTilename = format("%s/%s diagonal %s", here, otherTerrains[0][0], ["NW", "NE", "ES", "SW"][k]);
							tilenumbers[y][x] = (supposedTilename in tileNames) ? getTile(supposedTilename) : getTile(here);
							continue inner;
						}
				}

				if(otherTerrains.length == 2)
				{
					string first, second;
					if(around[0] == "water" || around[2] == "water")
					{
						first = around[3];
						second = around[1];
					}
					if(around[1] == "water" || around[3] == "water")
					{
						first = around[0];
						second = around[2];
					}
					foreach(k, v; around)
						if(v == "water")
						{
							string supposedTilename;
							if(here != "grass")
								supposedTilename = format("coast %s/%s %s", first, second, "NESW"[k]);
							else
								supposedTilename = format("grass/water %s", "NESW"[k]);
							tilenumbers[y][x] = (supposedTilename in tileNames) ? getTile(supposedTilename) : getTile(here);
							continue inner;
						}

				}

				auto diagonalAround = [ detailedMap[y-1][x-1], detailedMap[y-1][x+1], detailedMap[y+1][x+1], detailedMap[y+1][x-1] ];
				if(!around.canFind("water") && diagonalAround.canFind("water"))
				{
					foreach(k, v; diagonalAround)
						if(v == "water")
						{
							auto supposedTilename = format("%s/%s diagonal %s", here, v, ["NW", "NE", "ES", "SW"][k]);
							tilenumbers[y][x] = (supposedTilename in tileNames) ? getTile(supposedTilename) : getTile(here);
							continue inner;
						}
				}

				auto other = otherTerrains[0][0];
				char[] where;
				foreach(k, v; around)
					if(v == other)
						where ~= "NESW"[k];
				
				auto supposedTilename = format("%s/%s %s", here, other, where);
				tilenumbers[y][x] = (supposedTilename in tileNames) ? getTile(supposedTilename) : getTile(here);
			}
		tiles.load(Images.texture("world tileset"), Vector2u(48, 48), tilenumbers);
	}

	void prepareDrawing()
	{
		tiles = new Tilemap;
		updateTiles();
	}

	override void draw(RenderTarget target, RenderStates states)
	{
		target.draw(tiles, states);
		if(Settings.drawGrid)
		{
			Vertex[] lines;
			foreach(k; 0 .. 3*width+1)
			{
				Vertex v = Vertex();
				v.position = Vector2f(k*TILESIZE, 0);
				v.color = k % 3 == 0 ? Color.Red : Color.Black;
				lines ~= v;
				v.position = Vector2f(k*TILESIZE, height*3*TILESIZE);
				lines ~= v;
			}
			foreach(k; 0 .. 3*height+1)
			{
				Vertex v = Vertex();
				v.position = Vector2f(0, k*TILESIZE);
				v.color = k % 3 == 0 ? Color.Red : Color.Black;
				lines ~= v;
				v.position = Vector2f(width*3*TILESIZE, k*TILESIZE);
				lines ~= v;
			}
		
			target.draw(lines, PrimitiveType.Lines, states);
		}
	}
	
}
