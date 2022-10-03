//
//  ViewController.swift
//  CloudKitExp
//
//  Created by Hafizh Mo on 02/10/22.
//

import UIKit
import CloudKit

class ViewController: UIViewController {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemMint
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        return tableView
    }()
    
    let database = CKContainer(identifier: "iCloud.iCloudMo.Exploration").publicCloudDatabase
    
    var items = [String]()
    let tableName = "EverglowMembers"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Everglow Members"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = control
        
        fetchItems()
    }
    
    @objc func fetchItems() {
        let query = CKQuery(recordType: tableName, predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let records = records, error == nil else {
                return
            }
            DispatchQueue.main.async {
                self?.items = records.compactMap({ $0.value(forKey: "name") as? String})
                self?.tableView.reloadData()
            }
        }
    }
    
    @objc func pullToRefresh() {
        tableView.refreshControl?.beginRefreshing()
        let query = CKQuery(recordType: tableName, predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let records = records, error == nil else {
                return
            }
            DispatchQueue.main.async {
                self?.items = records.compactMap({ $0.value(forKey: "name") as? String})
                self?.tableView.reloadData()
                self?.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    @objc func didTapAdd() {
        let alert = UIAlertController(title: "Add Member", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Enter name..."
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            if let field = alert.textFields?.first, let text = field.text, !text.isEmpty {
                self?.saveMember(name: text)
            }
        }))
        present(alert, animated: true)
    }
    
    @objc func saveMember(name: String) {
        let record = CKRecord(recordType: tableName)
        record.setValue(name, forKey: "name")
        database.save(record) { [weak self] record, error in
            if record != nil, error == nil {
                DispatchQueue.main.asyncAfter(deadline: .now()+2) {
                    print("saved")
                    self?.fetchItems()
                }
            }
        }
    }
}


extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        
        return cell
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
}
