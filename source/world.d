import std.array;
import std.range;
import std.algorithm;
import std.random;
import std.conv;
import std.stdio;
import std.json;
import std.format;
import std.math;
import std.typecons;

import tilemap;
import resources;
import settings;

import boilerplate;
import dsfml.graphics;
import luad.all;

alias Pos = Vector2!size_t;

class World: Drawable
{
	private
	{
		@Read size_t _width, _height;
		@Read double _landFraction;
		Tilemap tiles, featureTiles, roadTiles;
		Sprite[] mountains;

	}

	const TILESIZE = 48;

	string[][] terrain;
	string[][] features;
	bool[][] roads;
	size_t[][] islandDivisions;

	mixin(GenerateAll);

	this(size_t w, size_t h, double landFrac)
	{
		_width = w;
		_height = h;
		_landFraction = landFrac;

		terrain = _height.iota.map!((x) => "water".repeat(_width).array).array;
		islandDivisions = _height.iota.map!((x) => (cast(size_t)0).repeat(_width).array).array;
		tiles = new Tilemap;
		featureTiles = new Tilemap;
		roadTiles = new Tilemap;
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

		auto conf = ConfigFiles.get("world terrain");
		int maxAttempts = conf["maxAttempts"].get!int;
		auto lua = new LuaState;
		lua.openLibs;
		lua["height"] = height;
		lua["width"] = width;
		lua["landFraction"] = landFraction;
		lua.doString(format(`function snowStart() return %s end`, conf["snow"]["start"].str));
		auto snowStart = lua.get!(size_t delegate())("snowStart");
		lua.doString(format(`function sandStart() return %s end`, conf["sand"]["start"].str));
		auto sandStart = lua.get!(size_t delegate())("sandStart");
		lua.doString(format(`function voronoiDistance(X, Y, centerX, centerY) return %s end`, conf["voronoiDistance"].str));
		auto voronoiDistance = lua.get!(double delegate(in size_t, in size_t, in size_t, in size_t))("voronoiDistance");
		lua.doString(format(`function advanceSnow(current) return %s end`, conf["snow"]["advanceProbabilities"].str));
		auto advanceSnow = lua.get!(double[] delegate(in size_t))("advanceSnow");
		lua.doString(format(`function advanceSand(current) return %s end`, conf["sand"]["advanceProbabilities"].str));
		auto advanceSand = lua.get!(double[] delegate(in size_t))("advanceSand");

		size_t[] snowLine = [ snowStart() ];
		size_t[] sandLine = [ sandStart() ];
		foreach(y; 0 .. height)
			foreach(x; 0 .. width)
				terrain[y][x] = "water";

		foreach(y; 1 .. height-1)
			foreach(x; 1 .. width-1)
			{
				auto closest = kernels.map!((k) => voronoiDistance(x, y, k.x, k.y)).array.minIndex;
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
				snowLine[$-1] = snow + [-1, 0, 1][dice(advanceSnow(snow))];
				attempts++;
			} while(isCorner(snowLine.length-1, snowLine[$-1]-1) && attempts < 10);

			auto sand = sandLine[$-1];
			sandLine ~= sand;
			do
			{
				sandLine[$-1] = sand + [-1, 0, 1][dice(advanceSand(sand))];
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
		features = terrain.map!((row) => row.map!((x) => x == "water" ? "water" : "plain").array).array;
		roads = height.iota.map!((x) => false.repeat(width).array).array;
		bool[][] mask;

		auto lua = new LuaState;
		lua.openLibs;
		lua["height"] = height;
		lua["width"] = width;
		lua["landFraction"] = landFraction;
		lua["terrainAt"] = delegate string (size_t x, size_t y) { return terrain[y][x]; };
		lua["featureAt"] = delegate string (size_t x, size_t y) { return features[y][x]; };
		lua["adjacentTerrain"] = delegate string[] (size_t x, size_t y) { return adjacent(Pos(x,y)).map!((p) => terrain[p.y][p.x]).array; };
		lua["adjacentFeatures"] = delegate string[] (size_t x, size_t y) { return adjacent(Pos(x,y)).map!((p) => features[p.y][p.x]).array; };
		lua["diagonallyAdjacentTerrain"] = delegate string[] (size_t x, size_t y) { return [Pos(x-1,y-1),Pos(x-1,y+1),Pos(x+1,y-1),Pos(x+1,y+1)].map!((p) => terrain[p.y][p.x]).array; };

		auto conf = ConfigFiles.get("world terrain");

		void makeMask(bool delegate(size_t, size_t) condition)
		{
			mask = features.map!((row) => row.map!((x) => x == "plain").array).array;
			foreach(y; 0 .. height)
				foreach(x; 0 .. width)
					if(!condition(x,y))
						mask[y][x] = false;
		}

		void distribute(string what, int amount, int radius)
		{
			if(amount == 0 || !mask.any!`a.any`)
				return;
			auto randomSquare = cartesianProduct(width.iota, height.iota).map!((x) => Pos(x[0], x[1])).filter!((p) => mask[p.y][p.x]).array.choice;
			features[randomSquare.y][randomSquare.x] = what;
			foreach(y; 0 .. height)
				foreach(x; 0 .. width)
					if((x-randomSquare.x)^^2 + (y-randomSquare.y)^^2 <= radius^^2)
						mask[y][x] = false;
			distribute(what, amount-1, radius);
		}

		void fill(string what, int amount, bool delegate(size_t, size_t) condition)
		{
			auto squares = cartesianProduct(width.iota, height.iota)
				.map!((x) => Pos(x[0], x[1]))
				.filter!((p) => features[p.y][p.x] == "plain" && adjacent(p).map!((r) => features[r.y][r.x]).canFind(what) && condition(p.x, p.y))
				.array;
			if(amount == 0 || squares.empty) return;
			auto target = squares.choice;
			features[target.y][target.x] = what;
			fill(what, amount-1, condition);
		}

		void featureCellularAutomaton(int iterations, string delegate(size_t x, size_t y)[] rules)
		{
			foreach(y; 1 .. height-1)
				foreach(x; 1 .. width-1)
					foreach(rule; rules)
						features[y][x] = rule(x, y);
		}

		void roadCellularAutomaton(int iterations, bool delegate(size_t x, size_t y)[] rules)
		{
			foreach(y; 1 .. height-1)
				foreach(x; 1 .. width-1)
					foreach(rule; rules)
						roads[y][x] = rule(x, y);
		}

		void makeRoads()
		{
			Pos[][] sets = cartesianProduct(width.iota, height.iota).map!((x) => Pos(x[0], x[1])).filter!((p) => ["city", "castle", "village"].canFind(features[p.y][p.x])).map!((x) => [x]).array;
			while(sets.length > 1)
			{
				writefln("sets: %s", sets);
				int[][] pathLen = height.iota.map!((x) => (int.max).repeat(width).array).array;
				sets[0].each!((p) => pathLen[p.y][p.x] = 0);
				Pos[] queue = sets[0];
				do
				{
					auto toExpand = queue[0];
					queue = queue.remove(0);
					foreach(adj; adjacent(toExpand))
						if(canFind(["plain", "city", "village", "castle"], features[adj.y][adj.x]))
						{
							if(pathLen[adj.y][adj.x] == int.max)
								queue ~= adj;
							pathLen[adj.y][adj.x] = min(pathLen[adj.y][adj.x], pathLen[toExpand.y][toExpand.x]+1);
						}
				} while(! (queue.empty || sets[1..$-1].any!((set) => set.canFind(queue[0])) ) );

				if(queue.empty)
				{
					sets = sets.remove(0);
					continue;
				}

				size_t hitSet = iota(1, sets.length).filter!((x) => sets[x].canFind(queue[0])).front;
				sets ~= sets[0] ~ sets[hitSet];
				sets = sets.remove(0, hitSet);

				writefln("hit set: %s", hitSet, pathLen);
				
				roads[queue[0].y][queue[0].x] = true;
				Pos step = queue[0];
				do
				{
					auto searchFor = pathLen[step.y][step.x] - 1;
					writefln("step: %s, searching for %s", step, searchFor);
					step = adjacent(step).filter!((p) => pathLen[p.y][p.x] == searchFor).front;
					roads[step.y][step.x] = true;
					sets[$-1] ~= step;
				} while(pathLen[step.y][step.x] != 0);
			}
		}

		lua["makeMask"] = &makeMask;
		lua["distribute"] = delegate void(LuaTable t) { return distribute(t.get!string("feature"), t.get!int("number"), t.get!int("exclusionRadius")); };
		lua["fill"] = delegate void(LuaTable t) { return fill(t.get!string("feature"), t.get!int("number"), t.get!(bool delegate(size_t, size_t))("condition")); };
		lua["makeRoads"] = delegate void() { return makeRoads(); };
		lua["roadAt"] = delegate bool(size_t x, size_t y) { return roads[y][x]; };
		lua["featureCellularAutomaton"] = delegate void(LuaTable t) { return featureCellularAutomaton(t.get!int("iterations"), t.get!(string delegate(size_t,size_t)[])("rules")); };
		lua["roadCellularAutomaton"] = delegate void(LuaTable t) { return roadCellularAutomaton(t.get!int("iterations"), t.get!(bool delegate(size_t,size_t)[])("rules")); };

		lua.doString(conf["fillFeatures"].str);
	}

	void updateTiles()
	{
		int[][] tilenumbers, featureTileNumbers, roadTileNumbers;
		auto tileNames = ConfigFiles.get("overworld tiles");
		int getTile(string name)
		{
			if(!(name in tileNames))
			{
				writefln("WARNING! Tile '%s' could not be found.", name);
				return 335;
			}
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

		featureTileNumbers = (3*height).iota.map!((x) => 335.repeat(3*width).array).array;
		foreach(y; 0 .. height)
			foreach(x; 0 .. width)
				if(features[y][x] == "mountains")
				{
					Sprite s = new Sprite;
					s.setTexture(Images.texture("world mountains"));
					s.origin = Vector2f(TILESIZE, TILESIZE);
					s.position = Vector2f(3*x*TILESIZE, 3*y*TILESIZE);
					if(terrain[y][x] == "snow")
						s.textureRect = IntRect(6*TILESIZE, 0, 6*TILESIZE, 6*TILESIZE);
					else
						s.textureRect = IntRect(0, 0, 6*TILESIZE, 6*TILESIZE);
					mountains ~= s;
				}
				else if(features[y][x] == "city" || features[y][x] == "castle" || features[y][x] == "grass hill" || features[y][x] == "cliff")
					foreach(k; 0 .. 3)
						foreach(l; 0 .. 3)
							featureTileNumbers[3*y + l][3*x + k] = getTile(format("%s %s%s", features[y][x], k, l));
				else if(features[y][x] == "village")
					foreach(k; 0 .. 2)
						foreach(l; 0 .. 2)
							featureTileNumbers[3*y + l][3*x + k + 1] = getTile(format("%s %s%s", features[y][x], k, l));
				else if(features[y][x] == "dune")
					foreach(k; 0 .. 4)
						foreach(l; 0 .. 2)
							featureTileNumbers[3*y + l + 1][3*x + k] = getTile(format("dune %s%s", k, l));
				else if(features[y][x] == "cactuses")
					foreach(k; 0 .. 3)
						foreach(l; 0 .. 3)
							if(!(k==0 && terrain[y][x-1] == "water") &&
								!(k==2 && terrain[y][x+1] == "water") &&
								!(l==0 && terrain[y-1][x] == "water") &&
								!(l==2 && terrain[y+1][x] == "water")
							)
								featureTileNumbers[3*y + l][3*x + k] = getTile(uniform01.predSwitch!`a<b`(1/9., "cactus 1", 2/9., "cactus 2", "water"));

		bool[][] forest = (3*height).iota.map!((y) => (3*height).iota.map!((x) => features[y/3][x/3] == "forest").array).array;
		
		foreach(y; 3 .. 3*(height-1))
			foreach(x; 3 .. 3*(width-1))
				if(forest[y][x])
				{
					auto around = [ forest[y-1][x], forest[y][x+1], forest[y+1][x], forest[y][x-1] ];
					auto diagonalAround = [ forest[y-1][x-1], forest[y-1][x+1], forest[y+1][x-1], forest[y+1][x+1] ];
					auto terrainType = terrain[y/3][x/3];
					auto standardForest = format("forest %s", terrainType);

					int safeGetTile(string name)
					{
						if(name in tileNames)
							return getTile(name);
						else
						{
							writefln("Bad forest tile name '%s'", name);
							return getTile(standardForest);
						}
					}

					if(around.count(false) == 0)
					{
						if(diagonalAround.count(false) == 0)
							featureTileNumbers[y][x] = getTile(format("forest %s", terrainType));
						else
							foreach(k, v; diagonalAround)
								if(v == false)
									featureTileNumbers[y][x] = safeGetTile(format("forest %s diagonal %s", terrainType, ["NW", "NE", "SW", "ES" ][k]));
					}
					else
					{
						char[] directions;
						foreach(k, v; around)
							if(v == false)
								directions ~= "NESW"[k];
						featureTileNumbers[y][x] = safeGetTile(format("forest %s %s", terrainType, directions));
					}
				}

		featureTiles.load(Images.texture("world tileset"), Vector2u(48, 48), featureTileNumbers);
		roadTileNumbers = (3*height).iota.map!((x) => 335.repeat(3*width).array).array;
		foreach(y; 0 .. height)
			foreach(x; 0 .. width)
				if(roads[y][x])
				{
					char[] directions;
					if(roads[y-1][x])
					{
						roadTileNumbers[3*y][3*x+1] = getTile("road NS");
						directions ~= "N";
					}
					if(roads[y][x+1])
					{
						roadTileNumbers[3*y+1][3*x+2] = getTile("road EW");
						directions ~= "E";
					}
					if(roads[y+1][x])
					{
						roadTileNumbers[3*y+2][3*x+1] = getTile("road NS");
						directions ~= "S";
					}
					if(roads[y][x-1])
					{
						roadTileNumbers[3*y+1][3*x] = getTile("road EW");
						directions ~= "W";
					}
					roadTileNumbers[3*y+1][3*x+1] = getTile(format("road %s", directions));
				}
		writefln("Roads:\n%s", roads.map!((r) => r.map!((x) => x ? '#' : '.').array).join("\n"));
		roadTiles.load(Images.texture("world tileset"), Vector2u(48, 48), roadTileNumbers);
		writefln("After load roads.");
	}

	override void draw(RenderTarget target, RenderStates states)
	{
		target.draw(tiles, states);
		mountains.each!((m) => target.draw(m, states));
		target.draw(roadTiles, states);
		target.draw(featureTiles, states);
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
