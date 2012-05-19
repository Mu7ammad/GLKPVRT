//
//  ViewController.m
//  GLKPVRT
//
//  Created by Muhammad Hilal on 3/12/12.
//  Copyright (c) 2012 Pirates. All rights reserved.
//

#import "ViewController.h"
#import "OGLES2Tools.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

/*
// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];
*/

// Index to bind the attributes to vertex shaders
#define VERTEX_ARRAY	0
#define NORMAL_ARRAY	1
#define TEXCOORD_ARRAY	2

/*
// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};*/

// Camera constants. Used for making the projection matrix
const float g_fCameraNear = 4.0f;
const float g_fCameraFar  = 5000.0f;

const float g_fDemoFrameRate = 1.0f / 30.0f;

// The camera to use from the pod file
const int g_ui32Camera = 0;


// Variables to handle the animation in a time-based manner

float			m_fFrame;

/*
GLfloat gCubeVertexData[216] = 
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
    
    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,
    
    -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,
    
    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,
    
    0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,
    
    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f
};
*/
// Source and binary shaders
const char c_szFragShaderSrcFile[]	= "FragShader.fsh";
const char c_szFragShaderBinFile[]	= "FragShader.fsc";
const char c_szVertShaderSrcFile[]	= "VertShader.vsh";
const char c_szVertShaderBinFile[]	= "VertShader.vsc";

@interface IntroPodViewController () {
    //GLuint _program;
    
    //GLKMatrix4 _modelViewProjectionMatrix;
    ////GLKMatrix3 _normalMatrix;
    //float _rotation;
    
    //GLuint _vertexArray;
    //GLuint _vertexBuffer;
    
    // 3D Model
	CPVRTModelPOD	m_Scene;
    
    // OpenGL handles for shaders, textures and VBOs
	GLuint m_uiVertShader;
	GLuint m_uiFragShader;
	GLuint* m_puiVbo;
	GLuint* m_puiIndexVbo;
	GLuint* m_puiTextureIDs;
    
	// Group shader programs and their uniform locations together
	struct
	{
		GLuint uiId;
		GLuint uiMVPMatrixLoc;
		GLuint uiLightDirLoc;
	}
	m_ShaderProgram;
    
}
@property (strong, nonatomic) EAGLContext *context;


-(void) initPod:(NSString*) scene;

- (void)setupGL;
- (void)tearDownGL;

-(BOOL) loadTextures;
-(BOOL) loadVBOs;
-(BOOL)loadShaders;
-(void) drawMesh:(int)nodeIndex;

/*
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
*/
@end

@implementation IntroPodViewController

@synthesize context = _context;


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
    
    [self initPod:@"test"];
    [self setupGL];
}


-(BOOL)loadTextures{
    /*
     Loads the textures.
     For a more detailed explanation, see Texturing and IntroducingPVRTools
     */
    
	/*
     Initialises an array to lookup the textures
     for each material in the scene.
     */
	m_puiTextureIDs = new GLuint[m_Scene.nNumMaterial];
    
	if(!m_puiTextureIDs)
	{
		NSLog(@"ERROR: Insufficient memory.");
        return NO;
	}
    
	for(int i = 0; i < (int) m_Scene.nNumMaterial; ++i)
	{
		m_puiTextureIDs[i] = 0;
		SPODMaterial* pMaterial = &m_Scene.pMaterial[i];
        
		if(pMaterial->nIdxTexDiffuse != -1)
		{
			/*
             Using the tools function PVRTTextureLoadFromPVR load the textures required by the pod file.
             
             Note: This function only loads .pvr files. You can set the textures in 3D Studio Max to .pvr
             files using the PVRTexTool plug-in for max. Alternatively, the pod material properties can be
             modified in PVRShaman.
             */
            
			CPVRTString sTextureName = m_Scene.pTexture[pMaterial->nIdxTexDiffuse].pszName;
            
			if(PVRTTextureLoadFromPVR(sTextureName.c_str(), &m_puiTextureIDs[i]) != PVR_SUCCESS)
			{
				
                NSLog(@"ERROR: Failed to load a Texture.");
                
				// Check to see if we're trying to load .pvr or not
				CPVRTString sFileExtension = PVRTStringGetFileExtension(sTextureName);
                
				if(sFileExtension.toLower() != "pvr")
					NSLog(@"Note: IntroducingPOD can only load pvr files.");
                return NO;
                
			}
		}
	}
    return YES;
}

