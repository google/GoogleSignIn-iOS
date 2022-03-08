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

#import "DataPickerState.h"

NSString * const kMultipleSelectKey = @"multiple-select";
NSString * const kElementsKey = @"elements";
NSString * const kLabelKey = @"label";
NSString * const kShortLabelKey = @"shortLabel";
NSString * const kSelectedKey = @"selected";

@implementation DataPickerState

- (id)initWithDictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    _multipleSelectEnabled =
        [[dict objectForKey:kMultipleSelectKey] boolValue];

    NSMutableArray *cellLabels = [[NSMutableArray alloc] init];
    NSMutableSet *selectedCells = [[NSMutableSet alloc] init];

    NSArray *elements = [dict objectForKey:kElementsKey];
    for (NSDictionary *elementDict in elements) {
      NSMutableDictionary *cellLabelDict = [NSMutableDictionary dictionary];
      NSString *label = [elementDict objectForKey:kLabelKey];
      cellLabelDict[kLabelKey] = label;

      if ([elementDict objectForKey:kShortLabelKey]) {
        cellLabelDict[kShortLabelKey] = [elementDict objectForKey:kShortLabelKey];
      }
      [cellLabels addObject:cellLabelDict];

      // Default selection mode is unselected, unless specified in plist.
      if ([[elementDict objectForKey:kSelectedKey] boolValue]) {
        [selectedCells addObject:label];
      }
    }

    self.cellLabels = cellLabels;
    self.selectedCells = selectedCells;
  }
  return self;
}

@end
