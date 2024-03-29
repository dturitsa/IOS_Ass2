
//  GameViewController.m
//  IOS_Ass2
//
//  Created by Denis Turitsa on 2017-03-05.
//  Copyright © 2017 Denis Turitsa. All rights reserved.
//

#import "GameViewController.h"
#import <OpenGLES/ES2/glext.h>
#import "GameObject.h"

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
    
   // Mix *parserObj;


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
    
    //detect drag
    UIPanGestureRecognizer *panRecognizer;
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragging:)];
    [self.view addGestureRecognizer:panRecognizer];
    
    //detect tap finger
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapGesture];
    
    //detect double tap finger
    UITapGestureRecognizer *tapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(minimapToggle:)];
    tapGesture2.numberOfTapsRequired = 2;
    tapGesture2.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:tapGesture2];
    
    //detect pinch
    UIPinchGestureRecognizer *pinchRecognizer;
    pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinching:)];
    [self.view addGestureRecognizer:pinchRecognizer];
    
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
float yRotation;
CGPoint oldRotation;

//drag-rotate detection
-(void)dragging:(UIPanGestureRecognizer *)gesture
{
    
    if(gesture.state == UIGestureRecognizerStateBegan)
    {
        oldRotation = [gesture locationInView:gesture.view];
    }
    
    if (gesture.numberOfTouches == 1) {
    CGPoint newCoord = [gesture locationInView:gesture.view];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    xRotation += newCoord.x / screenRect.size.width - oldRotation.x / screenRect.size.width;
    //moveSpeed = newCoord.y / screenRect.size.width - oldRotation.y / screenRect.size.width;
    moveSpeed = .7f - newCoord.y / screenRect.size.height;
    //NSLog(@"movespeed: %f", moveSpeed);
    moveSpeed *= .05f;
    oldRotation = [gesture locationInView:gesture.view];
    }
    
    if(gesture.state == UIGestureRecognizerStateEnded)
    {
        moveSpeed = 0;
    }
    
    if (gesture.numberOfTouches > 1 && !enemyMove && isTouchingEnemy) {
        CGPoint newCoord = [gesture locationInView:gesture.view];
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        enemyRotation = (newCoord.x / screenRect.size.width - oldRotation.x / screenRect.size.width) * 5;
        enemyYOffset += -(newCoord.y / screenRect.size.height - oldRotation.y / screenRect.size.height)/4.0f * self.timeSinceLastUpdate;
    }
    
//    NSLog (@"Number of touches: %lu", (unsigned long)gesture.numberOfTouches);
//    NSLog (@"Position X: %f, Y: %f", newCoord.x/100, newCoord.y/100);
//    NSLog (@"moveSpeed: %f", moveSpeed);
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
        //  xMovement = 0;
        //   zMovement = -10.0f;
        //   xRotation = 0;
        
        CGPoint location = [sender locationInView:sender.view];
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width * [[UIScreen mainScreen] scale];
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height * [[UIScreen mainScreen] scale];
        
        //Get the colour of the pixel at the touched point
        // CGPoint location = ccp((point.x - CGRectGetMinX(boundingBox)) * CC_CONTENT_SCALE_FACTOR(),
        //                    (point.y - CGRectGetMinY(boundingBox)) * CC_CONTENT_SCALE_FACTOR());
        GLint tapX = (GLint)location.x * [[UIScreen mainScreen] scale];
        GLint tapY = (GLint)location.y * [[UIScreen mainScreen] scale];
        
        UInt8 data[4];
        glReadPixels(tapX,
                     screenHeight - tapY,
                     1, 1, GL_RGBA, GL_UNSIGNED_BYTE, data);
        // NSLog(@"touched color: %u, %u, %u", data[0], data[1], data[2]);
        if(data[0] > 100 && data[1] > 100 && data[2] > 100){
            NSLog(@"HEY! don't touch me!");
            enemyMove = !enemyMove;
        }
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

float enemyXPosition = 0.0f;
float enemyYPosition = 0.0f;
float enemyZPosition = 0.0f;
float enemyYOffset = 0.0f;
float enemyScale = 1.0f;
float enemyRotation = 0.0f;
bool enemyMove = true;
bool isTouchingEnemy = false;

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
    _player.position = GLKVector3Make(0.0f, 0.0f, -10.0f);
    _player.scale = GLKVector3Make(1.2f,1.2f,1.2f);
    _player.rotation = GLKVector3Make(0.0f,-1.5708f,0.0f);
    _player.modelName = @"triangle";
    _player.name = @"player";
    _player.textureName = @"playerIconBackground.jpg";
    _player.length = 2.5f;
    _player.width = 2.5f;
    
    //setup floor
    GameObject *floor = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:floor];
    floor.position = GLKVector3Make(4.0f, -1.0f, -1);
    floor.scale = GLKVector3Make(9.0f,9.0f,9.0f);
    floor.modelName = @"triangulatedQuad";
    floor.textureName = @"dryGround.jpg";
    floor.length = 0;
    floor.width = 0;
    floor.name = @"floor";
    
    //setup enemy
    GameObject *enemy = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:enemy];
    enemy.position = GLKVector3Make(enemyXPosition, enemyYPosition, enemyZPosition);
    enemy.scale = GLKVector3Make(.3f,.3f,.3f);
    enemy.modelName = @"player";
    enemy.name = @"enemy";
    enemy.textureName = @"Player_White.png";
    enemy.length = 1.75f;
    enemy.width = 1.75f;
    enemy.speed = 0.1f;
    
    //setup maze walls
    GameObject *wall = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:wall];
    wall.position = GLKVector3Make(-2.0f, 0, 0.0f);
    wall.scale = GLKVector3Make(1,1,5);
    wall.modelName = @"crateCube";
    wall.textureName = @"redBrickTexture.jpg";
    wall.length = 2.0f * 1;
    wall.width = 2.0f * 5;
    wall.name = @"wall";
    
    GameObject *wall1 = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:wall1];
    wall1.position = GLKVector3Make(2.0f, 0, 2.0f);
    wall1.scale = GLKVector3Make(1,1,4);
    wall1.modelName = @"crateCube";
    wall1.textureName = @"brownBrickTexture2.jpg";
    wall1.length = 2.0f * 1;
    wall1.width = 2.0f * 4;
    wall1.name = @"wall1";
    
    GameObject *wall2 = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:wall2];
    wall2.position = GLKVector3Make(3.0f, 0.0f, -6.0f);
    wall2.scale = GLKVector3Make(6,1,1);
    wall2.modelName = @"crateCube";
    wall2.textureName = @"crate.jpg";
