import std.conv;
import std.format;

import dsfml.graphics;

string ptr2string(void *ptr)
{
	return format("%s", ptr);
}

T string2ptr(T)(string chunk)
{
	return (cast(T) (cast(void *) to!size_t(chunk, 16)));
}

void setTileNumber(Sprite sprite, int tileNumber, Vector2u tileSize)
{
	auto tileset = sprite.getTexture;
	if(tileset is null) return;
	int tx = tileNumber % (tileset.getSize.x / tileSize.x);
	int ty = tileNumber / (tileset.getSize.x / tileSize.x);

	sprite.textureRect = IntRect(tx*tileSize.x, ty*tileSize.y, tileSize.x, tileSize.y);
}
