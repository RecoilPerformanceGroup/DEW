#import "Fluids.h"

@implementation Fluids
@synthesize controlMouseColor;
@synthesize controlMouseColorEnabled;
@synthesize controlMouseForceEnabled;
@synthesize controlMouseForce;

-(void)initPlugin{
    [[self addPropF:@"controlDrawMode"] setMinValue:0 maxValue:3];
    
    [[self addPropF:@"fluidsDeltaT"] setMinValue:0 maxValue:0.1];
    [[self addPropF:@"fluidsFadeSpeed"] setMinValue:0 maxValue:0.1];
    [[self addPropF:@"fluidsSolverIterations"] setMinValue:1 maxValue:50];
    [[self addPropF:@"fluidsVisc"] setMaxValue:0.0002f];
    [self addPropB:@"fluidsReset"];
    
    [self addPropF:@"globalForce"];
    [[self addPropF:@"globalForceRotation"] setMaxValue:360];
    
}

//
//----------------
//


-(void)setup{
    fluids = new FluidSolver();
    fluids->setup(200,100);
    fluids->enableRGB(YES);

    
    fluidsDrawer = new FluidDrawerGl();
    fluidsDrawer->setup(fluids);
    
    lastControlMouse.x = -1;

}

-(void)awakeFromNib{
}

//
//----------------
//


-(void)update:(NSDictionary *)drawingInformation{
    if(PropB(@"fluidsReset")){
        SetPropB(@"fluidsReset", 0);
        fluids->reset(); 
    }
    
    CachePropF(globalForce);
    if(globalForce){
//        NSLog(@"%f %f",fluids->uv[10].x, fluids->uv[10].y);
        CachePropF(globalForceRotation);
        Vec2f f = Vec2f(0,globalForce*0.001);
        f.rotate(globalForceRotation*DEG_TO_RAD);
        for(int i=0;i<fluids->getNumCells();i++){
            fluids->uv[i] += f;
        }
    }
    
    fluids->setDeltaT(PropF(@"fluidsDeltaT"));
    fluids->setFadeSpeed(PropF(@"fluidsFadeSpeed"));
    fluids->setSolverIterations(PropI(@"fluidsSolverIterations"));
    fluids->setVisc(PropF(@"fluidsVisc"));
    fluids->update();
    
    if([[self controlMouseColorEnabled] state] && lastControlMouse.x != -1){
        NSColor * color = [[self controlMouseColor] color];
        Color c(MSA::CM_RGB,  [color redComponent], [color greenComponent], [color blueComponent] );
        fluids->addColorAtPos(Vec2f([self controlMouseX]/[[self controlGlView] frame].size.width, [self controlMouseY]/[[self controlGlView] frame].size.height), c*[color alphaComponent]*100.0);
    }
}

//
//----------------
//

-(void)draw:(NSDictionary *)drawingInformation{
    fluidsDrawer->setDrawMode(kFluidDrawColor);
    fluidsDrawer->draw(0,0,1,1);
}

//
//----------------
//

-(void)controlDraw:(NSDictionary *)drawingInformation{    
    ofBackground(0, 0, 0);
    fluidsDrawer->setDrawMode((FluidDrawMode)PropI(@"controlDrawMode"));
    fluidsDrawer->draw(0,0,ofGetWidth(),ofGetHeight());
}

-(void)controlMouseDragged:(float)x y:(float)y button:(int)button{
        Vec2f pos = Vec2f((float)x/[[self controlGlView] frame].size.width, (float)y/[[self controlGlView] frame].size.height);
    if(lastControlMouse.x == -1){
        lastControlMouse = pos;
    } else {
        Vec2f _d = pos - lastControlMouse;
        
        if([[self controlMouseForceEnabled] state]){
            fluids->addForceAtPos(pos, _d * [[self controlMouseForce] floatValue]);
        }
        
        lastControlMouse = pos;
    }
}

-(void)controlMouseReleased:(float)x y:(float)y{
    lastControlMouse.x = -1;
}

@end
