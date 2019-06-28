import Foundation

struct Paragraph {
    var text: String = ""
    
    init(_ words: String) {
        let MaxSentences: UInt32 = 7
        let MinSentences: UInt32 = 5
        let sentenceCount = Int(arc4random_uniform(MaxSentences) + MinSentences)
        
        for _ in 0...sentenceCount {
            text += self.createSentence(words)
        }
        
        text = text
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    func createSentence(_ words: String) -> String {
        let MaxWords: UInt32 = 8
        let MinWords: UInt32 = 4
        let words = words.words
        let wordCount = Int(arc4random_uniform(MaxWords) + MinWords)
        
        var sentence = ""
        
        for _ in 0...wordCount {
            let randomWordIndex = Int(arc4random_uniform(UInt32(words.count)))
            sentence += "\(words[randomWordIndex]) "
        }
        
        return sentence
            .condenseWhitespace().lowercased()
            .capitalizeFirstLetter() + ". "
    }
}
