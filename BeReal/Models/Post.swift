//
//  Post.swift
//  BeReal
//
//  Created by Claudia Espinosa on 10/10/25.
//

import Foundation
import ParseSwift

struct Post: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var caption: String?
    var user: User?
    var imageFile: ParseFile?
    var location: String?
    var comments: [Comment]?
}
