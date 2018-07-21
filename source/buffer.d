import sprite;
import std.algorithm;

struct Buffer
{
  size_t width, height;
  uint[] data;
}

uint rgbToUint(ubyte r, ubyte g, ubyte b)
{
  return (r << 24) | (g << 16) | (b << 8) | 255;
}

void bufferClear(Buffer *buffer, uint color)
{
  const auto dimension = buffer.width * buffer.height;
  for (size_t i = 0; i < dimension; ++i)
  {
    buffer.data[i] = color;
  }
}

void bufferDraw(
  Buffer* buffer, 
  const ref Sprite sprite,
  size_t x, 
  size_t y, 
  uint color
)
{
  for (size_t xi = 0; xi < sprite.width; ++xi)
  {
    for (size_t yi = 0; yi < sprite.height; ++yi)
    {
      size_t sy = sprite.height - 1 + y - yi;
      size_t sx = x + xi;

      if(sprite.data[yi * sprite.width + xi] && 
         sy < buffer.height && sx < buffer.width) 
      {
        buffer.data[sy * buffer.width + sx] = color;
      }
    }
  }
}

void bufferDrawText(
  Buffer* buffer,
  const ref Sprite textSprite,
  const string text,
  size_t x, 
  size_t y,
  uint color)
{
  auto stride = textSprite.width * textSprite.height;

  Sprite sprite;
  sprite.width = textSprite.width;
  sprite.height = textSprite.height;

  foreach (char character; text) 
  {
    // 0x20 = 32 = Space
    character -= 0x20;
    if (character < 0 || character >= 65) 
      continue;

    const auto start = character * stride;
    const auto sz = textSprite.data.length - start;
    sprite.data = new ubyte[sz];
    textSprite.data[start..textSprite.data.length].copy(sprite.data);
    bufferDraw(buffer, sprite, x, y, color);
    x += sprite.width + 1;
  }
}

void bufferDrawNumber(
  Buffer* buffer,
  const ref Sprite numberSprite, 
  size_t number,
  size_t x, 
  size_t y,
  uint color)
{
  ubyte[64] digits;
  size_t num_digits = 0;

  do
  {
    digits[num_digits++] = number % 10;
    number /= 10;
  }
  while (number > 0);

  const size_t stride = numberSprite.width * numberSprite.height;
  Sprite sprite;
  sprite.width = numberSprite.width;
  sprite.height = numberSprite.height;
  sprite.data = new ubyte[numberSprite.data.length];

  for (size_t i = 0; i < num_digits; ++i)
  {
    ubyte digit = digits[num_digits - i - 1];
    const auto start = digit * stride;
    numberSprite.data[start..numberSprite.data.length].copy(sprite.data);

    bufferDraw(buffer, sprite, x, y, color);
    x += numberSprite.width + 1;
  }
}