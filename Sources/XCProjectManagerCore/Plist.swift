//
//  Fixtures.swift
//  XCProjectManagerCore
//
//  Created by Simon Anreiter on 02.01.18.
//

import Foundation

class Plist {
    static func app(
        DEVELOPMENT_LANGUAGE: String = "$(DEVELOPMENT_LANGUAGE)",
        EXECUTABLE_NAME: String = "$(EXECUTABLE_NAME)",
        PRODUCT_BUNDLE_IDENTIFIER: String = "$(PRODUCT_BUNDLE_IDENTIFIER)",
        PRODUCT_NAME: String = "$(PRODUCT_NAME)",
        CURRENT_PROJECT_VERSION: String = "$(CURRENT_PROJECT_VERSION)"
        ) -> Data {
        
        return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
            <key>CFBundleDevelopmentRegion</key>
            <string>\(DEVELOPMENT_LANGUAGE)</string>
            <key>CFBundleExecutable</key>
            <string>\(EXECUTABLE_NAME)</string>
            <key>CFBundleIdentifier</key>
            <string>\(PRODUCT_BUNDLE_IDENTIFIER)</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundleName</key>
            <string>\(PRODUCT_NAME)</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0.0</string>
            <key>CFBundleVersion</key>
            <string>\(CURRENT_PROJECT_VERSION)</string>
            <key>LSRequiresIPhoneOS</key>
            <true/>
            <key>UIRequiredDeviceCapabilities</key>
            <array>
                <string>armv7</string>
            </array>
            <key>UISupportedInterfaceOrientations</key>
            <array>
                <string>UIInterfaceOrientationPortrait</string>
                <string>UIInterfaceOrientationLandscapeLeft</string>
                <string>UIInterfaceOrientationLandscapeRight</string>
            </array>
            <key>UISupportedInterfaceOrientations~ipad</key>
            <array>
                <string>UIInterfaceOrientationPortrait</string>
                <string>UIInterfaceOrientationPortraitUpsideDown</string>
                <string>UIInterfaceOrientationLandscapeLeft</string>
                <string>UIInterfaceOrientationLandscapeRight</string>
            </array>
            </dict>
            </plist>
            """.data(using: .utf8)!
    }
    
    
    static func appUnitTests(
        DEVELOPMENT_LANGUAGE: String = "$(DEVELOPMENT_LANGUAGE)",
        EXECUTABLE_NAME: String = "$(EXECUTABLE_NAME)",
        PRODUCT_BUNDLE_IDENTIFIER: String = "$(PRODUCT_BUNDLE_IDENTIFIER)",
        PRODUCT_NAME: String = "$(PRODUCT_NAME)",
        CURRENT_PROJECT_VERSION: String = "$(CURRENT_PROJECT_VERSION)"
        ) -> Data {
        
        return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
            <key>CFBundleDevelopmentRegion</key>
            <string>\(DEVELOPMENT_LANGUAGE)</string>
            <key>CFBundleExecutable</key>
            <string>\(EXECUTABLE_NAME)</string>
            <key>CFBundleIdentifier</key>
            <string>\(PRODUCT_BUNDLE_IDENTIFIER)</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundleName</key>
            <string>\(PRODUCT_NAME)</string>
            <key>CFBundlePackageType</key>
            <string>BNDL</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0.0</string>
            <key>CFBundleSignature</key>
            <string>????</string>
            <key>CFBundleVersion</key>
            <string>\(CURRENT_PROJECT_VERSION)</string>
            </dict>
            </plist>
            """.data(using: .utf8)!
    }
    
