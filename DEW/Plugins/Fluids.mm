#import "Fluids.h"

@implementation Fluids

-(void)initPlugin{
}

//
//----------------
//


-(void)setup{
    img = new ofImage();
    img->loadImage("/Users/admin/Documents/DEW/Dropbox/Photos/Sample Album/Costa Rican Frog.jpg");
}

//
//----------------
//


-(void)update:(NSDictionary *)drawingInformation{
}

//
//----------------
//

-(void)draw:(NSDictionary *)drawingInformation{
    img->draw(sin(ofGetElapsedTimeMillis()/1000.0) ,0,1,1);
}

//
//----------------
//

-(void)controlDraw:(NSDictionary *)drawingInformation{    
}

@end
