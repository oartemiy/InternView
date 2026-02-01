import Fluent
import FluentPostgresDriver
import NIOSSL
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.middleware.use(
        FileMiddleware(publicDirectory: app.directory.publicDirectory)
    )
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.keyEncodingStrategy = .convertToSnakeCase

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    ContentConfiguration.global.use(
        encoder: encoder,
        for: .json
    )
    ContentConfiguration.global.use(
        decoder: decoder,
        for: .json
    )

    app.databases.use(
        DatabaseConfigurationFactory.postgres(
            configuration: .init(
                hostname: Environment.get("DATABASE_HOST") ?? "localhost",
                port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:))
                    ?? SQLPostgresConfiguration.ianaPortNumber,
                username: Environment.get("DATABASE_USERNAME")
                    ?? "intern_username",
                password: Environment.get("DATABASE_PASSWORD")
                    ?? "intern_password",
                database: Environment.get("DATABASE_NAME") ?? "intern_database",
                tls: .prefer(try .init(configuration: .clientDefault))
            )
        ),
        as: .psql
    )

    app.migrations.add(CreateCV())
    try app.autoMigrate().wait()
    // register routes
    try routes(app)
}
