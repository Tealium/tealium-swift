//
//  ContentView.swift
//  iOSTealiumTest
//
//  Copyright © 2020 Tealium. All rights reserved.
//
import SwiftUI
import TealiumMedia

struct ContentView: View {
    @State private var traceId: String = ""
    
    // Timed event start
    var playButton: some View {
        IconButtonView(iconName: "play.fill") {
            TealiumHelper.shared.track(title: "product_view",
                                       data: ["product_id": ["prod123"]])
        }
    }
    
    // Timed event stop
    var stopButton: some View {
        IconButtonView(iconName: "stop.fill") {
            TealiumHelper.shared.track(title: "order_complete",
                                       data: ["order_id": "ord123"])
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    TraceIdTextField(traceId: $traceId)
                        .padding(.bottom, 20)
                    TextButtonView(title: "Start Trace") {
                        TealiumHelper.shared.joinTrace(self.traceId)
                    }
                    TextButtonView(title: "Leave Trace") {
                        TealiumHelper.shared.leaveTrace()
                    }
                    TextButtonView(title: "Track View") {
                        TealiumHelper.shared.trackView(title: "screen_view", data: nil)
                    }
                    TextButtonView(title: "Track Event") {
                        TealiumHelper.shared.track(title: "button_tapped",
                                                data: ["event_category": "example",
                                                       "event_action": "tap",
                                                       "event_label": "Track Event"])
                    }
                    TextButtonView(title: "Hosted Data Layer") {
                        TealiumHelper.shared.track(title: "hdl-test",
                                                   data: ["product_id": "abc123"])
                    }
                    TextButtonView(title: "SKAdNetwork Conversion") {
                        TealiumHelper.shared.track(title: "conversion_event",
                                                   data: ["conversion_value": 10])
                    }
                    TextButtonView(title: "Toggle Consent Status") {
                        TealiumHelper.shared.toggleConsentStatus()
                    }
                    TextButtonView(title: "Reset Consent") {
                        TealiumHelper.shared.resetConsentPreferences()
                    }
                    // TODO: Remove before release - Media specific sample app to be used
                    TextButtonView(title: "Media Sequence") {
                        let media = MediaCollection(name: "Star Wars",
                                                    streamType: .vod,
                                                    mediaType: .video,
                                                    qoe: QoE(bitrate: 123),
                                                    trackingType: .heartbeat,
                                                    metadata: ["meta_key": "meta_value"])
                        let mediaSession = TealiumHelper.shared.tealium?.media?.createSession(from: media)
                        
                        mediaSession?.startSession()
                        multiTrack(index: "1")
                        mediaSession?.startAdBreak(AdBreak(title: "AdBreak 1"))
                        multiTrack(index: "2")
                        mediaSession?.startAd(Ad(name: "Ad 1"))
                        multiTrack(index: "3")
                        mediaSession?.endAd()
                        multiTrack(index: "4")
                        mediaSession?.endAdBreak()
                        multiTrack(index: "5")
                        mediaSession?.play()
                        multiTrack(index: "6")
                        mediaSession?.startChapter(Chapter(name: "Chapter 1", duration: 60))
                        multiTrack(index: "7")
                        mediaSession?.pause()
                        multiTrack(index: "8")
                        mediaSession?.play()
                        multiTrack(index: "9")
                        mediaSession?.endChapter()
                        multiTrack(index: "10")
                        mediaSession?.stop()
                        multiTrack(index: "11")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                            (12...32).forEach {
                                multiTrack(index: "\($0)")
                            }
                            mediaSession?.stopPing()
                        }
                    }
                }
                .navigationTitle("iOSTealiumTest")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: playButton, trailing: stopButton)
                .padding(50)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    // TODO: Remove before release
    func multiTrack(index: String) {
        trackDict.enumerated().forEach {
            TealiumHelper.shared.track(title: "event \(index) dict \($0.offset)", data: $0.element)
        }
    }
    // TODO: Remove before release
    let trackDict: [[String: Any]] = [
        [
          "_id": "600b5766a369f2da04f756fd",
          "index": 0,
          "guid": "4b3ae4f4-52b4-4d94-90ef-1ba0698babfb",
          "isActive": true,
          "balance": "$3,147.98",
          "picture": "http://placehold.it/32x32",
          "age": 27,
          "eyeColor": "blue",
          "name": [
            "first": "Millicent",
            "last": "Lindsay"
          ],
          "company": "RONELON",
          "email": "millicent.lindsay@ronelon.net",
          "phone": "+1 (852) 587-3305",
          "address": "820 Garfield Place, Coleville, Massachusetts, 7007",
          "about": "Ipsum ullamco ullamco ex ut elit labore adipisicing ullamco aliquip labore. Officia amet ad dolor excepteur ea do consectetur. Deserunt commodo ex non qui eiusmod sint eiusmod velit esse elit consequat aliquip minim id. Elit exercitation ut occaecat ut qui dolor nostrud ad dolor id ipsum eu laboris consequat. Culpa quis officia proident velit duis Lorem elit irure deserunt enim est consequat esse voluptate.",
          "registered": "Wednesday, October 23, 2019 7:27 PM",
          "latitude": "66.175741",
          "longitude": "105.519916",
          "tags": [
            "commodo",
            "voluptate",
            "deserunt",
            "adipisicing",
            "irure"
          ],
          "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
          ],
          "friends": [
            [
              "id": 0,
              "name": "Sylvia Goodman"
            ],
            [
              "id": 1,
              "name": "Shannon Schmidt"
            ],
            [
              "id": 2,
              "name": "Paulette Ballard"
            ]
          ],
          "greeting": "Hello, Millicent! You have 7 unread messages.",
          "favoriteFruit": "banana"
        ],
        [
          "_id": "600b5766437695d3d8ff1d8e",
          "index": 1,
          "guid": "547f6494-46a9-45a1-ac05-aac0fdfc8779",
          "isActive": false,
          "balance": "$1,576.62",
          "picture": "http://placehold.it/32x32",
          "age": 32,
          "eyeColor": "blue",
          "name": [
            "first": "Moore",
            "last": "Spears"
          ],
          "company": "GRAINSPOT",
          "email": "moore.spears@grainspot.me",
          "phone": "+1 (970) 584-3717",
          "address": "226 Bond Street, Morningside, Iowa, 2363",
          "about": "Cillum ut voluptate velit incididunt laborum reprehenderit veniam adipisicing sunt nisi sint enim cillum. Sunt exercitation officia nisi Lorem. Exercitation nisi mollit amet cupidatat voluptate occaecat id. Deserunt reprehenderit consequat ut nostrud eu veniam eiusmod.",
          "registered": "Tuesday, April 16, 2019 1:36 AM",
          "latitude": "6.059548",
          "longitude": "124.255504",
          "tags": [
            "proident",
            "irure",
            "sint",
            "qui",
            "non"
          ],
          "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
          ],
          "friends": [
            [
              "id": 0,
              "name": "Gilda Dean"
            ],
            [
              "id": 1,
              "name": "Gilmore Stuart"
            ],
            [
              "id": 2,
              "name": "Moses Rogers"
            ]
          ],
          "greeting": "Hello, Moore! You have 6 unread messages.",
          "favoriteFruit": "apple"
        ],
        [
          "_id": "600b576616eebab6ad6f6ba7",
          "index": 2,
          "guid": "34a09322-4025-4447-97e2-2238c19bec8f",
          "isActive": true,
          "balance": "$2,131.64",
          "picture": "http://placehold.it/32x32",
          "age": 38,
          "eyeColor": "brown",
          "name": [
            "first": "Hayden",
            "last": "Cline"
          ],
          "company": "OMNIGOG",
          "email": "hayden.cline@omnigog.tv",
          "phone": "+1 (800) 492-2737",
          "address": "394 Beard Street, Joppa, Mississippi, 5351",
          "about": "Dolor quis est dolore aliquip minim aliquip mollit. Commodo magna labore tempor incididunt. Labore commodo mollit nulla officia culpa eiusmod et consectetur aliqua commodo incididunt pariatur. Tempor id commodo veniam occaecat ullamco. Sunt cupidatat irure fugiat labore quis aliquip laborum amet enim ullamco id ad commodo.",
          "registered": "Monday, November 7, 2016 4:34 AM",
          "latitude": "-80.120561",
          "longitude": "7.380285",
          "tags": [
            "ea",
            "ullamco",
            "adipisicing",
            "proident",
            "non"
          ],
          "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
          ],
          "friends": [
            [
              "id": 0,
              "name": "Jeanne Spencer"
            ],
            [
              "id": 1,
              "name": "Joyce Castillo"
            ],
            [
              "id": 2,
              "name": "Odonnell Lyons"
            ]
          ],
          "greeting": "Hello, Hayden! You have 7 unread messages.",
          "favoriteFruit": "strawberry"
        ],
        [
          "_id": "600b5766063eed75d256e67a",
          "index": 3,
          "guid": "061cc915-decf-4eb0-8bb2-4aa96c77f83d",
          "isActive": false,
          "balance": "$2,999.36",
          "picture": "http://placehold.it/32x32",
          "age": 24,
          "eyeColor": "brown",
          "name": [
            "first": "Raymond",
            "last": "Moss"
          ],
          "company": "COMVOY",
          "email": "raymond.moss@comvoy.name",
          "phone": "+1 (943) 489-2899",
          "address": "830 Broome Street, Haena, North Carolina, 7248",
          "about": "Qui enim quis consectetur qui laboris aute reprehenderit consequat ad aute in cupidatat nulla. Esse aliquip enim quis in pariatur duis officia. Mollit mollit esse nostrud quis qui laboris consectetur consequat pariatur ea. Nostrud eiusmod laborum tempor officia aliquip. Velit cupidatat amet culpa esse eu proident elit eu minim nostrud est qui incididunt ad. Eiusmod dolor elit eu adipisicing sint.",
          "registered": "Monday, September 4, 2017 3:31 AM",
          "latitude": "75.388672",
          "longitude": "-81.145445",
          "tags": [
            "veniam",
            "quis",
            "quis",
            "est",
            "commodo"
          ],
          "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
          ],
          "friends": [
            [
              "id": 0,
              "name": "House Tyson"
            ],
            [
              "id": 1,
              "name": "Caitlin Hammond"
            ],
            [
              "id": 2,
              "name": "Melva Lopez"
            ]
          ],
          "greeting": "Hello, Raymond! You have 7 unread messages.",
          "favoriteFruit": "banana"
        ],
        [
          "_id": "600b5766281462fb48bda8a8",
          "index": 4,
          "guid": "04c6eff0-fa9a-4a5d-bbbd-8e00c90f5010",
          "isActive": true,
          "balance": "$1,654.09",
          "picture": "http://placehold.it/32x32",
          "age": 39,
          "eyeColor": "green",
          "name": [
            "first": "Johanna",
            "last": "Hart"
          ],
          "company": "KIOSK",
          "email": "johanna.hart@kiosk.io",
          "phone": "+1 (948) 452-3143",
          "address": "944 Rockwell Place, Benson, Kansas, 3845",
          "about": "Sit voluptate duis sunt fugiat consectetur eiusmod aliquip incididunt exercitation. Ea enim est non esse do sunt. Ea labore incididunt consectetur fugiat commodo non ea.",
          "registered": "Monday, June 6, 2016 6:30 PM",
          "latitude": "-13.643028",
          "longitude": "105.3913",
          "tags": [
            "aute",
            "laborum",
            "deserunt",
            "tempor",
            "proident"
          ],
          "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
          ],
          "friends": [
            [
              "id": 0,
              "name": "Ashley Daniels"
            ],
            [
              "id": 1,
              "name": "Roslyn Contreras"
            ],
            [
              "id": 2,
              "name": "Reeves Suarez"
            ]
          ],
          "greeting": "Hello, Johanna! You have 5 unread messages.",
          "favoriteFruit": "strawberry"
        ],
        [
          "_id": "600b5766f0dc42c9340aa088",
          "index": 5,
          "guid": "b0d984d3-4aa8-4044-88f9-83cb3da07da2",
          "isActive": false,
          "balance": "$1,512.83",
          "picture": "http://placehold.it/32x32",
          "age": 30,
          "eyeColor": "brown",
          "name": [
            "first": "Barron",
            "last": "Good"
          ],
          "company": "TROPOLI",
          "email": "barron.good@tropoli.biz",
          "phone": "+1 (883) 455-3714",
          "address": "923 Milton Street, Cliffside, Oregon, 2992",
          "about": "Enim proident veniam Lorem irure esse occaecat minim amet ad amet cupidatat non irure id. Velit minim adipisicing elit in laboris aute commodo fugiat culpa nisi eu ea est. Veniam Lorem elit deserunt incididunt aliquip ex laborum exercitation. Eiusmod ut adipisicing nulla do ullamco nulla Lorem ea qui ea sint Lorem. Incididunt ullamco consectetur cupidatat dolor ipsum esse fugiat ipsum ipsum culpa proident esse ullamco. Amet esse ullamco esse duis.",
          "registered": "Monday, June 17, 2019 4:32 PM",
          "latitude": "-39.149057",
          "longitude": "-7.170292",
          "tags": [
            "laboris",
            "adipisicing",
            "excepteur",
            "duis",
            "excepteur"
          ],
          "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
          ],
          "friends": [
            [
              "id": 0,
              "name": "Mcmahon Mays"
            ],
            [
              "id": 1,
              "name": "Savage Dunn"
            ],
            [
              "id": 2,
              "name": "Felicia Campos"
            ]
          ],
          "greeting": "Hello, Barron! You have 9 unread messages.",
          "favoriteFruit": "apple"
        ],
        [
          "_id": "600b57668109c3d506c5fccc",
          "index": 6,
          "guid": "23b80513-8085-4186-82d5-3d21baed2945",
          "isActive": false,
          "balance": "$3,660.22",
          "picture": "http://placehold.it/32x32",
          "age": 25,
          "eyeColor": "blue",
          "name": [
            "first": "Wiley",
            "last": "Kim"
          ],
          "company": "ECRATIC",
          "email": "wiley.kim@ecratic.info",
          "phone": "+1 (902) 580-2479",
          "address": "231 Irvington Place, Davenport, Florida, 2018",
          "about": "Tempor elit laborum ipsum irure sint culpa. Incididunt veniam minim officia pariatur consequat cillum excepteur nisi tempor. Adipisicing culpa amet fugiat adipisicing et voluptate pariatur amet duis anim dolor. Consequat incididunt nostrud culpa tempor laboris esse. Irure consectetur enim aliquip Lorem ad enim elit excepteur proident. Eu laboris ea nostrud reprehenderit voluptate qui esse occaecat. Nisi exercitation velit anim in non deserunt.",
          "registered": "Sunday, June 12, 2016 10:30 AM",
          "latitude": "-55.087721",
          "longitude": "-173.916538",
          "tags": [
            "ipsum",
            "anim",
            "nostrud",
            "voluptate",
            "ad"
          ],
          "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
          ],
          "friends": [
            [
              "id": 0,
              "name": "Wong Cannon"
            ],
            [
              "id": 1,
              "name": "Lela Vaughan"
            ],
            [
              "id": 2,
              "name": "Tommie Finch"
            ]
          ],
          "greeting": "Hello, Wiley! You have 10 unread messages.",
          "favoriteFruit": "banana"
        ],
        [
          "_id": "600b57669606d801a193675c",
          "index": 7,
          "guid": "aabba41c-b6a0-42b7-a349-e1f60fcedaaf",
          "isActive": false,
          "balance": "$1,427.69",
          "picture": "http://placehold.it/32x32",
          "age": 40,
          "eyeColor": "green",
          "name": [
            "first": "Mclean",
            "last": "Beck"
          ],
          "company": "LIMAGE",
          "email": "mclean.beck@limage.biz",
          "phone": "+1 (865) 437-2743",
          "address": "868 Vanderveer Place, Nelson, Arkansas, 3775",
          "about": "Enim veniam esse id amet minim magna sit et quis id aute. Aliquip proident exercitation excepteur magna reprehenderit. Laboris ipsum sit sit aliqua ut dolor ullamco in ipsum magna cillum consequat consequat veniam. Fugiat voluptate laborum dolore incididunt commodo. Labore laborum occaecat exercitation pariatur tempor proident tempor ullamco culpa irure.",
          "registered": "Wednesday, December 27, 2017 6:24 AM",
          "latitude": "38.76582",
          "longitude": "8.881722",
          "tags": [
            "enim",
            "incididunt",
            "mollit",
            "exercitation",
            "incididunt"
          ],
          "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
          ],
          "friends": [
            [
              "id": 0,
              "name": "Callie Rasmussen"
            ],
            [
              "id": 1,
              "name": "Williams Brady"
            ],
            [
              "id": 2,
              "name": "Lynne Knapp"
            ]
          ],
          "greeting": "Hello, Mclean! You have 10 unread messages.",
          "favoriteFruit": "apple"
        ]
      ]

    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
          ContentView().previewDevice(PreviewDevice(rawValue: "iPhone X"))
            ContentView().previewDevice(PreviewDevice(rawValue: "iPhone 8"))
            ContentView().previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
            ContentView().previewDevice(PreviewDevice(rawValue: "iPhone 11 SE (1st generation)"))
        }
        
    }
}
