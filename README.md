# iOS Multipeer Connectivity Example Project

This is an example project that demonstrates the usage of [Multipeer Connectivity](https://developer.apple.com/documentation/multipeerconnectivity) framework.

The app discovers other peers, invites them into a sharing session and then peers share their business cards with each other.

### Key insights

- Only one peer should connect to the other peer, not both. That's why only one of them accepts the invitation. Otherwise connection is unreliable and often lost. Unfortunately this is not explained well in the docs.
- The sessions can have max of 8 peers. You can discover more but can't share data with more than 8 device at a time.
- The system caches some of the devices it has discovered before. This causes `MCNearbyServiceBrowser` to find offline devices. And there's no way of clearing that cache unfortunately. They just disappear on their own after a while. 



