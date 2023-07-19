//
//  SystemUtilities.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/19.
//

import SwiftUI
import Dynamic

func openDirectory(url: URL) {
    if
        ProcessInfo.processInfo.isiOSAppOnMac ||
        ProcessInfo.processInfo.isMacCatalystApp
    {
        // Finderで開く
        Dynamic.NSWorkspace.sharedWorkspace.activateFileViewerSelectingURLs([url])
    } else {
        // File.appで開く
        if
            let sharedURL = URL(string: "shareddocuments://\(url.path)"),
            UIApplication.shared.canOpenURL(sharedURL)
        {
            UIApplication.shared.open(sharedURL, options: [:])
        }
    }
}

func openURL(_ url: URL) {
    UIApplication.shared.open(url)
}
