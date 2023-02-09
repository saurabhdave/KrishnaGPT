//
//  DotsLoadingView.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import SwiftUI

struct DotsLoadingView: View {
    @State private var animateDots = false
    
    private let numberOfDots: Int
    
    init(numberOfDots: Int = 3) {
        self.numberOfDots = numberOfDots
    }
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<numberOfDots, id: \.self) { i in
                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(self.animateDots ? 1 : 0.3)
                    .opacity(self.animateDots ? 1 : 0.3)
                    .animation(
                        Animation.easeOut(duration: 1)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.3)
                        , value: self.animateDots)
            }
        }
        .onAppear {
            self.animateDots.toggle()
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        DotsLoadingView(numberOfDots: 5)
    }
}
