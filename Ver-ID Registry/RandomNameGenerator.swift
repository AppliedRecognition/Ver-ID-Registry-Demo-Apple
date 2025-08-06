//
//  RandomNameGenerator.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 31/07/2025.
//

import Foundation

struct RandomNameGenerator {
    
    static let adjectives: [String] = [
        "Adventurous", "Agile", "Ancient", "Angry", "Bashful", "Blue", "Bold", "Bouncy", "Brave", "Bright",
        "Busy", "Calm", "Cheery", "Clever", "Cloudy", "Cool", "Curious", "Daring", "Dazzling", "Delightful",
        "Determined", "Dizzy", "Dreamy", "Eager", "Fancy", "Fast", "Fierce", "Fluffy", "Friendly", "Funny",
        "Gentle", "Giant", "Giggly", "Glowing", "Graceful", "Grumpy", "Happy", "Helpful", "Honest", "Hungry",
        "Jolly", "Joyful", "Kind", "Lazy", "Light", "Loud", "Lucky", "Lush", "Magical", "Mellow", "Mighty",
        "Misty", "Noble", "Noisy", "Playful", "Proud", "Quick", "Quiet", "Quirky", "Radiant", "Sleepy", "Sneaky"
    ]
    
    static let nouns: [String] = [
        "Antelope", "Badger", "Bear", "Beaver", "Bison", "Butterfly", "Camel", "Cat", "Chameleon", "Cheetah",
        "Cobra", "Coyote", "Crane", "Crocodile", "Deer", "Dolphin", "Dragon", "Eagle", "Elephant", "Falcon",
        "Ferret", "Flamingo", "Fox", "Frog", "Giraffe", "Goat", "Goose", "Hedgehog", "Jaguar", "Kangaroo",
        "Koala", "Lemur", "Leopard", "Lion", "Llama", "Monkey", "Otter", "Owl", "Panda", "Panther"
    ]
    
    static func generateRandomName() -> String {
        let adjective = adjectives.randomElement()!
        let noun = nouns.randomElement()!
        return "\(adjective) \(noun)"
    }
}
