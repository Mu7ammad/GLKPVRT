//
//  ViewController.m
//  GLKPVRT
//
//  Created by Muhammad Hilal on 3/12/12.
//  Copyright (c) 2012 Pirates. All rights reserved.
//

#import "SkinningViewController.h"
#import "OGLES2Tools.h"


/******************************************************************************
 Constants
 ******************************************************************************/

// Camera constants used to generate the projection matrix
const float g_fCameraNear	= 4.0f;
const float g_fCameraFar	= 5000.0f;

const float g_fDemoFrameRate = 0.015f;

/******************************************************************************
 shader attributes
 ******************************************************************************/
// vertex attributes
enum EVertexAttrib {
	VERTEX_ARRAY, NORMAL_ARRAY, TEXCOORD_ARRAY, BONEWEIGHT_ARRAY, BONEINDEX_ARRAY, eNumAttribs };
const char* g_aszAttribNames[] = {
	"inVertex", "inNormal", "inTexCoord", "inBoneWeight", "inBoneIndex" };

// shader uniforms
enum EUniform {
	eMVPMatrix, eViewProj, eLightDirModel, eLightDirWorld, eBoneCount, eBoneMatrices, eBoneMatricesIT, eNumUniforms };
const char* g_aszUniformNames[] = {
	"MVPMatrix", "ViewProjMatrix", "LightDirModel", "LightDirWorld", "BoneCount", "BoneMatrixArray[0]", "BoneMatrixArrayIT[0]" };


/******************************************************************************
 Content file names
 ******************************************************************************/

// Source and binary shaders
const char c_szFragShaderSrcFile[]	= "FragShader2.fsh";
const char c_szFragShaderBinFile[]	= "FragShader2.fsc";
const char c_szVertShaderSrcFile[]	= "VertShader2.vsh";
const char c_szVertShaderBinFile[]	= "VertShader2.vsc";

// PVR texture files
const char c_szBodyTexFile[]		= "Body.pvr";
const char c_szLegTexFile[]			= "Legs.pvr";
const char c_szBeltTexFile[]		= "Belt.pvr";

// POD scene files
const char c_szSceneFile[]			= "man.pod";



@interface SkinningViewController () {
    
	// 3D Model
	CPVRTModelPOD	m_Scene;
    
	// Model transformation variables
	PVRTMat4	m_Transform;
	float		m_fAngle;
	float		m_fDistance;
    
	// OpenGL handles for shaders, textures and VBOs
	GLuint	m_uiVertShader;
	GLuint	m_uiFragShader;
	GLuint	m_uiBodyTex;
	GLuint	m_uiLegTex;
	GLuint	m_uiBeltTex;
	GLuint*	m_puiVbo;
	GLuint*	m_puiIndexVbo;
    
	// Group shader programs and their uniform locations together
	struct
	{
		GLuint uiId;
		GLuint auiLoc[eNumUniforms];
	}
	m_ShaderProgram;
    
	// Array to lookup the textures for each material in the scene
	GLuint*	m_puiTextures;
    
	// Variables to handle the animation in a time-based manner
	//unsigned long m_iTimePrev;
	float	m_fFrame;
    

    
}
@property (strong, nonatomic) EAGLContext *context;


-(void) initPod:(NSString*) scene;

- (void)setupGL;
- (void)tearDownGL;

-(BOOL)loadTextures;
-(BOOL)loadVBOs;
-(BOOL)loadShaders;

-(void) drawMesh:(int)nodeIndex;

/*
 - (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
 - (BOOL)linkProgram:(GLuint)prog;
 - (BOOL)validateProgram:(GLuint)prog;
 */
@end

@implementation SkinningViewController

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
    
    [self initPod:@"man_clothes"];
    [self setupGL];
}


