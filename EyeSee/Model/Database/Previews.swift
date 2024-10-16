//
//  Previews.swift
//  EyeSee
//
//  Created by Leo Ho on 2024/5/27.
//

import Foundation

protocol Previews {
    
    associatedtype PreviewType
    
    static var previewValue: PreviewType { get }
}
