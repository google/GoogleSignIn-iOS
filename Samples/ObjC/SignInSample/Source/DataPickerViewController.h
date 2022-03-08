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

#import <UIKit/UIKit.h>

@class DataPickerState;

// This view controller controls a table view meant to select
// options from a list. The list is supplied from the DataPickerDictionary.plist
// file based upon what |dataKey| the controller is initialized with.
@interface DataPickerViewController : UITableViewController

// |dataState| stores the list of cells and the current set of selected cells.
// It should be created and owned by whoever owns the DataPickerViewController,
// so we only need a weak reference to it from here.
@property(weak, readonly, nonatomic) DataPickerState *dataState;

// This method initializes a DataPickerViewController using
// a DataPickerState object, from which the view controller
// obtains cell information for use in its table.
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
            dataState:(DataPickerState *)dataState;

@end