-(BOOL)loadTextures{
        
    if(PVRTTextureLoadFromPVR(c_szBodyTexFile, &m_uiBodyTex) != PVR_SUCCESS)
	{
		NSLog(@"ERROR: Failed to load texture.");
		return NO;
	}
    
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
	if(PVRTTextureLoadFromPVR(c_szLegTexFile, &m_uiLegTex) != PVR_SUCCESS)
	{
		NSLog(@"ERROR: Failed to load texture.");
		return NO;
	}
    
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
	if(PVRTTextureLoadFromPVR(c_szBeltTexFile, &m_uiBeltTex) != PVR_SUCCESS)
	{
		NSLog(@"ERROR: Failed to load texture.");
		return NO;
	}
    
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
	return YES;
}

-(BOOL)loadVBOs{
    
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



- (BOOL)loadShaders
{
    CPVRTString ErrorStr;
    /*
     Load and compile the shaders from files.
     Binary shaders are tried first, source shaders
     are used as fallback.
     */
	if (PVRTShaderLoadFromFile(
                               c_szVertShaderBinFile, c_szVertShaderSrcFile, GL_VERTEX_SHADER, GL_SGX_BINARY_IMG, &m_uiVertShader, &ErrorStr) != PVR_SUCCESS)
	{
		return NO;
	}
    
	if (PVRTShaderLoadFromFile(
                               c_szFragShaderBinFile, c_szFragShaderSrcFile, GL_FRAGMENT_SHADER, GL_SGX_BINARY_IMG, &m_uiFragShader, &ErrorStr) != PVR_SUCCESS)
	{
		return NO;
	}
    
	/*
     Set up and link the shader program
     */
    
	if (PVRTCreateProgram(&m_ShaderProgram.uiId, m_uiVertShader, m_uiFragShader, g_aszAttribNames, eNumAttribs, &ErrorStr) != PVR_SUCCESS)
	{
		NSLog(@"Error in shader program.");
		return NO;
	}
    
	// Store the location of uniforms for later use
	for (int i = 0; i < eNumUniforms; ++i)
	{
		m_ShaderProgram.auiLoc[i] = glGetUniformLocation(m_ShaderProgram.uiId, g_aszUniformNames[i]);
	}
    
    return YES;
}



-(void) initPod:(NSString *)podScene{
    
    m_puiVbo = 0;
	m_puiIndexVbo = 0;
	    
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
    
    
	
	// Initialise variables used for the animation
	m_fFrame = 0;
	//m_iTimePrev = PVRShellGetTime();
	m_Transform = PVRTMat4::Identity();
	m_fAngle = 0.0f;
	m_fDistance = 0.0f;
    
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
    
    // Set the sampler2D uniforms to corresponding texture units
	glUniform1i(glGetUniformLocation(m_ShaderProgram.uiId, "sTexture"), 0);
    
    /*
     Set OpenGL ES render states needed
     */
	// Enable backface culling and depth test
	glCullFace(GL_BACK);
	glEnable(GL_CULL_FACE);
    
	glEnable(GL_DEPTH_TEST);
    
	// Use a nice bright blue as clear colour
	glClearColor(0.6f, 0.8f, 1.0f, 1.0f);
    
    /*
     Initialise an array to lookup the textures
     for each material in the scene.
     */
	m_puiTextures = new GLuint[m_Scene.nNumMaterial];
    
	for(unsigned int i = 0; i < m_Scene.nNumMaterial; ++i)
	{
		m_puiTextures[i] = m_uiLegTex;
        
		SPODMaterial* pMaterial = &m_Scene.pMaterial[i];
		if(strcmp(pMaterial->pszName, "Mat_body") == 0)
		{
			m_puiTextures[i] = m_uiBodyTex;
		}
		else if(strcmp(pMaterial->pszName, "Mat_legs") == 0)
		{
			m_puiTextures[i] = m_uiLegTex;
		}
		else if(strcmp(pMaterial->pszName, "Mat_belt") == 0)
		{
			m_puiTextures[i] = m_uiBeltTex;
		}
	}

}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    // Free the texture lookup array
	delete[] m_puiTextures;
    
	// Delete textures
	glDeleteTextures(1, &m_uiBodyTex);
	glDeleteTextures(1, &m_uiLegTex);
	glDeleteTextures(1, &m_uiBeltTex);
    
	// Delete program and shader objects
	glDeleteProgram(m_ShaderProgram.uiId);
    
	glDeleteShader(m_uiVertShader);
	glDeleteShader(m_uiFragShader);
    
	// Delete buffer objects
	glDeleteBuffers(m_Scene.nNumMesh, m_puiVbo);
	glDeleteBuffers(m_Scene.nNumMesh, m_puiIndexVbo);
    
    // Free the memory allocated for the scene
	m_Scene.Destroy();
    
	delete [] m_puiVbo;
	delete [] m_puiIndexVbo;
    
    /*
     glDeleteBuffers(1, &_vertexBuffer);
     glDeleteVertexArraysOES(1, &_vertexArray);
     
     self.effect = nil;
     
     if (_program) {
     glDeleteProgram(_program);
     _program = 0;
     }*/
}


