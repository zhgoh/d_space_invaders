struct Sprite
{
  size_t width, height;
  ubyte[] data;
};

Sprite[2] createAlienSprite()
{
  Sprite[2] alien;
  alien[0].width = 11;
  alien[0].height = 8;

  alien[1].width = 11;
  alien[1].height = 8;

  alien[0].data = 
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

  alien[1].data = 
  [
    0,0,1,0,0,0,0,0,1,0,0, // ..@.....@..
    1,0,0,1,0,0,0,1,0,0,1, // @..@...@..@
    1,0,1,1,1,1,1,1,1,0,1, // @.@@@@@@@.@
    1,1,1,0,1,1,1,0,1,1,1, // @@@.@@@.@@@
    1,1,1,1,1,1,1,1,1,1,1, // @@@@@@@@@@@
    0,1,1,1,1,1,1,1,1,1,0, // .@@@@@@@@@.
    0,0,1,0,0,0,0,0,1,0,0, // ..@.....@..
    0,1,0,0,0,0,0,0,0,1,0  // .@.......@.
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
    Sprite[2] frames;
}

SpriteAnimation createAlienAnimation()
{
  SpriteAnimation alienAnim;

  alienAnim.loop = true;
  alienAnim.num_frames = 2;
  alienAnim.frame_duration = 10;
  alienAnim.time = 0;

  alienAnim.frames = createAlienSprite();
  return alienAnim;
}

void loopAnim(ref SpriteAnimation anim)
{
  ++anim.time;
  if(anim.time == anim.num_frames * anim.frame_duration)
  {
      if(anim.loop) 
        anim.time = 0;
      else
      {
        //TODO: Remove anim
      }
  }
}