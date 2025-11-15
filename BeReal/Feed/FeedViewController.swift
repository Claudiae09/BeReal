//
//  FeedViewController.swift
//  BeReal
//
//  Created by Claudia Espinosa on 10/10/25.
//

import UIKit
import ParseSwift

class FeedViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    private var posts = [Post]() {
        didSet {
            tableView.reloadData()
        }
    }

    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false

        refreshControl.addTarget(self,
                                 action: #selector(didPullToRefresh(_:)),
                                 for: .valueChanged)

        refreshControl.tintColor = .systemBlue
        tableView.refreshControl = refreshControl
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        queryPosts()
    }

    @objc private func didPullToRefresh(_ sender: UIRefreshControl) {
        queryPosts()
    }

    private func queryPosts() {

        let yesterdayDate = Calendar.current.date(byAdding: .day,
                                                  value: -1,
                                                  to: Date())!

        let query = Post.query()
            .include("user")
            .include("comments")
            .include("comments.user")
            .order([.descending("createdAt")])
            .where("createdAt" >= yesterdayDate)
            .limit(10)

        query.find { [weak self] result in
            guard let self = self else { return }

            self.refreshControl.endRefreshing()

            switch result {
            case .success(let posts):
                self.posts = posts
            case .failure(let error):
                self.showAlert(description: error.localizedDescription)
            }
        }
    }

    @IBAction func onLogOutTapped(_ sender: Any) {
        showConfirmLogoutAlert()
    }

    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(title: "Log out of your account?",
                                                message: nil,
                                                preferredStyle: .alert)
        let logOutAction = UIAlertAction(title: "Log out",
                                         style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"),
                                            object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...",
                                                message: "\(description ?? "Please try again...")",
                                                preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

extension FeedViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell",
                                                       for: indexPath) as? PostCell else {
            return UITableViewCell()
        }

        cell.configure(with: posts[indexPath.row])
        cell.delegate = self
        return cell
    }
}


extension FeedViewController: UITableViewDelegate { }

extension FeedViewController: PostCellDelegate {
    
    func postCellDidTapComment(_ cell: PostCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let post = posts[indexPath.row]
        
        let alert = UIAlertController(title: "Add Comment",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Write a comment..."
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        let postAction = UIAlertAction(title: "Post", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            guard let text = alert.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else {
                return
            }
            
            var comment = Comment()
            comment.text = text
            comment.user = User.current
            comment.post = post
            
            comment.save { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let savedComment):
                        print("✅ Comment saved:", savedComment)
                        
                        var updatedPost = post
                        if var existing = updatedPost.comments {
                            existing.insert(savedComment, at: 0)
                            updatedPost.comments = existing
                        } else {
                            updatedPost.comments = [savedComment]
                        }
                        
                        self.posts[indexPath.row] = updatedPost
                        
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        
                    case .failure(let error):
                        self.showAlert(description: error.localizedDescription)
                    }
                }
            }
        }
        
        alert.addAction(cancel)
        alert.addAction(postAction)
        present(alert, animated: true)
    }
}
