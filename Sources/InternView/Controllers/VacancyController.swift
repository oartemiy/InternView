//
//  VacancyController.swift
//  InternView
//
//  Created by Артемий Образцов on 07.02.2026.
//

import Fluent
import Vapor

struct VacancyController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let vacanciesGroup = routes.grouped("vacancies")

        // Публичные маршруты (чтение)
        vacanciesGroup.get(use: getAllHandler)
        vacanciesGroup.get(":vacancyId", use: getHandler)
        vacanciesGroup.get(":vacancyId", "applications", use: getApplicationsHandler)

        // Защищенные маршруты (требуют авторизации)
        let basicMW = User.authenticator()
        let guardMW = User.guardMiddleware()
        let protected = vacanciesGroup.grouped(basicMW, guardMW)

        protected.post(use: createHandler)
        protected.put(":vacancyId", use: updateHandler)
        protected.delete(":vacancyId", use: deleteHandler)
        protected.patch(":vacancyId", "toggle", use: toggleActiveHandler)
        protected.get("my", use: getMyVacanciesHandler)
    }

    // MARK: - CRUD

    // Создание вакансии (только для рекрутеров)
    func createHandler(_ req: Request) async throws -> Vacancy.ResponseDTO {
        let user = try req.auth.require(User.self)

        guard user.role == "recruiter" else {
            throw Abort(.forbidden, reason: "Only recruiters can create vacancies")
        }

        let createDTO = try req.content.decode(Vacancy.CreateUpdateDTO.self)
        let vacancy = Vacancy(from: createDTO, recruiterID: user.id!)

        try await vacancy.save(on: req.db)
        
        // Сразу загружаем связанные данные
        try await vacancy.$recruiter.load(on: req.db)
        
        return vacancy.toResponseDTO(
            applicationCount: 0,
            recruiter: vacancy.recruiter
        )
    }

    // Получение всех вакансий
    func getAllHandler(_ req: Request) async throws -> [Vacancy.SimpleDTO] {
        // Дебаг-логирование
        req.logger.info("=== GET /vacancies called ===")
        
        // Получаем все активные вакансии
        let query = Vacancy.query(on: req.db)
            .filter(\.$isActive == true)
            .sort(\.$createdAt, .descending)
        
        let vacancies = try await query.all()
        
        req.logger.info("Found \(vacancies.count) active vacancies")
        
        // Если не нашли активные, показываем все
        if vacancies.isEmpty {
            req.logger.info("No active vacancies found, showing all vacancies")
            let allVacancies = try await Vacancy.query(on: req.db)
                .sort(\.$createdAt, .descending)
                .all()
            
            req.logger.info("Total vacancies in DB: \(allVacancies.count)")
            return try await createSimpleDTOs(from: allVacancies, on: req.db)
        }
        
        return try await createSimpleDTOs(from: vacancies, on: req.db)
    }
    
    // Вспомогательная функция для создания DTO
    private func createSimpleDTOs(from vacancies: [Vacancy], on db: any Database) async throws -> [Vacancy.SimpleDTO] {
        var result: [Vacancy.SimpleDTO] = []
        
        for vacancy in vacancies {
            let applicationCount = try await vacancy.$applications.query(on: db).count()
            let dto = vacancy.toSimpleDTO(applicationCount: applicationCount)
            result.append(dto)
        }
        
        return result
    }

    // Получение конкретной вакансии
    func getHandler(_ req: Request) async throws -> Vacancy.SimpleDTO {
        guard let vacancyId = req.parameters.get("vacancyId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid Vacancy ID format")
        }

        guard let vacancy = try await Vacancy.query(on: req.db)
            .filter(\.$id == vacancyId)
            .first() else {
            throw Abort(.notFound, reason: "Vacancy not found")
        }

        let applicationCount = try await vacancy.$applications.query(on: req.db).count()
        return vacancy.toSimpleDTO(applicationCount: applicationCount)
    }

    // Обновление вакансии (только создатель)
    func updateHandler(_ req: Request) async throws -> Vacancy.ResponseDTO {
        let user = try req.auth.require(User.self)

        guard let vacancyId = req.parameters.get("vacancyId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid Vacancy ID format")
        }

        guard let vacancy = try await Vacancy.find(vacancyId, on: req.db) else {
            throw Abort(.notFound, reason: "Vacancy not found")
        }

        // Проверяем, что пользователь - создатель вакансии
        guard vacancy.$recruiter.id == user.id else {
            throw Abort(.forbidden, reason: "You can only update your own vacancies")
        }

        let updateDTO = try req.content.decode(Vacancy.CreateUpdateDTO.self)

        // Обновляем поля
        vacancy.title = updateDTO.title
        vacancy.description = updateDTO.description
        vacancy.requirements = updateDTO.requirements
        vacancy.salaryRange = updateDTO.salaryRange
        vacancy.location = updateDTO.location
        vacancy.workMode = updateDTO.workMode
        vacancy.experienceLevel = updateDTO.experienceLevel
        vacancy.expiresAt = updateDTO.expiresAt

        try await vacancy.update(on: req.db)
        
        // Загружаем связанные данные
        try await vacancy.$recruiter.load(on: req.db)
        let applicationCount = try await vacancy.$applications.query(on: req.db).count()

        return vacancy.toResponseDTO(
            applicationCount: applicationCount,
            recruiter: vacancy.recruiter
        )
    }

    // Удаление вакансии (только создатель)
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)

        guard let vacancyId = req.parameters.get("vacancyId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid Vacancy ID format")
        }

        guard let vacancy = try await Vacancy.find(vacancyId, on: req.db) else {
            throw Abort(.notFound, reason: "Vacancy not found")
        }

        // Проверяем, что пользователь - создатель вакансии
        guard vacancy.$recruiter.id == user.id else {
            throw Abort(.forbidden, reason: "You can only delete your own vacancies")
        }

        try await vacancy.delete(on: req.db)
        return .noContent
    }

    // MARK: - Дополнительные методы

    // Переключение активности вакансии
    func toggleActiveHandler(_ req: Request) async throws -> Vacancy.SimpleDTO {
        let user = try req.auth.require(User.self)

        guard let vacancyId = req.parameters.get("vacancyId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid Vacancy ID format")
        }

        guard let vacancy = try await Vacancy.find(vacancyId, on: req.db) else {
            throw Abort(.notFound, reason: "Vacancy not found")
        }

        // Проверяем, что пользователь - создатель вакансии
        guard vacancy.$recruiter.id == user.id else {
            throw Abort(.forbidden, reason: "You can only update your own vacancies")
        }

        vacancy.isActive.toggle()
        try await vacancy.update(on: req.db)

        let applicationCount = try await vacancy.$applications.query(on: req.db).count()
        return vacancy.toSimpleDTO(applicationCount: applicationCount)
    }

    // Получение вакансий текущего пользователя (рекрутера)
    func getMyVacanciesHandler(_ req: Request) async throws -> [Vacancy.SimpleDTO] {
        let user = try req.auth.require(User.self)

        guard user.role == "recruiter" else {
            throw Abort(.forbidden, reason: "Only recruiters have vacancies")
        }

        let vacancies = try await Vacancy.query(on: req.db)
            .filter(\.$recruiter.$id == user.id!)
            .sort(\.$createdAt, .descending)
            .all()
        
        return try await createSimpleDTOs(from: vacancies, on: req.db)
    }

    // Получение всех откликов на вакансию
    func getApplicationsHandler(_ req: Request) async throws -> [VacancyApplication.ResponseDTO] {
        guard let vacancyId = req.parameters.get("vacancyId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid Vacancy ID format")
        }

        // Проверяем существование вакансии
        guard let vacancy = try await Vacancy.find(vacancyId, on: req.db) else {
            throw Abort(.notFound, reason: "Vacancy not found")
        }

        // Если пользователь авторизован, проверяем права
        if let user = req.auth.get(User.self) {
            // Только создатель вакансии может видеть отклики
            guard vacancy.$recruiter.id == user.id else {
                throw Abort(.forbidden, reason: "You can only view applications for your own vacancies")
            }
        } else {
            throw Abort(.unauthorized)
        }

        let applications = try await VacancyApplication.query(on: req.db)
            .filter(\.$vacancy.$id == vacancyId)
            .with(\.$intern)
            .with(\.$cv) // Загружаем CV
            .sort(\.$appliedAt, .descending)
            .all()

        return applications.map { application in
            application.toResponseDTO(
                intern: application.intern,
                cv: application.cv
            )
        }
    }
}
