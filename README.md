# SwiftyBridges

- Are you or your team working on a server and client in Swift?
- Are you tired of worrying about HTTP and generating requests and responses?
- Do you want to skip cobbling together an API client?

SwiftyBridges is here to help! 😎

## What is SwiftyBridges?

SwiftyBridges lets you write the server logic in a simple way and then automatically generates an API client plus all communication code for both server and client.

Server code:

```swift
import SwiftyBridges
import Vapor

struct HelloAPI: APIDefinition {
    var request: Request
    
    public func hello(firstName: String, lastName: String) -> String {
        "Hello, \(firstName) \(lastName)!"
    }
}
```

Client code:

```swift
import SwiftyBridgesClient

let api = HelloAPI(url: serverURL)

let greeting = try await api.hello(firstName: "Swifty", lastName: "Bridges")
print(greeting)
```

## Requirements

Server: Vapor >= 4.0

Code generation: Xcode 13.0

Client: Swift >= 5.5

## Usage

### Server

Create an API definition:

```swift
import SwiftyBridges

struct IceCreamAPI: APIDefinition {
    var request: Request
    
    public func getAllFlavors() -> [IceCreamFlavor] {
        [
            IceCreamFlavor(name "Chocolate"),
            IceCreamFlavor(name "Vanilla"),
        ]
    }
}
```

Conform the API definition `struct` to `APIDefinition` and make methods that shall be available to the client `public`.

All parameter and return types of `public` must conform to `Codable` (or be [futures](#optional-features) of `Codable` types):

```swift
struct IceCreamFlavor: Codable {
    var name
}
```

Create an instance of `APIRouter`:

```swift
import SwiftyBridges

let apiRouter = APIRouter()
```

Register all API definitions:

```swift
apiRouter.register(IceCreamAPI.self)
```

Set up a POST route for the API router:

```swift
app.post("api") { req -> EventLoopFuture<Response> in
    apiRouter.handle(req)
}
```

#### Optional Features {#optional-features}

API methods may return futures of `Codable` values:

```swift
public func getAllFlavors() -> EventLoopFuture<[IceCreamFlavor]> {
    ...
}
```

API methods may throw:

```swift
public func getAllFlavors() throws -> EventLoopFuture<[IceCreamFlavor]> {
    ...
}
```

API definitions may use middlewares:

```swift
struct IceCreamAPI: APIDefinition {
    static let middlewares: [Middleware] = [
        UserToken.authenticator(),
        User.guardMiddleware(), // <- Optional
    ]
    
    var request: Request
    var user: User
    
    init(request: Request) throws {
        guard let user = request.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated.")
        }
        
        self.request = request
        self.user = user
    }
    
    ...
}
```

### Code generation

> :warning: **Code generation currently needs the command line tools of Xcode 13.0**

To generate the communication code for both server and client, run the following commands in terminal:

```console
git clone https://github.com/SwiftyBridges/SwiftyBridgesVapor.git
cd SwiftyBridgesVapor
swift run BridgeBuilder [path to server package]/Sources/App --server-output [path to server package]/Sources/App/Generated.swift --client-output [path to client code]/Generated.swift
```

Then make sure that the generated Swift files for both server and client are in the right directories and are compiled.

### Client

Make sure all `Codable` types that are used by the API methods are available to the generated code.

Then use the API:

```swift
import SwiftyBridgesClient

let api = IceCreamAPI(url: serverURL)

let flavors: [IceCreamFlavor] = try await api.getAllFlavors()
```

That's it!

## Installation

### Server

Add `SwiftyBridgesVapor` to your `Package.swift`:

```swift
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MyServer",
    dependencies: [
        .package(url: "https://github.com/SwiftyBridges/SwiftyBridgesVapor.git", .upToNextMinor(from: "0.1")),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "SwiftyBridges", package: "SwiftyBridges"),
            ]
        ),
    ]
)
```

### Client

Add `SwiftyBridgesClient` with a version matching the version of `SwiftyBridgesVapor` used by the server in Xcode or to your `Package.swift`:

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/SwiftyBridges/SwiftyBridgesClient.git", .upToNextMinor(from: "0.1")),
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product(name: "SwiftyBridgesClient", package: "SwiftyBridgesClient"),
            ]
        ),
    ]
)
```

## Authentication

A simple way to implement authentication is via bearer tokens:

On the server, use `BearerAuthenticator` or `ModelTokenAuthenticatable` as described in the [Vapor documentation](https://docs.vapor.codes/4.0/authentication/).

For example, if you are using [Fluent](https://github.com/vapor/fluent), conform your token model to `ModelTokenAuthenticatable`:

```swift
extension UserToken: ModelTokenAuthenticatable {
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user

