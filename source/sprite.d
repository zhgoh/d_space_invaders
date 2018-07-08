struct Sprite
{
  size_t width, height;
  ubyte[] data;
};

Sprite createAlienSprite()
{
  Sprite alien;
  alien.width = 11;
  alien.height = 8;
  alien.data = 
  [
      0,0,1,0,0,0,0,0,1,0,0, // ..@.....@..
      0,0,0,1,0,0,0,1,0,0,0, // ...@...@...
      0,0,1,1,1,1,1,1,1,0,0, // ..@@@@@@@..
      0,1,1,0,1,1,1,0,1,1,0, // .@@.@@@.@@.
      1,1,1,1,1,1,1,1,1,1,1, // @@@@@@@@@@@
      1,0,1,1,1,1,1,1,1,0,1, // @.@@@@@@@.@
      1,0,1,0,0,0,0,0,1,0,1, // @.@.....@.@
      0,0,0,1,1,0,1,1,0,0,0  // ...@@.@@...
  ];
  return alien;
}

Sprite createPlayerSprite()
{
  Sprite player;
  player.width = 11;
  player.height = 7;
  player.data =
  [
      0,0,0,0,0,1,0,0,0,0,0, // .....@.....
      0,0,0,0,1,1,1,0,0,0,0, // ....@@@....
      0,0,0,0,1,1,1,0,0,0,0, // ....@@@....
      0,1,1,1,1,1,1,1,1,1,0, // .@@@@@@@@@.
      1,1,1,1,1,1,1,1,1,1,1, // @@@@@@@@@@@
      1,1,1,1,1,1,1,1,1,1,1, // @@@@@@@@@@@
      1,1,1,1,1,1,1,1,1,1,1, // @@@@@@@@@@@
  ];
  return player;
}

struct SpriteAnimation
{
    bool loop;
    size_t num_frames;
    size_t frame_duration;
    size_t time;
    Sprite** frames;
}