/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The OpenGLRenderer class creates and draws objects.
  Most of the code is OS independent.
 */

#import "OpenGLRenderer.h"
#include "glUtil.h"
#include "imageUtil.h"
#include "sourceUtil.h"

// Indicies to which we will set vertex array attibutes
// See buildVAO and buildProgram
enum {
	POS_ATTRIB_IDX,
	NORMAL_ATTRIB_IDX,
	TEXCOORD_ATTRIB_IDX
};

#ifndef NULL
#define NULL 0
#endif

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface OpenGLRenderer ()
{
    GLuint _defaultFBOName;

    GLuint _characterPrgName;
    GLint _characterMvpUniformIdx;
    GLuint _characterVAOName;
    GLuint _characterTexName;
    GLenum _characterPrimType;
    GLenum _characterElementType;
    GLuint _characterNumElements;
    GLfloat _characterAngle;
    
    GLuint _viewWidth;
    GLuint _viewHeight;
    
    GLboolean _useVBOs;
}
@end

@implementation OpenGLRenderer


- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height
{
	glViewport(0, 0, width, height);

	_viewWidth = width;
	_viewHeight = height;
}

- (void) render
{
	// Calculate the projection matrix
    // Clear the colorbuffer
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Draw our first triangle
	glUseProgram(_characterPrgName);
    
    glBindTexture(GL_TEXTURE_2D, _characterTexName);
    
//    glActiveTexture(GL_TEXTURE0);
//    glBindTexture(GL_TEXTURE_2D, _characterTexName);
//    glUniform1i(glGetUniformLocation(_characterPrgName, "ourTexture"), 0);
    
    
    glBindVertexArray(_characterVAOName);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    glBindVertexArray(0);
}

- (GLuint) buildVAO
{	
	
    // Set up vertex data (and buffer(s)) and attribute pointers
    GLfloat vertices[] = {
        -1.0f, -1.0f, 0.0f,  1.0f, 1.0f,
        1.0f, 1.0f, 0.0f, 0.0f, 0.0f,
        -1.0f,  1.0f, 0.0f, 1.f, 0.f,
        -1.0f, -1.0f, 0.0f,  1.0f, 1.0f,
        1.0f, -1.0f, 0.0f, 0.0f, 1.f,
        1.0f,  1.0f, 0.0f, 0.0f, 0.0f
    };
    
    GLuint VBO, VAO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    // Bind the Vertex Array Object first, then bind and set vertex buffer(s) and attribute pointer(s).
    glBindVertexArray(VAO);
    
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (GLvoid*)0);
    glEnableVertexAttribArray(0);
    
    glVertexAttribPointer(1, 2, GL_FLOAT,GL_FALSE, 5 * sizeof(GLfloat), (GLvoid*)(3 * sizeof(GLfloat)));
    glEnableVertexAttribArray(1);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0); // Note that this is allowed, the call to glVertexAttribPointer registered VBO as the currently bound vertex buffer object so afterwards we can safely unbind
    
    glBindVertexArray(0); // Unbind VAO (it's always a good thing to unbind any buffer/array to prevent strange bugs)
    
	
	return VAO;
}

