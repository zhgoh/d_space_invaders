import derelict.glfw3.glfw3;
import derelict.opengl;

import std.experimental.logger;
import std.stdio;
import std.typecons;
import std.string : format, fromStringz;

import shaders;
import buffer;

version(Windows) string libName = "dlls\\glfw3.dll";
else string libName = "glfw3.so";

void main()
{
  // Using Derelict to load openGL/GLFW
  DerelictGL3.load();
  DerelictGLFW3.load("dlls\\glfw3.dll");

  // Setting error callbacks
  glfwSetErrorCallback(&error_callback);

  if (!glfwInit())
  {
    fatal("glfw failed to init");
    return;
  }

  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
  glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
  
  auto window = glfwCreateWindow(640, 480, "Space Invaders", null, null);
  if(window is null)
  {
      fatal("glfw failed to create window");
      glfwTerminate();
      return;
  }

  glfwShowWindow(window);
  glfwMakeContextCurrent(window);
  glfwSwapInterval(1);

  // Reload after making context to use GL 3 core features
  DerelictGL3.reload();
  
  glViewport(0,0,640,480);
  glClearColor(0.39215686275, 0.58431372549, 0.92941176471, 1.0);

  uint clear_color = rgbToUint32(0, 128, 0);
  
  auto buffer_width = 640;
  auto buffer_height = 480;

  Buffer buffer;
  buffer.width = buffer_width;
  buffer.height = buffer_height;
  buffer.data = new uint[buffer.width * buffer.height];
  bufferClear(&buffer, clear_color);

  GLuint fullscreen_triangle_vao;
  glGenVertexArrays(1, &fullscreen_triangle_vao);
  glBindVertexArray(fullscreen_triangle_vao);

  auto shaderID = createShaders();
  if(!validateProgram(shaderID))
  {
    fatal("Error while validating shader.");
    glfwTerminate();
    glDeleteVertexArrays(1, &fullscreen_triangle_vao);

    return;
  }

  glUseProgram(shaderID);
  GLint location = glGetUniformLocation(shaderID, "buffer");
  glUniform1i(location, 0);

  glDisable(GL_DEPTH_TEST);
  glActiveTexture(GL_TEXTURE0);
  glBindVertexArray(fullscreen_triangle_vao);

  GLuint buffer_texture;
  glGenTextures(1, &buffer_texture);

  glBindTexture(GL_TEXTURE_2D, buffer_texture);
  glTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGB8,
      buffer.width, buffer.height, 0,
      GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, cast(char *)buffer.data
  );
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);


  while (!glfwWindowShouldClose(window))
  {
    glClear(GL_COLOR_BUFFER_BIT);

    glDrawArrays(GL_TRIANGLES, 0, 3);

    glfwSwapBuffers(window);
    glfwPollEvents();
  }

  glDeleteVertexArrays(1, &fullscreen_triangle_vao);
  
  glfwDestroyWindow(window);
  glfwTerminate();
}

extern(C) nothrow
{
	void error_callback(int error, const(char)* description)
	{
		throw new Error(format("Error: %s : %s", error, fromStringz(description)));
  }
}