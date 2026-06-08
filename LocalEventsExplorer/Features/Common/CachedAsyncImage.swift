import SwiftUI

struct CachedAsyncImage: View {
    let url: URL
    let maxPixel: CGFloat

    @State private var image: UIImage?
    @State private var isLoading = true

    init(url: URL, maxPixel: CGFloat = 600) {
        self.url = url
        self.maxPixel = maxPixel
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
            }
        }
        .task(id: url) {
            isLoading = true
            image = await ImageCache.shared.image(for: url, maxPixel: maxPixel)
            isLoading = false
        }
    }
}