- (void)update
{
    /*
     Calculates the frame number to animate in a time-based manner.
     Uses the shell function PVRShellGetTime() to get the time in milliseconds.
     */
    
    //int iTime = PVRShellGetTime();
	int iDeltaTime = self.timeSinceLastUpdate *1000; //iTime - m_iTimePrev;
	
	m_fFrame += (float)iDeltaTime * g_fDemoFrameRate;
	
    /*
     Calculates the frame number to animate in a time-based manner.
     Uses the shell function PVRShellGetTime() to get the time in milliseconds.
     */
	/*
    if(iTime > m_iTimePrev)
	{
		float fDelta = (float) (iTime - m_iTimePrev);
		m_fFrame += fDelta * g_fDemoFrameRate;
        
        
		// Modify the transformation matrix if it is needed
		bool bRebuildTransformation = false;
        
		if(PVRShellIsKeyPressed(PVRShellKeyNameRIGHT))
		{
			m_fAngle -= 0.03f;
            
			if(m_fAngle < PVRT_TWO_PIf)
				m_fAngle += PVRT_TWO_PIf;
            
			bRebuildTransformation = true;
		}
        
		if(PVRShellIsKeyPressed(PVRShellKeyNameLEFT))
		{
			m_fAngle += 0.03f;
            
			if(m_fAngle > PVRT_TWO_PIf)
				m_fAngle -= PVRT_TWO_PIf;
            
			bRebuildTransformation = true;
		}
        
		if(PVRShellIsKeyPressed(PVRShellKeyNameUP))
		{
			m_fDistance -= 10.0f;
            
			if(m_fDistance < -500.0f)
				m_fDistance = -500.0f;
            
			bRebuildTransformation = true;
		}
        
		if(PVRShellIsKeyPressed(PVRShellKeyNameDOWN))
		{
			m_fDistance += 10.0f;
            
			if(m_fDistance > 200.0f)
				m_fDistance = 200.0f;
            
			bRebuildTransformation = true;
		}
        
		if(bRebuildTransformation)
			m_Transform = PVRTMat4::Translation(0,0, m_fDistance) * PVRTMat4::RotationY(m_fAngle);
            
	}
    */
	
    
    if(m_fFrame > m_Scene.nNumFrame - 1)
		m_fFrame = 0;
    
	// Set the scene animation to the current frame
	m_Scene.SetFrame(m_fFrame);
    

}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // Clear the color and depth buffer
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
	// Use shader program
	glUseProgram(m_ShaderProgram.uiId);
	glActiveTexture(GL_TEXTURE0);
    
    
	/*
     Set up camera
     */
	PVRTVec3	vFrom, vTo, vUp(0, 1, 0);
	PVRTMat4 mView, mProjection;
	float fFOV;
    
	// We can get the camera position, target and field of view (fov) with GetCameraPos()
	fFOV = m_Scene.GetCamera(vFrom, vTo, vUp, 0);
    
	/*
     We can build the model view matrix from the camera position, target and an up vector.
     For this we use PVRTMat4::LookAtRH().
     */
	mView = PVRTMat4::LookAtRH(vFrom, vTo, vUp);
    
	// Calculate the projection matrix
	bool bRotate = 0; // PVRShellGet(prefIsRotated) && PVRShellGet(prefFullScreen);
	mProjection = PVRTMat4::PerspectiveFovRH(fFOV, (float)self.view.bounds.size.width/(float)self.view.bounds.size.height, g_fCameraNear, g_fCameraFar, PVRTMat4::OGL, bRotate);
    
	// Read the light direction from the scene
	PVRTVec4 vLightDirWorld = PVRTVec4( 0, 0, 0, 0 );
	vLightDirWorld = m_Scene.GetLightDirection(0);
	glUniform3fv(m_ShaderProgram.auiLoc[eLightDirWorld], 1, &vLightDirWorld.x);
    
	// Set up the View * Projection Matrix
	PVRTMat4 mViewProjection;
    
	mViewProjection = mProjection * mView;
	glUniformMatrix4fv(m_ShaderProgram.auiLoc[eViewProj], 1, GL_FALSE, mViewProjection.ptr());
        
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
        
		// Set up shader uniforms
		PVRTMat4 mModelViewProj;
		mModelViewProj = mViewProjection * mWorld;
		glUniformMatrix4fv(m_ShaderProgram.auiLoc[eMVPMatrix], 1, GL_FALSE, mModelViewProj.ptr());
        
		PVRTVec4 vLightDirModel;
		vLightDirModel = mWorld.inverse() * vLightDirWorld;
		glUniform3fv(m_ShaderProgram.auiLoc[eLightDirModel], 1, &vLightDirModel.x);
        
		// Loads the correct texture using our texture lookup table
		if(Node.nIdxMaterial == -1)
			glBindTexture(GL_TEXTURE_2D, 0); // It has no pMaterial defined. Use blank texture (0)
		else
			glBindTexture(GL_TEXTURE_2D, m_puiTextures[Node.nIdxMaterial]);
        
		
		/*
         Now that the model-view matrix is set and the materials ready,
         call another function to actually draw the mesh.
         */
		[self drawMesh:i];
	}
    
}


