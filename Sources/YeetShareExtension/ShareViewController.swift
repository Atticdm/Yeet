import UIKit
import SwiftUI
import os.log

final class ShareViewController: UIViewController {
    private let logger = Logger(subsystem: "com.atticdm.Yeet", category: "ShareExtension")
    private lazy var viewModel = DownloaderViewModel(extensionContext: extensionContext, logger: logger)

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 0, height: 240)
        embedShareView()
    }

    private func embedShareView() {
        let host = UIHostingController(rootView: ShareView(viewModel: viewModel))
        addChild(host)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
    }
}

