#import "Fluids.h"

@implementation Fluids

-(void)initPlugin{
    [[self addPropF:@"controlDrawMode"] setMinValue:0 maxValue:3];
}

//
//----------------
//


-(void)setup{
    fluids = new FluidSolver();
    fluids->setup();
    
    fluidsDrawer = new FluidDrawerGl();
    fluidsDrawer->setup(fluids);
}

//
//----------------
//


-(void)update:(NSDictionary *)drawingInformation{
    fluids->update();
    
    Color c(MSA::CM_HSV, ( ofGetElapsedTimeMillis() % 360 ) / 360.0f, 1, 1 );
    fluids->addColorAtPos(Vec2f(0.5,0.5), c);
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
        
        fluids->addForceAtPos(pos, _d);
        
        lastControlMouse = pos;
    }
}

-(void)controlMouseReleased:(float)x y:(float)y{
    lastControlMouse.x = -1;
}

@end
