
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
    UNIFORM_TEXTURE,
    UNIFORM_FLASHLIGHT_POSITION,
    UNIFORM_DIFFUSE_LIGHT_POSITION,
    UNIFORM_SHININESS,
    UNIFORM_AMBIENT_COMPONENT,
    UNIFORM_DIFFUSE_COMPONENT,
    UNIFORM_SPECULAR_COMPONENT,
    UNIFORM_FOG_COLOR,
    UNIFORM_FOG_INTENSITY,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];


@interface GameViewController () {
    GLuint _program;
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
    GLKVector4 diffuseComponent, diffuseDay, diffuseNight;
    float shininess;
    GLKVector4 specularComponent;
    GLKVector4 ambientComponent, ambientDay, ambientNight;
    GLKVector4 fogColor, fogIntensity;


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
    
    //detectdrag
    UIPanGestureRecognizer *panRecognizer;
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragging:)];
    [self.view addGestureRecognizer:panRecognizer];
    
    //detec double tap  finger
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapGesture];
    
    //detec double tap  finger
    UITapGestureRecognizer *tapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(minimapToggle:)];
    tapGesture2.numberOfTapsRequired = 2;
    tapGesture2.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:tapGesture2];
    
    //initialize night and day shader parameters
    ambientDay = GLKVector4Make(0.5, 0.5, 0.5, 1.0);
    diffuseDay = GLKVector4Make(0.8, 0.5, 0.5, 1.0);
    ambientNight = GLKVector4Make(0.2, 0.2, 0.2, 1.0);
    diffuseNight = GLKVector4Make(0.1, 0.1, 0.5, 1.0);
    
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



CGPoint originalLocation;
float xMovement, zMovement;
float xRotation;
CGPoint oldRotation;
//drag-rotate detection
-(void)dragging:(UIPanGestureRecognizer *)gesture
{

     if(gesture.state == UIGestureRecognizerStateBegan)
        {
            oldRotation = [gesture locationInView:gesture.view];
        }
    CGPoint newCoord = [gesture locationInView:gesture.view];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    xRotation += newCoord.x / screenRect.size.width - oldRotation.x / screenRect.size.width;
    //moveSpeed = newCoord.y / screenRect.size.width - oldRotation.y / screenRect.size.width;
    moveSpeed = .7f - newCoord.y / screenRect.size.height;
    //NSLog(@"movespeed: %f", moveSpeed);
    moveSpeed *= .05f;
    oldRotation = [gesture locationInView:gesture.view];
    
    if(gesture.state == UIGestureRecognizerStateEnded)
    {
        moveSpeed = 0;
    }
    
}
- (IBAction)dayToggle:(UISwitch *)sender {
    if ([sender isOn]) {
        ambientComponent = GLKVector4Make(0.5, 0.5, 0.5, 1.0);
        diffuseComponent = GLKVector4Make(0.8, 0.2, 0.2, 1.0);
    }else{
        
        ambientComponent = GLKVector4Make(0.2, 0.2, 0.2, 1.0);
        diffuseComponent = GLKVector4Make(0.1, 0.1, 0.5, 1.0);
    }
}
- (IBAction)fogToggle:(UISwitch *)sender {
    if ([sender isOn]) {
        fogIntensity = GLKVector4Make(.6f, .6f, .6f, 1.0);
    }else{
        fogIntensity = GLKVector4Make(0, 0, 0, 0);
    }
}
- (IBAction)flashlightToggle:(UISwitch *)sender {
    if ([sender isOn]) {
        specularComponent = GLKVector4Make(1.0f, 1.0, 0.6, 1.0);
    }else{
        specularComponent = GLKVector4Make(0.0f, 0.0, 0.0, 1.0);
    }
}

bool isDay = true;

//handle doubletaps
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        xMovement = 0;
        zMovement = -10.0f;
        xRotation = 0;
    }
}

