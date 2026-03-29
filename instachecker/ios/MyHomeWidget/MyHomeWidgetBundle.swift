//
//  MyHomeWidgetBundle.swift
//  MyHomeWidget
//
//  Created by Nolan Dean on 3/28/26.
//

import WidgetKit
import SwiftUI

@main
struct MyHomeWidgetBundle: WidgetBundle {
    var body: some Widget {
        MyHomeWidget()
        MyHomeWidgetControl()
        MyHomeWidgetLiveActivity()
    }
}
