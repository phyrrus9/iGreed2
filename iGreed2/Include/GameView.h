//
//  GameViewViewController.h
//  iGreed2
//
//  Created by phyrrus9 on 2/9/18.
//  Copyright © 2018 Ipseity. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GameView : UIViewController

@end

#define XSIZE 40
#define YSIZE 26
#define WINPERCENT 25

enum direction
{
	kDIR_W = 0x1,
	kDIR_A = 0x2,
	kDIR_S = 0x4,
	kDIR_D = 0x8,
};

extern char map[XSIZE][YSIZE];
extern NSUInteger player_x, player_y;
