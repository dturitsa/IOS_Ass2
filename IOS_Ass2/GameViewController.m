//
//  GameViewController.m
//  IOS_Ass2
//
//  Created by Denis Turitsa on 2017-03-05.
//  Copyright © 2017 Denis Turitsa. All rights reserved.
//

#import "GameViewController.h"
#import <OpenGLES/ES2/glext.h>
#import "GameObject.h"
#include "ModelData.m"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
#define VIEWPORT_WIDTH 720.0f
#define VIEWPORT_HEIGHT 1280.0f
#define RENDER_MODEL_SCALE 1.0f


// Shader uniform indices
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_MODELVIEW_MATRIX,
    /* more uniforms needed here... */
    UNIFORM_TEXTURE,
    UNIFORM_FLASHLIGHT_POSITION,
    UNIFORM_DIFFUSE_LIGHT_POSITION,
    UNIFORM_SHININESS,
    UNIFORM_AMBIENT_COMPONENT,
    UNIFORM_DIFFUSE_COMPONENT,
    UNIFORM_SPECULAR_COMPONENT,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];


@interface GameViewController () {
    GLuint _program;
    GLuint _bgTexture;
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix4 _modelViewMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    
    GLuint _vertexBuffers[3];
    GLuint _indexBuffer;
    
    VertexInfo playerVert, rotatingCubeVert;
    
    // Lighting parameters
    /* specify lighting parameters here...e.g., GLKVector3 flashlightPosition; */
    GLKVector3 flashlightPosition;
    GLKVector3 diffuseLightPosition;
    GLKVector4 diffuseComponent;
    float shininess;
    GLKVector4 specularComponent;
    GLKVector4 ambientComponent;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation GameViewController
{
    //MapModel* _mapModel;
    
    //game variables
    NSMutableArray *_gameObjects;
    GameObject  *_player;
    NSMutableArray *_gameObjectsInView;
    NSMutableArray *_gameObjectsToAdd;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGame];
    [self setupGL];
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (void)setupGame
{
    NSLog(@"Starting game...");
    
    //creating 'objects to add' array
    _gameObjectsToAdd = [[NSMutableArray alloc] init];
    
    //creating gameobjects array
    _gameObjects = [[NSMutableArray alloc]init];
    
    //create and init player
    //  NSLog(@"initializing player");
    _player = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:_player];
    _player.position = GLKVector3Make(0.9f, 0.0f, 0.0f);
    _player.scale = GLKVector3Make(1,1,1);

    
    //testing for dynamic enemy spawning;
    GameObject *rotatingCube = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:rotatingCube];
    rotatingCube.position = GLKVector3Make(2.0f, 2.0f, 0.0f);
    rotatingCube.scale = GLKVector3Make(1,1,1);
    
   /*
    //load map from file
    NSLog(@"loading map from file");
    _mapModel = [MapLoadHelper loadObjectsFromMap:@"map01"];
    [_gameObjectsToAdd addObjectsFromArray:_mapModel.objects];  //map number hardcoded for now
*/
  //  _gameObjectsInView = [[NSMutableArray alloc]init];
 //   [self refreshGameObjectsInView];


}
- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    uniforms[UNIFORM_MODELVIEW_MATRIX] = glGetUniformLocation(_program, "modelViewMatrix");
    /* more needed here... */
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(_program, "texture");
    uniforms[UNIFORM_FLASHLIGHT_POSITION] = glGetUniformLocation(_program, "flashlightPosition");
    uniforms[UNIFORM_DIFFUSE_LIGHT_POSITION] = glGetUniformLocation(_program, "diffuseLightPosition");
    uniforms[UNIFORM_SHININESS] = glGetUniformLocation(_program, "shininess");
    uniforms[UNIFORM_AMBIENT_COMPONENT] = glGetUniformLocation(_program, "ambientComponent");
    uniforms[UNIFORM_DIFFUSE_COMPONENT] = glGetUniformLocation(_program, "diffuseComponent");
    uniforms[UNIFORM_SPECULAR_COMPONENT] = glGetUniformLocation(_program, "specularComponent");
    
    // Set up lighting parameters
    /* set values, e.g., flashlightPosition = GLKVector3Make(0.0, 0.0, 1.0); */
    flashlightPosition = GLKVector3Make(0.0, 0.0, 1.0);
    diffuseLightPosition = GLKVector3Make(0.0, 1.0, 0.0);
    diffuseComponent = GLKVector4Make(0.8, 0.1, 0.1, 1.0);
    shininess = 200.0;
    specularComponent = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    ambientComponent = GLKVector4Make(0.5, 0.5, 0.5, 1.0);
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    glEnable(GL_DEPTH_TEST);
    
   
    
    //playerVert.length = sizeof(p2_pos) / 12;
    //[self setupVertices:(VertexInfo*)&playerVert :p2_pos :p2_norm :p2_norm];
    
    rotatingCubeVert.length = sizeof(cube_pos) / 12;
    [self setupVertices:(VertexInfo*)&rotatingCubeVert :cube_pos :cube_tex :cube_norm];

}

