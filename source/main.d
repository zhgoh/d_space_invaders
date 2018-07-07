import derelict.glfw3.glfw3;
import derelict.opengl;
import std.experimental.logger;
import std.stdio;
import std.typecons;
import std.string : format, fromStringz;

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
  
  glViewport(0,0,640,480);
  glClearColor(0.39215686275, 0.58431372549, 0.92941176471, 1.0);

  while (!glfwWindowShouldClose(window))
  {
      glClear(GL_COLOR_BUFFER_BIT);
      glfwSwapBuffers(window);
      glfwPollEvents();
  }
  
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