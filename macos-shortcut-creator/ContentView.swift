import SwiftUI
import LinkPresentation

class LinkState: ObservableObject {
    @Published var link: String = "https://apple.com"
    @Published var metadata: LPLinkMetadata?
    @Published var image: NSImage?
}

struct LinkView: View {
    @Binding var metadata: LPLinkMetadata?
    @Binding var image: NSImage?
    
    var body: some View {
        VStack {
            if metadata != nil {
                Text(metadata!.title!)
            } else {
                Text("Link preview")
            }
            Spacer()
            if image != nil {
                Image(nsImage: image!).resizable().scaledToFit()
            }
        }
    }
    
}

func getDesktopDir() -> URL {
    let paths = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
    return paths[0]
}

enum LoadIconError: Error {
    case errorOccurred(internalErr: Error)
    case noImage
}

struct ContentView: View {
    @StateObject var state = LinkState()
    
    func getImage(provider: NSItemProvider) throws {
        var error: Error? = nil
        provider.loadDataRepresentation(forTypeIdentifier: "public.image", completionHandler: { data, err in
            if err == nil && data != nil {
                DispatchQueue.main.async {
                    state.image = NSImage(data: data!)
                    
                    let savePanel = NSSavePanel()
                    savePanel.title = "Save Shortcut..."
                    savePanel.prompt = "Save to file"
                    savePanel.nameFieldLabel = "Pick a name"
                    savePanel.nameFieldStringValue = state.metadata!.title!
                    savePanel.allowedFileTypes = ["webloc"]
                    
                    let result = savePanel.runModal()
                    
                    switch result {
                    case .OK:
                        let linkXml = """
                        <?xml version="1.0" encoding="UTF-8"?>
                        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                        <plist version="1.0">
                            <dict>
                                <key>URL</key>
                                <string>\(state.link)</string>
                            </dict>
                        </plist>
                        """

                        do {
                            try linkXml.write(to: savePanel.url!, atomically: true, encoding: String.Encoding.utf8)
                        } catch {
                            print("error saving shortcut")
                        }
                        print("OK")
                    case .cancel:
                        print("User Cancelled")
                    default:
                        print("Panel shouldn't be anything other than OK or Cancel")
                    }
                }
            } else if err != nil {
                error = LoadIconError.errorOccurred(internalErr: err!)
            } else {
                error = LoadIconError.noImage
            }
        })
        if error != nil {
            throw error!
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text("Generate Desktop Shortcut")
                    .font(.headline)
                Spacer()
            }
            Spacer()
            LinkInputView(link: $state.link)
            Spacer()
            Button("Generate Preview") {
                let url = URL(string: state.link)!
                let metadataProvider = LPMetadataProvider()
                
                metadataProvider.startFetchingMetadata(for: url) { metadata, error in
                    if error != nil {
                        // TODO: handle error
                        return
                    }
                    DispatchQueue.main.async {
                        state.metadata = metadata!
                        do {
                            try getImage(provider: metadata!.iconProvider!)
                        } catch {
                            do {
                                try getImage(provider: metadata!.imageProvider!)
                            } catch {}
                        }
                    }
                }
            }
            Spacer()
            LinkView(metadata: $state.metadata, image: $state.image)
        }
        .padding()
        .navigationTitle("ShortDash")
        .frame(minWidth: 600, minHeight: 300)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

