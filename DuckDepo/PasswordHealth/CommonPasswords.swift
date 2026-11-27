//
//  CommonPasswords.swift
//  DuckDepo
//

import Foundation

/// Passwords and words that guessing tools try first: the most common passwords in published leaks,
/// keyboard patterns, names, and everyday words people build passwords from (including Russian ones,
/// and Russian words typed on an English keyboard). Lowercase.
enum CommonPasswords {

    static let all: Set<String> = Set(list)

    /// The longest entry, to bound the search for words inside a password.
    static let longest = list.map(\.count).max() ?? 0

    private static let list: [String] = [
        // Digits and keyboard patterns
        "123456", "12345678", "123456789", "1234567890", "12345", "1234", "1234567", "123123", "123321",
        "654321", "987654321", "111111", "000000", "666666", "777777", "7777777", "555555", "121212",
        "112233", "131313", "159753", "11111111", "88888888", "00000000", "1q2w3e4r", "1q2w3e", "1qaz2wsx",
        "qwerty", "qwertyuiop", "qwerty123", "qwe123", "123qwe", "asdfgh", "asdfghjkl", "zxcvbn", "zxcvbnm",
        "qazwsx", "abc123", "abcd1234", "aaaaaa", "a1b2c3", "q1w2e3r4", "zaq12wsx", "1qazxsw2", "asdf",
        "qwer", "azerty", "йцукен", "фывапролджэ", "ячсмить",
        // Passwords
        "password", "passw0rd", "pass", "passwd", "password1", "letmein", "welcome", "login", "admin",
        "administrator", "root", "master", "secret", "access", "default", "guest", "test", "user",
        "changeme", "trustno1", "iloveyou", "whatever", "nothing", "starwars", "superman", "batman",
        "spiderman", "pokemon", "minecraft", "fortnite", "matrix", "freedom", "hello", "hello123",
        "sunshine", "princess", "shadow", "dragon", "monkey", "football", "baseball", "soccer", "hockey",
        "basketball", "killer", "hunter", "ranger", "buster", "tigger", "pepper", "ginger", "cookie",
        "cheese", "chocolate", "flower", "butterfly", "rainbow", "angel", "baby", "love", "lovely", "loveme",
        "sexy", "money", "family", "friend", "friends", "forever", "computer", "internet",
        "google", "apple", "samsung", "iphone", "facebook", "instagram", "youtube", "mustang", "harley",
        "ferrari", "porsche", "mercedes", "corvette", "yankees", "dallas", "chelsea", "liverpool",
        "arsenal", "barcelona", "madrid", "london", "paris", "moscow", "russia", "america", "summer",
        "winter", "spring", "autumn", "january", "february", "march", "april", "june", "july", "august",
        "september", "october", "november", "december", "monday", "friday", "sunday", "thunder", "silver",
        "golden", "diamond", "orange", "banana", "purple", "yellow", "blue", "green", "black", "white",
        "music", "guitar", "pizza", "coffee", "qwerty1", "biteme", "fuckyou", "asshole", "jordan23",
        "michael", "jennifer", "jessica", "ashley", "amanda", "nicole", "daniel", "andrew", "joshua",
        "matthew", "thomas", "robert", "charlie", "george", "jordan", "taylor", "michelle", "maggie",
        "anthony", "william", "jasmine", "hannah", "justin", "austin", "sophie", "oliver", "alexander",
        "alexandr", "alexey", "andrey", "sergey", "dmitry", "vladimir", "natasha", "tatiana", "svetlana",
        "olga", "irina", "elena", "anna", "maria", "marina", "katya", "masha", "sasha", "nikita", "maxim",
        // Russian words, and Russian words typed on an English keyboard
        "пароль", "любовь", "солнце", "привет", "наташа", "россия", "москва", "gfhjkm", "ktyjxrf",
        "cjkysirj", "ghbdtn", "ytnkjubyf", "vfrcbv", "fylhtq", "nfnmzyf", "ifhbr", "zyndfhm", "rjnzhf",
    ]
}
