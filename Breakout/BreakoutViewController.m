//
//  ViewController.m
//  Breakout
//
//  Created by Patrick Hogan on 7/31/14.
//  Copyright (c) 2014 Dan Hogan. All rights reserved.
//

#import "BreakoutViewController.h"
#import "PaddleView.h"
#import "BallView.h"
#import "BlockView.h"
#import "RootViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "LifeView.h"



@interface BreakoutViewController () <UICollisionBehaviorDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet PaddleView *paddleView;
@property (weak, nonatomic) IBOutlet BallView *ballView;
@property UIDynamicAnimator *dynamicAnimator;
@property UIPushBehavior *pushBehavior;
@property UICollisionBehavior *collisionBehavior;
@property UIDynamicItemBehavior *ballDynamicBehavior;
@property UIDynamicItemBehavior *paddleDynamicBehavior;
@property UIDynamicItemBehavior *blockDynamicBehavior;
@property BlockView *blockView;
@property NSMutableArray *collisionBehaviorArray;
@property NSMutableArray *dynamicBehaviorArray;
@property NSMutableArray *blockViewsArray;
@property NSMutableArray *lifeViewsArray;

@property BOOL willDestroyBlock;

@end

@implementation BreakoutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setBehaviors];
    [self setUpLifeViews];

    CGPoint saveCenter = self.ballView.center;
    CGRect newFrame = CGRectMake(self.ballView.frame.origin.x, self.ballView.frame.origin.y, 30.0, 30.0);
    self.ballView.frame = newFrame;
    self.ballView.layer.cornerRadius = 30.0 / 2.0;
    self.ballView.center = saveCenter;

    self.paddleView.layer.cornerRadius = 5;
    self.paddleView.layer.masksToBounds = YES;

    self.blockViewsArray = [[NSMutableArray alloc] init];
    self.collisionBehaviorArray = [@[self.ballView, self.paddleView] mutableCopy];
    self.dynamicBehaviorArray = [@[self.paddleView] mutableCopy];
}

-(void)setBehaviors
{
    self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];

    self.pushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.ballView]
                                                         mode:UIPushBehaviorModeInstantaneous];
    self.pushBehavior.pushDirection = CGVectorMake(0.5, 1.0);
    self.pushBehavior.active = YES;
    self.pushBehavior.magnitude = 0.4;
    [self.dynamicAnimator addBehavior:self.pushBehavior];

    self.ballDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.ballView]];
    self.ballDynamicBehavior.allowsRotation = NO;
    self.ballDynamicBehavior.elasticity = 1.0;
    self.ballDynamicBehavior.friction = 0;
    self.ballDynamicBehavior.resistance = 0;
    [self.dynamicAnimator addBehavior:self.ballDynamicBehavior];

    self.paddleDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.paddleView]];
    self.paddleDynamicBehavior.allowsRotation = NO;
    self.paddleDynamicBehavior.density = 1000;
    [self.dynamicAnimator addBehavior:self.paddleDynamicBehavior];

    self.collisionBehaviorArray = [@[self.ballView, self.paddleView] mutableCopy];
    self.dynamicBehaviorArray = [@[self.paddleView] mutableCopy];

    [self setUpBlockViews];

    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:self.collisionBehaviorArray];
    self.collisionBehavior.collisionMode = UICollisionBehaviorModeEverything;
    self.collisionBehavior.collisionDelegate = self;
    self.collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [self.dynamicAnimator addBehavior:self.collisionBehavior];

    self.blockDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:self.dynamicBehaviorArray];
    self.blockDynamicBehavior.allowsRotation = NO;
    self.blockDynamicBehavior.density = 8000;
    [self.dynamicAnimator addBehavior:self.blockDynamicBehavior];
}

-(void)setUpBlockViews
{
    for (int y = 1; y < self.numberOfRows + 1; y++)
    {
        for (int x = 1; x < 9; x++)
        {
            CGRect frame = CGRectMake (x * 32, 4 + (y * 12), 30.0, 10.0);
            self.blockView = [[BlockView alloc] initWithFrame:frame];
            self.blockView.backgroundColor = [UIColor whiteColor];
            self.blockView.layer.cornerRadius = 5;
            self.blockView.layer.masksToBounds = YES;
            [self.view addSubview:self.blockView];
            //NSLog (@"x:%f, y:%f ", self.blockView.frame.origin.x, self.blockView.frame.origin.y);

            [self.blockViewsArray addObject:self.blockView];
            [self.collisionBehaviorArray addObject:self.blockView];
            [self.dynamicBehaviorArray addObject:self.blockView];
        }
    }
}

