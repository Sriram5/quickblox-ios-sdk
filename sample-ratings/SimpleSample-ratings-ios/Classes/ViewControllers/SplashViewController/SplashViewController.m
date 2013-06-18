//
//  SplashViewController.m
//  SimpleSample-ratings-ios
//
//  Created by Ruslan on 9/11/12.
//  Copyright (c) 2012 QuickBlox. All rights reserved.
//

#import "SplashViewController.h"
#import "MainViewController.h"
#import "DataManager.h"
#import "Movie.h"

@interface SplashViewController () <QBActionStatusDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (void)hideSplashScreen;

@end

@implementation SplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.activityIndicator startAnimating];
    
    // Your app connects to QuickBlox server here.
    //
    // QuickBlox session creation
    QBASessionCreationRequest *extendedAuthRequest = [[QBASessionCreationRequest alloc] init];
    extendedAuthRequest.userLogin = @"emma";
    extendedAuthRequest.userPassword = @"emma";
    
    [QBAuth createSessionWithExtendedRequest:extendedAuthRequest delegate:self];
    
    
    if (IS_HEIGHT_GTE_568) {
        CGRect frame = self.activityIndicator.frame;
        frame.origin.y += 44;
        [self.activityIndicator setFrame:frame];
    }
}

- (void)viewDidUnload {
    [self setActivityIndicator:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)hideSplashScreen {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark QBActionStatusDelegate

// QuickBlox API queries delegate
- (void)completedWithResult:(Result*)result {
    
    // QuickBlox session creation result
    if ([result isKindOfClass:[QBAAuthSessionCreationResult class]]) {
        
        // Success result
        if (result.success) {
            
            // Get average ratings
            [QBRatings averagesForApplicationWithDelegate:self];
        
        // show Errors
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", "")
                                                            message:[result.errors description]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", "")
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
    // Get average ratings result
    } else if ([result isKindOfClass:QBRAveragePagedResult.class]) {
        
        // Success result
        if (result.success) {
            
            QBRAveragePagedResult *res = (QBRAveragePagedResult *)result;
            
            [res.averages enumerateObjectsUsingBlock:^(QBRAverage* average, NSUInteger idx, BOOL *stop) {
                [self setFilmAverageValue:average];
            }];
           
            [[NSNotificationCenter defaultCenter] postNotificationName:@"mainControllerWillUpdateTable" object:nil];
            // hide splash
            [self performSelector:@selector(hideSplashScreen) withObject:self afterDelay:1];
        }
    }
}

- (void)setFilmAverageValue:(QBRAverage *)average {
    NSSet *moviesSet = [NSSet setWithArray:[DataManager shared].movies];
    
    NSSet *foundObjects = [moviesSet objectsPassingTest:^BOOL(Movie *movie, BOOL *stop) {
        return movie.gameModeID == average.gameModeID;
    }];
    
    Movie *foundMovie = [foundObjects anyObject];
    if (foundMovie) {
        [foundMovie setRating:average.value];
    }    
}

@end
