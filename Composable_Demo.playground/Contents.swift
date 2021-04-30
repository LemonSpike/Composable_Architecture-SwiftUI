//: A UIKit based Playground for presenting user interface

import SwiftUI
import Combine
import PlaygroundSupport

struct ContentView : View {
  @ObservedObject var state: AppState
  var body: some View {
    NavigationView {
      List {
        NavigationLink("Count!", destination: CounterView(state: self.state))
      }
      .navigationBarTitle("State management", displayMode: .large)
    }
  }
}

class AppState: ObservableObject, Codable {
  @Published var count: Int {
    willSet {
      let dict = ["count": newValue, "favouritePrimes": Array(favouritePrimes)] as [String : Any]
      UserDefaults.standard.set(dict, forKey: "state")
    }
  }

  @Published var favouritePrimes: Set<Int> {
    willSet {
      let dict = ["count": count, "favouritePrimes": Array(newValue)] as [String : Any]
      UserDefaults.standard.set(dict, forKey: "state")
      print("favouritePrimes: \(count), \(newValue)")
    }
  }
  var isFavouritePrime: Bool {
    self.favouritePrimes.contains(count)
  }

  init(json: [String: Any]?) {
    let count = json?["count"] as? Int ?? 0
    self.favouritePrimes = Set(json?["favouritePrimes"] as? Array<Int> ?? [])
    self.count = count
  }

  required init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let count = try container.decode(Int.self)
    self.favouritePrimes = try container.decode(Set<Int>.self)
    self.count = count
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(count)
    try container.encode(favouritePrimes)
  }

  func addToFavouritePrimes() {
    favouritePrimes.insert(count)
  }

  func removeFromFavouritePrimes() {
    favouritePrimes.remove(count)
  }

  func isPrime() -> Bool {
    let double = Double(count)

    if count <= 1 {
      return false
    }

    if count <= 3 {
      return true
    }

    let root = Int(sqrt(double))

    for i in 2...root {
      if count % i == 0 {
        return false
      }
    }
    return true
  }
}

struct CounterView : View {

  @ObservedObject var state: AppState

  @State var binding = false

  @State var color = Color.red

  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      HStack {
        Button("-") {
          self.state.count -= 1
          toggleColor()
        }
        Text("\(self.state.count)")
          .foregroundColor(color)
        Button("+") {
          self.state.count += 1
          toggleColor()
        }
      }
      Button("Is this prime?") {
        self.binding.toggle()
      }
      .sheet(isPresented: $binding) {
        VStack {
          state.isPrime() ? Text("YES") : Text("NO")
          if state.isFavouritePrime {
            Button("Remove from favourite primes?") {
              state.removeFromFavouritePrimes()
            }
          } else {
            Button("Add to favourite primes?") {
              state.addToFavouritePrimes()
            }
          }
        }
      }
      Button("What is the \(ordinal(self.state.count)) prime?") {
        fatalError()
      }
    }
    .navigationBarTitle("Counter Demo", displayMode: .large)
    .font(.title)
  }

  private func ordinal(_ n: Int) -> String {
    let form = NumberFormatter()
    form.numberStyle = .ordinal
    return form.string(for: n) ?? ""
  }

  private func toggleColor() {
    if state.isPrime() {
      color = .green
    } else {
      color = .red
    }
  }
}

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView(state: AppState(json: UserDefaults.standard.dictionary(forKey: "state"))))