-(BOOL)loadVBOs{
    
    if(!m_Scene.pMesh[0].pInterleaved)
	{
		NSLog(@"ERROR: IntroducingPOD requires the pod data to be interleaved. Please re-export with the interleaved option enabled.");
        return NO;
	}
    
	if (!m_puiVbo)      m_puiVbo = new GLuint[m_Scene.nNumMesh];
	if (!m_puiIndexVbo) m_puiIndexVbo = new GLuint[m_Scene.nNumMesh];
    
	/*
     Load vertex data of all meshes in the scene into VBOs
     
     The meshes have been exported with the "Interleave Vectors" option,
     so all data is interleaved in the buffer at pMesh->pInterleaved.
     Interleaving data improves the memory access pattern and cache efficiency,
     thus it can be read faster by the hardware.
     */
	glGenBuffers(m_Scene.nNumMesh, m_puiVbo);
	for (unsigned int i = 0; i < m_Scene.nNumMesh; ++i)
	{
		// Load vertex data into buffer object
		SPODMesh& Mesh = m_Scene.pMesh[i];
		unsigned int uiSize = Mesh.nNumVertex * Mesh.sVertex.nStride;
		glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[i]);
		glBufferData(GL_ARRAY_BUFFER, uiSize, Mesh.pInterleaved, GL_STATIC_DRAW);
        
		// Load index data into buffer object if available
		m_puiIndexVbo[i] = 0;
		if (Mesh.sFaces.pData)
		{
			glGenBuffers(1, &m_puiIndexVbo[i]);
			uiSize = PVRTModelPODCountIndices(Mesh) * sizeof(GLshort);
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[i]);
			glBufferData(GL_ELEMENT_ARRAY_BUFFER, uiSize, Mesh.sFaces.pData, GL_STATIC_DRAW);
		}
	}
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    return YES;

}


-(void) initPod:(NSString *)podScene{
    
    m_puiVbo = 0;
	m_puiIndexVbo = 0;
	m_puiTextureIDs = 0;
    
    // Get and set the read path for content files
	NSString* readPath = [NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] bundlePath], @"/"];
    
    CPVRTResourceFile::SetReadPath([readPath UTF8String]);
    
    // Load the scene
    
	if(m_Scene.ReadFromFile([[podScene stringByAppendingPathExtension:@"pod"]UTF8String]) != PVR_SUCCESS)
	{
		NSLog(@"ERROR: Couldn't load the .pod file\n");
		
	}
    
	// The cameras are stored in the file. We check it contains at least one.
	if(m_Scene.nNumCamera == 0)
	{
        NSLog(@"ERROR: The scene does not contain a camera. Please add one and re-export.\n");
		
	}
    
	// We also check that the scene contains at least one light
	if(m_Scene.nNumLight == 0)
	{
		NSLog(@"ERROR: The scene does not contain a light. Please add one and re-export.\n");
		
	}
    
    
	// Initialize variables used for the animation
	m_fFrame = 0;
	    
}


- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    /*
     Initialize VBO data
     */
	if(![self loadVBOs])
	{
		NSLog(@"Error loading VBOs");
		
	}
    
	/*
     Load textures
     */
	if(![self loadTextures])
	{
        NSLog(@"Error loading Textures");
	}
    
	/*
     Load and compile the shaders & link programs
     */
	if(![self loadShaders])
	{
        NSLog(@"Error loading Shaders");
	}
    
    /*
     Set OpenGL ES render states needed for this training course
     */
	// Enable backface culling and depth test
	glCullFace(GL_BACK);
	glEnable(GL_CULL_FACE);
    
	glEnable(GL_DEPTH_TEST);
    
	// Use a nice bright blue as clear colour
	glClearColor(0.6f, 0.8f, 1.0f, 1.0f);
    
    
    /*
    [self loadShaders];
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
     */
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    
    // Free the memory allocated for the scene
	m_Scene.Destroy();
    
	delete[] m_puiVbo;
	delete[] m_puiIndexVbo;
    
    /*
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }*/
}

