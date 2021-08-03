# SmartVoiceKit (iOS)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Cocoapods compatible](https://img.shields.io/badge/Cocoapods-compatible-4BC51D.svg?style=flat)](https://github.com/CocoaPods/CocoaPods)

## Introduction

SmartVoiceKit iOS is the production conversation SDK for the Orange and Deutsche Telekom projects.

The last version of this README.md file is in the gitHub repository : https://github.com/vpaas-sdks/ios-SmartVoiceKit

## Features
- A conversation UI allowing the user to ask questions to Assistant.
- The same conversation UI to display the history of interations the users had with Assistant independently of the source device
- Edition of the history (Messages deletion)
- Edition of the Filter 
- Edition of the V3 cards 
- Provides Djingo local services as timers, radio, news or music playing

All those features are based on [SmartVoiceKit framework](https://github.com/vpaas-sdks/ios-SmartVoiceKit).

## Requirements

- [iOS 10.0+](https://developer.apple.com)
- [Xcode 10.1+](https://developer.apple.com)
- [Carthage 0.33+](https://github.com/Carthage/Carthage) 
- [Cocoadpod 1.8.3+](https://cocoapods.org) 

## Building your app with SmartVoiceKit 
### Using Carthage   
 Add the following line in your Cartfile 

```git "https://github.com/vpaas-sdks/ios-SmartVoiceKit.git" ~> 6.6.2```

Build the SDK

```$ carthage update SmartVoiceKit```

#### Troubleshooting During Carthage’s Installation

If you have any path error prompted by **Carthage** in the terminal, you may verify your Xcode’s Preferences -> Locations -> Derived Data -> Advanced. We highly recommend that you set it to `unique build location`. If you use `Legacy`, `Shared Folder` or `custom` build location, do it on your risk with complete understanding why you do that.

### Using Cocoapods
 Add the following line in your Podfile

 ```pod 'SmartVoiceKit', :git => 'https://github.com/vpaas-sdks/ios-SmartVoiceKit.git', :tag => '6.6.2'```

Run pod install

```$ pod install```
#### Troubleshooting during CocoaPod's installation

 If you have an error message due to `pod install`. 
 For example 
 ```bash
 [!] CocoaPods could not find compatible versions for pod "SmartVoiceKit":
  In Podfile:
    SmartVoiceKit (from `https://github.com/vpaas-sdks/ios-SmartVoiceKit.git`, tag `6.6.2`)

Specs satisfying the `SmartVoiceKit (from `https://github.com/vpaas-sdks/ios-SmartVoiceKit.git`, tag `7.0`)` dependency were found, but they required a higher minimum deployment target.
 ```
 
 Please, check in your project your **iOS Deployment Target**, it should be at least `iOS 10.0`. There probably is an additional configuration for deployment targets in **Podfile**, you may look over the line `platform :ios, '10.0'`, as you see it should also be at least `iOS 10.0`.

## Integration of the History / Conversation Page

### Add SVKConversationViewController in your storyboard

You can add SVKConversationViewController from the SVKConversationStoryboard in your storyboard

### Using code 

```swift
import SmartVoiceKit

...
if let bundle = Bundle(identifier: "de.telekom.svk"),
	let conversationViewController = UIStoryboard(name: "SVKConversationStoryboard", bundle: bundle)
                                                .instantiateInitialViewController() as? SVKConversationViewController {
            
	// Set up SVKConversationViewController
	...
            
	// Present the viewcontroller into a navigation viewcontroller
	let navigationController = UINavigationController(rootViewController: conversationViewCOntroller)
	self.present(navigationController, animated: true, completion: nil)
}
```
Another way to obtain SmartVoiceKit bundle is `let bundle = Bundle(for: SVKConversationViewController.self)`.  Please, feel free to use the most convenient way in your implementation.
So to sum up, to procure the bundle you may use:
- `let bundle = Bundle(for: svkConversationViewController.self)` either use **cocoapods** or **carthage**    
- `let bundle = Bundle(path: "de.telekom.svk")` in which case use **carthage** or direct framework's import in the project.
- `let bundle = Bundle(path: "de.telekom.svk")` only if you use **cocoapods**

#### Using Storyboard References 
- Open your storyboard file and add a Storyboard reference object
- Click on newly created Storyboard Reference and go into Attribute inspector on the right panel
- In Storyboard field, select `SVKConversationStoryboard`
- In Bundle field, type `de.telekom.svk` if your are using cocoapods `de.telekom.svk`
- Finally, create a segue from the appropriate view of a UINavigationController in your app and this Storyboard Reference. The initial view controller (SVKConversationViewController) of the storyboard must be embed into a UINavigationController.

That's it !

## Integration of the Audio Recorder Button

### Add the SVKAudioRecorderViewController in your storyboard

You can add the `SVKAudioRecorderViewController` from the `SVKConversationStoryboard` in your storyboard by using Segue:

```swift
import UIKit

class AudioRecorderSegue: UIStoryboardSegue {
    
    static public let segueIdentifier = "AudioRecorderSegue"
 
    override func perform() {
        guard let viewController = source as? AudioRecorderViewController,
            let container = viewController.audioRecorderContainer,
            let inputView = self.destination.view
            else { return }
        
        container.subviews.first?.removeFromSuperview()
        container.addSubview(inputView)
        viewController.addChild(self.destination)
        inputView.translatesAutoresizingMaskIntoConstraints = false
        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leading)-[inputView]-(trailing)-|",
                                                               options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                               metrics: ["leading":0, "trailing":0],
                                                               views: ["inputView" : inputView]))
        container.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(top)-[inputView]-(bottom)-|",
                                                               options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                               metrics: ["top":0, "bottom":0],
                                                               views: ["inputView" : inputView]))        
        
    }
}
```

### Using code 

```swift
import SmartVoiceKit

...

    @IBOutlet var audioRecorderContainerView: UIView!    
    var audioRecorderViewController: SVKAudioRecorderViewController?
...
    override func viewDidLoad() {
        super.viewDidLoad()
...     
        // Do any additional setup after loading the view.
        if let bundle = Bundle(identifier: "de.telekom.svk"),
        let audioRecorderViewController = UIStoryboard(name: "SVKConversationStoryboard", bundle: bundle)
            .instantiateViewController(withIdentifier: "SVKAudioRecorderViewController") as? SVKAudioRecorderViewController {
      
            self.audioRecorderViewController = audioRecorderViewController
            self.audioRecorderContainerView.subviews.forEach { (view) in
                view.removeFromSuperview()
            }
            self.audioRecorderContainerView.addSubview(audioRecorderViewController.view)
            self.addChild(audioRecorderViewController)
            audioRecorderViewController.view.translatesAutoresizingMaskIntoConstraints = false
            
            self.audioRecorderContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leading)-[inputView]-(trailing)-|",
                                                                   options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                   metrics: ["leading":0, "trailing":0],
                                                                   views: ["inputView" : audioRecorderViewController.view]))
            self.audioRecorderContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(top)-[inputView]-(bottom)-|",
                                                                   options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                   metrics: ["top":0, "bottom":0],
                                                                   views: ["inputView" : audioRecorderViewController.view]))
   ...         
        }
   
```

## Customization

### Setting up of the SDK for the History / Conversation Page

```swift
import SmartVoiceKit
            
