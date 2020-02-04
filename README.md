# BandSite

0.0.38

## Swift Package to Scan and Analyze Music Files

I use it selfishly for apps in the bands I play with and also for using Publish to make static websites for the bands. It is, however, reasonably general purpose.

```swift

let bandfacts = BandInfo ( 
crawlTags: ["china" ,"elizabeth" ,"whipping" ,"one more" ,"riders" ,"light"],
pathToContentDir: dirpath + "/Content",
pathToOutputDir: dirpath + "/Resources/BigData",
matchingURLPrefix:  "https://billdonner.com/halfdead" ,
specialFolderPaths: ["/audiosessions","/favorites"],
language: "EN",
url: "http://abouthalfdead.com",
name: "About Half Dead ",
shortname: "ABHD",
description:"A Jamband Featuring Doors, Dead, ABB Long Form Performances",
resourcePaths:   ["Resources/HdTheme/hdstyles.css"],
imagePath:  "images/ABHDLogo.png" ,
favicon:  "images/favicon.png")


let status = generateBandSite(bandinfo:bandfacts,
                         rewriter:command_rewriter,
                         lgFuncs: LgFuncs(),
                         logLevel: .verbose)

```











