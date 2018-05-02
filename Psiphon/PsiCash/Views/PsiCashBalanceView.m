/*
 * Copyright (c) 2018, Psiphon Inc.
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "PsiCashBalanceView.h"
#import "PsiCashClient.h"
#import "ReactiveObjC.h"

@interface PsiCashBalanceView ()
@property (atomic, readwrite) PsiCashClientModel *model;
@end

#pragma mark -

@implementation PsiCashBalanceView {
    UIImageView *coin;
    UILabel *balance;
    UILabel *plusMinusIndicator;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self setupViews];
        [self addViews];
        [self setupLayoutConstraints];
    }

    return self;
}

- (void)setupViews {
    self.layer.cornerRadius = 20;
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor colorWithRed:0.38 green:0.27 blue:0.92 alpha:1.0];
    self.contentEdgeInsets = UIEdgeInsetsMake(10.0f, 30.0f, 10.0f, 30.0f);

    coin = [[UIImageView alloc] initWithFrame:CGRectMake(60, 95, 90, 90)];
    coin.image = [UIImage imageNamed:@"PsiCash_Coin"];
    [coin.layer setMinificationFilter:kCAFilterTrilinear];

    // Setup plus minus indicator (indicates the direction of balance changes)
    plusMinusIndicator = [[UILabel alloc] init];
    plusMinusIndicator.alpha = 0;
    plusMinusIndicator.font = [UIFont systemFontOfSize:14.f];
    plusMinusIndicator.text = @"+"; // placeholder

    // Setup balance label
    balance = [[UILabel alloc] init];
    balance.backgroundColor = [UIColor clearColor];
    balance.font = [UIFont systemFontOfSize:12.f];
    balance.textAlignment = NSTextAlignmentCenter;
    balance.textColor = [UIColor whiteColor];
    balance.userInteractionEnabled = NO;
}

- (void)addViews {
    [self addSubview:coin];
    [self addSubview:plusMinusIndicator];
    [self addSubview:balance];
}

- (void)setupLayoutConstraints {
    CGFloat coinSize = 30.f;
    coin.translatesAutoresizingMaskIntoConstraints = NO;
    [coin.heightAnchor constraintEqualToConstant:coinSize].active = YES;
    [coin.widthAnchor constraintEqualToConstant:coinSize].active = YES;
    [coin.centerYAnchor constraintEqualToAnchor:balance.centerYAnchor].active = YES;
    [coin.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:5.f].active = YES;

    plusMinusIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [plusMinusIndicator.centerYAnchor constraintEqualToAnchor:balance.centerYAnchor].active = YES;
    [plusMinusIndicator.trailingAnchor constraintEqualToAnchor:coin.leadingAnchor constant:-2.5f].active = YES;

    balance.translatesAutoresizingMaskIntoConstraints = NO;
    [balance.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
    [balance.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
}

#pragma mark - State Changes
- (NSString*)stringFromBalance:(double)balance {
    return [NSString stringWithFormat:@"%.2f", balance / 1e9];
}
- (void)bindWithModel:(PsiCashClientModel*)clientModel {
    double previousBalance = self.model.balanceInPsi;

    self.model = clientModel;

    if ([self.model hasAuthPackage]) {
        if ([self.model.authPackage hasIndicatorToken]) {
            balance.text = [self stringFromBalance:clientModel.balanceInNanoPsi];

            BOOL shouldAnimate = YES;
            if (self.model.balanceInPsi > previousBalance) {
                plusMinusIndicator.text = [@"+" stringByAppendingString:[self stringFromBalance:self.model.balanceInPsi - previousBalance]];
                plusMinusIndicator.textColor = [UIColor greenColor];
            } else if (self.model.balanceInPsi < previousBalance) {
                plusMinusIndicator.text = [@"" stringByAppendingString:[self stringFromBalance:self.model.balanceInPsi - previousBalance]];
                plusMinusIndicator.textColor = [UIColor redColor];
            } else {
                shouldAnimate = NO;
            }

            if (shouldAnimate) {
                NSTimeInterval fadeInOutTime = 0.5;

                [UIView animateWithDuration:fadeInOutTime animations:^{
                    plusMinusIndicator.alpha = 0.7;
                } completion:^(BOOL finished){
                    // TODO: check bool `finished`
                    [UIView animateWithDuration:fadeInOutTime animations:^{
                        plusMinusIndicator.alpha = 0;
                    }];
                }];
            }
        } else {
            // First launch: the user has no indicator token
            balance.text = [self stringFromBalance:0];
        }
    } else {
        // Do nothing
    }
}

@end