//    wall2.length = 2.0f * 6;
//    wall2.width = 2.0f * 1;
//    wall2.name = @"wall2";
    
    GameObject *wall3 = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:wall3];
    wall3.position = GLKVector3Make(4.05f, 0, -1.05f);
    wall3.scale = GLKVector3Make(3,1,1);
    wall3.modelName = @"crateCube";
    wall3.textureName = @"colorBrickTexture.jpg";
//    wall3.length = 2.0f * 3;
//    wall3.width = 2.0f * 1;
//    wall3.name = @"wall3";
    
    GameObject *wall4 = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:wall4];
    wall4.position = GLKVector3Make(9.5f, 0, -2.0f);
    wall4.scale = GLKVector3Make(1,1,4);
    wall4.modelName = @"crateCube";
    wall4.textureName = @"brownBrickTexture2.jpg";
//    wall4.length = 2.0f * 1;
//    wall4.width = 2.0f * 4;
//    wall4.name = @"wall4";
    
    GameObject *wall5 = [[GameObject alloc] init];
    [_gameObjectsToAdd addObject:wall5];
    wall5.position = GLKVector3Make(5.0f, 0.0f, 5.0f);
    wall5.scale = GLKVector3Make(4,1,1);
    wall5.modelName = @"crateCube";
    wall5.textureName = @"brownBrickTexture2.jpg";
