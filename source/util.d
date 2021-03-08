import dsfml.graphics;

void setTileNumber(Sprite sprite, int tileNumber, Vector2u tileSize)
{
	auto tileset = sprite.getTexture;
	if(tileset is null) return;
	int tx = tileNumber % (tileset.getSize.x / tileSize.x);
	int ty = tileNumber / (tileset.getSize.x / tileSize.x);

	sprite.textureRect = IntRect(tx*tileSize.x, ty*tileSize.y, tileSize.x, tileSize.y);
}
