//
//  GameViewViewController.m
//  iGreed2
//
//  Created by phyrrus9 on 2/9/18.
//  Copyright © 2018 Ipseity. All rights reserved.
//

#import "GameView.h"
#import "ScoresView.h"
#import "OptionsView.h"
#import "util.h"

NSUInteger XSIZE;
NSUInteger YSIZE;
struct preference gamePrefs;

@interface GameView ()
@property (weak, nonatomic) IBOutlet UITextView *textView_gameBoard;
@property (weak, nonatomic) IBOutlet UIButton *button_moveW;
@property (weak, nonatomic) IBOutlet UIButton *button_moveA;
@property (weak, nonatomic) IBOutlet UIButton *button_moveS;
@property (weak, nonatomic) IBOutlet UIButton *button_moveD;
@property (weak, nonatomic) IBOutlet UIButton *button_moveWA;
@property (weak, nonatomic) IBOutlet UIButton *button_moveWD;
@property (weak, nonatomic) IBOutlet UIButton *button_moveSA;
@property (weak, nonatomic) IBOutlet UIButton *button_moveSD;
@property (weak, nonatomic) IBOutlet UIButton *button_levelUp;
@property (weak, nonatomic) IBOutlet UIButton *button_restart;
@property (weak, nonatomic) IBOutlet UIButton *button_endGame;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segment_possibleMoves;
@property (weak, nonatomic) IBOutlet UILabel *label_score;
@property (weak, nonatomic) IBOutlet UILabel *label_points;
@property (weak, nonatomic) IBOutlet UILabel *label_level;
@end

@implementation GameView

char **map;
NSUInteger player_x, player_y;
NSUInteger player_level, player_level_removed, player_level_cleared, player_points, player_moves, highest;
BOOL highlightPaths = NO;
BOOL gameOver = NO;
BOOL Level_Reset = YES; // this gets set to normal state during viewDidLoad->userRestart
struct gameUI_device gUIDeviceDetails; // used to set up UI objects
struct clist_node *harden; // list of hardened coords

- (void)viewWillAppear:(BOOL)animated
{
	// set up gamepad
	struct gameUI_item details;
	struct gameUI_device d = gUIDeviceDetails;
	details = gUIGetButton(0);				[[self button_levelUp] setFrame:CGRectMake(details.x, details.y, details.w, details.h)]; // up
	details = gUIGetButton(kDIR_N);			[[self button_moveW  ] setFrame:CGRectMake(details.x, details.y, details.w, details.h)]; // up
	details = gUIGetButton(kDIR_S);			[[self button_moveS  ] setFrame:CGRectMake(details.x, details.y, details.w, details.h)]; // down
	details = gUIGetButton(kDIR_E);			[[self button_moveD  ] setFrame:CGRectMake(details.x, details.y, details.w, details.h)]; // right
	details = gUIGetButton(kDIR_W);			[[self button_moveA  ] setFrame:CGRectMake(details.x, details.y, details.w, details.h)]; // left
	details = gUIGetButton(kDIR_N | kDIR_W);	[[self button_moveWA ] setFrame:CGRectMake(details.x, details.y, details.w, details.h)]; // up left
	details = gUIGetButton(kDIR_N | kDIR_E);	[[self button_moveWD ] setFrame:CGRectMake(details.x, details.y, details.w, details.h)]; // up right
	details = gUIGetButton(kDIR_S | kDIR_W);	[[self button_moveSA ] setFrame:CGRectMake(details.x, details.y, details.w, details.h)]; // down left
	details = gUIGetButton(kDIR_S | kDIR_E);	[[self button_moveSD ] setFrame:CGRectMake(details.x, details.y, details.w, details.h)]; // down right
	// set up game view and buttons
	[[self textView_gameBoard]	setFrame:CGRectMake(	d.map.x,		d.map.y,		d.map.w,		d.map.h		)]; // game board
	[[self button_restart]		setFrame:CGRectMake(	d.restart.x,	d.restart.y,	d.restart.w,	d.restart.h	)]; // restart btn
	[[self segment_possibleMoves]	setFrame:CGRectMake(	d.cheat.x,	d.cheat.y,	d.cheat.w,	d.cheat.h		)]; // cheat segment
	[[self button_endGame]		setFrame:CGRectMake(	d.endgame.x,	d.endgame.y,	d.endgame.w,	d.endgame.h	)]; // end game btn
	[[self label_score]			setFrame:CGRectMake(	d.score.x,	d.score.y,	d.score.w,	d.score.h		)]; // score lbl
	[[self label_points]		setFrame:CGRectMake(	d.points.x,	d.points.y,	d.points.w,	d.points.h	)]; // points lbl
	[[self label_level]			setFrame:CGRectMake(	d.level.x,	d.level.y,	d.level.w,	d.level.h		)]; // level lbl
	[super viewDidAppear:animated];
}

