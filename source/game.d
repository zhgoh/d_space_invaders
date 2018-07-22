import derelict.glfw3.glfw3;
import derelict.opengl;

import std.experimental.logger;
import std.stdio;
import std.typecons;
import std.string : format, fromStringz;
import std.exception;

import shaders;
import buffer;
import sprite;

version(Windows) string libName = "dlls\\glfw3.dll";
else string libName = "glfw3.so";

// Player state
static auto playerDir = 0;

// Whether fired
static auto firePressed = false;

struct Alien
{
  size_t x, y;
  ubyte type;
}

struct Player
{
  size_t x, y;
  size_t life;
}

struct Bullet
{
  size_t x, y;
  int dir;
}

class GameState
{
  public size_t width, height;
  public size_t numAliens;
  public size_t numBullets;
  public Alien[] aliens;
  public Player player;
  public Bullet[128] bullets;
  public ubyte[] deathCounters;

  this(size_t width, size_t height, size_t x, size_t y, size_t numLives = 3)
  {
    this.width = width;
    this.height = height;

    // Hardcoded because setting alien pos needs it
    this.numAliens = 55;
    this.aliens = new Alien[numAliens];

    this.player.x = x;
    this.player.y = y;
    this.player.life = numLives;

    this.deathCounters = new ubyte[numAliens];
    deathCounters[] = 10;
  }
}

class Game
{
  private static bool isRunning = true;
  private uint width, height;
  private GLFWwindow *window;
  private GameState gameState;
  private Buffer buffer;
  private GLuint fullscreenTriangleVAO;

  private AlienAnimation alienAnim;
  private const Sprite playerSprite;
  private const Sprite bulletSprite;
  private const Sprite textSprite;
  private const Sprite numberSprite;

  private size_t score = 0;

  this(uint width, uint height)
  {
    this.width = width;
    this.height = height;
    
    gameState = new GameState(width, height, 112 - 5, 32);
    buffer = new Buffer(width, height);

    // Creates animation
    alienAnim = createAlienAnimation();
    playerSprite = createPlayerSprite();
    bulletSprite = createBulletSprite();
    textSprite = createTextSprite();
    numberSprite = createNumberSprite();

    // Set Alien position
    for (size_t yi = 0; yi < 5; ++yi)
    {
      for (size_t xi = 0; xi < 11; ++xi)
      {
        auto alien = &gameState.aliens[yi * 11 + xi];
        alien.type = cast (ubyte) (5 - yi) / 2 + 1;

        const auto sprite = &alienAnim.frames[2 * (alien.type - 1)];

        alien.x = 16 * xi + 20 + (alienAnim.frames[AlienFrame.ALIEN_DEATH].width - sprite.width) / 2;
        alien.y = 17 * yi + 128;
      }
    }
  }