-(void)drawMesh:(int)nodeIndex{
    
    SPODNode& Node = m_Scene.pNode[nodeIndex];
	SPODMesh& Mesh = m_Scene.pMesh[Node.nIdx];
    
	// bind the VBO for the mesh
	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[Node.nIdx]);
	// bind the index buffer, won't hurt if the handle is 0
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[Node.nIdx]);
    
	// Enable the vertex attribute arrays
	glEnableVertexAttribArray(VERTEX_ARRAY);
	glEnableVertexAttribArray(NORMAL_ARRAY);
	glEnableVertexAttribArray(TEXCOORD_ARRAY);
    
	// Set the vertex attribute offsets
	glVertexAttribPointer(VERTEX_ARRAY, 3, GL_FLOAT, GL_FALSE, Mesh.sVertex.nStride,  Mesh.sVertex.pData);
	glVertexAttribPointer(NORMAL_ARRAY, 3, GL_FLOAT, GL_FALSE, Mesh.sNormals.nStride, Mesh.sNormals.pData);
	glVertexAttribPointer(TEXCOORD_ARRAY, 2, GL_FLOAT, GL_FALSE, Mesh.psUVW[0].nStride, Mesh.psUVW[0].pData);
    
	/*
     If the current mesh has bone index and weight data then we need to
     set up some additional variables in the shaders.
     */
	if(Mesh.sBoneIdx.n && Mesh.sBoneWeight.n)
	{
		glEnableVertexAttribArray(BONEINDEX_ARRAY);
		glEnableVertexAttribArray(BONEWEIGHT_ARRAY);
        
		glVertexAttribPointer(BONEINDEX_ARRAY, Mesh.sBoneIdx.n, GL_UNSIGNED_BYTE, GL_FALSE, Mesh.sBoneIdx.nStride, Mesh.sBoneIdx.pData);
		glVertexAttribPointer(BONEWEIGHT_ARRAY, Mesh.sBoneWeight.n, GL_UNSIGNED_BYTE, GL_TRUE, Mesh.sBoneWeight.nStride, Mesh.sBoneWeight.pData);
        
		/*
         There is a limit to the number of bone matrices that you can pass to the shader so we have
         chosen to limit the number of bone matrices that affect a mesh to 8. However, this does
         not mean our character can only have a skeleton consisting of 8 bones. We can get around
         this by using bone batching where the character is split up into sub-meshes that are only
         affected by a sub set of the overal skeleton. This is why we have this for loop that
         iterates through the bone batches contained with the SPODMesh.
         */
		for (int i32Batch = 0; i32Batch < Mesh.sBoneBatches.nBatchCnt; ++i32Batch)
		{
			// Set the number of bones that will influence each vertex in the mesh
			glUniform1i(m_ShaderProgram.auiLoc[eBoneCount], Mesh.sBoneIdx.n);
            
			// Go through the bones for the current bone batch
			PVRTMat4 amBoneWorld[8];
			PVRTMat3 afBoneWorldIT[8], mBoneIT;
            
			int i32Count = Mesh.sBoneBatches.pnBatchBoneCnt[i32Batch];
            
			for(int i = 0; i < i32Count; ++i)
			{
				// Get the Node of the bone
				int i32NodeID = Mesh.sBoneBatches.pnBatches[i32Batch * Mesh.sBoneBatches.nBatchBoneMax + i];
                
				// Get the World transformation matrix for this bone and combine it with our app defined
				// transformation matrix
				amBoneWorld[i] = m_Transform * m_Scene.GetBoneWorldMatrix(Node, m_Scene.pNode[i32NodeID]);
                
				// Calculate the inverse transpose of the 3x3 rotation/scale part for correct lighting
				afBoneWorldIT[i] = PVRTMat3(amBoneWorld[i]).inverse().transpose();
			}
            
			glUniformMatrix4fv(m_ShaderProgram.auiLoc[eBoneMatrices], i32Count, GL_FALSE, amBoneWorld[0].ptr());
			glUniformMatrix3fv(m_ShaderProgram.auiLoc[eBoneMatricesIT], i32Count, GL_FALSE, afBoneWorldIT[0].ptr());
            
			/*
             As we are using bone batching we don't want to draw all the faces contained within pMesh, we only want
             to draw the ones that are in the current batch. To do this we pass to the drawMesh function the offset
             to the start of the current batch of triangles (Mesh.sBoneBatches.pnBatchOffset[i32Batch]) and the
             total number of triangles to draw (i32Tris)
             */
			int i32Tris;
			if(i32Batch+1 < Mesh.sBoneBatches.nBatchCnt)
				i32Tris = Mesh.sBoneBatches.pnBatchOffset[i32Batch+1] - Mesh.sBoneBatches.pnBatchOffset[i32Batch];
			else
				i32Tris = Mesh.nNumFaces - Mesh.sBoneBatches.pnBatchOffset[i32Batch];
            
			// Draw the mesh
			glDrawElements(GL_TRIANGLES, i32Tris * 3, GL_UNSIGNED_SHORT, &((unsigned short*)0)[3 * Mesh.sBoneBatches.pnBatchOffset[i32Batch]]);
		}
        
		glDisableVertexAttribArray(BONEINDEX_ARRAY);
		glDisableVertexAttribArray(BONEWEIGHT_ARRAY);
	}
	else
	{
		glUniform1i(m_ShaderProgram.auiLoc[eBoneCount], 0);
		glDrawElements(GL_TRIANGLES, Mesh.nNumFaces*3, GL_UNSIGNED_SHORT, 0);
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


@end
