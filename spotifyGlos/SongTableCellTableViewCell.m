//
//  SongTableCellTableViewCell.m
//  SonosProjectInterface
//
//  Created by Suma Reddy on 11/9/14.
//  Copyright (c) 2014 Flatiron. All rights reserved.
//

#import "SongTableCellTableViewCell.h"

@interface SongTableCellTableViewCell ()

@end

@implementation SongTableCellTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    [self.contentView addSubview:self.songLabel];
    [self.contentView addSubview:self.artistLabel];
    return self;
}

- (UILabel *)songLabel {
    if (_songLabel == nil) {
        _songLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 3, 300, 20)];
        _songLabel.font = [UIFont systemFontOfSize:15];
        _songLabel.textColor = [UIColor purpleColor];
    }
    return _songLabel;
}

- (UILabel *)artistLabel {
    if (_artistLabel == nil) {
        _artistLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 24, 300, 15)];
        _artistLabel.font = [UIFont systemFontOfSize:13];
    }
    return _artistLabel;
}


@end
