//
//  DeepLinkHandler.swift
//  UIKitProject
//

import Foundation

protocol DeepLinkHandling {
    func route(from url: URL) -> AppRoute?
}

struct DeepLinkConfiguration {
    let customScheme: String
    let universalLinkHosts: Set<String>

    static var application: DeepLinkConfiguration {
        let hosts = Bundle.main.object(forInfoDictionaryKey: "UniversalLinkHosts") as? [String] ?? []
        let scheme = Bundle.main.object(forInfoDictionaryKey: "DeepLinkCustomScheme") as? String
            ?? "uikitproject"
        return DeepLinkConfiguration(
            customScheme: scheme,
            universalLinkHosts: Set(hosts)
        )
    }
}

struct DeepLinkHandler: DeepLinkHandling {
    private let customScheme: String
    private let universalLinkHosts: Set<String>

    init(customScheme: String, universalLinkHosts: Set<String>) {
        self.customScheme = customScheme.lowercased()
        self.universalLinkHosts = Set(universalLinkHosts.map { $0.lowercased() })
    }

    init(configuration: DeepLinkConfiguration) {
        self.init(
            customScheme: configuration.customScheme,
            universalLinkHosts: configuration.universalLinkHosts
        )
    }

    func route(from url: URL) -> AppRoute? {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let scheme = components.scheme?.lowercased()
        else {
            return nil
        }

        var path = components.path
            .split(separator: "/")
            .map { $0.lowercased() }

        switch scheme {
        case customScheme:
            guard components.host?.lowercased() == "open" else {
                return nil
            }

        case "https":
            guard
                let host = components.host?.lowercased(),
                universalLinkHosts.contains(host),
                path.first == "open"
            else {
                return nil
            }
            path.removeFirst()

        default:
            return nil
        }

        guard path.count <= 1 else {
            return nil
        }

        guard let destination = path.first else {
            return .home
        }

        switch destination {
        case "home":
            return .home
        case "pan":
            return .panGesture
        case "pages":
            return pageRoute(from: components)
        case "property-animator":
            return .propertyAnimator
        case "crash":
            return .crashSimulator
        case "mini-player":
            return .miniPlayer
        case "html":
            return .htmlViewer
        case "date-picker":
            return .datePicker
        case "search":
            return .searchTransition
        default:
            return nil
        }
    }

    private func pageRoute(from components: URLComponents) -> AppRoute? {
        guard let item = components.queryItems?.first(where: {
            $0.name.caseInsensitiveCompare("index") == .orderedSame
        }) else {
            return .page(index: nil)
        }

        guard
            let value = item.value,
            let index = Int(value),
            index >= 0
        else {
            return nil
        }

        return .page(index: index)
    }
}
