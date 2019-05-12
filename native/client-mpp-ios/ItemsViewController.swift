/*
 * Copyright 2019 Simon Schubert Use of this source code is governed by the Apache 2.0 license
 * that can be found in the LICENSE file.
 */

import UIKit

import main

class ItemsViewController: UITableViewController {
    let api = Api()
    var data = ([Item])()
    var itemId: Int64 = 0
    var type: Int64 = 0
    var rowHeights: [Int: CGFloat] = [:]
    var defaultHeight: CGFloat = 43

    override func viewDidLoad() {
        super.viewDidLoad()

        let refreshControl = UIRefreshControl()
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(refreshItemData(_:)), for: .valueChanged)

        tableView.tableFooterView = UIView()

        let database = Database()
        self.data = database.getItems(feedId: itemId, type: type) as! [Item]
        self.tableView?.reloadData()

        self.tableView.refreshManually()
        fetchItemData()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = self.rowHeights[indexPath.row] {
            return height
        } else {
            return defaultHeight
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "item", for: indexPath) as! ItemTableViewCell

        let item = data[indexPath.row]
        
        cell.titleLabel?.text = item.title
        cell.coverImageView?.kf.setImage(with: URL(string: item.imageUrl)) { result in
            switch result {
            case .success(let value):
                let aspectRatio = value.image.size.height/value.image.size.width
                let imageHeight = self.view.frame.width*aspectRatio
                tableView.beginUpdates()
                self.rowHeights[indexPath.row] = imageHeight
                tableView.endUpdates()
                print("success")
            case .failure(_):
                tableView.beginUpdates()
                self.rowHeights[indexPath.row] = cell.titleLabel?.bounds.size.height
                tableView.endUpdates()
                print("fail")
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = data[indexPath.row]

        guard let url = URL(string: item.url) else { return }
        UIApplication.shared.open(url)
    }

    @objc private func refreshItemData(_ sender: Any) {
        fetchItemData()
    }

    private func fetchItemData() {
        api.getItems(id: itemId
                     , type: type
                     , offset: false
                     , callback: { (items) in
                         self.data = items
                         self.tableView?.reloadData()
                         self.refreshControl?.endRefreshing()
                         return KotlinUnit()
                     }) { () in
            self.refreshControl?.endRefreshing()
            return KotlinUnit()
        }
    }
}

class ItemTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
}
