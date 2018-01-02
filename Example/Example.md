Given a spec file like this:

```yaml
name: Example
files:
  - example.yml

apps:
  Example:
    carthageDependencies:
      - RxDataSources
      - Differentiator
      - RxSwift
      - RxCocoa
      - Differentiator
    dependencies:
      - Core
      - ExampleUIKit
      - Persistence
      - Authorization

features:
  Core:
    carthageDependencies:
      - Alamofire
      - RxSwift
      - Moya
      - RxMoya
  ExampleUIKit:
    dependencies:
      - Core

```

XCProjectManager will generate the following files

```
|____Example.xcworkspace
|____example.yml
|____Example
| |____Example.xcodeproj
| |____Example
| | |____Config
| | |____Resources
| | |____Sources
| | | |____Dependencies.swift
| | | |____AppDelegate.swift
| | |____Info.plist
| |____ExampleUI-Tests
| | |____Config
| | |____Resources
| | |____Sources
| | |____Info.plist
| |____ExampleTests
| | |____Config
| | |____Resources
| | |____Sources
| | |____Info.plist
|____Core
| |____Core
| | |____Config
| | |____Resources
| | |____Sources
| | | |____Dependencies.swift
| | |____Info.plist
| |____CoreTests
| | |____Config
| | |____Resources
| | |____Sources
| | |____Info.plist
| |____Core.xcodeproj
|____ExampleUIKit
| |____ExampleUIKitTests
| | |____Config
| | |____Resources
| | |____Sources
| | |____Info.plist
| |____ExampleUIKit
| | |____Config
| | |____Resources
| | |____Sources
| | | |____Dependencies.swift
| | |____Info.plist
| |____ExampleUIKit.xcodeproj
```