...

let conversationViewController: SVKConversationViewController =             

// Set to false to disable the sound effets
conversationViewController.isSoundEffectsEnabled = true

// Set to false to disable the vocalization
conversationViewController.isVocalizationEnabled = true

// The SVKConversationProtocol
conversationViewController.delegate = your delegate

// Set the viewController display mode. SVKConversationDisplayMode
// .conversation will enable audio or text conversation with Djingo
conversationViewController.displayMode = [.history, .conversation]

// Specify the conversation input mode. SVKConversationInputMode
conversationViewController.inputMode = [.text, .audio]

// hide the default device name defined by SVKConstant.defaultDeviceName = "default-fallback"
viewController.isHideDeviceDefaultNameEnabled = true

// Specify the activate/deactivate consent that is associated with the vocal assistant to provide a feedback
// This is a static parameter used by all SVK Components
// See Global SDK configuration
SVKContext.consentFeedbackCheck = [ ... ]
```

### Setting up of the SDK for the Audio Recorder Button

```swift
let audioRecorderViewController :AudioRecorderViewController = 

// The SVKConversationProtocol
audioRecorderViewController.delegate = your delegate for conversation

// The SVKAudioRecorderDelegate
audioRecorderViewController.delegateAudioRecorder = your delegate for audio

// Set to false to disable the sound effets
audioRecorderViewController.isSoundEffectsEnabled = true

// Set to false to disable the vocalization
audioRecorderViewController.isVocalizationEnabled = true
            
```
### Setting up of the SDK for the Contextual Recommendation Hack
```swift
// Set to true to enable the hack for Contextual Recommendation for error status "DIDNT_UNDERSTOOD_SPEECH"
conversationViewController.context.isEmptyRequestRecommendationHackEnable

// Set to true to enable the hack for Contextual Recommendation for error status "COULDNT_RESOLVE_INTENT"
conversationViewController.context.isMisunderstoodRequestRecommendationHackEnable

// Set to true to enable the global commands to show in the conversation history/conversation
conversationViewController.context.isShowGlobalCommandsConfirmationEnable

// Set to true to enable the vocalisation of global commands for the live interactions
conversationViewController.context.isVocaliseGlobalCommandsConfirmationEnable

```

### Setting up of the petals animation / barGraph
BarGraph is the default setting.
You can set the petals animations for both SVKAudioRecorderViewController and SVKConversationViewController component.
```swift
// the component must be loaded. You can load it by asking for his view
let _ = component.view

// for the SVKConversationViewController you must set inputMode to audio
if let componentConversation  = component as? SVKConversationViewController {
    componentConversation.inputMode = .audio
}
// Set the type of the animation
component.setUpAnimationType(animationType: .petals)

```
To customize the “animation’s view” background, there are two parameters available to perform the most accurate adjustment. 
The `audioInputAnimationBackgroundColor` lets you set the desired color to the background
area behind all layers.
The `audioInputAnimationTorusColor` helps you to apply the needed tint on the 
inner circle. 

Here is an example how to override these parameters in code:

```swift
svkAppearance.audioInputAnimationTorusColor = SVKColor(main: .white, dark: .black)
svkAppearance.audioInputAnimationBackgroundColor = SVKColor(main: .white, dark: .black)
```

or it's possible to do it in json file:

```json
"audioInputAnimationTorusColor": {
    "main": "#EFEFEF",
    "dark": "#191919"
},
"audioInputAnimationBackgroundColor": {
    "main": "#EFEFEF",
    "dark": "#191919"
}
```
                                                    ▲ ┌──────────────────────────────────┐
                                                    │ │  audioInputAnimationTorusColor   │
                                                    │ └──────────────────────────────────┘
                                                    │
                        ┌───────────────────────────┼──────────────────┐
                        │                           │                  │
                        │                           │                  │
                        │                           │                  │
                        │                           │                  │
                        │                           │                  │
                        │                           │                  │
                        │                           │                  │
              ┏━━━━━━━━━┻━━━━━┓             .───────│              ┏━━━╋━━━━━━━━━━━┓
              ┃███████████████┃           ,'        │`.            ┃███│███████████┃
              ┃███████████████┃          ╱          │  ╲           ┃███│███████████┃           ┌─────────────────┐
              ┃███████████████┃         ;               :          ┃███│█████████──╋─────────▶ │  a view behind  │
              ┃███████⌘███████┃         :               ;          ┃███│███⌘███████┃           └─────────────────┘
              ┃███████████████┃          ╲             ╱           ┃███│███████████┃
              ┃███████████████┃           ╲           ╱            ┃███│███████████┃
              ┃███████████████┃            `.       ,'             ┃███│███████████┃
              ┃███████████████┃              `─────'               ┃███│███████████┃
              ┗┳━━━━━━━━┳━━━━━┛                                    ┗━━━╋━━━━━━━━━━━┛
               │        │                                              │
               │        │                                              │
               ▼        │                                              │
    ┌─────────────┐     │                                              │
    │a view ahead │     │                                              │
    └─────────────┘     │                                              │
                        │                             │                │
                        └─────────────────────────────┼────────────────┘
                                                      │
                                                      │
                                                      │
                                                      │
                                                      ▼
                                                     ┌─────────────────────────────────────┐
                                                     │ audioInputAnimationBackgroundColor  │
                                                     └─────────────────────────────────────┘

### Setting up of the SDK for the Consent Page

```swift
// Specify the activate/deactivate consent that is displayed in the consentPage
// This is a static parameter used by all SVK Components
// See Global SDK configuration
SVKContext.consentPage = [ ... ]

let storyboard = UIStoryboard(name: "SVKConversationStoryboard", bundle: SVKBundle)
let viewController = storyboard.instantiateViewController(withIdentifier: "SVKGDPRViewController") as! SVKGDPRViewController

// the SVKGDPRViewController is configure with three delegate (gdprDelegate, conversationDelegate and userDelegate), the isShowOnlyDeviceHistory to define if we use the only device delete or not, and the content to display

viewController.configureWith(gdprDelegate: GDPRController(), conversationDelegate: ConversationController() ,  userDelegate: UserController(), isShowOnlyDeviceHistory: Settings.shared.isShowOnlyDeviceHistory, dedicatedPreFixLocalisationKey: dedicatedPreFixLocalisationKey(),useNavigation: true,contentDisplayed: contentDisplayed)

self.navigationController?.pushViewController(viewController, animated: true)

```
### Global SDK configuration

```swift

// Define the global locale            
SVKContext.locale = Locale(identifier: "fr")

// Configure the view controller context
let context: SVKContext = SVKContext()

conversationViewController.context = context
audioRecorderViewController.contect = context

// Set the audio resources to use when in audio (wav or pcm) conversation mode
context.soundConfiguration.resources = [
                        SVKSoundConfiguration.SpeechRecognitionKeys.startListening : "H_HunHun_acceptation.wav",
                        SVKSoundConfiguration.SpeechRecognitionKeys.stopListening : "D_StopListening_Outro.wav"]                    

            
// Specify the audio codec to use for Speech To Text            
context.speechConfiguration = SVKSpeechConfiguration(sttCodecFormat: "wav/16khz/16bit/1")

// Specify the activate/deactivate consent that is associated with the vocal assistant to provide a feedback
// This is a static parameter used by all SVK Components
SVKContext.consentFeedbackCheck = [.languageTechnology, .voiceProcessing, .usageStatistics, .listenVoice]

// Specify the activate/deactivate consent that is displayed in the consentPage
// This is a static parameter used by all SVK Components
SVKContext.consentPage = [.languageTechnology, .voiceProcessing, .usageStatistics, .listenVoice]

```

