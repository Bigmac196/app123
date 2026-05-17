import Foundation

struct CategoryProfile {
    let category: ProductCategory
    let strongKeywords: [String]   // weight 3
    let weakKeywords: [String]     // weight 1
    let brandHints: [String]       // weight 2
    let negativeKeywords: [String] // weight -3
}

/// Deterministic weighted keyword/brand scorer. No ML.
public struct CategoryClassifier: Sendable {
    public init() {}

    public func classify(_ product: ProductData) -> (category: ProductCategory, confidence: Double) {
        let text = product.searchableText
        var scores: [(ProductCategory, Double)] = []

        for p in Self.profiles {
            var s = 0.0
            s += Double(HeuristicKit.count(text, occurrencesOfAny: p.strongKeywords)) * 3
            s += Double(HeuristicKit.count(text, occurrencesOfAny: p.weakKeywords)) * 1
            if let brand = product.brand?.lowercased(),
               p.brandHints.contains(where: { brand.contains($0.lowercased()) }) {
                s += 2
            }
            s += Double(HeuristicKit.count(text, occurrencesOfAny: p.negativeKeywords)) * -3
            scores.append((p.category, s))
        }

        let sorted = scores.sorted { $0.1 > $1.1 }
        guard let best = sorted.first, best.1 >= 3 else {
            return (.general, 0.3)
        }
        let runnerUp = sorted.dropFirst().first?.1 ?? 0
        // Confidence rises with absolute score and the gap to the runner-up.
        let separation = best.1 - max(0, runnerUp)
        let confidence = min(0.95, 0.4 + (best.1 / 18.0) + (separation / 18.0))
        return (best.0, confidence)
    }

    static let profiles: [CategoryProfile] = [
        CategoryProfile(category: .fragrance,
            strongKeywords: ["eau de parfum", "eau de toilette", "edp", "edt",
                             "fragrance for men", "fragrance for women", "cologne", "perfume"],
            weakKeywords: ["spray", "scent", "notes", "sillage", "fragrance"],
            brandHints: ["dior", "chanel", "versace", "creed", "armani", "ysl", "tom ford"],
            negativeKeywords: ["air freshener", "car diffuser", "candle", "detergent"]),
        CategoryProfile(category: .standingDesk,
            strongKeywords: ["standing desk", "sit-stand desk", "height adjustable desk",
                             "electric desk", "adjustable desk"],
            weakKeywords: ["desk frame", "desktop", "motorized", "memory preset"],
            brandHints: ["uplift", "fully", "flexispot", "vari", "secretlab"],
            negativeKeywords: ["desk lamp", "desk organizer", "desk mat", "desk pad"]),
        CategoryProfile(category: .officeChair,
            strongKeywords: ["office chair", "ergonomic chair", "desk chair",
                             "gaming chair", "task chair"],
            weakKeywords: ["lumbar", "armrest", "recline", "mesh back", "headrest"],
            brandHints: ["herman miller", "steelcase", "secretlab", "autonomous", "branch"],
            negativeKeywords: ["chair mat", "chair cover", "dining chair", "folding chair"]),
        CategoryProfile(category: .headphones,
            strongKeywords: ["headphones", "earbuds", "earphones", "headset", "over-ear", "in-ear"],
            weakKeywords: ["anc", "noise cancelling", "noise canceling", "driver", "bluetooth audio"],
            brandHints: ["sony", "bose", "sennheiser", "jabra", "anker soundcore", "airpods"],
            negativeKeywords: ["headphone stand", "ear tips replacement", "headphone case only"]),
        CategoryProfile(category: .skincare,
            strongKeywords: ["serum", "moisturizer", "cleanser", "sunscreen", "spf",
                             "retinol", "niacinamide", "hyaluronic"],
            weakKeywords: ["skin", "face cream", "toner", "exfoliant", "dermatologist"],
            brandHints: ["cerave", "the ordinary", "la roche-posay", "paula's choice", "cosrx"],
            negativeKeywords: ["makeup remover wipes only", "skincare fridge", "skincare tool"]),
        CategoryProfile(category: .clothing,
            strongKeywords: ["t-shirt", "hoodie", "jacket", "jeans", "dress", "sweater", "shirt"],
            weakKeywords: ["cotton", "polyester", "fit", "size chart", "apparel"],
            brandHints: ["nike", "adidas", "uniqlo", "carhartt", "lululemon"],
            negativeKeywords: ["clothing rack", "garment bag", "laundry"]),
        CategoryProfile(category: .supplement,
            strongKeywords: ["supplement", "capsules", "softgels", "protein powder",
                             "vitamins", "creatine", "pre-workout"],
            weakKeywords: ["servings", "dietary", "gummies", "dose", "mg per"],
            brandHints: ["optimum nutrition", "now foods", "thorne", "nature made"],
            negativeKeywords: ["pill organizer", "supplement shaker only"]),
        CategoryProfile(category: .powerBank,
            strongKeywords: ["power bank", "portable charger", "battery pack", "powerbank"],
            weakKeywords: ["mah", "power delivery", "pd", "fast charge", "usb-c output"],
            brandHints: ["anker", "ugreen", "baseus", "ravpower"],
            negativeKeywords: ["aa battery", "battery charger station", "car battery"]),
        CategoryProfile(category: .kitchenAppliance,
            strongKeywords: ["air fryer", "blender", "espresso machine", "coffee maker",
                             "stand mixer", "instant pot", "toaster oven"],
            weakKeywords: ["wattage", "quart", "nonstick", "stainless steel", "countertop"],
            brandHints: ["ninja", "instant pot", "cosori", "breville", "vitamix"],
            negativeKeywords: ["replacement basket", "appliance cover", "cleaning tablets"]),
        CategoryProfile(category: .ledLighting,
            strongKeywords: ["led strip", "led lights", "rgb lights", "light strip",
                             "smart bulb", "led panel", "neon rope light"],
            weakKeywords: ["lumens", "rgbic", "music sync", "app control", "color changing"],
            brandHints: ["govee", "philips hue", "nanoleaf", "lifx"],
            negativeKeywords: ["led mask", "grow light", "led for car only"])
    ]
}
