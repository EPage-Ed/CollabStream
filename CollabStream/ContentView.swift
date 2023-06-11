//
//  ContentView.swift
//  CollabStream
//
//  Created by Edward Arenberg on 6/10/23.
//

import SwiftUI
import SwiftData

struct PlayerView: UIViewControllerRepresentable {

  func makeUIViewController(context: Context) -> MoviePlayerViewController {
    let vc = MoviePlayerViewController()
    // Do some configurations here if needed.
    return vc
  }
  
  func updateUIViewController(_ uiViewController: MoviePlayerViewController, context: Context) {
    // Updates the state of the specified view controller with new information from SwiftUI.
  }

}


struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var items: [Note]

  @State private var selectedMovie : Movie?
  
  var body: some View {
    VStack {
      PlayerView()
        .border(.red)
      List(Library.shared.movies, id:\.hashValue) { movie in
        VStack {
          Text(movie.title)
            .frame(maxWidth: .infinity)
          Text(movie.description)
            .font(.caption)
        }
        .padding(.vertical, 8)
        .background {
          selectedMovie == movie ? Color.secondary : Color.clear
        }
        .onTapGesture {
          selectedMovie = movie
          CoordinationManager.shared.prepareToPlay(movie)
        }
      }
      NavigationView {
        List {
          ForEach(items) { item in
            NavigationLink {
              Text("Item at \(item.date, format: Date.FormatStyle(date: .numeric, time: .standard))")
            } label: {
              Text(item.date, format: Date.FormatStyle(date: .numeric, time: .standard))
            }
          }
          .onDelete(perform: deleteItems)
        }
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            EditButton()
          }
          ToolbarItem {
            Button(action: addItem) {
              Label("Add Item", systemImage: "plus")
            }
          }
        }
        Text("Select an item")
      }
    }
    .onChange(of: selectedMovie) { old,new in
      guard new != old else { return }
      
    }
  }
  
  private func addItem() {
    withAnimation {
      let newItem = Note(text: "", date: Date())
      modelContext.insert(newItem)
    }
  }
  
  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        modelContext.delete(items[index])
      }
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(for: Note.self, inMemory: true)
}
