//
//  ImageDropDelegate.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/15.
//

import SwiftUI
import StewardUIKit

struct ImageDropDelegate: DropDelegate {
    @Binding var image: CGImage?

    func performDrop(info: DropInfo) -> Bool {
        guard let item = info.itemProviders(for: [.image]).first else { return false }

        _ = item.loadTransferable(type: Data.self) { result in
            if
                case .success(let data) = result,
                let image = UIImage(data: data)?.normalized().cgImage
            {
                Task { @MainActor in
                    self.image = image
                }
            }
        }
        
        return true
    }
}

