//
//  Comment.swift
//  BeReal
//
//  Created by Claudia Espinosa on 11/15/25.
//

import Foundation
import ParseSwift

struct Comment: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var text: String?
    var user: User?
    var post: Post?
}
