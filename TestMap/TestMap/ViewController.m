//
//  ViewController.m
//  TestMap
//
//  Created by moyekong on 15/2/26.
//  Copyright (c) 2015年 MK. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "MKMapAnnotation.h"

@interface ViewController ()<MKMapViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *mapBackView;
@property (weak, nonatomic) IBOutlet UITextField *destinationTextField;
@property (weak, nonatomic) IBOutlet UIButton *showButton;
@property (weak, nonatomic) IBOutlet UIButton *jumpButton;
@property (weak, nonatomic) IBOutlet UILabel *errorMessageLabel;

@property (nonatomic, strong) CLGeocoder * geocoder;
@property (nonatomic, strong) MKMapView * mapView;
@property (nonatomic, strong) CLPlacemark * clDestinationPlacemark;
@property (nonatomic, strong) MKMapAnnotation * annotation;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.showButton addTarget:self action:@selector(handleShow:) forControlEvents:UIControlEventTouchUpInside];
    [self.jumpButton addTarget:self action:@selector(handleJump:) forControlEvents:UIControlEventTouchUpInside];
    
    self.destinationTextField.delegate = self;
    
    self.geocoder = [[CLGeocoder alloc] init];
    
    self.mapView = [[MKMapView alloc] initWithFrame:self.mapBackView.bounds];
    self.mapView.showsUserLocation = NO;
    self.mapView.mapType = MKMapTypeStandard;
    /**
     *  MKMapTypeStandard 标准地图
     *  MKMapTypeSatellite 卫星地图
     *  MKMapTypeHybrid 具有街道信息的卫星地图模式
     */
    self.mapView.delegate = self;
    [self.mapBackView addSubview:self.mapView];
}

- (void)addMapViewRegion
{
    MKCoordinateSpan theSpan;
    // 地图的范围越小越精确
    theSpan.latitudeDelta = 0.01;
    theSpan.longitudeDelta = 0.01;
    MKCoordinateRegion theRegion;
    theRegion.center = _clDestinationPlacemark.location.coordinate;
    theRegion.span = theSpan;
    [self.mapView setRegion:theRegion];
    
    _annotation = [[MKMapAnnotation alloc] init];
    _annotation.title = @"首都图书馆";
    _annotation.subtitle = @"你输入的地址没找到，可能在月球上";
    _annotation.coordinate = theRegion.center;
    [self.mapView addAnnotation:_annotation];
}

#pragma mark - 添加大头针 -
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView * pinView = nil;
    static NSString * defaultPinID = @"com.companylocation.pin";
    pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:defaultPinID];
    if (pinView == nil) {
        pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:defaultPinID];
    }
    pinView.pinColor = MKPinAnnotationColorRed;
    pinView.canShowCallout = YES;
    pinView.animatesDrop = YES;
    return pinView;
}

- (void)handleShow:(UIButton *)sender
{
    [self.destinationTextField resignFirstResponder];
    [self getDestinationCordinateWithName:self.destinationTextField.text withActionType:1];
}

- (void)handleJump:(UIButton *)sender
{
    if (!_clDestinationPlacemark) {
        [self getDestinationCordinateWithName:self.destinationTextField.text withActionType:2];
    } else {
        MKPlacemark * destinationPlaceMark = [[MKPlacemark alloc] initWithPlacemark:_clDestinationPlacemark];
        [self jumpToMapWithDestinationCordinate:destinationPlaceMark];
    }
}

- (void)getDestinationCordinateWithName:(NSString *)destinationName withActionType:(NSInteger)actionType
{
    // 1、get destination address
    NSString * address = destinationName;
    if (address.length != 0) {
        
        // 2、begin geocode
        // geocode with method below, the method in block will be called no matter success or fail
        [self.geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
            
            // 如果有错误信息，或者是数组中获取的地名元素数量为0，说明没有找到
            if (error || placemarks.count == 0) {
                
                self.errorMessageLabel.text = @"你输入的地址没找到，可能在月球上";
                
            } else {
                // 编码成功，找到了具体的位置信息
                // 打印查看找到的所有的位置信息
                /**
                 *  name: 名称
                 *  locality: 城市
                 *  country: 国家
                 *  postalCode: 邮政编码
                 */
                _clDestinationPlacemark = [placemarks firstObject];
                if (actionType == 2) {
                    
                    MKPlacemark * destinationPlaceMark = [[MKPlacemark alloc] initWithPlacemark:_clDestinationPlacemark];
                    [self jumpToMapWithDestinationCordinate:destinationPlaceMark];
                    
                } else if (actionType == 1) {
                    
                    [self addMapViewRegion];
                }
            }
        }];
    }
}

- (void)jumpToMapWithDestinationCordinate:(MKPlacemark *)destinationPlacemark
{
    MKMapItem * currentLocation = [MKMapItem mapItemForCurrentLocation];
    MKMapItem * toLocation = [[MKMapItem alloc] initWithPlacemark:destinationPlacemark];
    toLocation.name = self.destinationTextField.text;
    [MKMapItem openMapsWithItems:[NSArray arrayWithObjects:currentLocation, toLocation, nil] launchOptions:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeDriving, [NSNumber numberWithBool:YES], nil] forKeys:[NSArray arrayWithObjects:MKLaunchOptionsDirectionsModeKey, MKLaunchOptionsShowsTrafficKey, nil]]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.destinationTextField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
