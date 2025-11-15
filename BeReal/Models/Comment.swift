//
//  Comment.swift
//  BeReal
//
//  Created by Claudia Espinosa on 11/15/25.
//

import Foundation
import ParseSwift

struct Comment: ParseObject {
    // Required ParseObject fields
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    // Custom fields
    var text: String?
    var user: User?
    var post: Post?
}
