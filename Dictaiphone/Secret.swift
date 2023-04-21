//
//  Secret.swift
//  Dictaiphone
//
//  Created by Stefan Britton on 2023-04-20.
//

import Foundation

struct Secret {
    static func string(for key: String) -> String {
        Bundle.main.infoDictionary?[key] as? String ?? ""
    }
}

struct OpenAI {
    static var apiKey: String {
        Secret.string(for: "OPENAI_API_KEY")
    }
}