-(void)drawMesh:(int)nodeIndex{
    
    int i32MeshIndex = m_Scene.pNode[nodeIndex].nIdx;
	SPODMesh* pMesh = &m_Scene.pMesh[nodeIndex];
    
	// bind the VBO for the mesh
	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[nodeIndex]);
	// bind the index buffer, won't hurt if the handle is 0
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[i32MeshIndex]);
    
	// Enable the vertex attribute arrays
	glEnableVertexAttribArray(VERTEX_ARRAY);
	glEnableVertexAttribArray(NORMAL_ARRAY);
	glEnableVertexAttribArray(TEXCOORD_ARRAY);
    
	// Set the vertex attribute offsets
	glVertexAttribPointer(VERTEX_ARRAY, 3, GL_FLOAT, GL_FALSE, pMesh->sVertex.nStride, pMesh->sVertex.pData);
	glVertexAttribPointer(NORMAL_ARRAY, 3, GL_FLOAT, GL_FALSE, pMesh->sNormals.nStride, pMesh->sNormals.pData);
	glVertexAttribPointer(TEXCOORD_ARRAY, 2, GL_FLOAT, GL_FALSE, pMesh->psUVW[0].nStride, pMesh->psUVW[0].pData);
    
	/*
     The geometry can be exported in 4 ways:
     - Indexed Triangle list
     - Non-Indexed Triangle list
     - Indexed Triangle strips
     - Non-Indexed Triangle strips
     */
	if(pMesh->nNumStrips == 0)
	{
		if(m_puiIndexVbo[i32MeshIndex])
		{
			// Indexed Triangle list
			glDrawElements(GL_TRIANGLES, pMesh->nNumFaces*3, GL_UNSIGNED_SHORT, 0);
		}
		else
		{
			// Non-Indexed Triangle list
			glDrawArrays(GL_TRIANGLES, 0, pMesh->nNumFaces*3);
		}
	}
	else
	{
		int offset = 0;
        
		for(int i = 0; i < (int)pMesh->nNumStrips; ++i)
		{
			if(m_puiIndexVbo[i32MeshIndex])
			{
				// Indexed Triangle strips
				glDrawElements(GL_TRIANGLE_STRIP, pMesh->pnStripLength[i]+2, GL_UNSIGNED_SHORT, &((GLshort*)0)[offset]);
			}
			else
			{
				// Non-Indexed Triangle strips
				glDrawArrays(GL_TRIANGLE_STRIP, offset, pMesh->pnStripLength[i]+2);
			}
			offset += pMesh->pnStripLength[i]+2;
		}
	}
    
	// Safely disable the vertex attribute arrays
	glDisableVertexAttribArray(VERTEX_ARRAY);
	glDisableVertexAttribArray(NORMAL_ARRAY);
	glDisableVertexAttribArray(TEXCOORD_ARRAY);
    
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}


- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}



