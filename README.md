[![Build Status](https://travis-ci.org/anreitersimon/xcproj-manager.svg?branch=master)](https://travis-ci.org/anreitersimon/xcproj-manager)

# XCProjectManager
XCProjectManager generates/scaffolds Xcode workspace/project

XCProjectManager uses a spec file to generate a workspace + projects and folder structure

Example [here](Example/Example.md)

## Installing
Make sure Xcode 9 is installed first.

### Make

```
$ git clone https://github.com/anreitersimon/xcproj-manager
$ cd project-manager
$ make
```

### Swift Package Manager

**Use as CLI**

```
$ git clone https://github.com/anreitersimon/xcproj-manager.git
$ cd xcproj-manager
$ swift run xcproj-manager
```

**Use as dependency**

Add the following to your Package.swift file's dependencies:

```
.package(url: "https://github.com/anreitersimon/xcproj-manager.git", from: "1.0.0"),
```

And then import wherever needed: `import XCProjectManagerCore`

### Homebrew

```
$ brew tap anreitersimon/xcproj-manager https://github.com/anreitersimon/xcproj-manager.git
$ brew install xcproj-manager
```

## Usage

```
$ xcproj-manager generate --spec path/to/spec.yml
```

or

```
$ xcproj-manager scaffold --spec path/to/spec.yml
```

## Attributions

This tool is powered by:

- [xcodeproj](https://github.com/carambalabs/xcodeproj)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [JSONUtilities](https://github.com/yonaskolb/JSONUtilities)
- [PathKit](https://github.com/kylef/PathKit)
- [Commander](https://github.com/kylef/Commander)
- [Yams](https://github.com/jpsim/Yams)

Inspiration for this tool came from:

- [XcodeGen](https://github.com/workshop/XcodeGen)
- [microfeatures](https://github.com/microfeatures/guidelines)

## Contributions
Pull requests and issues are welcome

## License

XCProjectManager is licensed under the MIT license. See [LICENSE](LICENSE) for more info.
