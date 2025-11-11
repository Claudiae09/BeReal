//
//  DateFormatter+Extensions.swift
//  BeReal
//
//  Created by Claudia Espinosa on 10/10/25.
//

import Foundation

extension DateFormatter {
    static var postFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
}
