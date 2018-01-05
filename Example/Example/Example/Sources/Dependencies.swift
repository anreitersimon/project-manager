import Foundation
import Core
import ExampleUIKit

public protocol ExampleDependenciesProtocol {

}

public final class ExampleDescription {

    public static var features: [Any.Type] {
        return [
            CoreDescription.self,
          ExampleUIKitDescription.self
        ]
    }

    public static var bundles: [Bundle] {
        return [
        CoreDescription.resources,
          ExampleUIKitDescription.resources
        ].flatMap { $0 }
    }


}