    static func appUITests(
        DEVELOPMENT_LANGUAGE: String = "$(DEVELOPMENT_LANGUAGE)",
        EXECUTABLE_NAME: String = "$(EXECUTABLE_NAME)",
        PRODUCT_BUNDLE_IDENTIFIER: String = "$(PRODUCT_BUNDLE_IDENTIFIER)",
        PRODUCT_NAME: String = "$(PRODUCT_NAME)",
        CURRENT_PROJECT_VERSION: String = "$(CURRENT_PROJECT_VERSION)"
    ) -> Data {
        
        return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>CFBundleDevelopmentRegion</key>
                <string>\(DEVELOPMENT_LANGUAGE)</string>
                <key>CFBundleExecutable</key>
                <string>\(EXECUTABLE_NAME)</string>
                <key>CFBundleIdentifier</key>
                <string>\(PRODUCT_BUNDLE_IDENTIFIER)</string>
                <key>CFBundleInfoDictionaryVersion</key>
                <string>6.0</string>
                <key>CFBundleName</key>
                <string>\(PRODUCT_NAME)</string>
                <key>CFBundlePackageType</key>
                <string>BNDL</string>
                <key>CFBundleShortVersionString</key>
                <string>1.0.0</string>
                <key>CFBundleVersion</key>
                <string>\(CURRENT_PROJECT_VERSION)</string>
            </dict>
            </plist>
            """.data(using: .utf8)!
    }
    
    static func frameworkTarget(
        DEVELOPMENT_LANGUAGE: String = "$(DEVELOPMENT_LANGUAGE)",
        EXECUTABLE_NAME: String = "$(EXECUTABLE_NAME)",
        PRODUCT_BUNDLE_IDENTIFIER: String = "$(PRODUCT_BUNDLE_IDENTIFIER)",
        PRODUCT_NAME: String = "$(PRODUCT_NAME)",
        CURRENT_PROJECT_VERSION: String = "$(CURRENT_PROJECT_VERSION)"
        ) -> Data {
        
        return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
            <key>CFBundleDevelopmentRegion</key>
            <string>\(DEVELOPMENT_LANGUAGE)</string>
            <key>CFBundleExecutable</key>
            <string>\(EXECUTABLE_NAME)</string>
            <key>CFBundleIdentifier</key>
            <string>\(PRODUCT_BUNDLE_IDENTIFIER)</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundleName</key>
            <string>\(PRODUCT_NAME)</string>
            <key>CFBundlePackageType</key>
            <string>FMWK</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0.0</string>
            <key>CFBundleVersion</key>
            <string>\(CURRENT_PROJECT_VERSION)</string>
            <key>NSPrincipalClass</key>
            <string></string>
            </dict>
            </plist>
            """.data(using: .utf8)!
    }
    
    static func frameworkTargetTests(
        DEVELOPMENT_LANGUAGE: String = "$(DEVELOPMENT_LANGUAGE)",
        EXECUTABLE_NAME: String = "$(EXECUTABLE_NAME)",
        PRODUCT_BUNDLE_IDENTIFIER: String = "$(PRODUCT_BUNDLE_IDENTIFIER)",
        PRODUCT_NAME: String = "$(PRODUCT_NAME)",
        CURRENT_PROJECT_VERSION: String = "$(CURRENT_PROJECT_VERSION)"
        ) -> Data {
        
        return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
            <key>CFBundleDevelopmentRegion</key>
            <string>\(DEVELOPMENT_LANGUAGE)</string>
            <key>CFBundleExecutable</key>
            <string>\(EXECUTABLE_NAME)</string>
            <key>CFBundleIdentifier</key>
            <string>\(PRODUCT_BUNDLE_IDENTIFIER)</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundleName</key>
            <string>\(PRODUCT_NAME)</string>
            <key>CFBundlePackageType</key>
            <string>BNDL</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0.0</string>
            <key>CFBundleVersion</key>
            <string>\(CURRENT_PROJECT_VERSION)</string>
            </dict>
            </plist>
            """.data(using: .utf8)!
    }
    
    
    
    static func resourceBundle(
        BUNDLE_IDENTIFIER: String = "$(PRODUCT_BUNDLE_IDENTIFIER)",
        PRODUCT_NAME: String = "$(PRODUCT_NAME)",
        BUNDLE_VERSION: String = "1"
        ) -> Data {
        
        return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>CFBundleDisplayName</key>
                <string>\(PRODUCT_NAME)</string>
                <key>CFBundleIdentifier</key>
                <string>\(BUNDLE_IDENTIFIER)</string>
                <key>CFBundleShortVersionString</key>
                <string>1.0.0</string>
                <key>CFBundleVersion</key>
                <string>\(BUNDLE_VERSION)</string>
            </dict>
            </plist>
            """.data(using: .utf8)!
    }
    
    
    

}
