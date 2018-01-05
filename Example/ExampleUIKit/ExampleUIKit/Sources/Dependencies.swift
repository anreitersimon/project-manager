import Foundation
import Core

public protocol ExampleUIKitDependenciesProtocol {

}

public final class ExampleUIKitDescription {

    public static var features: [Any.Type] {
        return [
            CoreDescription.self
        ]
    }

    public static var bundles: [Bundle] {
        return [
        CoreDescription.resources
        ].flatMap { $0 }
    }

    public static var resources: Bundle? {
        return Bundle.main
            .url(forResource: "ExampleUIKitResources", withExtension: "bundle", subdirectory: nil)
            .flatMap { Bundle(url: $0) }
    }
}
