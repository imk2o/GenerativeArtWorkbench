//
//  IssueAlert+Extension.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/07/16.
//

import Foundation
import StewardSwiftUI

extension IssueAlert {
    init(error: Error, style: Style = .alert, action: Action? = nil) {
        self.init(
            title: "Error",
            message: error.localizedDescription,
            style: style,
            action: action
        )
    }
}
