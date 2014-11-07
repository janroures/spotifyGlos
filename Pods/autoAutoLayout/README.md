# autoAutoLayout

[![CI Status](http://img.shields.io/travis/Cathy Chen/autoAutoLayout.svg?style=flat)](https://travis-ci.org/Cathy Chen/autoAutoLayout)
[![Version](https://img.shields.io/cocoapods/v/autoAutoLayout.svg?style=flat)](http://cocoadocs.org/docsets/autoAutoLayout)
[![License](https://img.shields.io/cocoapods/l/autoAutoLayout.svg?style=flat)](http://cocoadocs.org/docsets/autoAutoLayout)
[![Platform](https://img.shields.io/cocoapods/p/autoAutoLayout.svg?style=flat)](http://cocoadocs.org/docsets/autoAutoLayout)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

First, remove constraints: 
    [self.view removeConstraints:self.view.constraints];

To auto-Auto Layout all UIView subview objects:
    [AutoAutoLayout reLayoutAllSubviewsFromBase:@"4s" forSubviewsOf:self.view]; //4s = storyboard size you worked from

To select a specific array of objects to Auto Layout:
    NSArray *objArray = @[self.titleLabel, self.mainButton];
    [AutoAutoLayout reLayoutSubviewFromArray:objArray fromBaseModel:@"4s" forSubviewsOf:self.view];

## Requirements

iOS 7.0+

## Installation

autoAutoLayout is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "autoAutoLayout"

## Author

Cathy Chen, i@cathychen.com

## License

autoAutoLayout is available under the MIT license. See the LICENSE file for more info.