//    wall5.length = 2.0f * 4;
//    wall5.width = 2.0f * 1;
//    wall5.name = @"wall5";
    
    // Create two walls just for testing collisions
//    GameObject *wall6 = [[GameObject alloc] init];
//    [_gameObjectsToAdd addObject:wall6];
//    wall6.position = GLKVector3Make(-2.1f, 0.0f, 5.5f);
//    wall6.scale = GLKVector3Make(2,1,1);
//    wall6.modelName = @"crateCube";
//    wall6.textureName = @"colorBrickTexture.jpg";
//    wall6.length = 2.0f * 2;
//    wall6.width = 2.0f;
//    wall6.name = @"wall6";
//    
//    GameObject *wall7 = [[GameObject alloc] init];
//    [_gameObjectsToAdd addObject:wall7];
//    wall7.position = GLKVector3Make(1.0f, 0.0f, 5.5f);
//    wall7.scale = GLKVector3Make(1,1,1);
//    wall7.modelName = @"crateCube";
//    wall7.textureName = @"crate.jpg";
//    wall7.length = 2.0f;
//    wall7.width = 2.0f;
//    wall7.name = @"wall7";
    
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

//Michael
//Physics collision detection
//Each GameObject is a square with x,y position, length and width
-(bool)checkCollisionBetweenObject:(GameObject *)one and:(GameObject *)two
{
    //    NSLog(@"-------------------------------------------------------------------------------------------------------");
    //    NSLog(@"Checking Collisiosn Between: %@ and %@", one.name, two.name);
    //    NSLog(@"One.Position: %f,%f One.Length: %f One.Width: %f", one.position.x, one.position.z, one.length, one.width);
    //    NSLog(@"Two.Position: %f,%f Two.Length: %f Two.Width: %f", two.position.x, two.position.z, two.length, two.width);
    //    NSLog(@"-------------------------------------------------------------------------------------------------------");
    
    if (one.length == 0 || one.width == 0 || two.length == 0 || two.width == 0)
        return false;
    
    // check x-axis collision
    bool collisionX = one.position.x + one.length/2 >= two.position.x - two.length/2 && two.position.x + two.length/2 >= one.position.x - one.length/2;
    
    // check y-axis collision
    bool collisionY = one.position.z + one.width/2 >= two.position.z - two.width/2 && two.position.z + two.width/2 >= one.position.z - one.width/2;
    
    // collision occurs only if on both axes
    return collisionX && collisionY;
    
}

- (IBAction)pinching:(UIPinchGestureRecognizer *)sender {
    
//    NSLog(@"Scale: %f", sender.scale);
//    NSLog(@"Velocity: %f", sender.velocity);
    
    if (isTouchingEnemy && !enemyMove) {
        enemyScale = sender.scale;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    for(id o in _gameObjectsToAdd)
    {
        ((GameObject*)o).modelHandle = [self loadModel :((GameObject*)o).modelName :((GameObject*)o).textureName];
        [_gameObjects addObject:o];
    }
    [_gameObjectsToAdd removeAllObjects];

    //check for GameObject collisions
    //loop through all gameobjects in scene
    //check if any of those two objects are colliding AND they are both solid
    //if they are, then return collision!
    isTouchingEnemy = false;
    for (int i=0; i <_gameObjects.count ; i++)
    {
        for (int j=0; j < _gameObjects.count ; j++)
        {
            if (_gameObjects[i] != _gameObjects[j] && [self checkCollisionBetweenObject:_gameObjects[i] and:_gameObjects[j]])
            {
                //detect collision when player touches enemy
                if ([((GameObject *)_gameObjects[i]).name isEqualToString:@"player"] && [((GameObject *)_gameObjects[j]).name isEqualToString:@"enemy"]) {
//                    NSLog(@"Collision Detected Between: %@ and %@", ((GameObject *)_gameObjects[i]).name,((GameObject *)_gameObjects[j]).name);
                    isTouchingEnemy = true;
                }
//                NSLog(@"isTouchingEnemy: %d", isTouchingEnemy);
//                NSLog(@"%@: (%f, %f)", ((GameObject *)_gameObjects[i]).name, ((GameObject *)_gameObjects[i]).position.x, ((GameObject *)_gameObjects[i]).position.z);
                
                //call oncollide function for first object only
                [(GameObject *)_gameObjects[i] onCollision:_gameObjects[j]];
            }
        }
    }
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
            [self renderMiniMap:(GameObject*)o];
        }
    }
}

