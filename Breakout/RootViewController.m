//
//  RootViewController.m
//  Breakout
//
//  Created by Dan Hogan on 8/1/14.
//  Copyright (c) 2014 Dan Hogan. All rights reserved.
//

#import "RootViewController.h"
#import "BreakoutViewController.h"

@interface RootViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *numberOfRowsTextField;

@end

@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.numberOfRowsTextField.text = @"";
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //NSLog(@"foobar");
    BreakoutViewController *vc = segue.destinationViewController;
    //[vc setNumberOfRows:self.numberOfRowsTextField.text.integerValue];
    vc.numberOfRows = self.numberOfRowsTextField.text.intValue;
}


@end
