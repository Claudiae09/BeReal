//
//  PostCell.swift
//  BeReal
//
//  Created by Claudia Espinosa on 10/10/25.
//

import UIKit
import Alamofire
import AlamofireImage

protocol PostCellDelegate: AnyObject {
    func postCellDidTapComment(_ cell: PostCell)
}

class PostCell: UITableViewCell {

    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var postImageView: UIImageView!
    @IBOutlet private weak var captionLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var commentsLabel: UILabel!
    @IBAction private func onCommentButtonTapped(_ sender: UIButton) {
        delegate?.postCellDidTapComment(self)
    }

    
    weak var delegate: PostCellDelegate?
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private let blurView: UIVisualEffectView = {
            let effect = UIBlurEffect(style: .regular)
            let view = UIVisualEffectView(effect: effect)
            view.isHidden = true
            return view
        }()

    private var imageDataRequest: DataRequest?
    
    override func awakeFromNib() {
            super.awakeFromNib()
            
            postImageView.addSubview(blurView)
            blurView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                blurView.topAnchor.constraint(equalTo: postImageView.topAnchor),
                blurView.leadingAnchor.constraint(equalTo: postImageView.leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: postImageView.trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: postImageView.bottomAnchor)
            ])
        }

    func configure(with post: Post) {

        if let user = post.user {
            usernameLabel.text = user.username
        }

        if let imageFile = post.imageFile,
           let imageUrl = imageFile.url {

            imageDataRequest = AF.request(imageUrl).responseImage { [weak self] response in
                switch response.result {
                case .success(let image):
                    self?.postImageView.image = image
                case .failure(let error):
                    print("Error fetching image: \(error.localizedDescription)")
                    break
                }
            }
        }

        captionLabel.text = post.caption

        if let date = post.createdAt {
            var text = timeAgoString(from: date)

            if let location = post.location, !location.isEmpty {
                text += "  " + location
            }

            dateLabel.text = text
        }
        
        if let comments = post.comments, !comments.isEmpty {
                    let first = comments[0]
                    let commenter = first.user?.username ?? "Someone"
                    let commentText = first.text ?? ""
                    commentsLabel.text = "\(commenter): \(commentText)"
                } else {
                    commentsLabel.text = ""
                }


        if let currentUser = User.current,
           let lastPostedDate = currentUser.lastPostedDate,
           let postCreatedDate = post.createdAt,
           let diffHours = Calendar.current
                .dateComponents([.hour],
                                from: postCreatedDate,
                                to: lastPostedDate).hour {
            
            blurView.isHidden = abs(diffHours) < 24
            
        } else {
            blurView.isHidden = false
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        postImageView.image = nil
        imageDataRequest?.cancel()

        blurView.isHidden = false
    }
}
