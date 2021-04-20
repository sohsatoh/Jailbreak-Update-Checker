#import "JBUCommandOutputViewController.h"

@implementation JBUCommandOutputViewController
- (void)viewDidLoad {
    [super viewDidLoad];

    if (self) {
        [self setupView];
    }
}

- (void)setupView {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.view.bounds;
    [self.view addSubview:visualEffectView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, self.view.frame.size.width, self.view.frame.size.height / 6)];
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:[UIFont labelFontSize] * 1.5];
    titleLabel.textColor = [UIColor labelColor];
    titleLabel.text = @"Running update...";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];

    self.outputView = [[UITextView alloc] initWithFrame:CGRectMake(20, titleLabel.frame.size.height + titleLabel.frame.origin.y, self.view.frame.size.width - 40, self.view.frame.size.height - titleLabel.frame.size.height * 2)];
    self.outputView.backgroundColor = [UIColor clearColor];
    self.outputView.textColor = [UIColor labelColor];
    self.outputView.font = [UIFont fontWithName:@"HelveticaNeue-Regular" size:[UIFont labelFontSize] * 2];
    self.outputView.editable = NO;
    [self.view addSubview:self.outputView];
}
@end