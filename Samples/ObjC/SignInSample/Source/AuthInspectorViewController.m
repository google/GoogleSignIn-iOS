/*
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "AuthInspectorViewController.h"

@import GoogleSignIn;

static NSString * const kReusableCellIdentifier = @"AuthInspectorCell";
static CGFloat const kVeryTallConstraint = 10000.f;
static CGFloat const kTableViewCellFontSize = 16.f;
static CGFloat const kTableViewCellPadding = 22.f;

@interface AuthInspectorViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation AuthInspectorViewController {
  // Key-paths for the GIDSignIn instance to inspect.
  NSArray *_keyPaths;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _keyPaths = @[
      @"accessToken.tokenString",
      @"accessToken.expirationDate",
      @"refreshToken.tokenString",
      @"idToken.tokenString",
      @"grantedScopes",
      @"userID",
      @"profile.email",
      @"profile.name",
    ];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                        style:UITableViewStyleGrouped];
  tableView.delegate = self;
  tableView.dataSource = self;
  tableView.frame = self.view.bounds;
  [self.view addSubview:tableView];
}

- (void)viewDidLayoutSubviews {
  if (self.view.subviews.count) {
    ((UIView *)self.view.subviews[0]).frame = self.view.bounds;
  }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return (NSInteger)[_keyPaths count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return [self contentForSectionHeader:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kReusableCellIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:kReusableCellIdentifier];
  }
  cell.textLabel.font = [UIFont systemFontOfSize:kTableViewCellFontSize];
  cell.textLabel.numberOfLines = 0;
  cell.textLabel.text = [self contentForRowAtIndexPath:indexPath];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    willDisplayHeaderView:(UIView *)view
               forSection:(NSInteger)section {
  // The default header view capitalizes the title, which we don't want (because it's the key path).
  if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
    ((UITableViewHeaderFooterView *)view).textLabel.text = [self contentForSectionHeader:section];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return [self heightForTableView:tableView content:[self contentForSectionHeader:section]]
      - (section ? kTableViewCellPadding : 0);  // to remove the extra padding in later sections.
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self heightForTableView:tableView content:[self contentForRowAtIndexPath:indexPath]];
}

#pragma mark - Helpers

- (NSString *)contentForSectionHeader:(NSInteger)section {
  return _keyPaths[section];
}

- (NSString *)contentForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *keyPath = _keyPaths[indexPath.section];
  return [[GIDSignIn.sharedInstance.currentUser valueForKeyPath:keyPath] description];
}

- (CGFloat)heightForTableView:(UITableView *)tableView content:(NSString *)content {
  CGSize constraintSize =
      CGSizeMake(tableView.frame.size.width - 2 * kTableViewCellPadding, kVeryTallConstraint);
  CGSize size;
  UIFont *font = [UIFont systemFontOfSize:kTableViewCellFontSize];
  NSDictionary *attributes = @{ NSFontAttributeName : font };
  size = [content boundingRectWithSize:constraintSize
                               options:NSStringDrawingUsesLineFragmentOrigin
                            attributes:attributes
                               context:NULL].size;
  return size.height + kTableViewCellPadding;
}

@end