### Enable the debug mode
You can enable some debugging feature to debug your development.

```swift
import SmartVoiceKit
            
...

let conversationViewController: SVKConversationViewController =             

#if DEBUG
// If true, the SDK will log some informations into the console
context.isDevelopmentEnabled = true

// If true when displaying a card, the SDK fill the card will data rather than using empty values
context.isCardHackEnabled = true
#endif
```

When the development mode is enabled, you can acces the JSON portion of each bubble displayed by the SDK, by doing a long press on this bubble then tap the code button.


### Appearance customization
SVK offers an easy way to customize its appearance. There are two possible ways to do it. one you may be used to do : in-code configuration. The second approach is to provide a JSON file.

#### Configure programmatically
- instantiate  `SVKAppearance` for example in your **appDelegate** and provide the instance to `SVKAppearanceBox`
```swift
var svkAppearance = SVKAppearance()
SVKAppearanceBox.shared.appearance = svkAppearance
```

- Configure whether you support dark and light appearance or not
```swift
svkAppearance.userInterfaceStyle = [.main, .dark]
```
- You may set up **background** color, **tint** color and color of **audio input** component. It can be done by `SVKColor` help. `SVKColor` has mandatory `main` color and optional `dark` color. The `dark` color must be set if you support `.dark` userInterfaceStyle.

```swift
        svkAppearance.backgroundColor = SVKColor(main: .white, dark: .black)
        svkAppearance.audioInputColor = SVKColor(main: .red, dark: .blue)
        svkAppearance.tintColor = SVKColor(main: .orange, dark: .orange)
```
- Customize buttons appearance by setting `SVKButtonAppearance`.
	- To personalize **Cancallation** or **Validation** buttons, `buttonStyle` variable should be set. You should provide `default` state for normal button's style and `highlight` state for buttons in colored state to bring user's attention, e.g. **Delete** or **Cancel** button.

```swift
        let normalStateForButton = SVKButtonStyleDescription(
            fillColor: SVKColor(main: .clear, dark: .clear),
            shapeColor: SVKColor(main: dynamicBlack, dark: dynamicBlack),
            lineWidth: 2)
        
        let highlightedStateForButton = SVKButtonStyleDescription(
            fillColor: SVKColor(main: .black, dark: .white),            shapeColor: SVKColor(main: .tintColor, dark: .tintColor),
            lineWidth: 0)
        
        let buttonStyle = SVKButtonAppearance(
            default: normalStateForButton,
            highlighted: highlightedStateForButton,
            cornerRadius: 0)
        
        svkAppearance.buttonStyle = buttonStyle
```

	- To personalize **Filter** buttons,`filterButtonStyle` variable should be set.

```swift
	svkAppearance.filterButtonStyle = filterButtonStyle
```
- you can always verify you configuration 
 

```swift
svkAppearance.checkConfiguration()
```

#### configure with JSON file
This method was created to let designers, developpers, testers, product owners etc. to provide an appearance configuration in a stand-alone JSON file.
Once you've got the file, you need to go through the following steps:

- Drop the file to the project and make sure you added it to all needed targets. 
- instantiate  the `SVKAppearance` with the file

```swift
let svkAppearance = SVKAppearance(with: "MagentaAppearance")
```

- you may verify if your configuration is valid

```swift
svkAppearance.checkConfiguration()
```
- Feed the configured `svkAppearance` instance to `SVKAppearanceBox`

```swift
SVKAppearanceBox.shared.appearance = svkAppearance
```

