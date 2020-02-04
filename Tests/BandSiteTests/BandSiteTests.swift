import XCTest

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
    func testGenerateSiteHD2019() {
        func command_rewriter (c:String)->URL {
                let url = URL(string:"https://billdonner.com/halfdead/2019/")
                  guard let nrl  = url else { print("bad url in command rewriter"); exit(0)}
                  return nrl
        }
        let bandfacts = BandInfo (
        crawlTags: ["china" ,"elizabeth" ,"whipping" ,"one" ,"riders" ,"light","love"],
        pathToContentDir: dirpath + "/Content",
        pathToOutputDir: dirpath + "/Resources/BigData",
        matchingURLPrefix:  "https://billdonner.com/halfdead" ,
        specialFolderPaths: ["/audiosessions","/favorites"],
        url: "http://abouthalfdead.com",
        name: "About Half Dead ",
        shortname: "ABHD")
        
        
        let status = generateBandSite(bandinfo:bandfacts,
                                 rewriter:command_rewriter,
                                 lgFuncs: LgFuncs(),
                                 logLevel: .verbose)

        XCTAssertEqual(status, 200)
    }
    func testGenerateSiteTwoSite() {
        func command_rewriter (c:String)->URL {
                let url = URL(string:"https://billdonner.github.io/LinkGrubber/linkgrubberexamples/two-site/")
                  guard let nrl  = url else { print("bad url in command rewriter"); exit(0)}
                  return nrl
        }
        let bandfacts = BandInfo (
        crawlTags: ["china" ,"elizabeth" ,"whipping" ,"one more" ,"riders" ,"light"],
        pathToContentDir: dirpath + "/Content",
        pathToOutputDir: dirpath + "/Resources/BigData",
        matchingURLPrefix:  "https://billdonner.com/halfdead" ,
        specialFolderPaths: ["/audiosessions","/favorites"],
        url: "http://abouthalfdead.com",
        name: "About Half Dead ",
        shortname: "ABHD")
        
        
        let status = generateBandSite(bandinfo:bandfacts,
                                 rewriter:command_rewriter,
                                 lgFuncs: LgFuncs(),
                                 logLevel: .verbose)

        XCTAssertEqual(status, 200)
    }
    

    static var allTests = [
        ("testExample", testExample),
        ("testGenerateSiteHD2019", testGenerateSiteHD2019) ,
        ("testGenerateSiteTwoSite", testGenerateSiteTwoSite)
    ]
}