-(void)destroyVAO:(GLuint) vaoName
{
	GLuint index;
	GLuint bufName;
	
	// Bind the VAO so we can get data from it
	glBindVertexArray(vaoName);
	
	// For every possible attribute set in the VAO
	for(index = 0; index < 16; index++)
	{
		// Get the VBO set for that attibute
		glGetVertexAttribiv(index , GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
		
		// If there was a VBO set...
		if(bufName)
		{
			//...delete the VBO
			glDeleteBuffers(1, &bufName);
		}
	}
	
	// Get any element array VBO set in the VAO
	glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
	
	// If there was a element array VBO set in the VAO
	if(bufName)
	{
		//...delete the VBO
		glDeleteBuffers(1, &bufName);
	}
	
	// Finally, delete the VAO
	glDeleteVertexArrays(1, &vaoName);
	
	GetGLError();
}


-(GLuint) buildTexture:(demoImage*) image
{
	GLuint texName;
	
    if (_characterTexName == 0) {
        // Create a texture object to apply to model
        glGenTextures(1, &texName);
    } else {
        texName = _characterTexName;
    }
	
    glBindTexture(GL_TEXTURE_2D, texName);
	// Set up filter and wrap modes for this texture object
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	
	// Indicate that pixel rows are tightly packed 
	//  (defaults to stride of 4 which is kind of only good for
	//  RGBA or FLOAT data types)
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	
	// Allocate and load image data into texture
	glTexImage2D(GL_TEXTURE_2D, 0, image->format, image->width, image->height, 0,
				 image->format, image->type, image->data);

	// Create mipmaps for this texture for better image quality
	glGenerateMipmap(GL_TEXTURE_2D);
	
	GetGLError();
	
	return texName;
}

- (void)setImage:(CVImageBufferRef)pixelBuffer {
    
//    glDeleteBuffers(1, &_characterTexName);
//    _characterTexName = 0;
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    demoImage image = {0};
    image.width = width;
    image.height = height;
    image.rowByteSize = image.width * 3;
    image.format = GL_RGB;
    image.type = GL_UNSIGNED_BYTE;
    image.size = CVPixelBufferGetDataSize(pixelBuffer);
    image.data = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    _characterTexName = [self buildTexture:&image];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer,0);

}


-(GLuint) buildProgramWithVertexSource:(demoSource*)vertexSource
					withFragmentSource:(demoSource*)fragmentSource
{
	GLuint prgName;
	
	GLint logLength, status;
	
	// String to pass to glShaderSource
	GLchar* sourceString = NULL;  
	
	// Determine if GLSL version 140 is supported by this context.
	//  We'll use this info to generate a GLSL shader source string  
	//  with the proper version preprocessor string prepended
	float  glLanguageVersion;
	
#if TARGET_IOS
	sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "OpenGL ES GLSL ES %f", &glLanguageVersion);
#else
	sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &glLanguageVersion);	
#endif
	
	// Get the size of the version preprocessor string info so we know
	//  how much memory to allocate for our sourceString
	
	// Create a program object
	prgName = glCreateProgram();
	
	
	//////////////////////////////////////
	// Specify and compile VertexShader //
	//////////////////////////////////////
	
			
	GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);	
	glShaderSource(vertexShader, 1, (const GLchar **)&(vertexSource->string), NULL);
	glCompileShader(vertexShader);
	glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);
	
	if (logLength > 0) 
	{
		GLchar *log = (GLchar*) malloc(logLength);
		glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
		NSLog(@"Vtx Shader compile log:%s\n", log);
		free(log);
	}
	
	glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &status);
	if (status == 0)
	{
		NSLog(@"Failed to compile vtx shader:\n%s\n", sourceString);
		return 0;
	}
	
	free(sourceString);
	sourceString = NULL;
	
	// Attach the vertex shader to our program
	glAttachShader(prgName, vertexShader);
	
	// Delete the vertex shader since it is now attached
	// to the program, which will retain a reference to it
	glDeleteShader(vertexShader);
	
	/////////////////////////////////////////
	// Specify and compile Fragment Shader //
	/////////////////////////////////////////
	
	GLuint fragShader = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(fragShader, 1, (const GLchar **)&(fragmentSource->string), NULL);
	glCompileShader(fragShader);
	glGetShaderiv(fragShader, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) 
	{
		GLchar *log = (GLchar*)malloc(logLength);
		glGetShaderInfoLog(fragShader, logLength, &logLength, log);
		NSLog(@"Frag Shader compile log:\n%s\n", log);
		free(log);
	}
	
	glGetShaderiv(fragShader, GL_COMPILE_STATUS, &status);
	if (status == 0)
	{
		NSLog(@"Failed to compile frag shader:\n%s\n", sourceString);
		return 0;
	}
	
	free(sourceString);
	sourceString = NULL;
	
	// Attach the fragment shader to our program
	glAttachShader(prgName, fragShader);
	
	// Delete the fragment shader since it is now attached
	// to the program, which will retain a reference to it
	glDeleteShader(fragShader);
	
	//////////////////////
	// Link the program //
	//////////////////////
	
	glLinkProgram(prgName);
	glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar*)malloc(logLength);
		glGetProgramInfoLog(prgName, logLength, &logLength, log);
		NSLog(@"Program link log:\n%s\n", log);
		free(log);
	}
	
	glGetProgramiv(prgName, GL_LINK_STATUS, &status);
	if (status == 0)
	{
		NSLog(@"Failed to link program");
		return 0;
	}
	
	glValidateProgram(prgName);

	glGetProgramiv(prgName, GL_VALIDATE_STATUS, &status);
	if (status == 0)
    {
        // 'status' set to 0 here does NOT indicate the program itself is invalid,
        //   but rather the state OpenGL was set to when glValidateProgram was called was
        //   not valid for this program to run (i.e. Given the CURRENT openGL state,
        //   draw call with this program will fail).  You may still be able to use this
        //   program if certain OpenGL state is set before a draw is made.  For instance,
        //   'status' could be 0 because no VAO was bound and so long as one is bound
        //   before drawing with this program, it will not be an issue.
		NSLog(@"Program cannot run with current OpenGL State");
	}

    glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetProgramInfoLog(prgName, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s\n", log);
        free(log);
    }

	glUseProgram(prgName);
	
	GetGLError();
	
	return prgName;
	
}