#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    /*
     Calculates the frame number to animate in a time-based manner.
     Uses the shell function PVRShellGetTime() to get the time in milliseconds.
     */

    //int iTime = PVRShellGetTime();
	int iDeltaTime = self.timeSinceLastUpdate *1000; //iTime - m_iTimePrev;
	
	m_fFrame += (float)iDeltaTime * g_fDemoFrameRate;
	if (m_fFrame > m_Scene.nNumFrame - 1) m_fFrame = 0;
    
    // Sets the scene animation to this frame
	m_Scene.SetFrame(m_fFrame);
	
    
    /*
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    // Compute the model view matrix for the object rendered with ES2
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    _rotation += self.timeSinceLastUpdate * 0.5f;*/
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // Clear the color and depth buffer
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
	// Use shader program
	glUseProgram(m_ShaderProgram.uiId);
    
    /*
     Get the direction of the first light from the scene.
     */
	PVRTVec4 vLightDirection;
	vLightDirection = m_Scene.GetLightDirection(0);
	// For direction vectors, w should be 0
	vLightDirection.w = 0.0f;
    
	/*
     Set up the view and projection matrices from the camera
     */
	PVRTMat4 mView, mProjection;
	PVRTVec3	vFrom, vTo(0.0f), vUp(0.0f, 1.0f, 0.0f);
	float fFOV;
    
	// Setup the camera
    
	// Camera nodes are after the mesh and light nodes in the array
	int i32CamID = m_Scene.pNode[m_Scene.nNumMeshNode + m_Scene.nNumLight + g_ui32Camera].nIdx;
    
	// Get the camera position, target and field of view (fov)
	if(m_Scene.pCamera[i32CamID].nIdxTarget != -1) // Does the camera have a target?
		fFOV = m_Scene.GetCameraPos( vFrom, vTo, g_ui32Camera); // vTo is taken from the target node
	else
		fFOV = m_Scene.GetCamera( vFrom, vTo, vUp, g_ui32Camera); // vTo is calculated from the rotation
    
	// We can build the model view matrix from the camera position, target and an up vector.
	// For this we usePVRTMat4LookAtRH()
	mView = PVRTMat4::LookAtRH(vFrom, vTo, vUp);
    
	// Calculate the projection matrix
	bool bRotate =0;  /*PVRShellGet(prefIsRotated) && PVRShellGet(prefFullScreen);*/
	mProjection = PVRTMat4::PerspectiveFovRH(fFOV, (float)self.view.bounds.size.width/*PVRShellGet(prefWidth)*//self.view.bounds.size.height/*(float)PVRShellGet(prefHeight)*/, g_fCameraNear, g_fCameraFar, PVRTMat4::OGL, bRotate);
    
	/*
     A scene is composed of nodes. There are 3 types of nodes:
     - MeshNodes :
     references a mesh in the pMesh[].
     These nodes are at the beginning of the pNode[] array.
     And there are nNumMeshNode number of them.
     This way the .pod format can instantiate several times the same mesh
     with different attributes.
     - lights
     - cameras
     To draw a scene, you must go through all the MeshNodes and draw the referenced meshes.
     */
   
    
	for (unsigned int i = 0; i < m_Scene.nNumMeshNode; ++i)
	{
		SPODNode& Node = m_Scene.pNode[i];
        
		// Get the node model matrix
		PVRTMat4 mWorld;
		mWorld = m_Scene.GetWorldMatrix(Node);
        
		// Pass the model-view-projection matrix (MVP) to the shader to transform the vertices
		PVRTMat4 mModelView, mMVP;
		mModelView = mView * mWorld;
		mMVP = mProjection * mModelView;
		glUniformMatrix4fv(m_ShaderProgram.uiMVPMatrixLoc, 1, GL_FALSE, mMVP.f);
        
		// Pass the light direction in model space to the shader
		PVRTVec4 vLightDir;
		vLightDir = mWorld.inverse() * vLightDirection;
        
		PVRTVec3 vLightDirModel = *(PVRTVec3*)&vLightDir;
		vLightDirModel.normalize();
        
		glUniform3fv(m_ShaderProgram.uiLightDirLoc, 1, &vLightDirModel.x);
        
		// Load the correct texture using our texture lookup table
		GLuint uiTex = 0;
        
		if(Node.nIdxMaterial != -1)
			uiTex = m_puiTextureIDs[Node.nIdxMaterial];
        
		glBindTexture(GL_TEXTURE_2D, uiTex);
        
		/*
         Now that the model-view matrix is set and the materials ready,
         call another function to actually draw the mesh.
         */
		[self drawMesh:i];
	}
    
    
    /*
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object with GLKit
    [self.effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
     */
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
   /* GLuint vertShader, fragShader;
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
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_NORMAL, "normal");
    
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
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    */
    
    /*
     Load and compile the shaders from files.
     Binary shaders are tried first, source shaders
     are used as fallback.
     */
    
    CPVRTString ErrorStr;
    
	if(PVRTShaderLoadFromFile(
                              c_szVertShaderBinFile, c_szVertShaderSrcFile, GL_VERTEX_SHADER, GL_SGX_BINARY_IMG, &m_uiVertShader, 
                              &ErrorStr) != PVR_SUCCESS)
	{
		return false;
	}
    
	if (PVRTShaderLoadFromFile(
                               c_szFragShaderBinFile, c_szFragShaderSrcFile, GL_FRAGMENT_SHADER, GL_SGX_BINARY_IMG, &m_uiFragShader, &ErrorStr) != PVR_SUCCESS)
	{
		return false;
	}
    
	/*
     Set up and link the shader program
     */
	const char* aszAttribs[] = { "inVertex", "inNormal", "inTexCoord" };
    
	if(PVRTCreateProgram(
                         &m_ShaderProgram.uiId, m_uiVertShader, m_uiFragShader, aszAttribs, 3, &ErrorStr) != PVR_SUCCESS)
	{
		NSLog(@"Error in shader program");
		return NO;
	}
	// Set the sampler2D variable to the first texture unit
	glUniform1i(glGetUniformLocation(m_ShaderProgram.uiId, "sTexture"), 0);
    
	// Store the location of uniforms for later use
	m_ShaderProgram.uiMVPMatrixLoc	= glGetUniformLocation(m_ShaderProgram.uiId, "MVPMatrix");
	m_ShaderProgram.uiLightDirLoc	= glGetUniformLocation(m_ShaderProgram.uiId, "LightDirection");
    

    return YES;
}

/*
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
*/

@end
