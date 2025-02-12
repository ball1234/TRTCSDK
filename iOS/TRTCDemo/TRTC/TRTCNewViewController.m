/*
 * Module:   TRTCNewViewController
 * 
 * Function: 该界面可以让用户输入一个【房间号】和一个【用户名】
 * 
 * Notice:   
 *
 *  （1）房间号为数字类型，用户名为字符串类型
 *
 *  （2）在真实的使用场景中，房间号大多不是用户手动输入的，而是系统分配的，
 *       比如视频会议中的会议号是会控系统提前预定好的，客服系统中的房间号也是根据客服员工的工号决定的。
 */

#import "TRTCNewViewController.h"
#import "TRTCMainViewController.h"
#import "UIView+Additions.h"
#import "ColorMacro.h"
#define KEY_ALL_USER_ID         @"__all_userid__"
#define KEY_CURRENT_USERID      @"__current_userid__"

#import "TRTCGetUserIDAndUserSig.h"
#import "MBProgressHUD.h"
#import "QBImagePickerController.h"
#import "TRTCFloatWindow.h"

#import "AppDelegate.h"

@interface TRTCNewViewController () <UITextFieldDelegate,UIPickerViewDelegate, UIPickerViewDataSource> {
    UILabel           *_tipLabel;
    UITextField       *_roomIdTextField;
    UITextField       *_userIdTextField;
    UIButton          *_joinBtn;
    UIPickerView      *_userIdPicker;

    TRTCGetUserIDAndUserSig *_userInfo;
    uint32_t         _sdkAppid;
    NSString          *_selfPwd;
}
@property (nonatomic, assign) TRTCRoleType role;
@property (nonatomic, retain) UISwitch* talkModeSwitch;
@property (nonatomic, retain) UISegmentedControl* customVideoCaptureSeg;
@property (nonatomic, retain) UISegmentedControl* appSenceSeg;
@property (nonatomic, retain) UISegmentedControl* roleSeg;
@property (nonatomic, retain) AVAsset*  customSourceAsset;

@end

