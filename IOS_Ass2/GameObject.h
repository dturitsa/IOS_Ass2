//
//  GameObject.h
//  IOS_Ass2
//
//  Created by Denis Turitsa on 2017-03-05.
//  Copyright © 2017 Denis Turitsa. All rights reserved.
//

#ifndef GameObject_h
#define GameObject_h
#import <GLKit/GLKit.h>
//#import "GOTypes.h"

@interface GameObject : NSObject

typedef struct
{
    GLuint vArray; //pointer to vertex array
    GLuint vBuffer; //pointer to vertex buffer
    int   length; //# of vertices
    GLuint textureHandle;//the texture of the object
    
} VertexInfo;

@property GLKVector3 position;
@property GLKVector3 rotation;
@property GLKVector3 modelRotation;
@property GLKVector3 scale;

@property NSString* modelName;
@property NSString* name;
@property VertexInfo modelHandle;

@property NSString* textureName;

//collision detection
@property float length;
@property float width;
@property float speed;

-(bool)checkCollisionBetweenObject:(GameObject *)one and:(GameObject *)two; //MICHAEL'S Collision function declaration
-(void)onCollision:(GameObject*)otherObject;

@end



#endif /* GameObject_h */