- (void)minimapToggle:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
            displayMinimap = !displayMinimap;
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
    _player.position = GLKVector3Make(0.0f, 0.0f, 0.0f);
    _player.scale = GLKVector3Make(1.2f,1.2f,1.2f);
    _player.rotation = GLKVector3Make(0.0f,-1.5708f,0.0f);
    _player.modelName = @"player";
    _player.textureName = @"playerIconBackground.jpg";
    
    //setup floor
    GameObject *floor = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:floor];
    floor.position = GLKVector3Make(4.0f, -1.0f, -1);
    floor.scale = GLKVector3Make(9.0f,9.0f,9.0f);
    floor.modelName = @"floor";
    floor.textureName = @"dryGround.jpg";
    
    //setup rotating cube
    GameObject *rotatingCube = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:rotatingCube];
    rotatingCube.position = GLKVector3Make(0.0f, 0.5f, 8.0f);
    rotatingCube.scale = GLKVector3Make(.3f,.3f,.3f);
    rotatingCube.modelName = @"crate";
    rotatingCube.textureName = @"crate.jpg";
    
    //setup maze walls
    GameObject *wall = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:wall];
    wall.position = GLKVector3Make(-2.0f, 0, 0.0f);
    wall.scale = GLKVector3Make(1,1,5);
    wall.modelName = @"wall";
    wall.textureName = @"redBrickTexture.jpg";
    
    GameObject *wall1 = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:wall1];
    wall1.position = GLKVector3Make(2.0f, 0, 2.0f);
    wall1.scale = GLKVector3Make(1,1,4);
    wall1.modelName = @"wall";
    wall1.textureName = @"brownBrickTexture2.jpg";
    
    GameObject *wall2 = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:wall2];
    wall2.position = GLKVector3Make(3.0f, 0.0f, -6.0f);
    wall2.scale = GLKVector3Make(6,1,1);
    wall2.modelName = @"wall";
    wall2.textureName = @"crate.jpg";
    
    GameObject *wall3 = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:wall3];
    wall3.position = GLKVector3Make(4.05f, 0, -1.05f);
    wall3.scale = GLKVector3Make(3,1,1);
    wall3.modelName = @"wall";
    wall3.textureName = @"colorBrickTexture.jpg";
    
    GameObject *wall4 = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:wall4];
    wall4.position = GLKVector3Make(9.5f, 0, -2.0f);
    wall4.scale = GLKVector3Make(1,1,4);
    wall4.modelName = @"wall";
    wall4.textureName = @"brownBrickTexture2.jpg";
    
    
    GameObject *wall5 = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:wall5];
    wall5.position = GLKVector3Make(5.0f, 0.0f, 5.0f);
    wall5.scale = GLKVector3Make(4,1,1);
    wall5.modelName = @"wall";
    wall5.textureName = @"brownBrickTexture2.jpg";


}
- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    uniforms[UNIFORM_MODELVIEW_MATRIX] = glGetUniformLocation(_program, "modelViewMatrix");
 
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(_program, "texture");
    uniforms[UNIFORM_FLASHLIGHT_POSITION] = glGetUniformLocation(_program, "flashlightPosition");
    uniforms[UNIFORM_DIFFUSE_LIGHT_POSITION] = glGetUniformLocation(_program, "diffuseLightPosition");
    uniforms[UNIFORM_SHININESS] = glGetUniformLocation(_program, "shininess");
    uniforms[UNIFORM_AMBIENT_COMPONENT] = glGetUniformLocation(_program, "ambientComponent");
    uniforms[UNIFORM_DIFFUSE_COMPONENT] = glGetUniformLocation(_program, "diffuseComponent");
    uniforms[UNIFORM_SPECULAR_COMPONENT] = glGetUniformLocation(_program, "specularComponent");
    uniforms[UNIFORM_FOG_INTENSITY] = glGetUniformLocation(_program, "fogIntensity");
    uniforms[UNIFORM_FOG_COLOR] = glGetUniformLocation(_program, "fogColor");
    
    // Set up lighting parameters
    flashlightPosition = GLKVector3Make(0.0, 0.0, 0.1f);
    diffuseLightPosition = GLKVector3Make(0.0, 1.0, 1.0);
    diffuseComponent = diffuseDay;
    shininess = 50.0;
    
    fogIntensity = GLKVector4Make(0, 0, 0, 1.0);
    fogColor = GLKVector4Make(0.5f, 0.5f, 0.5f, 1);
    
    
    ambientComponent = ambientDay;
    
    /*
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    */
    glEnable(GL_DEPTH_TEST);

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
//this should only run once for each object
-(void)bindObject:(GameObject*)object
{
    
    //for debugging
    NSLog(@"Binding GL for: %@", object.modelName);
    
    //determine model based on what the object is
    //if([object isKindOfClass:[GameObject class]])
    int vertexNum;
    if ([object.modelName isEqualToString:@"crate"])
    {
        vertexNum = sizeof(crate_v) / 12;
        object.modelHandle = [self setupVertices :crate_v :crate_vt :crate_vn :vertexNum :object.textureName];
    }
    else if ([object.modelName isEqualToString:@"player"])
    {
        vertexNum = sizeof(playerIndicator_v) / 12;
        object.modelHandle = [self setupVertices :playerIndicator_v :playerIndicator_vt :playerIndicator_vn :vertexNum :object.textureName];
    }
    else if ([object.modelName isEqualToString:@"wall"])
    {
        vertexNum = sizeof(cube_pos) / 12;
        object.modelHandle = [self setupVertices :cube_pos :cube_tex :cube_norm :vertexNum :object.textureName];
    }
    else if ([object.modelName isEqualToString:@"floor"])
    {
        vertexNum = sizeof(background_v) / 12;
        object.modelHandle = [self setupVertices :background_v :background_vt :background_vn :vertexNum :object.textureName];
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

bool displayMinimap = false;
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //set screen size
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width * [[UIScreen mainScreen] scale];
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height * [[UIScreen mainScreen] scale];
    
    
    //1st viewport (main gameview)
    //glScissor(0, screenHeight / 2, screenWidth, screenHeight/2);
    glScissor(0, 0, screenWidth, screenHeight);
    glEnable(GL_SCISSOR_TEST);
    glClearColor(0.3f, 0.1f, 0.1, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); //clear

    
    //glViewport(0, screenHeight / 2, screenWidth, screenHeight/2);
    glViewport(0, 0, screenWidth, screenHeight);
    for(id o in _gameObjects)
    {
        [self renderObject:(GameObject*)o];
    }
    
    //2nd viewport (minimap)
    if(displayMinimap){
        glScissor(screenWidth/2, 0, screenWidth/2, screenWidth/2);
        glViewport(screenWidth/2, 0, screenWidth/2, screenWidth/2);
        glEnable(GL_SCISSOR_TEST);
        glClearColor(0.1f, 0.1f, 0.1, 0.2f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); //clear
        
        for(id o in _gameObjects)
        {
            [self renderObject2:(GameObject*)o];
        }
    }

}

-(void)renderObject2:(GameObject*)gameObject{
    
    glBindVertexArrayOES(gameObject.modelHandle.vArray);
    glUseProgram(_program);
    
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.width);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(7.0f), aspect, 0.1f, 300.0f);
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(-4.0f, 4.0f, 0.0f);
    
    if ([gameObject.modelName isEqualToString:@"player"])
    {
        //player movement
        zMovement += moveSpeed * cosf(xRotation);
        xMovement += moveSpeed * -sinf(xRotation);
        GLKMatrix4 baseModelViewMatrix2 = GLKMatrix4MakeTranslation(-xMovement, zMovement, 0);
        baseModelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, baseModelViewMatrix2);
    }

    
    
    
    //baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, 1.5708, 1.0f, 0.0f, 0.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, 1.5708f, 1.0f, 0.0f, 0.0f);
    GLKMatrix4 baseModelViewMatrix2 = GLKMatrix4MakeTranslation(0, -200.0f, 0);
    baseModelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, baseModelViewMatrix2);
    
    //set model postion
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(gameObject.position.x, gameObject.position.y, gameObject.position.z);
    
    
    //rotate the crate
    if ([gameObject.modelName isEqualToString:@"crate"]){
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
       // _rotation += self.timeSinceLastUpdate * 0.3f;
    }
    
    
    //model rotation
    if ([gameObject.modelName isEqualToString:@"player"])
    {
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, -xRotation, 0, 1,0);
    }
    
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.x+gameObject.modelRotation.x, 1, 0,0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.y+gameObject.modelRotation.y, 0, 1,0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.z+gameObject.modelRotation.z, 0, 0,1);
    
    //model scale
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, gameObject.scale.x, gameObject.scale.y, gameObject.scale.z);
    
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    
    // Set up uniforms
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniform3fv(uniforms[UNIFORM_FLASHLIGHT_POSITION], 1, flashlightPosition.v);
    glUniform3fv(uniforms[UNIFORM_DIFFUSE_LIGHT_POSITION], 1, diffuseLightPosition.v);
    glUniform4fv(uniforms[UNIFORM_DIFFUSE_COMPONENT], 1, diffuseComponent.v);
    glUniform1f(uniforms[UNIFORM_SHININESS], shininess);
    glUniform4fv(uniforms[UNIFORM_SPECULAR_COMPONENT], 1, specularComponent.v);
    glUniform4fv(uniforms[UNIFORM_AMBIENT_COMPONENT], 1, ambientComponent.v);
    glUniform4fv(uniforms[UNIFORM_FOG_INTENSITY], 1, fogIntensity.v);
    glUniform4fv(uniforms[UNIFORM_FOG_COLOR], 1, fogColor.v);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, gameObject.modelHandle.textureHandle);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    
    //draw!
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gameObject.modelHandle.vBuffer);
    glDrawArrays(GL_TRIANGLES, 0, gameObject.modelHandle.length);
    glBindVertexArrayOES(0);
}