-(void)renderMiniMap:(GameObject*)gameObject{
    
    glBindVertexArrayOES(gameObject.modelHandle.vArray);
    glUseProgram(_program);
    
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.width);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(7.0f), aspect, 0.1f, 300.0f);
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(-4.0f, 4.0f, 0.0f);
    
    if ([gameObject.name isEqualToString:@"player"])
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
    
    //rotate the enemy
    if ([gameObject.name isEqualToString:@"enemy"]){
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
//        _rotation += self.timeSinceLastUpdate * 0.3f;
    }
    
    //model rotation
    if ([gameObject.name isEqualToString:@"player"])
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
    
    //move and rotate the enemy
    if ([gameObject.name isEqualToString:@"enemy"]){
        
        modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, enemyXPosition, enemyYPosition + enemyYOffset, enemyZPosition);
        if (enemyMove) {
            enemyXPosition += self.timeSinceLastUpdate * gameObject.speed;
        }
        
        gameObject.rotation = GLKVector3Make( 0, enemyRotation, 0);
        gameObject.position = GLKVector3Make(enemyXPosition, enemyYPosition, enemyZPosition);
        gameObject.scale = GLKVector3Make(.3f * enemyScale,.3f * enemyScale,.3f * enemyScale);
        
//        NSLog(@"Enemy Position: %f, %f", gameObject.position.x, gameObject.position.z);
        
//        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
//        _rotation += self.timeSinceLastUpdate * 0.3f;
    }
    
    //don't render the player (player model used for minimap only
