//
//  Utilities.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 26/06/2026.
//

import Foundation
import UIKit

final class Utilities {
    
    static let shared = Utilities()
    private init() {}
    
    // NEW: Safely retrieves the active window across connected scenes
    @MainActor
    var topWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    @MainActor
    func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        // FIXED: Using our new topWindow property instead of the deprecated keyWindow
        let controller = controller ?? topWindow?.rootViewController
        
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        
        return controller
    }
}