//player movement info
float xMovement = 0;
float zMovement = -10.0f;
float moveSpeed = 0;
-(void)renderObject:(GameObject*)gameObject
{
    
    glBindVertexArrayOES(gameObject.modelHandle.vArray);
    glUseProgram(_program);
    
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    
    //simulate camera rotation
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, xRotation, 0.0f, 1.0f, 0.0f);

    //player movement
    zMovement += moveSpeed * cosf(xRotation);
    xMovement += moveSpeed * -sinf(xRotation);
    GLKMatrix4 baseModelViewMatrix2 = GLKMatrix4MakeTranslation(xMovement, 0.0f, zMovement);
    baseModelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, baseModelViewMatrix2);
    
    //set model postion
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(gameObject.position.x, gameObject.position.y, gameObject.position.z);
    
    //rotate the crate
    if ([gameObject.modelName isEqualToString:@"crate"]){
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
        _rotation += self.timeSinceLastUpdate * 0.3f;
    }
    //don't render the player (player model used for minimap only
    if ([gameObject.modelName isEqualToString:@"player"]){
        return;
    }

    
    //model rotation
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.x+gameObject.modelRotation.x, 1, 0,0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.y+gameObject.modelRotation.y, 0, 1,0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, gameObject.rotation.z+gameObject.modelRotation.z, 0, 0,1);
    
    //model scale
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, gameObject.scale.x, gameObject.scale.y, gameObject.scale.z);
    
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);

    
    // Set up uniforms
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniform3fv(uniforms[UNIFORM_FLASHLIGHT_POSITION], 1, flashlightPosition.v);
    glUniform3fv(uniforms[UNIFORM_DIFFUSE_LIGHT_POSITION], 1, diffuseLightPosition.v);
    glUniform4fv(uniforms[UNIFORM_DIFFUSE_COMPONENT], 1, diffuseComponent.v);
    glUniform1f(uniforms[UNIFORM_SHININESS], shininess);
    glUniform4fv(uniforms[UNIFORM_SPECULAR_COMPONENT], 1, specularComponent.v);
    glUniform4fv(uniforms[UNIFORM_AMBIENT_COMPONENT], 1, ambientComponent.v);
    glUniform4fv(uniforms[UNIFORM_FOG_COLOR], 1, fogColor.v);
    glUniform4fv(uniforms[UNIFORM_FOG_INTENSITY], 1, fogIntensity.v);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, gameObject.modelHandle.textureHandle);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    
    //draw!
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gameObject.modelHandle.vBuffer);
    glDrawArrays(GL_TRIANGLES, 0, gameObject.modelHandle.length);
    glBindVertexArrayOES(0);
 
}

//sets up the models and textures
-(VertexInfo)setupVertices :(GLfloat*)posArray :(GLfloat*)texArray :(GLfloat*)normArray :(int)vertexNum :(NSString*) textureName
{
    VertexInfo vertexInfoStruct;
    vertexInfoStruct.length = vertexNum;
    //NSLog(@"%u", vertexInfoStruct.length);
    
    glGenVertexArraysOES(1, &vertexInfoStruct.vArray);
    glBindVertexArrayOES(vertexInfoStruct.vArray);
    
    glGenBuffers(1, &vertexInfoStruct.vBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexInfoStruct.vBuffer);
    
    long size = vertexInfoStruct.length * 8;
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
    }
    
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
    vertexInfoStruct.textureHandle = [self setupTexture:textureName];
    
    return vertexInfoStruct;
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
