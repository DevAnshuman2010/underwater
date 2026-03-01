import SwiftUI

struct ModeSelectionView: View {
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                
                Spacer()
                
                Text("Underwater Communication")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                NavigationLink(destination: SendView()) {
                    Text("Send Message")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .fontWeight(.bold)
                        .cornerRadius(30)
                }
                
                NavigationLink(destination: ReceiveView()) {
                    Text("Receive Message")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .fontWeight(.bold)
                        .cornerRadius(30)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}
