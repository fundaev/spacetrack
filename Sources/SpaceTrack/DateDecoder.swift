// Copyright (c) 2022 Sergei Fundaev
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

private func makePattern(for format: DateFormat) -> String {
    switch format {
    case .date:
        return "^(\\d{4})-(\\d{2})-(\\d{2})$"
    case .dateTime:
        return "^(\\d{4})-(\\d{2})-(\\d{2})T(\\d{2}):(\\d{2}):(\\d{2})$"
    case .dateTimeWithBlankDelimiter:
        return "^(\\d{4})-(\\d{2})-(\\d{2}) (\\d{1,2}):(\\d{2}):(\\d{2})$"
    case .datePreciseTime:
        return "^(\\d{4})-(\\d{2})-(\\d{2})T(\\d{2}):(\\d{2}):(\\d{2}).(\\d{6})$"
    }
}

private func extractInt(from text: String, match: NSTextCheckingResult, index: Int) -> Int? {
    guard let range = Range(match.range(at: index), in: text) else {
        return nil
    }
    return Int(text[range])
}

func parseDate(from text: String, for format: DateFormat) -> Date? {
    let regex = try! NSRegularExpression(pattern: makePattern(for: format))
    let range = NSRange(location: 0, length: text.utf8.count)
    if let m = regex.firstMatch(in: text, options: [], range: range) {
        var components = DateComponents()
        components.timeZone = TimeZone(secondsFromGMT: 0)!

        guard let year = extractInt(from: text, match: m, index: 1) else { return nil }
        guard let month = extractInt(from: text, match: m, index: 2) else { return nil }
        guard let day = extractInt(from: text, match: m, index: 3) else { return nil }

        components.year = year
        components.month = month
        components.day = day

        if format.hasTime {
            guard let hour = extractInt(from: text, match: m, index: 4) else { return nil }
            guard let minute = extractInt(from: text, match: m, index: 5) else { return nil }
            guard let second = extractInt(from: text, match: m, index: 6) else { return nil }

            components.hour = hour
            components.minute = minute
            components.second = second
        }

        if format.hasMicrosecond {
            guard let microsecond = extractInt(from: text, match: m, index: 7) else {
                return nil
            }
            components.nanosecond = microsecond * 1000
        }

        return Calendar.current.date(from: components)
    }
    return nil
}

func decodeOptional<Key: EntityField>(container: KeyedDecodingContainer<Key>, forKey key: Key) throws -> Date? {
    let stringValue = try container.decodeIfPresent(String.self, forKey: key)
    if let stringValue = stringValue {
        if stringValue == "null" {
            return nil
        }
        guard let date = parseDate(from: stringValue, for: key.dateFormat) else {
            throw ParsingError(message: "Unexpected value: expecting \(Date.self) while \"\(stringValue)\" is provided")
        }
        return date
    }
    return nil
}

func decode<Key: EntityField>(container: KeyedDecodingContainer<Key>, forKey key: Key) throws -> Date {
    let stringValue = try container.decode(String.self, forKey: key)
    let value = parseDate(from: stringValue, for: key.dateFormat)
    if value == nil {
        throw ParsingError(message: "Unexpected value: expecting \(Date.self) while \"\(stringValue)\" is provided")
    }
    return value!
}