@implementation TRTCNewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"腾讯视频通话";
    

    _role = TRTCRoleAnchor;
    
    [self.view setBackgroundColor:UIColorFromRGB(0x333333)];
    
    _tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, 100, 200, 30)];
    _tipLabel.textColor = UIColorFromRGB(0x999999);
    _tipLabel.text = @"请输入房间号：";
    _tipLabel.textAlignment = NSTextAlignmentLeft;
    _tipLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:_tipLabel];
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 18, 40)];
    _roomIdTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 136, self.view.width, 40)];
    _roomIdTextField.delegate = self;
    _roomIdTextField.leftView = paddingView;
    _roomIdTextField.leftViewMode = UITextFieldViewModeAlways;
    _roomIdTextField.placeholder = @"901";
    _roomIdTextField.backgroundColor = UIColorFromRGB(0x4a4a4a);
    _roomIdTextField.textColor = UIColorFromRGB(0x939393);
    _roomIdTextField.keyboardType = UIKeyboardTypeNumberPad;
    _roomIdTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:_roomIdTextField];
    
    UILabel* userTipLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, 182, 200, 30)];
    userTipLabel.textColor = UIColorFromRGB(0x999999);
    userTipLabel.text = @"请输入用户名：";
    userTipLabel.textAlignment = NSTextAlignmentLeft;
    userTipLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:userTipLabel];
    
    NSString* userId = [self getUserId];
    UIView *paddingView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 18, 40)];
    _userIdTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 220, self.view.width, 40)];
    _userIdTextField.delegate = self;
    _userIdTextField.leftView = paddingView1;
    _userIdTextField.leftViewMode = UITextFieldViewModeAlways;
    _userIdTextField.text = userId;
    _userIdTextField.placeholder = @"12345";
    _userIdTextField.backgroundColor = UIColorFromRGB(0x4a4a4a);
    _userIdTextField.textColor = UIColorFromRGB(0x939393);
    _userIdTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:_userIdTextField];
    

    _customVideoCaptureSeg = [[UISegmentedControl alloc] initWithItems:@[@"前摄像头", @"视频文件"]];
    UIFont *font = [UIFont boldSystemFontOfSize:14.0f];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
                                                           forKey:NSFontAttributeName];
    [_customVideoCaptureSeg setTitleTextAttributes:attributes
                               forState:UIControlStateNormal];
    _customVideoCaptureSeg.bounds = CGRectMake(0, 0, self.view.width * 0.4, 35);
    _customVideoCaptureSeg.center = CGPointMake(self.view.width - _customVideoCaptureSeg.width / 2 - 10, _userIdTextField.bottom + 45);
    _customVideoCaptureSeg.tintColor = UIColorFromRGB(0x05a764);
    _customVideoCaptureSeg.selectedSegmentIndex = 0;
    [_customVideoCaptureSeg setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.whiteColor} forState:UIControlStateSelected];
    [_customVideoCaptureSeg setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColorFromRGB(0x939393)} forState:UIControlStateNormal];

    [self.view addSubview:_customVideoCaptureSeg];
    UILabel *customVideoCaptureLabel = [[UILabel alloc] init];
    customVideoCaptureLabel.textColor = userTipLabel.textColor;
    customVideoCaptureLabel.text = @"视频输入";
    [customVideoCaptureLabel sizeToFit];
    customVideoCaptureLabel.center = CGPointMake(userTipLabel.x + customVideoCaptureLabel.width / 2, _customVideoCaptureSeg.center.y);
    [self.view addSubview:customVideoCaptureLabel];
    
    
    _joinBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _joinBtn.frame = CGRectMake(40, self.view.height - 70, self.view.width - 80, 50);
    _joinBtn.layer.cornerRadius = 8;
    _joinBtn.layer.masksToBounds = YES;
    _joinBtn.layer.shadowOffset = CGSizeMake(1, 1);
    _joinBtn.layer.shadowColor = UIColorFromRGB(0x019b5c).CGColor;
    _joinBtn.layer.shadowOpacity = 0.8;
    _joinBtn.backgroundColor = UIColorFromRGB(0x05a764);
    [_joinBtn setTitle:@"创建并自动加入该房间" forState:UIControlStateNormal];
    [_joinBtn addTarget:self action:@selector(onJoinBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_joinBtn];
    
    _appSenceSeg = [[UISegmentedControl alloc] initWithItems:@[@"视频通话", @"在线直播"]];
    _appSenceSeg.frame = CGRectMake(_userIdTextField.width - _customVideoCaptureSeg.width - 10, _customVideoCaptureSeg.bottom + 10, _customVideoCaptureSeg.width, _customVideoCaptureSeg.height);
    _appSenceSeg.tintColor = UIColorFromRGB(0x05a764);
    _appSenceSeg.selectedSegmentIndex = 0;
    [_appSenceSeg setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.whiteColor} forState:UIControlStateSelected];
    [_appSenceSeg setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColorFromRGB(0x939393)} forState:UIControlStateNormal];
    [_appSenceSeg addTarget:self action:@selector(onSegmentValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_appSenceSeg];
    
    UILabel *senceLabel = [[UILabel alloc] init];
    senceLabel.textColor = userTipLabel.textColor;
    senceLabel.text = @"应用场景";
    [senceLabel sizeToFit];
    senceLabel.center = CGPointMake(customVideoCaptureLabel.x + senceLabel.width / 2, _appSenceSeg.center.y);
    [self.view addSubview:senceLabel];
    
    
    _roleSeg = [[UISegmentedControl alloc] initWithItems:@[@"上麦主播", @"普通观众"]];
    _roleSeg.frame = CGRectMake(_userIdTextField.width - _customVideoCaptureSeg.width - 10, _appSenceSeg.bottom + 10, _customVideoCaptureSeg.width, _customVideoCaptureSeg.height);
    _roleSeg.tintColor = UIColorFromRGB(0x05a764);
    _roleSeg.selectedSegmentIndex = 0;
    [_roleSeg setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.whiteColor} forState:UIControlStateSelected];
    [_roleSeg setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColorFromRGB(0x939393)} forState:UIControlStateNormal];
    [self.view addSubview:_roleSeg];
    
    UILabel* roleLabel = [[UILabel alloc] init];
    roleLabel.textColor = userTipLabel.textColor;
    roleLabel.text = @"角色选择";
    [roleLabel sizeToFit];
    roleLabel.center = CGPointMake(customVideoCaptureLabel.x + roleLabel.width / 2, _roleSeg.center.y);
    [self.view addSubview:roleLabel];
    _roleSeg.enabled = NO;
