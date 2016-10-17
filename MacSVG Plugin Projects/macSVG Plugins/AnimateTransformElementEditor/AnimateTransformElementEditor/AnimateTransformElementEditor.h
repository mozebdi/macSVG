//
//  AnimateTransformElementEditor.h
//  AnimateTransformElementEditor
//
//  Created by Douglas Ward on 9/1/16.
//  Copyright © 2016 ArkPhone LLC. All rights reserved.
//

#import <MacSVGPlugin/MacSVGPlugin.h>
@class AnimateTransformKeyValuesPopoverViewController;

@interface AnimateTransformElementEditor : MacSVGPlugin <NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate, NSControlTextEditingDelegate>
{
    IBOutlet NSPopUpButton * calcModePopUpButton;
    IBOutlet NSTextField * beginTextField;
    IBOutlet NSTextField * durTextField;
    IBOutlet NSComboBox * repeatCountComboBox;
    IBOutlet NSTabView * animateTransformTabView;
    IBOutlet NSTextField * fromXTextField;
    IBOutlet NSTextField * fromYTextField;
    IBOutlet NSTextField * toXTextField;
    IBOutlet NSTextField * toYTextField;
    IBOutlet NSTableView * valuesTableView;

    IBOutlet NSButton * addValuesRowButton;
    IBOutlet NSButton * deleteValuesRowButton;
    
    IBOutlet NSButton * cancelButton;
    IBOutlet NSButton * applyChangesButton;

    IBOutlet NSPopover * keyValuesPopover;
    IBOutlet AnimateTransformKeyValuesPopoverViewController * keyValuesPopoverViewController;
}

@property (strong) NSMutableArray * valuesArray;

- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)applyChangesButtonAction:(id)sender;
- (IBAction)keyValuesButtonAction:(id)sender;

- (IBAction)itemTextFieldUpdated:(id)sender;

- (IBAction)addValuesRow:(id)sender;
- (IBAction)deleteValuesRow:(id)sender;

@end