//
//  Shader.fsh
//  IOS_Ass2
//
//  Created by Denis Turitsa on 2017-03-05.
//  Copyright © 2017 Denis Turitsa. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
