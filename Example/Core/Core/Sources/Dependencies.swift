import Foundation

public protocol CoreDependenciesProtocol {

}

public final class CoreDescription {

    public static var features: [Any.Type] {
        return [
            
        ]
    }

    public static var bundles: [Bundle] {
        return [
        
        ].flatMap { $0 }
    }

    public static var resources: Bundle? {
        return Bundle.main
            .url(forResource: "CoreResources", withExtension: "bundle", subdirectory: nil)
            .flatMap { Bundle(url: $0) }
    }
}