#ifndef APPSTORE
//    _talkModeSwitch = [[UISwitch alloc] init];
//    _talkModeSwitch.frame = CGRectMake(_userIdTextField.width - _talkModeSwitch.width - 10, _userIdTextField.bottom + 10, _talkModeSwitch.width, _talkModeSwitch.height);
//    [self.view addSubview:self.talkModeSwitch];
//    UILabel* talkModeLabel = [[UILabel alloc] init];
//    talkModeLabel.textColor = userTipLabel.textColor;
//    talkModeLabel.text = @"纯音频模式";
//    [talkModeLabel sizeToFit];
//    talkModeLabel.center = CGPointMake(userTipLabel.x + talkModeLabel.width / 2, _talkModeSwitch.center.y);
//    [self.view addSubview:talkModeLabel];
#endif
    _userInfo = [[TRTCGetUserIDAndUserSig alloc] init];
    if (_userInfo.configSdkAppid) {
        _userIdPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 200)];
        _userIdPicker.dataSource = self;
        _userIdPicker.delegate = self;
        _userIdTextField.inputView = _userIdPicker;
        _userIdTextField.text = _userInfo.configUserIdArray[0];
        _sdkAppid = _userInfo.configSdkAppid;
    }

    if (_sdkAppid == 0) {
        _userIdTextField.enabled = NO;
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"提示" message:@"config.json 加载失败！" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil ];
        [ac addAction:ok];
        [self.navigationController presentViewController:ac animated:YES completion:nil];
        return;
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

#pragma mark - UIControl event handle
- (void)onSegmentValueChange:(UISegmentedControl*)seg
{
    if (seg == _appSenceSeg) {
        BOOL roleEnable = YES;
        if (_appSenceSeg.selectedSegmentIndex == 1) {
            roleEnable = YES;
        }
        else {
            roleEnable = NO;
            _roleSeg.selectedSegmentIndex = 0;
        }
        _roleSeg.enabled = roleEnable;
    }
}


- (void)showMeidaPicker
{
    QBImagePickerController* imagePicker = [[QBImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsMultipleSelection = YES;
    imagePicker.showsNumberOfSelectedAssets = YES;
    imagePicker.minimumNumberOfSelection = 1;
    imagePicker.maximumNumberOfSelection = 1;
    imagePicker.mediaType = QBImagePickerMediaTypeVideo;
    imagePicker.title = @"选择视频源";

    [self.navigationController pushViewController:imagePicker animated:YES];
}

#pragma mark - QBImagePickerControllerDelegate
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets
{
    [self.navigationController popViewControllerAnimated:YES];
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    // 最高质量的视频
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    // 可从iCloud中获取图片
    options.networkAccessAllowed = YES;
    
    __weak __typeof(self) weakSelf = self;
    [[PHImageManager defaultManager] requestAVAssetForVideo:assets.firstObject options:options resultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        weakSelf.customSourceAsset = avAsset;
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [weakSelf joinRoom];

            };
        });
    }];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    NSLog(@"imagePicker Canceled.");
    _customVideoCaptureSeg.selectedSegmentIndex = 0;
    [self.navigationController popViewControllerAnimated:YES];
    
}

/**
 *  Function: 读取用户输入，并创建（或加入）音视频房间
 *
 *  此段示例代码最主要的作用是组装 TRTC SDK 进房所需的 TRTCParams
 *  
 *  TRTCParams.sdkAppId => 可以在腾讯云实时音视频控制台（https://console.cloud.tencent.com/rav）获取
 *  TRTCParams.userId   => 此处即用户输入的用户名，它是一个字符串
 *  TRTCParams.roomId   => 此处即用户输入的音视频房间号，比如 125
 *  TRTCParams.userSig  => 此处示例代码展示了两种获取 usersig 的方式，一种是从【控制台】获取，一种是从【服务器】获取
 *
 * （1）控制台获取：可以获得几组已经生成好的 userid 和 usersig，他们会被放在一个 json 格式的配置文件中，仅适合调试使用
 * （2）服务器获取：直接在服务器端用我们提供的源代码，根据 userid 实时计算 usersig，这种方式安全可靠，适合线上使用
 *
 *  参考文档：https://cloud.tencent.com/document/product/647/17275
 */

