import std.string : toStringz;
import std.stdio;
import std.experimental.logger;
import derelict.opengl;

const string vertex_shader =
  "\n"
  ~"#version 330\n"
  ~"\n"
  ~"noperspective out vec2 TexCoord;\n"
  ~"\n"
  ~"void main(void){\n"
  ~"\n"
  ~"    TexCoord.x = (gl_VertexID == 2)? 2.0: 0.0;\n"
  ~"    TexCoord.y = (gl_VertexID == 1)? 2.0: 0.0;\n"
  ~"    \n"
  ~"    gl_Position = vec4(2.0 * TexCoord - 1.0, 0.0, 1.0);\n"
  ~"}\n";

const string fragment_shader =
  "\n"
  ~"#version 330\n"
  ~"\n"
  ~"uniform sampler2D buffer;\n"
  ~"noperspective in vec2 TexCoord;\n"
  ~"\n"
  ~"out vec3 outColor;\n"
  ~"\n"
  ~"void main(void){\n"
  ~"    outColor = texture(buffer, TexCoord).rgb;\n"
  ~"}\n";

void validateShader(GLuint shader, string file)
{
  static const uint BUFFER_SIZE = 512;
  char[BUFFER_SIZE] buffer;
  GLsizei length = 0;

  glGetShaderInfoLog(shader, BUFFER_SIZE, &length, cast(char*)buffer);

  if (length > 0)
  {
    writeln("Shader %d(%s) compile error: %s\n", shader, (file ? file: ""), buffer);
  }
}

bool validateProgram(GLuint program)
{
  static const GLsizei BUFFER_SIZE = 512;
  GLchar[BUFFER_SIZE] buffer;
  GLsizei length = 0;

  glGetProgramInfoLog(program, BUFFER_SIZE, &length, cast(char*)buffer);

  if (length > 0)
  {
    writeln("Program %d link error: %s\n", program, buffer);
    return false;
  }

  return true;
}

int createShaders()
{
  GLuint shaderID = glCreateProgram();
  attachShader(shaderID, GL_VERTEX_SHADER, vertex_shader);
  attachShader(shaderID, GL_FRAGMENT_SHADER, fragment_shader);
  
  glLinkProgram(shaderID);
  return shaderID;
}

void attachShader(in GLuint shaderID, in GLenum shaderType, in string shaderSource)
{
  GLuint shader = glCreateShader(shaderType);

  const char* fileData = toStringz(shaderSource);
  glShaderSource(shader, 1, &fileData, null);
  glCompileShader(shader);
  
  validateShader(shader, shaderSource);
  glAttachShader(shaderID, shader);
  //glDeleteShader(shader_vp);
}