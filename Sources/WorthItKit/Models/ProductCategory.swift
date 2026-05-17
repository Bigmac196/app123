import Foundation

public enum ProductCategory: String, Codable, Sendable, CaseIterable {
    case fragrance
    case standingDesk
    case officeChair
    case headphones
    case skincare
    case clothing
    case supplement
    case powerBank
    case kitchenAppliance
    case ledLighting
    case general

    public var displayName: String {
        switch self {
        case .fragrance: return "Fragrance"
        case .standingDesk: return "Standing Desk"
        case .officeChair: return "Office Chair"
        case .headphones: return "Headphones"
        case .skincare: return "Skincare"
        case .clothing: return "Clothing"
        case .supplement: return "Supplement"
        case .powerBank: return "Power Bank"
        case .kitchenAppliance: return "Kitchen Appliance"
        case .ledLighting: return "LED Lighting"
        case .general: return "General"
        }
    }

    public var symbolName: String {
        switch self {
        case .fragrance: return "drop.fill"
        case .standingDesk: return "table.furniture"
        case .officeChair: return "chair.fill"
        case .headphones: return "headphones"
        case .skincare: return "face.smiling"
        case .clothing: return "tshirt.fill"
        case .supplement: return "pills.fill"
        case .powerBank: return "battery.100.bolt"
        case .kitchenAppliance: return "oven.fill"
        case .ledLighting: return "lightbulb.led.fill"
        case .general: return "shippingbox.fill"
        }
    }
}