- (void)joinRoom
{
    NSString *roomId = _roomIdTextField.text;
    if (roomId.length == 0) {
        roomId = _roomIdTextField.placeholder;
    }
    
    NSString* userId = _userIdTextField.text;
    if(userId.length == 0) {
        double tt = [[NSDate date] timeIntervalSince1970];
        int user = ((uint64_t)(tt * 1000.0)) % 100000000;
        userId = [NSString stringWithFormat:@"%d", user];
    }
    
    NSString* lastUserId = [self getUserId];
    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:KEY_CURRENT_USERID];
    [[NSUserDefaults standardUserDefaults] synchronize];
    TRTCMainViewController *vc = [[TRTCMainViewController alloc] init];
    //    vc.pureAudioMode = _talkModeSwitch.isOn;

    TRTCParams *param = [[TRTCParams alloc] init];
    param.sdkAppId = _sdkAppid;
    param.userId = userId;
    param.roomId = (UInt32)roomId.integerValue;
    param.privateMapKey = @"";
    param.bussInfo = @"";
    param.role = _role;
    vc.param = param;

    vc.enableCustomVideoCapture = _customVideoCaptureSeg.selectedSegmentIndex == 1;
    vc.customMediaAsset = _customSourceAsset;
    vc.appScene = _appSenceSeg.selectedSegmentIndex == 0 ? TRTCAppSceneVideoCall : TRTCAppSceneLIVE;
    
    // 从控制台获取的 json 文件中，简单获取几组已经提前计算好的 userid 和 usersig
    if (_sdkAppid == _userInfo.configSdkAppid && _userInfo.configSdkAppid > 0) {
        NSInteger row = [_userInfo.configUserIdArray indexOfObject:userId];
        if (row != NSNotFound) {
            param.userSig = _userInfo.configUserSigArray[row];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

- (void)onJoinBtnClicked:(UIButton *)sender {
    if ([TRTCFloatWindow sharedInstance].localView) {
        [[TRTCFloatWindow sharedInstance] close];
    }
    
    if (_roleSeg != nil) {
        _role = _roleSeg.selectedSegmentIndex == 1 ? TRTCRoleAudience : TRTCRoleAnchor;
    }
    
    if (_customVideoCaptureSeg.selectedSegmentIndex == 1) {
        [self showMeidaPicker];
    }
    else {
        [self joinRoom];
    }
   
}

- (NSString *)getUserId {
    NSString* userId = @"";
    NSObject *d = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_CURRENT_USERID];
    if (d) {
        userId = [NSString stringWithFormat:@"%@", d];
    } else {
        double tt = [[NSDate date] timeIntervalSince1970];
        int user = ((uint64_t)(tt * 1000.0)) % 100000000;
        userId = [NSString stringWithFormat:@"%d", user];
        [[NSUserDefaults standardUserDefaults] setObject:userId forKey:KEY_CURRENT_USERID];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return userId;
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == _roomIdTextField) {
        NSCharacterSet *numbersOnly = [NSCharacterSet characterSetWithCharactersInString:@"9876543210"];
        NSCharacterSet *characterSetFromTextField = [NSCharacterSet characterSetWithCharactersInString:string];
        
        BOOL stringIsValid = [numbersOnly isSupersetOfSet:characterSetFromTextField];
        return stringIsValid;
    }
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:NO];
}


#pragma mark - picker
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _userInfo.configUserIdArray.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _userInfo.configUserIdArray[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    _userIdTextField.text = _userInfo.configUserIdArray[row];
    [self.view endEditing:YES];
}

- (void)dealloc
{
    [[TRTCFloatWindow sharedInstance] close];
}

@end
