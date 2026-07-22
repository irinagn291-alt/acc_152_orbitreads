import UIKit
@preconcurrency import Alamofire

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        AppConfiguration.serverBaseURL = "https://warpages-flightdeck.pro"
        WebViewUserAgent.install()
        return true
    }
}
