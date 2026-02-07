import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: CVController())
    try app.register(collection: UserController())
    try app.register(collection: VacancyController())
    try app.register(collection: VacancyApplicationController())
    
    app.get { req in
            return "InternView API is running!"
        }
        
        // Статистика API
        app.get("status") { req -> [String: String] in
            return [
                "status": "ok",
                "service": "InternView API",
                "version": "1.0.0"
            ]
        }
}