and that's it, you are done with configuration. 
##### Json file structure
You can find the complete file [here](https://github.com/vpaas-sdks/ios-SmartVoiceKit/blob/master/README.md).
The SVK appearance supports two user interface styles : **"light"** called `.main` in SVK and **"dark"** which port the same name in SVN `.dark`. All color configurations have a possibility to provide a color for the given user interface style. 

```json
{
        "main": "#FFFFFF",
        "dark": "#000000"
}
``` 

You may have no need to support the dark appearance in your application or need just one appearance. For this case you need to set only **main** color which is mandatory and leave the **"dark"** which is optional. 

```json
{
        "main": "#FFFFFF"
}
```

#### Bubbles customization

There are two ways to customize a bubble with `SVKAppearance`. You can do it in code and in json configuration file.            
In code customization:              
With help of `SVKBubbleAppearanceSettings` you may configure the assistant size bubble style **assistantBubbleStyle** and the user’s size bubble style **userBubbleStyle**.
`SVKBubbleAppearanceSettings` let you fine-tune bubble’s background color, text color, the flag color, corner radius which set the radius for all four corners, content inset for bubble’s position in **UITableViewCell** and a bubble’s category which is used for pin style, it can be either magenta or djingo.

`SVKBubbleAppearanceSettings` comes with convenience initializer in which all parameters are set to assistant bubble style. For example for Djingo you can do:

```swift
var svkAppearance = SVKAppearance()
…
let assistantBubbleStyle = SVKBubbleAppearanceSettings()

let userBubbleStyle = SVKBubbleAppearanceSettings(backgroundColor: SVKColor(main: .user,
                                                      dark: UIColor(hex: "#272727")),
                            textColor: SVKColor(main: .black,
                                                dark: UIColor(hex: "#EEEEEE")),
                            flagColor: SVKColor(main: .user,
                                                dark: UIColor(hex: "#272727")))

svkAppearance.userBubbleStyle = userBubbleStyle
svkAppearance.assistantBubbleStyle = assistantBubbleStyle
```
To configure the bubbles of the "Hide Error interactions from the History" feature, it is necessary to initialize the style of the headers and the style of the bubbles users and assistant.
```swift
let headerCollapsedErrorBubbleStyle = SVKBubbleAppearanceSettings(backgroundColor: SVKColor(main: .white, dark: .black),
                                                          textColor: SVKColor(main: UIColor(hex: "#DDDDDD"), dark: UIColor(hex: "#DDDDDD")),
                                                          borderColor: SVKColor(main: .white, dark: .black),
                                                          borderWidth: CGFloat(0.0))
  
let headerExpandedErrorBubbleStyle = SVKBubbleAppearanceSettings(backgroundColor: SVKColor(main: .white, dark: .black),
                                                         textColor: SVKColor(main: UIColor(hex: "#9B9B9B"), dark: UIColor(hex: "#9B9B9B")),
                                                        borderColor: SVKColor(main: .white, dark: .black),
                                                        borderWidth: CGFloat(0.0))
    
let userErrorBubbleStyle = SVKBubbleAppearanceSettings(backgroundColor: SVKColor(main: .white, dark: UIColor(hex: "#272727")),
                                          textColor: SVKColor(main: UIColor(hex: "#9B9B9B"), dark: UIColor(hex: "#DDDDDD")),
                                          borderColor: SVKColor(main: UIColor(hex: "#9B9B9B"), dark: UIColor(hex: "#DDDDDD")),
                                          borderWidth: CGFloat(2.5))
 
let assistantErrorBubbleStyle = SVKBubbleAppearanceSettings(backgroundColor: SVKColor(main: UIColor(hex: "#9B9B9B"), dark: UIColor(hex: "#9B9B9B")),
                                         textColor: SVKColor(main: .white, dark: UIColor(white: 1, alpha: 1)),
                                         borderColor: SVKColor(main: UIColor(hex: "#9B9B9B"), dark: UIColor(hex: "#DDDDDD")),
                                         borderWidth: CGFloat(0.0))

svkAppearance.headerErrorCollapsedBubbleAppearance = headerCollapsedErrorBubbleStyle
svkAppearance.headerErrorExpandedBubbleAppearance = headerExpandedErrorBubbleStyle
svkAppearance.userErrorBubbleAppearance = userErrorBubbleStyle
svkAppearance.assistantErrorBubbleAppearance = assitantErrorBubbleStyle
```
To configure the bubbles of the "Contextual Recommendation" feature, it is necessary to initialize the style of the headers and the style of the bubble reco.

```swift
let recoBubbleStyle = SVKBubbleAppearanceSettings(backgroundColor: SVKColor(main: .white, dark: .black),
                                          textColor: SVKColor(main: UIColor(hex: "#9B9B9B"), dark: UIColor(hex: "#DDDDDD")),
                                          flagColor: SVKColor(main: UIColor(hex: "#9B9B9B"), dark: UIColor(hex: "#DDDDDD")),
                                          borderColor: SVKColor(main: UIColor(hex: "#9B9B9B"), dark: UIColor(hex: "#DDDDDD")),
                                          borderWidth: CGFloat(2.5))

svkAppearance.recoBubbleStyle = recoBubbleStyle

```
To set your bubble appearance in configuration file, you must set all parameters up. Here is an example of the pinch of json file which is responsible for bubbles appearance.

```json
    "assistantBubbleStyle":{
        "backgroundColor": {
            "main": "#FFFFFF",
            "dark": "#303030"
        },
        "flagColor": {
            "main": "#b2b2b2",
            "dark": "#6b6b6b"
        },
        "textColor": {
            "main": "#262626",
            "dark": "#FFFFFF"
        },
        "typingTextColor": {
            "main": "#7ecbf5ff",
            "dark": "#FFFFFF"
        },
        "contentInset": [12,16,12,16],
        "cornerRadius": 5,
        "borderColor": {
            "main": "#FFFFFF",
            "dark": "#303030"
        },
        "borderWidth": 1.5,
        "category": "magenta"
    },
    "userBubbleStyle":{
        "backgroundColor": {
            "main": "#009DE0",
            "dark": "#00a1de"
        },
        "flagColor": {
            "main": "#00A1DE",
            "dark": "#00A1DE"
        },
        "textColor": {
            "main": "#FFFFFF",
            "dark": "#FFFFFF"
        },
        "typingTextColor": {
            "main": "#7ecbf5ff",
            "dark": "#7ecbf5ff"
        },
        "contentInset": [12,16,12,16],
        "cornerRadius": 5,
        "borderColor": {
            "main": "#00A1DE",
            "dark": "#00A1DE"
        },
        "borderWidth": 1.5,
        "category": "magenta"
    }
```
To set your bubble of the "Hide Error interactions from the History" feature appearance in configuration file, you must set the Hide Error Interactions specific parameters up
```json
"headerExpandedErrorBubbleStyle":{
        "backgroundColor": {
            "main": "#00A1DE",
            "dark": "#00A1DE"
        },
        "flagColor": {
            "main": "#00A1DE",
            "dark": "#00A1DE"
        },
        "textColor": {
            "main": "#262626",
            "dark": "#262626"
        },
        "typingTextColor": {
            "main": "#7ecbf5ff",
            "dark": "#FFFFFF"
        },
        "contentInset": [12,16,12,16],
        "cornerRadius": 5,
        "borderColor": {
            "main": "#00A1DE",
            "dark": "#00A1DE"
        },
        "borderWidth": 1.5,
        "category": "magenta"
    },
    "headerCollapsedErrorBubbleStyle":{
        "backgroundColor": {
            "main": "#00A1DE",
            "dark": "#00A1DE"
        },
        "flagColor": {
            "main": "#00A1DE",
            "dark": "#00A1DE"
        },
        "textColor": {
            "main": "#6B6B6B",
            "dark": "#6B6B6B"
        },
        "typingTextColor": {
            "main": "#7ecbf5ff",
            "dark": "#FFFFFF"
        },
        "contentInset": [12,16,12,16],
        "cornerRadius": 5,
        "borderColor": {
            "main": "#00A1DE",
            "dark": "#00A1DE"
        },
        "borderWidth": 1.5,
        "category": "magenta"
    },
    "userErrorBubbleStyle":{
        "backgroundColor": {
            "main": "#FFFFFF",
            "dark": "#6B6B6B"
        },
        "flagColor": {
            "main": "#9B9B9B",
            "dark": "#DDDDDD"
        },
        "textColor": {
            "main": "#9B9B9B",
            "dark": "#DDDDDD"
        },
        "typingTextColor": {
            "main": "#7ecbf5ff",
            "dark": "#FFFFFF"
        },
        "contentInset": [12,16,12,16],
        "cornerRadius": 5,
        "borderColor": {
            "main": "#9B9B9B",
            "dark": "#DDDDDD"
        },
        "borderWidth": 1.5,
        "category": "magenta"
    },
    "assistantErrorBubbleStyle":{
        "backgroundColor": {
            "main": "#9B9B9B",
            "dark": "#9B9B9B"
        },
        "flagColor": {
            "main": "#00A1DE",
            "dark": "#E20074"
        },
        "textColor": {
            "main": "#FFFFFF",
            "dark": "#FFFFFF"
        },
        "typingTextColor": {
            "main": "#7ecbf5ff",
            "dark": "#FFFFFF"
        },
        "contentInset": [12,16,12,16],
        "cornerRadius": 5,
        "borderColor": {
            "main": "#00A1DE",
            "dark": "#E20074"
        },
        "borderWidth": 1.5,
        "category": "magenta"
    }
```
To set your bubble of the "Contextual Recommendation" feature appearance in configuration file, you must set the Contextual Recommendation specific parameters up
```json
"recoBubbleStyle":{
        "backgroundColor": {
            "main": "#bee5fa",
            "dark": "#bee5fa"
        },
        "flagColor": {
            "main": "#bee5fa",
            "dark": "#bee5fa"
        },
        "textColor": {
            "main": "#262626",
            "dark": "#262626"
        },
        "typingTextColor": {
            "main": "#7ecbf5ff",
            "dark": "#FFFFFF"
        },
        "contentInset": [12,16,12,16],
        "cornerRadius": 5,
        "borderColor": {
            "main": "#bee5fa",
            "dark": "#bee5fa"
        },
        "borderWidth": 1.5,
        "category": "magenta"
    }
```

#### Font

In code             
Please use `SVKFont` structure to configure your custom fonts. Font is not mandatory for SVK functionality. But if there is no custom set up for `SVKFont`, system bold font size 15 will be used, e.g. `.boldSystemFont(ofSize: 15)`
There are a couple of ways to initialize SVKFont:
-	You can use just a UIFont 


```swift
SVKFont(with: UIFont.boldSystemFont(ofSize: 15))
```

-	With name and size

```swift
SVKFont(name: "systembold", size: 15.0)
```
Or even
```swift
SVKFont(name: " TeleNeoOffice-Regular ", size: 18)

```
In json:
```json
"font": {
        "name":"TeleNeoOffice-Regular",
        "size": 15.0
    }
```
#### Card
In code             
In order to configure the card look and feel, there is `SVKCardAppearance`.             
`SVKCardAppearance` accommodates the background color, the texts color, the supplementary text color, border color adjustments and corner radius for all four corners. 
`SVKCardAppearance` supplied with convenience initializer. All paramerters are set to Djingo style card.
```swift
…
let djingoCardStyle = SVKCardAppearance (backgroundColor: SVKColor = SVKColor(main: UIColor(white: 1, alpha: 1), dark: .black),
                textColor: SVKColor = SVKColor(main: .black, dark: .whiteTwo),
                supplementaryTextColor: SVKColor = SVKColor(main: .greyishBrown, dark: .elegantGray),
         cornerRadius: CGFloat = 18,
         borderColor: SVKColor = SVKColor(main: .greyishBrown, dark: .whiteTwo)

svkAppearance.cardStyle = djingoCardStyle
```

in JSON file.           
Please, notice that all parameters are required in JSON file.

```json
"cardStyle":{
        "backgroundColor": {
            "main": "#FFFFFF",
            "dark": "#303030"
        },
        "textColor": {
            "main": "#7f7f7fff",
            "dark": "#FFFFFF"
        },
        "supplementaryTextColor": {
            "main": "#7f7f7fff",
            "dark": "#FFFFFF"
        },
        "cornerRadius": 8,
        "borderColor": {
            "main": "#00000000",
            "dark": "#00000000"
        }
    }

```
#### SVK appearance: Custom PDF images.

SVK provides a convenient way to supply custom images to your project. These images must be in vector format (PDF). 

Here is the list of supported elements to be customized:
- radio buttons
	- **on** state: use `radioButtonActiveImageName`
	- **off** state: use `radioButtonInactiveImageName`
- check box buttons
	- **on** state: use `checkBoxActiveImageName`
	- **off** state: use `checkBoxInactiveImageName`
- Audio Recorder component
	- **enabled** state: `audioRecordingActiveImageName`
	- **disabled** state: `audioRecordingInactiveImageName`
	- mic size size: `audioRecordingImageSideSize`
- Swipe over bubble
	- copy : `swipeCopyImageName`
	- share : `swipeShareImageName`
	- play : `swipePlayImageName`
	- delete : `swipeDeleteImageName`
	- misunderstood : `swipeMisunderstoodImageName`
- Long press on bubble images
	- copy : `lpCopyImageName`
	- share : `lpShareImageName`
	- play : `lpPlayImageName`
	- delete : `lpDeleteImageName`
	- misunderstood : `lpMisunderstoodImageName`
- **flag** : `flagImageName`
- **speakingAnimation** : use list of images to animate.

All these parameters are optional and not mandatory. They can be set either in-code configuration using the SVK appearance structure or via JSON configuration file. If you decide not to provide any image for some listed elements, the SVK will use a default asset for these resources. If the host app supports dark mode and there is no image provided for the dark mode, SVK will reuse the light mode’s image.

All used assets must have PDF file extension or they will be ignored.
To add a PDF image to your project, select the right place in the "Project navigator", then tap on "Add Files to ..." in "File" or just press `"⌥⌘A"`, select "Copy items if needed" and choose required target(s). You can then customize images in `"SVKAppearance"`.
##### In code configuration
Let's look at the example when you want to add a custom activated checkbox image and set audio recorder component to 80 by 80 pixels.
```swift
		var djingoAssets = SVKImageProvider()
        djingoAssets.audioRecordingImageSideSize = 80
        let checkbox = SVKImageDescription(main: "DJCheckboxON", dark: "DJCheckboxON_dark")
        djingoAssets.checkBoxOn = checkbox
        svkAppearance.assets = djingoAssets
```
##### In JSON configuration

```json
"assets": {
        "radioButtonActive": {
            "main": "DTRadiobuttonActive"
        },
        "radioButtonInactive": {
            "main": "DTRadiobuttonInactive"
        },
        "checkBoxActive": {
            "main": "DTCheckBoxActive"
        },
        "checkBoxInactive": {
            "main": "DTCheckBoxInactive"
        },
        "longPressCopy": {
            "main": "DTKopierenLP_dark",
            "dark": "DTKopierenLP_dark"
        },
        "longPressShare": {
            "main": "DTTeilenLP_dark",
            "dark": "DTTeilenLP_dark"
        },
        "longPressPlay": {
            "main":"DTAbspielenLP_dark",
            "dark": "DTAbspielenLP_dark"
        },
        "longPressDelete": {
            "main": "DTLoschenLP_dark",
            "dark": "DTLoschenLP_dark"
        },
        "longPressResend": {
            "main": "DTResend_dark",
            "dark": "DTResend_dark"
        },
        "longPressMisunderstood": {
            "main": "DTMissverstandenLP_dark",
            "dark": "DTMissverstandenLP_dark"
        },
        "swipeCopy": {
            "main": "DTCopySwipe"
        },
        "swipeShare": {
            "main": "DTShareSwipe"
        },
        "swipePlay": {
            "main": "DTPlaySwipe"
        },
        "swipeDelete": {
            "main": "DTBinSwipe"
        },
        "swipeMisunderstood": {
            "main": "DTLightningSwipe"
        },
        "flag": {
            "main": "DTFlag"
        },
        "audioRecActive": {
            "main": "DTMicActive",
            "dark": "DTMicActive_dark"
        },
        "audioRecInactive": {
            "main": "DTMicInactive",
            "dark": "DTMicInactive_dark"
        },
        "speakingAnimation": [
            {
                "main": "DTSpeakingAnim0",
                "dark": "DTSpeakingAnim_dark0"
            },
            {
                "main": "DTSpeakingAnim1",
                "dark": "DTSpeakingAnim_dark1"
            },
            {
                "main": "DTSpeakingAnim2",
                "dark": "DTSpeakingAnim_dark2"
            }
        ],
        "audioRecHighlighted": {
            "main": "DTMicHightlighted",
            "dark": "DTMicHightlighted_dark"
        },
        "audioRecSideSize": 200,

        "emptyPage": {
            "main": "DTEmpty",
            "dark": "DTEmpty_dark"
        },
        "networkError": {
            "main": "DTEmpty_network",
            "dark": "DTEmpty_network"
        },
        "tableCellActionIcon": {
            "main": "DTChevronDown"
        },        
        "feedbackPage": {
            "main": "DTConsent",
            "dark": "DTConsent-dark"
        },
        "deleteAllPage" : {
            "main": "DTAlert"
        },
        "filterDropDown": {
            "main": "DTDropDown",
            "dark": "DTDropDown-dark"
        },
        "filterClose": {
            "main": "DTClose",
            "dark": "DTClose-dark"
        }
    }
```

#### SVK appearance: features actions

SVK provides a convenient way to define the features list displayed on the long tap action or with the swipe action.

##### In code configuration
```swift
SVKAppearanceBox.shared.appearance.features.actions.useShare = true
SVKAppearanceBox.shared.appearance.features.actions.usePlay = true
SVKAppearanceBox.shared.appearance.features.actions.useDelete = true
SVKAppearanceBox.shared.appearance.features.actions.useMisunderstood = true
SVKAppearanceBox.shared.appearance.features.actions.useResend = true

```
##### In JSON configuration

```json
{
    ...
    "features": {
        "actions": {
            "useShare": true,
            "usePlay": true,
            "useDelete": true,
            "useMisunderstood": true,
            "useResend": true
        }
    },
    ...
}
```

### Setting up your app Info.plist

#### Configure and handle specifics deeplinks for your app

create the specific SmartVoiceKit key in the info.plist file and add the SVKTrustBadgeDeeplink key to it.

| NAME  		 | TYPE 			| VALUES     | DESCRIPTION |
| :---        |    :----:  	| :--- 	| :--- |
| SVKTrustBadgeDeeplink | String| ex: your-app-scheme://trustbadge | The deeplink the SDK will use to open the page TrustBadge of your app. If this key isn't present the user will not be proposed to go to this page.

You should have this in your info.plist
```xml
<key>SmartVoiceKit</key>
    <dict>
        <key>SVKTrustBadgeDeeplink</key>
        <string>your-app-scheme://trustbadge</string>
    </dict>
```
#### Set the visibility of the Trust badge link

You can hide or unhide the trust badge link using this boolean parameter `showTrustBadge` in `SVKAppearance`.
if there is no SVKTrustBadgeDeeplink key, the link trust badge will be hidden.

### Adopting SDK protocols

In order to manage authentication, token renew, data transformation, the SDK delegates backend calls to the hosting app through the protocol **SVKConversationProtocol**.

If the hosting app uses the conversation it must implement **SVKConversationProtocol**.
If the hosting app uses the history it must implement **SVKHistoryDataSoureProtocol**.
If the hosting app want to listen the scroll state of Converstation or History, it must implement **SVKHistoryProtocol**.
If the hosting app uses the audio Recorder Button it must implement **SVKAudioRecorderDelegate**.
If the hosting app uses the consentPage it must implement **SVKGDPRProtocol, SVKConversationProtocol, SVKUserProtocol**.


**The SmartVoiceKit Protocols provide us default implementation for CVI access. You can override them if need**

#### How it works
From the conversation :

- 1. The conversation delegate receives a response (**SVKInvokeResult**) from the CVI 
- 2. If the response contains a card id, it makes a request to fetch this card and receives a **SVKCard**
- 3. The delegate notifies the SDK through its delegate, **SVKConversationViewControllerDelegate**

The hosting app should implement the following protocol : **SVKConversationProtocol**

```swift
public protocol SVKConversationProtocol {
    
    var secureTokenDelegate: SVKSecureTokenDelegate { get }
    
    /// Implement this dynamic property to provide a title to the view controller
    var title: String { get }
    
    /// The conversation view controller delegate
    var delegate: SVKConversationViewControllerDelegate? { set get }
    
    /**
     Sends a text to Djingo - default implementation is provided by SmartVoiceKit, you can override them if need
     - parameter text: the text to send
     - parameter sessionId: The id of the session that identify a ping-pong conversation or nil
     */
    func sendText(_ text: String, with sessionId: String?)
    
    /**
     Vocalize a text - default implementation is provided by SmartVoiceKit, you can override them if need
     
     After the text has been vocalized if the completion handler is nil,
     the function **SVKConversationViewControllerDelegate.didVocalizeText(_: String, stream: Data)**
     of the delegate is called
     
     - parameter text: The text to be localized
     - parameter completionHandler: The completion handler.
     */
    func vocalizeText(_ text: String, completionHandler: ((Data?) -> Void)?)
    
    /**
     returns the cell idendifier for a SVKAssistantBubbleDescription - default implementation is provided by SmartVoiceKit, you can override them if need
     */
    func cellIdentifier(for description: SVKAssistantBubbleDescription) -> String?

    /**
    returns the Skills Catalog from the cvi - default implementation is provided by SmartVoiceKit, you can override them if need
    */
    func getCatalog(completionHandler: ((SVKSkillsCatalog?) -> Void)?)
    
    /// Tells the delegate when the user finishes scrolling the content.
    /// - Parameters:
    ///   - scrollView: The scroll-view object where the user ended the touch..
    ///   - velocity: The velocity of the scroll view (in points) at the moment the touch was released.
    ///   - targetContentOffset: The expected offset when the scrolling action decelerates to a stop.
    func conversationScrollViewWillEndDragging(_ scrollView: UIScrollView,
                                               withVelocity velocity: CGPoint,
                                               targetContentOffset: UnsafeMutablePointer<CGPoint>)

    /// Tells the delegate when the scroll view is about to start scrolling the content.
    /// - Parameter scrollView: The scroll-view object that is about to scroll the content view.
    func conversationScrollViewWillBeginDragging(_ scrollView: UIScrollView)

    /// Tells the delegate when the user scrolls the content view within the receiver.
    /// - Parameter scrollView: The scroll-view object in which the scrolling occurred.
    func conversationScrollViewDidScroll(_ scrollView: UIScrollView)
    
    /// Tells the delegate that the url should be open by the Application. The application can decide to open the url or let the SDK do it. Deepkins must be processed by the application.
    func open(url: String, bubbleDescription: SVKAssistantBubbleDescription?) -> SVKOpenUrlResult
}

```
##### Invoking the CVI, get and transform the result

```swift
 func sendText(_ text: String, with sessionId: String?)
```
 
 The hosting app should implement the following protocol : **SVKSpeechProtocol**

```swift
public typealias SVKInvokeResultCardHandler = (SVKInvokeResult, SVKCard?)->Void

public protocol SVKSpeechProtocol {

    var secureTokenDelegate: SVKSecureTokenDelegate { get }
    
    /**
     return a card for the identifier reponse.cardId - default implementation is provided by SmartVoiceKit, you can override them if need
     - parameter response: the SVKInvokeResult get from the STT webSocket
     - parameter completionHandler: the callback to provide the card and the InvokeResult or a new InvokeResult which has been rewritten
     */
    func translateCard(_ response: SVKInvokeResult, completionHandler: SVKInvokeResultCardHandler?)
    
    /**
     return the codec to be used - default implementation is provided by SmartVoiceKit, you can override them if need
     - parameter completionHandler: the callback to provide the codec
     */
    func supportedCodecFormat(completionHandler: ((String?) -> Void)?)
}
```
**the translateCard allows you to retrieve the card and allows you to rewrite the invokeResult from the cvi via the websocket.**


From the history:

- 1. The history delegate receives a response (**SVKHistoryEntries**) from the CVI 
- 2. Each entry of the received history already has the content of cards when present. So just pass the response to the SDK as the result of the function : ```loadHistoryEntries(from date: Date, direction: FetchDirection, numberOfMessages: Int,suppressError: Bool, deviceSerialNumber: String?, completionHandler: @escaping (SVKHistoryEntries?, String?) -> Void)```

The hosting app should implement the following item of the protocol : **SVKHistoryDataSoureProtocol**

```swift
public protocol SVKHistoryDataSoureProtocol: SVKDeleteHistoryProtocol {
    
    var secureTokenDelegate: SVKSecureTokenDelegate { get }
    
    /// Load messages from the history - default implementation is provided by SmartVoiceKit, you can override them if need
    func loadHistoryEntries(from date: Date, direction: FetchDirection, numberOfMessages: Int,suppressError: Bool, deviceSerialNumber: String?, completionHandler: @escaping (SVKHistoryEntries?, String?) -> Void)
    
    /// Send a feedback on a history entry - default implementation is provided by SmartVoiceKit, you can override them if need
    func sendFeedback(_ feedback: SVKFeedback, on historyId: String,
                      completionHandler: @escaping (SVKHistoryEntry?) -> Void)

    /// Asks the delegate if feedbacks are authorized by the user - default implementation is provided by SmartVoiceKit, you can override them if need
    func canSendFeedback(completionHandler: @escaping (_ authorized: Bool) -> Void)

    /// Tells the delegate that the user authorize or not feedbacks - default implementation is provided by SmartVoiceKit, you can override them if need
    func authorizeFeedback(completionHandler: @escaping (_ success: Bool) -> Void)
    
    /// Ask the delegate for the serial number device list - default implementation is provided by SmartVoiceKit, you can override them if need
    func getDeviceList(completionHandler: @escaping ([String]) -> Void)
    
    /// Ask the delegate for the device metadata - default implementation is provided by SmartVoiceKit, you can override them if need
    func getDeviceMetadata(from serialNumber: String, completionHandler: @escaping (SVKDeviceMetadata?) -> Void)
}

public protocol SVKDeleteHistoryProtocol {
    
    var secureTokenDelegate: SVKSecureTokenDelegate { get }

    /// Delete some history entries - default implementation is provided by SmartVoiceKit, you can override them if need
    func deleteHistoryEntries(ids: [String],completionHandler: @escaping (_ success: Bool) -> Void)
    
    /// Delete all history entries - default implementation is provided by SmartVoiceKit, you can override them if need
    @available(*,deprecated)
    func deleteAllHistoryEntries(_ completionHandler: @escaping (_ success: Bool) -> Void)
    func deleteAllHistoryEntries(SerialNumber: String?, completionHandler: @escaping (_ success: Bool) -> Void)
}
```

From the History + Scroll delegate:
- 1. This protocol combines the history and scroll behaviour
- 2. If hosting app wants to perform certian operations based on the scroll, The hosting app should implement the following item of the protocol : **SVKHistoryProtocol**

```swift

public protocol SVKHistoryProtocol: SVKHistoryDataSoureProtocol, SVKHistoryScrollViewDelegate {}

public protocol SVKHistoryDataSoureProtocol: SVKDeleteHistoryProtocol {
    
    var secureTokenDelegate: SVKSecureTokenDelegate { get }
    
    /// Load messages from the history - default implementation is provided by SmartVoiceKit, you can override them if need
    func loadHistoryEntries(from date: Date, direction: FetchDirection, numberOfMessages: Int,suppressError: Bool, deviceSerialNumber: String?, completionHandler: @escaping (SVKHistoryEntries?, String?) -> Void)
    
    /// Send a feedback on a history entry - default implementation is provided by SmartVoiceKit, you can override them if need
    func sendFeedback(_ feedback: SVKFeedback, on historyId: String,
                      completionHandler: @escaping (SVKHistoryEntry?) -> Void)

    /// Asks the delegate if feedbacks are authorized by the user - default implementation is provided by SmartVoiceKit, you can override them if need
    func canSendFeedback(completionHandler: @escaping (_ authorized: Bool) -> Void)

    /// Tells the delegate that the user authorize or not feedbacks - default implementation is provided by SmartVoiceKit, you can override them if need
    func authorizeFeedback(completionHandler: @escaping (_ success: Bool) -> Void)
    
    /// Ask the delegate for the serial number device list - default implementation is provided by SmartVoiceKit, you can override them if need
    func getDeviceList(completionHandler: @escaping ([String]) -> Void)
    
    /// Ask the delegate for the device metadata - default implementation is provided by SmartVoiceKit, you can override them if need
    func getDeviceMetadata(from serialNumber: String, completionHandler: @escaping (SVKDeviceMetadata?) -> Void)
}

public protocol SVKDeleteHistoryProtocol {
    
    var secureTokenDelegate: SVKSecureTokenDelegate { get }

    /// Delete some history entries - default implementation is provided by SmartVoiceKit, you can override them if need
    func deleteHistoryEntries(ids: [String],completionHandler: @escaping (_ success: Bool) -> Void)
    
    /// Delete all history entries - default implementation is provided by SmartVoiceKit, you can override them if need
    @available(*,deprecated)
    func deleteAllHistoryEntries(_ completionHandler: @escaping (_ success: Bool) -> Void)
    func deleteAllHistoryEntries(SerialNumber: String?, completionHandler: @escaping (_ success: Bool) -> Void)
}

public protocol SVKHistoryScrollViewDelegate {

    /// Tells the delegate when the user finishes scrolling the content.
    /// - Parameters:
    ///   - scrollView: The scroll-view object where the user ended the touch..
    ///   - velocity: The velocity of the scroll view (in points) at the moment the touch was released.
    ///   - targetContentOffset: The expected offset when the scrolling action decelerates to a stop.
    func conversationScrollViewWillEndDragging(_ scrollView: UIScrollView,
                                               withVelocity velocity: CGPoint,
                                               targetContentOffset: UnsafeMutablePointer<CGPoint>)

    /// Tells the delegate when the scroll view is about to start scrolling the content.
    /// - Parameter scrollView: The scroll-view object that is about to scroll the content view.
    func conversationScrollViewWillBeginDragging(_ scrollView: UIScrollView)

    /// Tells the delegate when the user scrolls the content view within the receiver.
    /// - Parameter scrollView: The scroll-view object in which the scrolling occurred.
    func conversationScrollViewDidScroll(_ scrollView: UIScrollView)
}
```


From the Audio Recorder:

- 1. The audio recorder delegate receives a Web Socket message from the CVI 
- 2. we can get either a partial text or an invoke result

The hosting app should implement the following protocol : **SVKAudioRecorderDelegate**

```swift
public protocol SVKAudioRecorderDelegate {
    /// Called when the audio input controller did start recognition
    func didStartRecognition()

    /// Called when the audio input controller did stop recognition
    func didStopRecognition()
    
    /// Called when the autio input controller did finish a transaction
    func didFinishRecognition()
        
    /// Called when a response has been received
    func didReceive(_ invokeResult: SVKInvokeResult)
    
    /// Called when a response has been received
    func didReceive(_ partialText: String)
    
}
```
The hosting app should implement the following protocol : **SVKAudioRecorderDelegate**

```swift
public protocol SVKGDPRProtocol {
    
    var secureTokenDelegate: SVKSecureTokenDelegate { get }
    
    /// Load messages from the history
    func getUserAgreements( completionHandler: @escaping (SVKUserAgreements?) -> Void)
    
    func update(tncAgreement: SVKTNCAgreement, completionHandler: @escaping (Bool) -> Void)
}
```
##### App authentication

Your application must manage the cvi token : Secure the storage of the token, provide the cvi token and provide a way to save a refreshed token. To do this, the application must implement the SVKSecureTokenDelegate protocol. The delegate is transmitted through the function configureWith. 


```swift
/**
    Delegate the storage of the token
 */
public protocol SVKSecureTokenDelegate {
    /**
    Store the token

    Ask to the delegate to store the token
    - parameter token: A string representing the token to be stored
    */
     func storeToken(_ token: String?)

    /**
     Returns the stored token or nil.
     */
    func getToken() -> String?
    
}

SVKAPIClient.configureWith(apiKey: ,
                        baseURL: ,
                        loginURL: ,
                        language: ,
                        secureTokenDelegate: ,
                        clientMetadata:)

SVKAPILoginRequest(externalToken: cooses).perform() { result in 
                                                        ...
                                                    }

```

### Start an audio session by code
if your project uses and has loaded an SVKAudioRecorderViewController or an SVKConversationViewController, you can start an audio session by sending a SVKNotificationAudioTriggerAssistant notification.

```swift
NotificationCenter.default.post(name: SVKNotificationAudioTriggerAssistant, object: nil)
```

### Stop an audio session by code when app state is in background
if your project uses and has loaded an SVKAudioRecorderViewController or an SVKConversationViewController, you can stop an audio session by sending a SVKKitNotificationStateBackground notification.

```swift
NotificationCenter.default.post(name: NSNotification.Name("SVKKitNotificationStateBackground"), object: nil)
```

### Get the audio level from a audio session
To get the sound level of an audio session, it is necessary to implement the SVKAudioLevelDelegate and record this observer at the SVKAudioLevel class level. The getAudio method will be called at each change.
Each observer must have a unique haskKey value.

```swift
public protocol SVKAudioLevelDelegate {
    // notifies the end of the audio session
    func onFinished()
    // returns the sound level
    func getAudio(level: Float)
    // The HashKey allows to identify the observer, if we add a new observer with the same key it will be replaced by the new one.
    func getHashKey() -> String
}

// register the observer
public class MyAudioLevelObserver: SVKAudioLevelDelegate {
    ...
}
var observer = MyAudioLevelObserver()
SVKAudioLevel.shared.addObserver(observer)

// remove the observer
SVKAudioLevel.shared.removeObserver(observer)
```

By default, SVKConversationViewController can receive a notification and SVKAudioRecorderViewController cannot.
isMainNotificationAudioTriggerAssistantReceiver is used to configure the ability to receive notification for each component. Be careful, only one component must be able to receive a notification.


### App tracking
In order to track the reuqest, SVK adds the header "X-Touchpoint-Id" with value unique id to each request. This unique id is an optional parameter that can be set by the host application. If its not set by host app, SVK will generate unique id and store it. This unique id should be same for every request over the lifetime of App.


```swift
public class SVKUserIdentificationManager {
    private init() {}

    public static let shared = SVKUserIdentificationManager()

    /// Return the unique id which is used for tracking purpose
    public var uniqueID: String {
        get {
            getUniqueID()
        }
    }

    /// Stores unique id from host app
    private var _uniqueID: String?

    /// Generates unique id using the device uuidString
    /// - Returns: UUIDString
    private func generateUniqueID() -> String {
        if let uniqueDeviceId = UIDevice.current.identifierForVendor?.uuidString {
            SVKUserDefaults.store(uniqueID: uniqueDeviceId)
            return uniqueDeviceId
        } else {
            SVKLogger.fatal("ConfigureWith uniqueDeviceId can't be set")
            let defaultID = "i-SVK-000000000000000"
            SVKUserDefaults.store(uniqueID: defaultID)
            return defaultID
        }
    }

    /// Sets the unique id provided by host app
    /// - Parameter uniqueID: This should be unique between the sessions
    public func set(uniqueID: String) {
        _uniqueID = uniqueID
    }

    /// returns unique id provided by host app otherwise SVK generate new one and store it.
    ///  same unique id is used for all the session.
    /// - Returns: Unique id
    private func getUniqueID() -> String {
        if let id = _uniqueID {
            return id
        } else if let id = SVKUserDefaults.getUniqueID() {
            return id
        } else {
           return generateUniqueID()
        }
    }
}
```

## Sample Code
The [SVPocket project](https://github.com/vpaas-sdks/ios-SmartVoiceKit/tree/master/sampleCode) is the reference project for using the SDK.

samples codes :
- djingo Navigation Controller => [DjingoNavigationController.swift](https://github.com/vpaas-sdks/ios-SmartVoiceKit/tree/master/sampleCode/Conversation/SVPocket/DjingoNavigationController.swift)
- setting the UI apparence, the SmartvoiceSDK and how to perform a cvi login => [AppDelegate.swift](https://github.com/vpaas-sdks/ios-SmartVoiceKit/tree/master/sampleCode/SVPocket/AppDelegate.swift)
- SVKConversationProtocol implementation => [ConversationController.swif](https://github.com/vpaas-sdks/ios-SmartVoiceKit/tree/master/sampleCode/SVPocket/Conversation/ConverstionController.swift)
- SVKUserProtocol implementation => [UserController.swift](https://github.com/vpaas-sdks/ios-SmartVoiceKit/tree/master/sampleCode/SVPocket/Conversation/UserController.swift)
- SVKHistoryProtocol implementation => [HistoryController](https://github.com/vpaas-sdks/ios-SmartVoiceKit/tree/master/sampleCode/SVPocket/Conversation/HistoryController.swift)
- SVKAudioRecorderDelegate implementation and AudoRecorder integration => [AudioRecorderViewController](https://github.com/vpaas-sdks/ios-SmartVoiceKit/tree/master/sampleCode//SVPocket/AudioRecorder/AudioRecorderViewController.swift)
- a page for agreement management, history and user account deletion => [DataTableViewController.swif](https://github.com/vpaas-sdks/ios-SmartVoiceKit/tree/master/sampleCode/SVPocket/Settings/Data/DataTableViewController.swift)
## Documentation
This file : https://github.com/vpaas-sdks/ios-SmartVoiceKit/tree/master/README.md
The [backlog]() is hosted on gard.

## Changelog
See [Changelog]( https://github.com/vpaas-sdks/ios-SmartVoiceKit/tree/master/Changelog)

## 3rd Party libraries dependencies
- [daltoniam/Starscream 3.1.1](https://github.com/daltoniam/Starscream) : Starscream is a conforming WebSocket (RFC 6455) library in Swift. Starscream is licensed under the Apache v2 License.
- [onevcat/Kingfisher 6.3.0](https://github.com/onevcat/Kingfisher) : Kingfisher is a powerful, pure-Swift library for downloading and caching images from the web.Kingfisher is released under the MIT license.

## Contacts
- Devs
[Rutvik Kanbargi,](rutvik.kanbargi@t-systems.com)
[Nikhil Aggarwal,](Nikhil.aggarwal@t-systems.com)
[Kirill Simagin,](mailto:kirill.simagin@orange.com)
[Stephen Roze](mailto:stephen.roze@orange.com)
- PO 
[Benoit Suzanne](mailto:benoit.suzanne@orange.com)
