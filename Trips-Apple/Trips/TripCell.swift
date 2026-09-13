//
//  TripCell.swift
//  Trips
//

import SwiftUI

struct TripCell: View {
    let trip: Trip

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background cover image
            AsyncImage(url: URL(string: trip.image)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Rectangle()
                        .fill(Color(hue: 0.58, saturation: 0.4, brightness: 0.25))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.3))
                        )
                default:
                    Rectangle()
                        .fill(Color(hue: 0.58, saturation: 0.3, brightness: 0.2))
                        .overlay(ProgressView().tint(.white))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipped()

            // Bottom gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(trip.year)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}
