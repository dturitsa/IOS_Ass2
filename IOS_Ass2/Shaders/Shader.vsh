//
//  Shader.vsh
//  IOS_Ass2
//
//  Created by Denis Turitsa on 2017-03-05.
//  Copyright © 2017 Denis Turitsa. All rights reserved.
//

precision mediump float;

attribute vec4 position;
attribute vec3 normal;
attribute vec2 texCoordIn;

varying vec3 eyeNormal;
varying vec4 eyePos;
varying vec2 texCoordOut;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;

void main()
{
    // Calculate normal vector in eye coordinates
    eyeNormal = normalize(normalMatrix * normal);
    
    // Calculate vertex position in view coordinates
    eyePos = modelViewMatrix * position;
    
    // Pass through texture coordinate
    texCoordOut = texCoordIn;
    
    // Set gl_Position with transformed vertex position
    gl_Position = modelViewProjectionMatrix * position;
}
