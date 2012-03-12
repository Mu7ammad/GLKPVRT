//
//  Shader.fsh
//  GLKPVRT
//
//  Created by Muhammad Hilal on 3/12/12.
//  Copyright (c) 2012 Pirates. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
