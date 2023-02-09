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
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30, alignment: .center)
                    .clipShape(
                        Circle()
                    )
            } placeholder: {
                ProgressView()
            }
        } else {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30, alignment: .center)
                .clipShape(
                    Circle()
                )
        }
    }
}

struct MessageRowImageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowImageView(image: "profile")
    }
}