  void InitGL()
  {
    // Using Derelict to load openGL/GLFW
    DerelictGL3.load();
    DerelictGLFW3.load("dlls\\glfw3.dll");

    // Setting error callbacks
    glfwSetErrorCallback(&error_callback);

    if (!glfwInit())
    {
      fatal("glfw failed to init");
      throw new Exception("glfw failed to init");
    }

    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    
    window = glfwCreateWindow(2 * width, 2 * height, "Space Invaders", null, null);
    if(window is null)
    {
      fatal("glfw failed to create window");
      glfwTerminate();
      throw new Exception("glfw failed to create window");
    }

    // Setting key callbacks
    glfwSetKeyCallback(window, &key_callback);

    glfwShowWindow(window);
    glfwMakeContextCurrent(window);

    // Turning on vsync
    glfwSwapInterval(1);

    // Reload after making context to use GL 3 core features
    DerelictGL3.reload();

    // Create textures for the buffer
    GLuint buffer_texture;
    glGenTextures(1, &buffer_texture);
    glBindTexture(GL_TEXTURE_2D, buffer_texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, buffer.width, buffer.height, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, cast(char *)buffer.data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    // Create a triangular mesh for drawing background
    glGenVertexArrays(1, &fullscreenTriangleVAO);

    // Create a default shader
    const auto shaderID = createShaders();
    if (!validateProgram(shaderID))
    {
      fatal("Error while validating shader.");
      glfwTerminate();
      glDeleteVertexArrays(1, &fullscreenTriangleVAO);

      throw new Exception("Error while validating shader.");
    }

    glUseProgram(shaderID);
    GLint location = glGetUniformLocation(shaderID, "buffer");
    glUniform1i(location, 0);

    glDisable(GL_DEPTH_TEST);
    glActiveTexture(GL_TEXTURE0);
    glBindVertexArray(fullscreenTriangleVAO);
  }

  private void CleanupGL()
  {
    glDeleteVertexArrays(1, &fullscreenTriangleVAO);
    glfwDestroyWindow(window);
    glfwTerminate();
  }

  public void Run()
  {
    InitGL();
    Frame();
    CleanupGL();
  }

  private void Frame()
  {
    // Clear for first frame
    auto clearColor = rgbToUint(0, 128, 0);
    bufferClear(&buffer, clearColor);

    // Main loop
    while (!glfwWindowShouldClose(window) && isRunning)
    {
      loopAnim(alienAnim);

      const auto newDir = playerDir * 2;

      if (newDir != 0)
      {
        if (gameState.player.x + playerSprite.width + newDir >= gameState.width)
        {
          gameState.player.x = gameState.width - playerSprite.width;
        }
        else if (cast (int)gameState.player.x + newDir <= 0)
        {
          gameState.player.x = 0;
        }
        else 
          gameState.player.x += newDir;
      }

      bufferClear(&buffer, clearColor);

      // Drawing of UI/Text
      bufferDrawText(&buffer, textSprite, "SCORE", 4, gameState.height - textSprite.height - 7, rgbToUint(128, 0, 0));
      bufferDrawNumber(&buffer, numberSprite, score, 4 + 2 * numberSprite.width, gameState.height - 2 * numberSprite.height - 12, rgbToUint(128, 0, 0));
      bufferDrawText(&buffer, textSprite, "CREDIT 00", 164, 7, rgbToUint(128, 0, 0));
      for (size_t i = 0; i < gameState.width; ++i)
      {
        buffer.data[gameState.width * 16 + i] = rgbToUint(128, 0, 0);
      }

      for (size_t ai = 0; ai < gameState.numAliens; ++ai)
      {
        if (!gameState.deathCounters[ai]) 
          continue;
        
        const auto alien = &gameState.aliens[ai];

        if (alien.type == AlienType.ALIEN_DEAD)
        {
          // Draw death sprite
          bufferDraw(&buffer, alienAnim.frames[6], alien.x, alien.y, rgbToUint(128, 0, 0));
        }
        else
        {
          size_t currentFrame = alienAnim.time / alienAnim.frameDuration;
          const auto sprite = alienAnim.frames[2 * (alien.type - 1) + currentFrame];
          bufferDraw(&buffer, sprite, alien.x, alien.y, rgbToUint(128, 0, 0));
        }
      }

      for (size_t bi = 0; bi < gameState.numBullets; ++bi)
      {
        const auto bullet = &gameState.bullets[bi];
        bufferDraw(&buffer, bulletSprite, bullet.x, bullet.y, rgbToUint(128, 0, 0));
      }

      // Simulate bullets
      for (size_t bi = 0; bi < gameState.numBullets;)
      {
        gameState.bullets[bi].y += gameState.bullets[bi].dir;
        if (gameState.bullets[bi].y >= gameState.height ||
          gameState.bullets[bi].y < bulletSprite.height)
        {
            gameState.bullets[bi] = gameState.bullets[gameState.numBullets - 1];
            --gameState.numBullets;
            continue;
        }

        // Check hit
        for (size_t ai = 0; ai < gameState.numAliens; ++ai)
        {
          const auto alien = &gameState.aliens[ai];
          if (alien.type == AlienType.ALIEN_DEAD) 
            continue;

          const auto animation = &alienAnim;
          size_t current_frame = animation.time / animation.frameDuration;
          const auto alien_sprite = &animation.frames[current_frame];
          bool overlap = overlapCheck(
            bulletSprite, gameState.bullets[bi].x, gameState.bullets[bi].y,
            *alien_sprite, alien.x, alien.y
          );
          
          if (overlap)
          {
            gameState.aliens[ai].type = AlienType.ALIEN_DEAD;

            score += 10 * (4 - gameState.aliens[ai].type);

            // NOTE: Hack to recenter death sprite
            gameState.aliens[ai].x -= (alienAnim.frames[6].width - alien_sprite.width)/2;
            gameState.bullets[bi] = gameState.bullets[gameState.numBullets - 1];
            --gameState.numBullets;
            continue;
          }
        }
        
        ++bi;
      }

      bufferDraw(&buffer, playerSprite, gameState.player.x, gameState.player.y, rgbToUint(128, 0, 0));

      glTexSubImage2D(
        GL_TEXTURE_2D, 0, 0, 0,
        buffer.width, buffer.height,
        GL_RGBA, GL_UNSIGNED_INT_8_8_8_8,
        cast(char *)buffer.data
      );
      glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

      glfwSwapBuffers(window);
      glfwPollEvents();

      // Simulate aliens
      for (size_t ai = 0; ai < gameState.numAliens; ++ai)
      {
        const auto alien = &gameState.aliens[ai];
        if (alien.type == AlienType.ALIEN_DEAD && gameState.deathCounters[ai])
        {
          --gameState.deathCounters[ai];
        }
      }

      // SImulate bullets
      if (firePressed && gameState.numBullets < 128)
      {
        gameState.bullets[gameState.numBullets].x = gameState.player.x + playerSprite.width / 2;
        gameState.bullets[gameState.numBullets].y = gameState.player.y + playerSprite.height;
        gameState.bullets[gameState.numBullets].dir = 2;
        ++gameState.numBullets;
      }
      firePressed = false;
    }
  }

  public static void Stop() nothrow
  {
    isRunning = false;
  }
}

extern(C) nothrow
{
	void error_callback(int error, const(char)* description)
	{
		throw new Error(format("Error: %s : %s", error, fromStringz(description)));
  }

  void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
  {
    switch(key)
    {
    case GLFW_KEY_ESCAPE:
      if(action == GLFW_PRESS) 
        Game.Stop();
      break;

    case GLFW_KEY_D:
    case GLFW_KEY_RIGHT:
      if(action == GLFW_PRESS) 
        playerDir += 1;
      else if(action == GLFW_RELEASE) 
        playerDir -= 1;
      break;

    case GLFW_KEY_A:
    case GLFW_KEY_LEFT:
      if(action == GLFW_PRESS) 
        playerDir -= 1;
      else if(action == GLFW_RELEASE) 
        playerDir += 1;
      break;
    
    case GLFW_KEY_SPACE:
      if (action == GLFW_RELEASE) 
        firePressed = true;
      break;

    default:
      break;
    }
  } 
}