//
//  MessageRowImageView.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import SwiftUI

struct MessageRowImageView: View {
    
    var image: String
    
    var body: some View {
        if image.hasPrefix("http"), let url = URL(string: image) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 30, height: 30)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .clipped()
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .clipped()
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(width: 30, height: 30)
                .clipped()
                .clipShape(Circle())
        }
    }
}

struct MessageRowImageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowImageView(image: "profile")
    }
}
