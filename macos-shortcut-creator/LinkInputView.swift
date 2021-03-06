import SwiftUI

struct LinkInputView: View {
    @Binding var link: String
    
    var body: some View {
        HStack {
            Text("Enter Link:")
            Spacer()
            TextField(
                "https://apple.com",
                text: $link
            )
//            { isEditing in
//                self.isEditing = isEditing
//            } onCommit: {
//                validate(name: username)
//            }
        }
    }
}

struct LinkInputView_Previews: PreviewProvider {
    static var data: String = ""
    static var previews: some View {
        PreviewWrapper()
    }
    
    struct PreviewWrapper: View {
        @State var link: String = ""
        
        var body: some View {
            LinkInputView(link: $link)
        }
    }
}
