#import "JBUCommandOutputViewController.h"

@implementation JBUCommandOutputViewController
- (void)viewDidLoad {
    [super viewDidLoad];

    if (self) {
        [self _setupView];
    }
}

- (void)_setupView {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.view.bounds;
    [self.view addSubview:visualEffectView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height / 6)];
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:[UIFont labelFontSize]];
    titleLabel.textColor = [UIColor labelColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    titleLabel.text = @"Updating...";
    [self.view addSubview:titleLabel];

    // UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height / 6)];
    // titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:[UIFont labelFontSize] * 1.5];
    // titleLabel.textColor = [UIColor blackColor];
    // titleLabel.text = @"Running update...";
    // titleLabel.textAlignment = NSTextAlignmentCenter;
    // [self.view addSubview:titleLabel];

    // self.outputView = [[UITextView alloc] initWithFrame:CGRectMake(20, titleLabel.frame.size.height / 2, self.view.frame.size.width - 40, self.view.frame.size.height - titleLabel.frame.size.height * 2)];
    // self.outputView.backgroundColor = [UIColor clearColor];
    // self.outputView.textColor = [UIColor blackColor];
    // self.outputView.font = [UIFont fontWithName:@"HelveticaNeue-Regular" size:[UIFont labelFontSize]];
    // self.outputView.editable = NO;
    // [self.view addSubview:self.outputView];
}
@end