-(void)setUpLifeViews
{
    self.lifeViewsArray = [[NSMutableArray alloc] init];
    for (int x = 1; x < 4; x++)
    {
        CGRect frame = CGRectMake (x * 22, 555, 20.0, 10.0);
        LifeView *lifeView = [[LifeView alloc] initWithFrame:frame];
        lifeView.backgroundColor = [UIColor greenColor];
        lifeView.layer.cornerRadius = 5;
        lifeView.layer.masksToBounds = YES;
        [self.view addSubview:lifeView];
        [self.lifeViewsArray addObject:lifeView];
    }
}

- (IBAction)dragPaddle:(UIPanGestureRecognizer *)panGestureRecognizer
{
    self.paddleView.center = CGPointMake([panGestureRecognizer locationInView:self.view].x, self.paddleView.center.y);

//                                         paddle x   origin
    CGFloat paddleViewXOrigin = MAX(0, self.paddleView.frame.origin.x);
    self.paddleView.frame = CGRectMake(paddleViewXOrigin, self.paddleView.frame.origin.y, self.paddleView.frame.size.width, self.paddleView.frame.size.height);

//                            right end of view              paddle x origin                  paddle width                      offset to get left endpoint
    paddleViewXOrigin = MIN(self.view.frame.size.width, self.paddleView.frame.origin.x + self.paddleView.frame.size.width) - self.paddleView.frame.size.width;
    self.paddleView.frame = CGRectMake(paddleViewXOrigin, self.paddleView.frame.origin.y, self.paddleView.frame.size.width, self.paddleView.frame.size.height);
    [self.dynamicAnimator updateItemUsingCurrentState:self.paddleView];
}

-(void)returnBall
{
    CGRect frame = CGRectMake(145.0, 269.0, 30.0, 30.0);
    [self.ballView setFrame:frame];
    [self.dynamicAnimator updateItemUsingCurrentState:self.ballView];
}

-(BOOL)shouldStartAgain
{
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[BlockView class]]) {
            return NO;
        }
    }
    return YES;
}

-(void)showRestartMessage
{
    UIAlertView *alertview = [[UIAlertView alloc] init];
    alertview.title = @"You Win";
    alertview.delegate = self;
    [alertview addButtonWithTitle:@"Play Again"];
    [alertview show];

}

#pragma mark - Collision Behavior Delegate

-(void)collisionBehavior:(UICollisionBehavior *)behavior
     beganContactForItem:(id<UIDynamicItem>)item
  withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p
{
    if (p.y > 566) {
        NSLog(@"%f", p.y);
        [self returnBall];
        UIView *view = self.lifeViewsArray.lastObject;
        [self.lifeViewsArray removeLastObject];
        [view removeFromSuperview];
    }
}

-(void)collisionBehavior:(UICollisionBehavior *)behavior
     beganContactForItem:(UIView *)item1
                withItem:(UIView *)item2
                 atPoint:(CGPoint)p
{
    //NSLog(@"item1:%@, item2:%@", item1, item2);
    self.willDestroyBlock = arc4random() % 3;
    if (behavior == self.collisionBehavior) {
        if (self.willDestroyBlock == 0) {
            return;
        }
        else {
            if ([item2 isKindOfClass:[BlockView class]]) {
                [UIView animateWithDuration:0.25 animations:^(void) {
                    item2.alpha = 1;
                    item2.alpha = 0;
                } completion:^(BOOL finished) {
                    [(UIView *)item2 removeFromSuperview];
                    [behavior removeItem:item2];
                }];
            }
        }
        BOOL shouldStartAgain = [self shouldStartAgain];
        if (shouldStartAgain) {
            [self showRestartMessage];
        }
    }
}

#pragma mark - Alert View Delegate

-(void)          alertView:(UIAlertView *)alertView
willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    //[self.delegate alertView:self willDismissWithButtonIndex:0];
    [self returnBall];
    [self setBehaviors];
}

@end