- (GLuint)setupTexture:(NSString *)fileName
{
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &playerVert.vBuffer);
    glDeleteVertexArraysOES(1, &playerVert.vArray);
    
    glDeleteBuffers(1, &rotatingCubeVert.vBuffer);
    glDeleteVertexArraysOES(1, &rotatingCubeVert.vArray);
    
    self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    
    //clear gameobjects list
    [_gameObjects removeAllObjects];
    _gameObjects = nil;
}


//Associate gameobjects with models
-(void)bindObject:(GameObject*)object
{
    
    //for debugging
    NSLog(@"Binding GL for: %@", NSStringFromClass([object class]));
    
    //determine model based on what the object is
    if([object isKindOfClass:[GameObject class]])
    {
        //object.modelHandle = playerVert;
        object.modelHandle = rotatingCubeVert;
        
    }
    
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{

    for(id o in _gameObjectsToAdd)
    {
        [_gameObjects addObject:o];
        [self bindObject:o];
    }
    [_gameObjectsToAdd removeAllObjects];

}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //clear the display
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f); //set background color (I remember this from GDX)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); //clear

    
    for(id o in _gameObjects)
    {
        [self renderObject:(GameObject*)o];
    }
}

-(void)renderObject:(GameObject*)gameObject
{
    
    glBindVertexArrayOES(gameObject.modelHandle.vArray);
    glUseProgram(_program);
    
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -10.0f);
    
    // Compute the model view matrix for the object rendered with ES2
    //GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(gameObject.position.x, gameObject.position.y, 1.5f);
    
     modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
     _rotation += self.timeSinceLastUpdate * 0.2f;
    
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.x+gameObject.modelRotation.x, 1, 0,0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.y+gameObject.modelRotation.y, 0, 1,0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.z+gameObject.modelRotation.z, 0, 0,1);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, gameObject.scale.x, gameObject.scale.y, gameObject.scale.z);
   // modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, RENDER_MODEL_SCALE, RENDER_MODEL_SCALE, RENDER_MODEL_SCALE);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 1.0f, 1.0f, 1.0f); //temp; should use object scale
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);

    
    // Set up uniforms
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    /* set lighting parameters... */
    glUniform3fv(uniforms[UNIFORM_FLASHLIGHT_POSITION], 1, flashlightPosition.v);
    glUniform3fv(uniforms[UNIFORM_DIFFUSE_LIGHT_POSITION], 1, diffuseLightPosition.v);
    glUniform4fv(uniforms[UNIFORM_DIFFUSE_COMPONENT], 1, diffuseComponent.v);
    glUniform1f(uniforms[UNIFORM_SHININESS], shininess);
    glUniform4fv(uniforms[UNIFORM_SPECULAR_COMPONENT], 1, specularComponent.v);
    glUniform4fv(uniforms[UNIFORM_AMBIENT_COMPONENT], 1, ambientComponent.v);
    
    //draw!
   // glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
   // glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);

    // NSLog(@"moduleHandel array Size: %u", s);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gameObject.modelHandle.vBuffer);
    glDrawArrays(GL_TRIANGLES, 0, gameObject.modelHandle.length);
    glBindVertexArrayOES(0);
 
}
/*
 sets up the vertex array and texture info

params: vertex info struct to hold the model info
     position array
    texture array
    normals array
 */
-(void)setupVertices:(VertexInfo*)vertexInfoStruct :(GLfloat*)posArray :(GLfloat*)texArray :(GLfloat*)normArray
{
    
    glGenVertexArraysOES(1, &vertexInfoStruct->vArray);
    glBindVertexArrayOES(vertexInfoStruct->vArray);
    
    glGenBuffers(1, &vertexInfoStruct->vBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexInfoStruct->vBuffer);
    
    long size = vertexInfoStruct->length * 8;
    GLfloat mixedArray[size];
    int j = 0;
    int k = 0;
    int n = 0;
    for(int i = 0; i < size; i++){
        //NSLog(@"%u", i%6);
        if(i%8 < 3){
            mixedArray[i] = posArray[j];
            j++;
        }else if(i%8 < 6){
            mixedArray[i] = normArray[k];
            k++;
        }else{
            mixedArray[i] = texArray[n];
            n++;
        }
        //NSLog(@"%.2f", mixedArray[i]);
    }
 //   NSLog(@"%lu", sizeof(sphere_pos));
  //  NSLog(@"%lu", sizeof(sphere_tex));
    
    //load array into buffer
    glBufferData(GL_ARRAY_BUFFER, sizeof(mixedArray), mixedArray, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(12));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(24));

    
    glBindVertexArrayOES(0);

    
    // Load in and set texture
    /* use setupTexture to create crate texture */
    _bgTexture = [self setupTexture:@"cubeTexture.png"];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _bgTexture);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    
}




#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    glBindAttribLocation(_program, GLKVertexAttribTexCoord0, "texCoordIn");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}
@end