- (id) initWithDefaultFBO: (GLuint) defaultFBOName
{
	if((self = [super init]))
	{
		NSLog(@"%s %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));
		
		////////////////////////////////////////////////////
		// Build all of our and setup initial state here  //
		// Don't wait until our real time run loop begins //
		////////////////////////////////////////////////////
		
		_defaultFBOName = defaultFBOName;
		
		_viewWidth = 100;
		_viewHeight = 100;

		_characterAngle = 0;
		
		
		NSString* filePathName = nil;

		//////////////////////////////
		// Load our character model //
		//////////////////////////////
		
		
		// Build Vertex Buffer Objects (VBOs) and Vertex Array Object (VAOs) with our model data
		_characterVAOName = [self buildVAO];
		
	
        ////////////////////////////////////
		// Load texture for our character //
		////////////////////////////////////
		
		filePathName = [[NSBundle mainBundle] pathForResource:@"container" ofType:@"jpg"];
		demoImage *image = imgLoadImage([filePathName cStringUsingEncoding:NSASCIIStringEncoding], false);
		
		// Build a texture object with our image data
		_characterTexName = [self buildTexture:image];
		
		// We can destroy the image once it's loaded into GL
		imgDestroyImage(image);
	
		
		////////////////////////////////////////////////////
		// Load and Setup shaders for character rendering //
		////////////////////////////////////////////////////
		
		demoSource *vtxSource = NULL;
		demoSource *frgSource = NULL;
		
		filePathName = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vs"];
		vtxSource = srcLoadSource([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
		
		filePathName = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"frag"];
		frgSource = srcLoadSource([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
		
		// Build Program
		_characterPrgName = [self buildProgramWithVertexSource:vtxSource
											 withFragmentSource:frgSource];
		
		srcDestroySource(vtxSource);
		srcDestroySource(frgSource);
		
		
		////////////////////////////////////////////////
		// Set up OpenGL state that will never change //
		////////////////////////////////////////////////
		
		// Depth test will always be enabled
		glEnable(GL_DEPTH_TEST);
	
		// We will always cull back faces for better performance
		glEnable(GL_CULL_FACE);
		
		// Always use this clear color
		glClearColor(1.0f, 0.4f, 0.5f, 1.0f);
		
		// Draw our scene once without presenting the rendered image.
		//   This is done in order to pre-warm OpenGL
		// We don't need to present the buffer since we don't actually want the 
		//   user to see this, we're only drawing as a pre-warm stage
		[self render];
		
		// Check for errors to make sure all of our setup went ok
		GetGLError();
	}
	
	return self;
}


- (void) dealloc
{
	// Cleanup all OpenGL objects and
	glDeleteTextures(1, &_characterTexName);
		
	[self destroyVAO:_characterVAOName];

	glDeleteProgram(_characterPrgName);
}

@end
