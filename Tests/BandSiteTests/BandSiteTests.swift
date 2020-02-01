import XCTest
import Plot
import Publish
@testable import BandSite

final class BandSiteTests: XCTestCase {
    
let dirpath = "/Users/williamdonner/hd"

func command_rewriter (c:String)->URL {
        let url = URL(string:"https://billdonner.com/halfdead/2019/")
          guard let nrl  = url else { print("bad url in command rewriter"); exit(0)}
          return nrl
}
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(BandSite().text, "BandSite")
    }
    func testGenerateSite() {
        
        let bandfacts = BandInfo (
        venueShort: "thorn",
        venueLong: "Highline Studios, Thornwood, NY",
        crawlTags: ["china" ,"elizabeth" ,"whipping" ,"one more" ,"riders" ,"light"],
        pathToContentDir: dirpath + "/Content",
        pathToOutputDir: dirpath + "/Resources/BigData",
        matchingURLPrefix:  "https://billdonner.com/halfdead" ,
        specialFolderPaths: ["/audiosessions","/favorites"],
        language: Language.english,
        url: "http://abouthalfdead.com",
        name: "About Half Dead ",
        shortname: "ABHD",
        description:"A Jamband Featuring Doors, Dead, ABB Long Form Performances",
        resourcePaths:   ["Resources/HdTheme/hdstyles.css"],
        imagePath:  Path("images/ABHDLogo.png") ,
        favicon:  Favicon(path: "images/favicon.png"))
        
        
        let status = generateBandSite(bandinfo:bandfacts,
                                 rewriter:command_rewriter,
                                 lgFuncs: LgFuncs(),
                                 logLevel: .verbose)

        XCTAssertEqual(status, 200)
    }
    
    func testPublishSite() {
        // this publishes a new version of the static website based on the Publish and Plot spm
        let _ =  publishBandSite() // turn it over to John Sundell
    }
    static var allTests = [
        ("testExample", testExample),
        ("testGenerateSite", testGenerateSite)
             ("testPublishSite", testPublishSite)
    ]
}
