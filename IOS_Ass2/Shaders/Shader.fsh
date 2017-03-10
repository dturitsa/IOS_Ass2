//
//  Shader.fsh
//  IOS_Ass2
//
//  Created by Denis Turitsa on 2017-03-05.
//  Copyright © 2017 Denis Turitsa. All rights reserved.
//
/*
 //default shader
varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
*/
//new shader:
precision mediump float;

varying vec3 eyeNormal;
varying vec4 eyePos;
varying vec2 texCoordOut;
/* set up a uniform sampler2D to get texture */
uniform sampler2D texture;

/* set up uniforms for lighting parameters */
uniform vec3 flashlightPosition;
uniform vec3 diffuseLightPosition;
uniform vec4 diffuseComponent;
uniform float shininess;
uniform vec4 specularComponent;
uniform vec4 ambientComponent;

void main()
{
    vec4 ambient = ambientComponent;
    vec3 N = normalize(-eyeNormal);
    float nDotVP = max(0.0, dot(N, normalize(diffuseLightPosition)));
    vec4 diffuse = diffuseComponent * nDotVP;
    
    vec3 E = normalize(-eyePos.xyz);
    vec3 L = normalize(flashlightPosition - eyePos.xyz);
    vec3 H = normalize(L+E);
    float Ks = pow(max(dot(N, H), 0.0), shininess);
    vec4 specular = Ks*specularComponent;
    
    
    if( dot(L, N) < 0.0 ) {
        specular = vec4(0.0, 0.0, 0.0, 1.0);
    }
    
    //vec4 fog = vec4(0.5, 0.5, 0.5, 1.0);
    
    gl_FragColor = (ambient + diffuse + specular) * texture2D(texture, texCoordOut);
    gl_FragColor.a = 1.0;
}
