#import "BDInfoListController.h"
#import <Preferences/PSSpecifier.h>

@interface PSTableCell()
-(id)iconImageView;
@end

@implementation BDInfoListController
-(void)loadView{
	[super loadView];
    self.navigationItem.title = @"Brend0n";
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
  id cell=[super tableView:tableView cellForRowAtIndexPath:indexPath];
  UIImageView* imageView=[cell iconImageView];
  imageView.layer.cornerRadius = 7.0;
  imageView.layer.masksToBounds = YES;
  return cell;
}
- (NSArray *)specifiers {
	if (!_specifiers) {
		    _specifiers = [NSMutableArray arrayWithCapacity:5];

        PSSpecifier* spec;
        spec = [PSSpecifier preferenceSpecifierNamed:@""
                                              target:self
                                              set:Nil
                                              get:Nil
                                              detail:Nil
                                              cell:PSGroupCell
                                              edit:Nil];
        [spec setProperty:@"" forKey:@"label"];
        [_specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Github"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        spec->action = @selector(open_github);
        [spec setProperty:@YES forKey:@"hasIcon"];
        [spec setProperty:[UIImage imageNamed:@"github" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forKey:@"iconImage"];
        [_specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Bilibili"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        spec->action = @selector(open_bilibili);
        [spec setProperty:@YES forKey:@"hasIcon"];
        [spec setProperty:[UIImage imageNamed:@"bilibili" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forKey:@"iconImage"];
        [_specifiers addObject:spec];
        spec = [PSSpecifier preferenceSpecifierNamed:@"打赏支持"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        spec->action = @selector(open_alipay);
        [spec setProperty:@YES forKey:@"hasIcon"];
        [spec setProperty:[UIImage imageNamed:@"alipay" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forKey:@"iconImage"];
        [_specifiers addObject:spec];
        

        spec = [PSSpecifier preferenceSpecifierNamed:@"添加我的Cydia源"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        spec->action = @selector(open_cydia);
        [spec setProperty:@YES forKey:@"hasIcon"];
        [spec setProperty:[UIImage imageNamed:@"cydia" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forKey:@"iconImage"];
        [_specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@""
                                              target:self
                                              set:Nil
                                              get:Nil
                                              detail:Nil
                                              cell:PSGroupCell
                                              edit:Nil];
        [spec setProperty:@"" forKey:@"label"];
        [_specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Follow Me"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        spec->action = @selector(open_twitter);
        [spec setProperty:@YES forKey:@"hasIcon"];
        [spec setProperty:[UIImage imageNamed:@"twitter" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forKey:@"iconImage"];
        [_specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Support Developer"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        spec->action = @selector(open_paypal);
        [spec setProperty:@YES forKey:@"hasIcon"];
        [spec setProperty:[UIImage imageNamed:@"paypal" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil] forKey:@"iconImage"];
        [_specifiers addObject:spec];

	}

	return _specifiers;
}

- (void)open_bilibili{
  if ([UIApp canOpenURL:[NSURL URLWithString:@"bilibili://space/22182611"]]) {
      [UIApp openURL:[NSURL URLWithString:@"bilibili://space/22182611"]];
  } else {
      [UIApp openURL:[NSURL URLWithString:@"https://space.bilibili.com/22182611"]];
  }
}
- (void)open_github{
  [UIApp openURL:[NSURL URLWithString:@"https://github.com/brendonjkding/Unity60FPS"]];
}
- (void)open_alipay{
  [UIApp openURL:[NSURL URLWithString:@"https://qr.alipay.com/fkx199226yyspdubbiibddc"]];
}
- (void)open_paypal{
  [UIApp openURL:[NSURL URLWithString:@"https://paypal.me/brend0n"]];
}
- (void)open_cydia{
  [UIApp openURL:[NSURL URLWithString:@"cydia://url/https://cydia.saurik.com/api/share#?source=http://brendonjkding.github.io"]];
}
- (void)open_twitter{
	if ([UIApp canOpenURL:[NSURL URLWithString:@"twitter://user?screen_name=brendonjkding"]]) {
		[UIApp openURL:[NSURL URLWithString:@"twitter://user?screen_name=brendonjkding"]];
	} 
	else if ([UIApp canOpenURL:[NSURL URLWithString:@"tweetbot:///user_profile/brendonjkding"]]) {
		[UIApp openURL:[NSURL URLWithString:@"tweetbot:///user_profile/brendonjkding"]];		
	} 
	else {
		[UIApp openURL:[NSURL URLWithString:@"https://mobile.twitter.com/brendonjkding"]];
	}
}

@end