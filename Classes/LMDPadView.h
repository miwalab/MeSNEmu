//
//  LMDPadView.h
//  MeSNEmu
//
//  Created by Lucas Menge on 1/4/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMDPadView : UIButton
{
  UIImage* _portraitImage;
  UIImage* _landscapeImage;
}

- (void)portrait;
- (void)landscape;

@end