- (void)viewDidLoad
{
	gamePrefs = [OptionsView loadPrefs];
	highest = [ScoresView highestScore];
	if (gamePrefs.seed == 0)
		srand((unsigned int)time(0));
	else
		srand(gamePrefs.seed);
	[super viewDidLoad];
	[[self textView_gameBoard] setBackgroundColor:[UIColor blackColor]];
	[self userRestart:nil];
	[self display];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}
- (void)display
{
	NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
	NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
	NSUInteger x, y, harden_i, harden_count;
	paragraphStyle.alignment = NSTextAlignmentCenter;
	for (y = 0; y < YSIZE; ++y)
	{
		for (x = 0; x < XSIZE; ++x)
		{
			if (x == player_x && y == player_y) [string appendAttributedString: [[NSAttributedString alloc] initWithString:@"#" attributes:@{NSParagraphStyleAttributeName:paragraphStyle}]];
			else if (map[x][y] != 0) [string appendAttributedString: [[NSAttributedString alloc] initWithString:[[NSString alloc] initWithFormat:@"%d", map[x][y]] attributes:@{NSParagraphStyleAttributeName:paragraphStyle,NSForegroundColorAttributeName:[UIColor whiteColor]}]];
			else [string appendAttributedString: [[NSAttributedString alloc] initWithString:@"+" attributes:@{NSParagraphStyleAttributeName:paragraphStyle}]];
		}
		if (y != YSIZE - 1) [string appendAttributedString: [[NSAttributedString alloc] initWithString:@"\n" attributes:@{NSParagraphStyleAttributeName:paragraphStyle}]];
	}
	string = [self highlightCharacter:string atX:player_x atY:player_y withColor:[UIColor blueColor]];
	string = [self highlightGridNumbers:string];
	if (highlightPaths) string = [self highlightPossibleMoves:string fromX:player_x fromY:player_y withIncrement:0];
	[string addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Courier" size:12.5] range:(NSRange){0, [string length]}];
	[[self label_score] setText:[[NSString alloc] initWithFormat:@"%.2f%%", [self score]]];
	[[self label_points] setText:[[NSString alloc] initWithFormat:@"%lu", (unsigned long)player_points]];
	[[self label_level] setText:[[NSString alloc] initWithFormat:@"lvl %lu", (unsigned long)player_level + 1]];
	harden_count = clist_count(harden);
	for (harden_i = 0; harden_i < harden_count; ++harden_i) // loop over hardened vals and make them black/white so they're easy to spot
	{ string = [self highlightBackground:string atX:clist_get(harden, harden_i)->coord_x atY:clist_get(harden, harden_i)->coord_y withColor:[UIColor whiteColor]];
	  string = [self highlightCharacter: string atX:clist_get(harden, harden_i)->coord_x atY:clist_get(harden, harden_i)->coord_y withColor:[UIColor blackColor]]; }
	harden = clist_free(harden); // wipe it out so it only shows for 1 move
	if ([self score] > WINPERCENT) [[self button_levelUp] setHidden:NO]; // player can level up
	else if (gameOver) [self disableGame];
	[[self textView_gameBoard] setAttributedText:string];
		if (player_points > highest)		[[self label_points] setTextColor:[UIColor greenColor]];
	else if (player_points > (highest / 2))	[[self label_points] setTextColor:[UIColor yellowColor]];
	else if (player_points > (highest / 4))	[[self label_points] setTextColor:[UIColor orangeColor]];
	else if (highest != 0)				[[self label_points] setTextColor:[UIColor redColor]];
}
- (NSMutableAttributedString *)highlightCharacter:(NSMutableAttributedString *)string atX:(NSUInteger)x atY:(NSUInteger)y withColor:(UIColor *)color
{
	NSUInteger offset = y * XSIZE + x + y;
	if (offset > [string length]) return string;
	NSRange range = [[string mutableString] rangeOfComposedCharacterSequenceAtIndex: offset];
	[string addAttribute:NSForegroundColorAttributeName value:color range:range];
	return string;
}
- (NSMutableAttributedString *)highlightBackground:(NSMutableAttributedString *)string atX:(NSUInteger)x atY:(NSUInteger)y withColor:(UIColor *)color
{
	NSUInteger offset = y * XSIZE + x + y;
	if (offset > [string length]) return string;
	NSRange range = [[string mutableString] rangeOfComposedCharacterSequenceAtIndex: offset];
	[string addAttribute:NSBackgroundColorAttributeName value:color range:range];
	return string;
}
- (NSMutableAttributedString *)highlightGridNumbers:(NSMutableAttributedString *)string
{
	NSUInteger x, y;
	UIColor *c1 = [[UIColor alloc] initWithRed:0.01 green:0.52 blue:0.09 alpha:1]; //038617	3	134	23
	UIColor *c2 = [[UIColor alloc] initWithRed:0.79 green:0.87 blue:0.26 alpha:1]; //cbf442	203	224	66
	UIColor *c3 = [[UIColor alloc] initWithRed:1.00 green:1.00 blue:0.00 alpha:1]; //ffff00	255	255	0
	UIColor *c4 = [[UIColor alloc] initWithRed:0.95 green:0.63 blue:0.00 alpha:1]; //f2a100	242	161	0
	UIColor *c5 = [[UIColor alloc] initWithRed:0.89 green:0.19 blue:0.15 alpha:1]; //e53027	229	48	39
	for (y = 0; y < YSIZE; y++)
	{
		for (x = 0; x < XSIZE; x++)
		{
				if (map[x][y] > 0 && map[x][y] <= 4)	[self highlightCharacter:string atX:x atY:y withColor:c1];
			else if (map[x][y] == 5 || map[x][y] == 6)	[self highlightCharacter:string atX:x atY:y withColor:c2];
			else if (map[x][y] == 7)					[self highlightCharacter:string atX:x atY:y withColor:c3];
			else if (map[x][y] == 8)					[self highlightCharacter:string atX:x atY:y withColor:c4];
			else if (map[x][y] == 9)					[self highlightCharacter:string atX:x atY:y withColor:c5];
		}
	}
	return string;
}
- (struct clist_node *)destFromList:(struct clist_node *)list
{
	struct clist_node *ptr;
	for (ptr = list; ptr->next != NULL; ptr = ptr->next);
	return ptr;
}
- (UIColor *)getColorForIncrement:(NSUInteger)increment
{
	enum uxcolor clr = 0;
	switch (increment)
	{
		case 0:	clr = gamePrefs.move1;	break;
		case 1:	clr = gamePrefs.move2;	break;
		case 2:	clr = gamePrefs.move3;	break;
	}
	switch (clr)
	{
		case kCOL_GRY:	return [UIColor grayColor];
		case kCOL_RED:	return [UIColor redColor];
		case kCOL_BLU:	return [UIColor blueColor];
	}
}
- (NSMutableAttributedString *)highlightPossibleMoves:(NSMutableAttributedString *)string fromX:(NSUInteger)x fromY:(NSUInteger)y withIncrement:(NSUInteger)increment
{
	struct clist_node *list = NULL;
	BOOL foundMove = NO;
	UIColor *color;
	if (increment >= gamePrefs.moves) return string;
	color = [self getColorForIncrement:increment];
	if ((list = [self trackMoveInDirection:kDIR_N fromX:x fromY:y]) != NULL) foundMove = YES;			// up
	if (list) string = [self highlightPossibleMoves:string fromX:[self destFromList:list]->coord_x fromY:[self destFromList:list]->coord_x withIncrement:increment + 1];
	string = [self highlightString:string withCoordinateList:list withColor:color];
	clist_free(list);
	if ((list = [self trackMoveInDirection:kDIR_W fromX:x fromY:y]) != NULL) foundMove = YES;			// left
	if (list) string = [self highlightPossibleMoves:string fromX:[self destFromList:list]->coord_x fromY:[self destFromList:list]->coord_x withIncrement:increment + 1];
	string = [self highlightString:string withCoordinateList:list withColor:color];
	clist_free(list);
	if ((list = [self trackMoveInDirection:kDIR_S fromX:x fromY:y]) != NULL) foundMove = YES;			// down
	if (list) string = [self highlightPossibleMoves:string fromX:[self destFromList:list]->coord_x fromY:[self destFromList:list]->coord_x withIncrement:increment + 1];
	string = [self highlightString:string withCoordinateList:list withColor:color];
	clist_free(list);
	if ((list = [self trackMoveInDirection:kDIR_E fromX:x fromY:y]) != NULL) foundMove = YES;			// right
	if (list) string = [self highlightPossibleMoves:string fromX:[self destFromList:list]->coord_x fromY:[self destFromList:list]->coord_x withIncrement:increment + 1];
	string = [self highlightString:string withCoordinateList:list withColor:color];
	clist_free(list);
	if ((list = [self trackMoveInDirection:kDIR_N | kDIR_W fromX:x fromY:y]) != NULL) foundMove = YES;	// up left
	if (list) string = [self highlightPossibleMoves:string fromX:[self destFromList:list]->coord_x fromY:[self destFromList:list]->coord_x withIncrement:increment + 1];
	string = [self highlightString:string withCoordinateList:list withColor:color];
	clist_free(list);
	if ((list = [self trackMoveInDirection:kDIR_N | kDIR_E fromX:x fromY:y]) != NULL) foundMove = YES;	// up right
	if (list) string = [self highlightPossibleMoves:string fromX:[self destFromList:list]->coord_x fromY:[self destFromList:list]->coord_x withIncrement:increment + 1];
	string = [self highlightString:string withCoordinateList:list withColor:color];
	clist_free(list);
	if ((list = [self trackMoveInDirection:kDIR_S | kDIR_W fromX:x fromY:y]) != NULL) foundMove = YES;	// down left
	if (list) string = [self highlightPossibleMoves:string fromX:[self destFromList:list]->coord_x fromY:[self destFromList:list]->coord_x withIncrement:increment + 1];
	string = [self highlightString:string withCoordinateList:list withColor:color];
	clist_free(list);
	if ((list = [self trackMoveInDirection:kDIR_S | kDIR_E fromX:x fromY:y]) != NULL) foundMove = YES;	// down right
	if (list) string = [self highlightPossibleMoves:string fromX:[self destFromList:list]->coord_x fromY:[self destFromList:list]->coord_x withIncrement:increment + 1];
	string = [self highlightString:string withCoordinateList:list withColor:color];
	clist_free(list);
	if (!foundMove && [self score] <= WINPERCENT && increment == 0) gameOver = YES; // no moves left (including a level up)
	return string;
}
- (NSMutableAttributedString *)highlightString:(NSMutableAttributedString *)string withCoordinateList:(struct clist_node *)list withColor:(UIColor *)color
{
	if (list != NULL)
	{
		string = [self highlightBackground:string atX:(NSUInteger)list->coord_x atY:(NSUInteger)list->coord_y withColor:color];
		string = [self highlightCharacter:string atX:(NSUInteger)list->coord_x atY:(NSUInteger)list->coord_y withColor:[UIColor whiteColor]];
		string = [self highlightString:string withCoordinateList:list->next withColor:color];
	}
	return string;
}
- (BOOL)canMoveInDirection:(NSUInteger)direction fromX:(NSUInteger)x fromY:(NSUInteger)y
{
	NSUInteger l_x = x, l_y = y, l_val, p_x = x, p_y = y, p_i;
	NSInteger slope_x, slope_y;
	if (direction & kDIR_N) --l_y; // up
	if (direction & kDIR_S) ++l_y; // down
	if (direction & kDIR_W) --l_x; // left
	if (direction & kDIR_E) ++l_x; // right
	if (l_x >= XSIZE || l_y >= YSIZE) return NO; // check for edge
	l_val = map[l_x][l_y];
	if (!l_val) return NO; // space immediately to left is empty
	slope_x = l_x - x; slope_y = l_y - y; // get move slope (to be added to p_*
	for (p_i = 0, p_x += slope_x, p_y += slope_y; p_i < l_val; ++p_i, p_x += slope_x, p_y += slope_y) // see if possible
		if (p_x >= XSIZE /* bounds check */ || p_y >= YSIZE /* bounds check */ || map[p_x][p_y] == 0 /* empty check */) return NO;
	return YES;
}
- (struct clist_node *)trackMoveInDirection:(NSUInteger)direction fromX:(NSUInteger)x fromY:(NSUInteger)y
{
	NSUInteger l_x = x, l_y = y, l_val, p_x = x, p_y = y, p_i;
	NSInteger slope_x, slope_y;
	struct clist_node *steps = NULL;
	if (direction & kDIR_N) --l_y; // up
	if (direction & kDIR_S) ++l_y; // down
	if (direction & kDIR_W) --l_x; // left
	if (direction & kDIR_E) ++l_x; // right
	if (l_x >= XSIZE || l_y >= YSIZE) return nil; // check for edge
	l_val = map[l_x][l_y];
	if (!l_val) return nil; // space immediately to left is empty
	slope_x = l_x - x; slope_y = l_y - y; // get move slope (to be added to p_*
	for (p_i = 0, p_x += slope_x, p_y += slope_y; p_i < l_val; ++p_i, p_x += slope_x, p_y += slope_y) // see if possible
	{
		if (p_x >= XSIZE /* bounds check */ || p_y >= YSIZE /* bounds check */ || map[p_x][p_y] == 0 /* empty space check */)
		{
			clist_free(steps);
			return nil;
		}
		clist_insert(&steps, p_x, p_y);
	}
	return steps;
}
- (void)moveInDirection:(NSUInteger)direction
{
	NSUInteger p_x = player_x, p_y = player_y, p_i, l_val, moves_made = 0;
	NSInteger slope_x = 0, slope_y = 0;
	if (direction & kDIR_N) --slope_y; // up
	if (direction & kDIR_S) ++slope_y; // down
	if (direction & kDIR_W) --slope_x; // left
	if (direction & kDIR_E) ++slope_x; // right
	l_val = map[player_x + slope_x][player_y + slope_y];
	for (p_i = 0, p_x += slope_x, p_y += slope_y; p_i < l_val; ++p_i, p_x += slope_x, p_y += slope_y) // move loop
	{
		map[p_x][p_y] = 0; // clear gridpoint
		player_x += slope_x; player_y += slope_y; // move player
		++player_level_cleared;
		++moves_made;
	}
	if (moves_made > 1)	player_points += moves_made;				 // standard points
	if (moves_made > 5)	player_points += [self score];	 		 // moderate bonus for 5,6,7
	if (moves_made > 7)	player_points += [self score] * player_level; // huge bonus for 8 & 9 items
	++player_moves;
	[self hardenLevel];
}
- (void)levelUpMap
{
	NSUInteger i, rm_x, rm_y, removeItems = rand() % player_level * (gamePrefs.difficulty + 1) + 1;
	for (i = 0; i < removeItems; ++i)
	{
		do { rm_x = rand() % XSIZE; rm_y = rand() % YSIZE; }
		while (rm_x == player_x && rm_y == player_y);
		map[rm_x][rm_y] = 0;
		++player_level_removed;
	}
}
- (void)hardenLevel
{
	NSUInteger minMoves, squares, i, x, y;
	if (gamePrefs.difficulty == 0) return; // easy mode is easy
	minMoves = gamePrefs.difficulty == 2 ? 10 /* hard mode */ : 35 /* normal mode */;
	squares = (gamePrefs.difficulty - 1) * player_level; // each level gets harder, level 1 doesn't get hardened
	if (player_moves <= minMoves || player_moves % 3 != 0) return; // don't harden if player hasnt moved enough, only harden every third move
	for (i = 0; i < squares; ++i)
	{
		do { x = rand() % XSIZE; y = rand() % YSIZE; } while (map[x][y] == 0 || map[x][y] == 9 || (x == 0 && y == 0)); // don't modify crossed squares, and don't wrap them over, don't touch (0,0)
		++map[x][y]; // increment the square
		clist_insert(&harden, x, y); // push the number onto the list
	}
}
- (void)generateMap
{
	NSUInteger x, y, i_level;
	for (x = 0; x < XSIZE; ++x)
		for (y = 0; y < YSIZE; ++y)
			map[x][y] = rand() % 9 + 1;
	player_level_removed = 0;
	player_level_cleared = 0;
	player_x = rand() % XSIZE;
	player_y = rand() % YSIZE;
	map[player_x][player_y] = 0;
	player_moves = 0;
	for (i_level = 0; i_level < player_level; ++i_level) [self levelUpMap];
}
- (float)score { return ((float)player_level_cleared / (float)(XSIZE * YSIZE - player_level_removed)) * 100.0; }
- (void)disableGame
{
	[[self button_levelUp] setTitle:@"X" forState:UIControlStateNormal];
	[[self button_levelUp] setBackgroundColor:[UIColor redColor]];
	[[self button_moveA]   setEnabled:NO];
	[[self button_moveS]   setEnabled:NO];
	[[self button_moveD]   setEnabled:NO];
	[[self button_moveW]   setEnabled:NO];
	[[self button_moveWA]  setEnabled:NO];
	[[self button_moveWD]  setEnabled:NO];
	[[self button_moveSA]  setEnabled:NO];
	[[self button_moveSD]  setEnabled:NO];
	[[self button_levelUp] setHidden: NO];
	[[self button_levelUp] setEnabled:YES]; // use this button to add to high scores
}
- (void)enableGame
{
	[[self button_levelUp] setTitle:@"+" forState:UIControlStateNormal];
	[[self button_levelUp] setBackgroundColor:[UIColor greenColor]];
	[[self button_levelUp] setHidden: YES];
	[[self button_levelUp] setEnabled:YES];
	[[self button_moveA]   setEnabled:YES];
	[[self button_moveS]   setEnabled:YES];
	[[self button_moveD]   setEnabled:YES];
	[[self button_moveW]   setEnabled:YES];
	[[self button_moveWA]  setEnabled:YES];
	[[self button_moveWD]  setEnabled:YES];
	[[self button_moveSA]  setEnabled:YES];
	[[self button_moveSD]  setEnabled:YES];
}
- (IBAction)userMove:(id)sender
{
	[[self button_endGame] setBackgroundColor:[UIColor whiteColor]];
	if (Level_Reset)
	{
		Level_Reset = NO;
		[[self button_levelUp] setBackgroundColor:[UIColor greenColor]];
		[[self button_restart] setBackgroundColor:[UIColor whiteColor]];
		[[self button_endGame] setBackgroundColor:[UIColor whiteColor]];
	}
	if ([self canMoveInDirection:[sender tag] fromX:player_x fromY:player_y])
		[self moveInDirection:[sender tag]];
	[self display];
}
- (IBAction)userRestart:(id)sender
{
	if (!Level_Reset) [[self button_restart] setBackgroundColor:[UIColor redColor]];
	if (Level_Reset)
	{
		gameOver = NO;
		Level_Reset = NO;
		highlightPaths = NO;
		player_level = 0;
		player_points = 0;
		[[self segment_possibleMoves] setSelectedSegmentIndex:0];
		[[self button_restart] setBackgroundColor:[UIColor whiteColor]];
		[self enableGame];
		[self generateMap];
		[self display];
	}
	else Level_Reset = YES;
}
- (IBAction)userEndGame:(id)sender
{
	[[self button_endGame] setBackgroundColor:[UIColor redColor]];
	if (Level_Reset) [self performSegueWithIdentifier:@"endGame" sender:self];
	else Level_Reset = YES;
}
- (IBAction)userCheat:(id)sender
{
	if ([sender selectedSegmentIndex] == 0) highlightPaths = NO;
	else								highlightPaths = YES;
	[self display];
}
- (IBAction)userLevelUp:(id)sender
{
	if (!gameOver) // next level
	{
		[[self button_levelUp] setBackgroundColor:[UIColor blueColor]];
		if (Level_Reset)
		{
			++player_level;
			[self generateMap];
			[self enableGame];
			[self display];
			Level_Reset = NO;
		}
		else Level_Reset = YES;
	}
	else [self enterScore]; // high scores
}
- (void)enterScore
{
	FILE *fp __block;
	NSString *score = [[NSString alloc] initWithFormat:@"LVL %lu/%.2f%%/%lupt", (unsigned long)player_level + 1, [self score], (unsigned long)player_points];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *scoresFile = [documentsDirectory stringByAppendingPathComponent:@"/scores.txt"];
	UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Game Over!"
									message: score preferredStyle:UIAlertControllerStyleAlert];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
	{
		textField.placeholder = @"name";
		textField.textColor = [UIColor blueColor];
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		textField.borderStyle = UITextBorderStyleRoundedRect;
	}];
	[alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
	{
		NSArray * textfields = alertController.textFields;
		UITextField * namefield = textfields[0];
		if (!([[namefield text] length] < 1 || [[namefield text] length] > 15))
		{
			if ((fp = fopen([scoresFile UTF8String], "a")) != NULL)
			{
				fprintf(fp, "%s\n%lu/%.2f/%lu\n", [[namefield text] UTF8String],
					   (unsigned long)player_level + 1, [self score], (unsigned long)player_points);
				fflush(fp);
				fclose(fp);
				[self userRestart:nil];
				[self performSegueWithIdentifier:@"showScores" sender:self]; // show scores screen
				return;
			}
		}
		printf("ERROR!\n");
	}]];
	[self presentViewController:alertController animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
