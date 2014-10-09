//
//  ViewController.m
//  LinkedIn
//
//  Created by Ashish on 07/10/14.
//  Copyright (c) 2014 individual. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

{
    NSString *getAuthorizationCode;
    NSString *getAccessToken;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Allocate the webView on the screen
    // add the webview to the subView
    // set the delegate to self
    tempWebview = [[UIWebView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:tempWebview];
    tempWebview.delegate=self;
    
    // Form the Url and provide certain parameters
    
    // Get the CLIENT ID - Form linked in
    // Get the STATE - it should be a unique ID which is given by you
    // Get the REDIRECT URL -  This should also be registered at the linked in redirect URl while you create your app
    
    //  **************  Method to Form the URL after the above parameters are provided *************
    
    NSString *getTheFormedAuthorizatioURl=[ViewController getTheFormedUrlForLinkedInAuthorization:@"" state:@"" redirect:@""];
    
    // load the URL on the View, if every thing goes fine the URl would load ont he webview and a linked In dialog fro entering USername and Password would come up
    
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:getTheFormedAuthorizatioURl]];
    [tempWebview loadRequest:requestObj];
    
    
    // ************ After this enter Username and Password on the webview that appeared ************

}

+(NSString *)getTheFormedUrlForLinkedInAuthorization :(NSString *)clientId state:(NSString *)uniqueState redirect:(NSString *)redirectURL{
    
    static NSString *getTheFormedURL;
    
    getTheFormedURL=[NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth2/authorization?response_type=code&client_id=%@&state=%@&redirect_uri=%@",clientId,uniqueState,redirectURL];
    
    return getTheFormedURL;
    
}

- (NSString*) stringBetweenString:(NSString*)start andString:(NSString*)end {
    NSScanner* scanner = [NSScanner scannerWithString:tempString];
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanUpToString:start intoString:NULL];
    if ([scanner scanString:start intoString:NULL]) {
        NSString* result = nil;
        if ([scanner scanUpToString:end intoString:&result]) {
            return result;
        }
    }
    return nil;
}

#pragma mark - Delgate Of WebView

// WebView called when request is loaded

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    // loaded one time ignore as authorixation has been done
    i++;
    
    // loaded second time once you enter username and Password on the web dialog
    if(i==2){
        
        // get the URL currently on the WebView URL dialog
        NSString *currentURL = webView.request.URL.absoluteString;
        // store that URL in the temp String
        tempString=currentURL;
        
        // get the Authorization Code form the URL of the
        getAuthorizationCode=[self stringBetweenString:@"code=" andString:@"&state="];
        
        // return if tghe length of the authorization token is not valid
        if(getAuthorizationCode.length==0){
            
            return;
        }
        
        // ************ CAll the Method for the POST webservice to get Access Token ************
        [self getTheAccessToken];

       }

}

// Get the access Token POST webservice

-(void)getTheAccessToken{
    
    // Form the POST request for the Access Token and send all the required info
    
    NSString *getTheFormedUrlForAccessToken= [ViewController getTheUrlForAccessToken:@"" redirect:@"" secret:@"" code:getAuthorizationCode];
    NSData *postData = [getTheFormedUrlForAccessToken dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d",[postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth2/accessToken?"]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    NSURLConnection *conn = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    
    if(conn) {
        
        NSLog(@"Connection Successful");
    } else {
        
        NSLog(@"Connection could not be made");
    }

    
}

// form the URL for the Access Token

+(NSString *)getTheUrlForAccessToken :(NSString *)clientId redirect:(NSString *)redirectURL secret:(NSString *)client_Secret code:(NSString *)authorization_Code{
    
    static NSString * getTheAccessTokenURL;
     getTheAccessTokenURL = [NSString stringWithFormat:@"grant_type=authorization_code&code=%@&redirect_uri=%@&client_id=%@&client_secret=%@",authorization_Code,redirectURL,clientId,client_Secret];
    return getTheAccessTokenURL;
}

#pragma mark - Response of the Access Token

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData*)data{
    
    // Conver the data in Json
    id json=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    
    // store theAccess Token and use for future request of the REST api
    getAccessToken=[json valueForKey:@"access_token"];
    
    // remove the WebView
    [tempWebview removeFromSuperview];
    
    // ************* Call the Methods to link to the Linked In Service to get Details  **********
    [self getLinkedInUserDetails];
    
}

#pragma mark - get the Linked in Methods

// Method is used to get the User details

-(void)getLinkedInUserDetails{
    
    NSURLSession *session=[NSURLSession sharedSession];
    NSString *urlStringWithToken = [NSString stringWithFormat:@"https://api.linkedin.com/v1/people/~:(id,first-name,last-name,maiden-name,email-address,formatted-name,phonetic-last-name,location:(country:(code)),industry,distance,current-status,current-share,network,skills,phone-numbers,date-of-birth,main-address,positions:(title),educations:(school-name,field-of-study,start-date,end-date,degree,activities))?oauth2_access_token=%@&format=json", getAccessToken];
    [[session dataTaskWithURL:[NSURL URLWithString:urlStringWithToken] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        // Parse the data in the form of Json
        id json=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        NSLog(@"%@",json);
        
    }]resume];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
