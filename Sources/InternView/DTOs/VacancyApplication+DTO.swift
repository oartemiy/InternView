import Vapor

extension VacancyApplication {
    struct CreateDTO: Content {
        let vacancyId: UUID
        let coverLetter: String?
        let resumeUrl: String?
        let cvId: UUID // Теперь обязательное!
    }
    
    struct UpdateDTO: Content {
        let status: String?
        let coverLetter: String?
        let resumeUrl: String?
    }
    
    struct ResponseDTO: Content {
        let id: UUID
        let vacancyId: UUID
        let internId: UUID
        let cvId: UUID // Теперь обязательное!
        let status: String
        let coverLetter: String?
        let resumeUrl: String?
        let appliedAt: Date?
        let intern: User.ResponseDTO?
        let cv: CV.ResponseDTO?
    }
    
    convenience init(from dto: CreateDTO, internID: User.IDValue) {
        self.init(
            vacancyID: dto.vacancyId,
            internID: internID,
            cvID: dto.cvId, // Теперь обязательное!
            coverLetter: dto.coverLetter,
            resumeURL: dto.resumeUrl
        )
    }
    
    func toResponseDTO(
        intern: User? = nil,
        cv: CV? = nil
    ) -> ResponseDTO {
        guard let cv = cv else {
            fatalError("CV must be loaded before converting to ResponseDTO")
        }
        
        let internDTO = intern?.toResponseDTO()
        let cvDTO = cv.toResponseDTO()
        
        return ResponseDTO(
            id: self.id ?? UUID(),
            vacancyId: self.$vacancy.id,
            internId: self.$intern.id,
            cvId: self.$cv.id,
            status: self.status,
            coverLetter: self.coverLetter,
            resumeUrl: self.resumeURL,
            appliedAt: self.appliedAt,
            intern: internDTO,
            cv: cvDTO
        )
    }
}
