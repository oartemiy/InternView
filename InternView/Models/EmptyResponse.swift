//
//  EmptyResponse.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation

struct EmptyResponse: Codable {
    init() {}
    init(from decoder: Decoder) throws {
        // ничего не делаем, тело пустое
    }
}
