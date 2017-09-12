//
//  Placeholders+UILabel.swift
//  Placeholders
//
//  Created by Tyson Kerridge on 26/6/17.
//  Copyright © 2017 Tyson Kerridge. All rights reserved.
//

import UIKit

// NOTE: This is an extension of Placeholders referencing the `TextFieldPlaceholder` set up so it can be used on a UILabel in the same way.

public protocol LabelPlaceholder {
    func set(on label: UILabel)
}

extension String : LabelPlaceholder {

    public func set(on label: UILabel) {
        label.text = self
    }

}

extension NSAttributedString : LabelPlaceholder {

    @objc(setOnLabel:)
    public func set(on label: UILabel) {
        label.attributedText = self
    }

}

extension UILabel {

    public struct PlaceholderChange<Placeholder : LabelPlaceholder> {

        private let _setNewPlaceholder: (Placeholder, UILabel) -> ()

        public func setNewPlaceholder(_ placeholder: Placeholder, on label: UILabel) {
            _setNewPlaceholder(placeholder, label)
        }

        public init(setNewPlaceholder: @escaping (Placeholder, UILabel) -> ()) {
            self._setNewPlaceholder = setNewPlaceholder
        }

    }

}

extension UILabel.PlaceholderChange {

    public static func caTransition(_ transition: @escaping () -> CATransition) -> UILabel.PlaceholderChange<Placeholder> {
        return UILabel.PlaceholderChange { (placeholder, label) in
            let transition = transition()
            label.layer.add(transition, forKey: nil)
            placeholder.set(on: label)
        }
    }

    public enum TransitionPushDirection {
        case fromBottom
        case fromLeft
        case fromRight
        case fromTop

        public var coreAnimationConstant: String {
            switch self {
            case .fromBottom:
                return kCATransitionFromBottom
            case .fromTop:
                return kCATransitionFromTop
            case .fromLeft:
                return kCATransitionFromLeft
            case .fromRight:
                return kCATransitionFromRight
            }
        }
    }

    public static func pushTransition(_ direction: TransitionPushDirection, duration: TimeInterval = 0.35,
                                      timingFunction: CAMediaTimingFunction = .init(name: kCAMediaTimingFunctionEaseInEaseOut)) -> UILabel.PlaceholderChange<Placeholder> {
        return .caTransition {
            let transition = CATransition()
            transition.duration = duration
            transition.timingFunction = timingFunction
            transition.type = kCATransitionPush
            transition.subtype = direction.coreAnimationConstant
            return transition
        }
    }

}

extension Placeholders where Element : LabelPlaceholder {

    public func start(interval: TimeInterval, fireInitial: Bool = true, shouldSkipFirstElement: ((Element) -> Bool)? = nil, label: UILabel, animation change: UILabel.PlaceholderChange<Element>) {
        self.start(interval: interval, fireInitial: fireInitial, shouldSkipFirstElement: shouldSkipFirstElement) { [weak label, weak self] (placeholder) in
            if let label = label {
                change.setNewPlaceholder(placeholder, on: label)
            } else {
                self?.timer?.invalidate()
            }
        }
    }
    
}
