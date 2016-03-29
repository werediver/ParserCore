//
//  ActionProducer.swift
//  EasyProjects
//
//  Created by Roman Fedoseev on 2/24/16.
//  Copyright © 2016 Cactussoft. All rights reserved.
//

import Foundation

protocol ActionProducer {

    associatedtype Action

    var onAction: ((Action, sender: Self) -> ())? { get set }

}