//    if ([gameObject.name isEqualToString:@"player"]){
//        return;
//    }
    
    if ([gameObject.name isEqualToString:@"player"])
    {
        gameObject.position = GLKVector3Make(xMovement, 0, zMovement);
//        NSLog(@"Player Position: (%f, %f)", gameObject.position.x, gameObject.position.z);
        
        //player movement
//        zMovement += moveSpeed * cosf(xRotation);
//        xMovement += moveSpeed * -sinf(xRotation);
//        GLKMatrix4 baseModelViewMatrix2 = GLKMatrix4MakeTranslation(-xMovement, zMovement, 0);
//        baseModelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, baseModelViewMatrix2);
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
/*
Loads model vtnf arrays from the obj file, and sets up the vertex buffer, and uses the provided image for texture
Parameters:
 filename - string file name of the obj model - DON'T INCLUDE THE EXTENSION!(ie "crate" instead of "crate.obj")
 textureName - string name of the texture image file - this one should have the extension included
 */
-(VertexInfo)loadModel :(NSString*) fileName :(NSString*) textureName
{
    NSString* fileRoot = [[NSBundle mainBundle]
                          pathForResource:fileName ofType:@"obj"];
    
    NSString* fileContents =
    [NSString stringWithContentsOfFile:fileRoot
                              encoding:NSUTF8StringEncoding error:nil];
    
    // separate by new line
    NSArray* allLinedStrings =
    [fileContents componentsSeparatedByCharactersInSet:
     [NSCharacterSet newlineCharacterSet]];
    

    int tLength = 0;
    int vLength = 0;
    int nLength = 0;
    int fLength = 0;
 
    //determine the length of the vtnf arrays
    for (NSString* line in allLinedStrings) {
        if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == 't') {
            tLength+= 2;
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == 'n') {
            nLength+= 3;
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == ' ') {
            vLength+= 3;
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'f'){
            
            fLength+= 9;
        }
    }
    float vArray[vLength];
    float nArray[nLength];
    float tArray[tLength];
    int fArray[fLength];
    int tCount = 0;
    int vCount = 0;
    int nCount = 0;
    int fCount = 0;
    int i = 0;
    NSScanner *scanner;
    
    
    
    //populate the vtnf arrays with values from the obj file
    for (NSString* line in allLinedStrings) {
        scanner = [NSScanner scannerWithString:line];
        
        if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == 't') {
            [scanner scanUpToString:@" " intoString:NULL];
            
            for(i = 0; i < 2; i++){
                [scanner setScanLocation:[scanner scanLocation] + 1];
                [scanner scanFloat:&tArray[tCount]];
                tCount++;
            }
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == 'n') {
            [scanner scanUpToString:@" " intoString:NULL];
            
            for(i = 0; i < 3; i++){
                [scanner setScanLocation:[scanner scanLocation] + 1];
                [scanner scanFloat:&nArray[nCount]];
                nCount++;
            }
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == ' ') {
            [scanner scanUpToString:@" " intoString:NULL];
            
            for(i = 0; i < 3; i++){
                [scanner setScanLocation:[scanner scanLocation] + 1];
                [scanner scanFloat:&vArray[vCount]];
                vCount++;
            }

        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'f'){
            [scanner scanUpToString:@" " intoString:NULL];
            
            for(i = 0; i <9; i++){
                [scanner setScanLocation:[scanner scanLocation] + 1];
                [scanner scanInt:&fArray[fCount]];
                fCount++;
            }
        }
    }
    //build the combined vnt array based on the vertices specified in the fArray
    float mixedArray[(fLength/3)*8];
    int mCount = 0;
    vCount = 0;
    tCount = 0;
    nCount = 0;
    tCount = 0;
    for(i=0; i < fLength; i++){
        if(i%3 == 0){
            mixedArray[mCount] = vArray[(fArray[i]-1)*3];
            mCount++;
            mixedArray[mCount] = vArray[(fArray[i]-1)*3 + 1];
            mCount++;
            mixedArray[mCount] = vArray[(fArray[i]-1)*3 + 2];
            mCount++;
        }
        else if(i%3 == 2){
            mixedArray[mCount] = nArray[(fArray[i]-1)*3];
            mCount++;
            mixedArray[mCount] = nArray[(fArray[i]-1)*3 + 1];
            mCount++;
            mixedArray[mCount] = nArray[(fArray[i]-1)*3 + 2];
            mCount++;
        }
        else if(i%3 == 1){
            mixedArray[mCount] = tArray[(fArray[i]-1)*2];
            mCount++;
            mixedArray[mCount] = 1-tArray[(fArray[i]-1)*2 + 1];
            mCount++;
        }
    }
    
    VertexInfo vertexInfoStruct;
    vertexInfoStruct.length = fLength/3;
    //NSLog(@"%u", vertexInfoStruct.length);
    
    glGenVertexArraysOES(1, &vertexInfoStruct.vArray);
    glBindVertexArrayOES(vertexInfoStruct.vArray);
    
    glGenBuffers(1, &vertexInfoStruct.vBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexInfoStruct.vBuffer);

    //load array into buffer
    glBufferData(GL_ARRAY_BUFFER, sizeof(mixedArray), mixedArray, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(12));
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(20));
    
    
    glBindVertexArrayOES(0);
    
    // Load in and set texture
    vertexInfoStruct.textureHandle = [self setupTexture:textureName];
    
    return vertexInfoStruct;
    
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