    var isValid: Bool {
        Date() < expirationDate // <- If tokens do not expire, simply return true
    }
}
```

Then you can restrict one of your API definitions to logged in users:

```swift
struct IceCreamAPI: APIDefinition {
    static let middlewares: [Middleware] = [
        UserToken.authenticator(),
        User.guardMiddleware(), // <- Only needed if you don't use the `init()` below.
    ]
    
    var request: Request
    var user: User
    
    init(request: Request) throws {
        guard let user = request.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "User not authenticated.")
        }
        
        self.request = request
        self.user = user
    }
    
    ...
}
```

On the client, you can pass the user token as the bearer token:

```swift
let api = IceCreamAPI(url: serverURL, bearerToken: userToken)
```

Authentication may also be done by:

- Explicitly passing the user token:
    ```swift
    public func getAllFlavors(userToken: String) -> [IceCreamFlavor]
    ```
- Passing authentication information in the URL query:
    ```swift
    let api = IceCreamAPI(url: serverURLWithConfiguredQuery)
    ```
- Passing authentication information HTTP headers:
    ```swift
    let api = IceCreamAPI(baseRequest: requestWithPresetHTTPHeaders)
    ```

### Login

Login may for example be implemented using an unauthenticated API definition like so:

```swift
import Fluent
import SwiftyBridges
import Vapor

/// Allows the user to log in and to register an account
struct LoginAPI: APIDefinition {
    var request: Request
    
    /// Allows the user to log in
    /// - Parameters:
    ///   - username: The username of the user
    ///   - password: The password of the user
    /// - Returns: A user token needed to perform subsequent API calls for this user
    public func logIn(username: String, password: String) throws -> EventLoopFuture<String> {
        User.query(on: request.db)
            .filter(\.$name == username)
            .first()
            .flatMapThrowing { foundUser -> UserToken in
                guard
                    let user = foundUser,
                    try user.verify(password: password)
                else {
                    throw Abort(.unauthorized)
                }
                return try user.generateToken()
            }.flatMap { token in
                token.save(on: request.db)
                    .map { token.value }
            }
    }
}
```

The client can then use the returned user token as the bearer token as explained above.

### Login Expiration

If the login has expired, the server can throw an `Abort(.unauthorized)` or just use a middleware like `UserToken.authenticator()` in combination with `User.guardMiddleware()`.

On the client-side, this can be handled like this:

```swift
let iceCreamAPI = IceCreamAPI(url: serverURL, bearerToken: userToken)

let httpErrors = iceCreamAPI.errors
    .compactMap { $0 as? HTTPError }

Task {
    if await httpErrors.first(where: { $0.isUnauthorizedError }) != nil {
        handleExpiredLogin()
    }
}
```

## Current Limitations

- SwiftyBridges currently only supports [Vapor](https://vapor.codes/) on the server-side
- Server-side API methods do not currently support the following features:
    - Default parameter values
    - Variadic parameters
    - `async`
- All errors thrown by API methods are currently converted to `HTTPError` on the client
- Running code generation as part of the server code compilation is currently not supported. This will hopefully change when [package plugins](https://github.com/apple/swift-evolution/blob/main/proposals/0303-swiftpm-extensible-build-tools.md) land in Swift 5.6.

If any of these limitations is bothering you, please get in touch.
