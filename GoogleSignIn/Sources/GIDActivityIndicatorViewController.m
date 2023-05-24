//
//  GIDActivityIndicatorViewController.m
//  GoogleSignIn
//
//  Created by Matt Mathias on 5/24/23.
//

#import "GIDActivityIndicatorViewController.h"

@interface GIDActivityIndicatorViewController ()

@end

@implementation GIDActivityIndicatorViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
  self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
  [self.activityIndicator startAnimating];
  [self.view addSubview:self.activityIndicator];

  NSLayoutConstraint *centerX =
      [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
  NSLayoutConstraint *centerY =
      [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor];
  [NSLayoutConstraint activateConstraints:@[centerX, centerY]];
}

@end
