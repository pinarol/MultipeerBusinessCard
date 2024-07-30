//
//  CardView.swift
//  BusinessCard
//
//  Created by Pinar Olguc on 30.07.2024.
//

import SwiftUI

struct CardView: View {
    var peer: Peer
    var body: some View {
        VStack(alignment: .leading) {
            if let name = peer.name {
                Text(name)
                    .font(.title2)
                    .padding(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            if let job = peer.job {
                Text(job)
                    .font(.headline)
                    .padding(.init(top: 0, leading: 0, bottom: 12, trailing: 0))
            }
            if let email = peer.email {
                Text(email)
                    .font(.subheadline)
            }
            if let phone = peer.phone {
                Text(phone)
                    .font(.caption)
            }
            Text(peer.displayName)
                .font(.footnote)
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .foregroundColor(Color(UIColor.label))
    }
}

#Preview {
    CardView(peer: Peer(displayName: "PinPin", lastSeen: Date(), name: "Pinar Olguc", email: "email@domain.com", phone: "+90 (216) 645 56 32", job: "Engineer"))
}
