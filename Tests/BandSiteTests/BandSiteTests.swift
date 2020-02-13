import XCTest
import HTMLExtractor
import LinkGrubber

@testable import BandSite

final class BandSiteTests: XCTestCase {
    

    struct  FileTypeFuncs:BandSiteProt {
        var bandfacts:BandInfo
        
        public init( bandfacts:BandInfo) { self.bandfacts = bandfacts }
        
        
        public func pageMakerFunc(_ props: CustomPageProps, _ links: [Fav]) throws {
           let _    = try AudioHTMLSupport(bandinfo: bandfacts,
                                       lgFuncs: self ).audioListPageMakerFunc(props: props, links: links)
        }
        
        public func matchingFunc(_ u: URL) -> Bool {
            return  u.absoluteString.hasPrefix(bandfacts.matchingURLPrefix)
        }
        
        public func scrapeAndAbsorbFunc ( theURL:URL, html:String ) throws ->  ScrapeAndAbsorbBlock {
            let x   = HTMLExtractor.extractFrom (  html:html )
            return HTMLExtractor.converttoScrapeAndAbsorbBlock(x,relativeTo:theURL)
        }

        public func isImageExtensionFunc (_ s:String) -> Bool {
             ["jpg","jpeg","png"].includes(s)
         }

        public func isAudioExtensionFunc(_ s:String) -> Bool {
            ["mp3","mpeg","wav"].includes(s)
        }
        public func isMarkdownExtensionFunc(_ s:String) -> Bool{
            ["md", "markdown", "txt", "text"].includes(s)
        }
        public func isNoteworthyExtensionFunc(_ s: String) -> Bool {
            isImageExtensionFunc(s) || isMarkdownExtensionFunc(s)
        }
       public  func isInterestingExtensionFunc (_ s:String) -> Bool {
            isImageExtensionFunc(s) || isAudioExtensionFunc(s)
        }
    }

    
let dirpath = "/Users/williamdonner/hd"

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(BandSite().text, "BandSite")
    }
    
    func testGenerateSiteHD2019() {
 
        let bandfacts = BandInfo (
        crawlTags: ["china" ,"elizabeth" ,"whipping" ,"one" ,"riders" ,"light","love"],
        pathToContentDir: dirpath + "/Content",
        pathToOutputDir: dirpath + "/Resources/BigData",
        matchingURLPrefix:  "https://billdonner.com/halfdead" ,
        specialFolderPaths: ["/audiosessions","/favorites"],
        url: "http://abouthalfdead.com",
        name: "About Half Dead ",
        shortname: "ABHD")
        
        
        let status = generateBandSite(URL(string:"https://billdonner.com/halfdead/2019/")!,
                                 bandinfo:bandfacts,
                                 lgFuncs: FileTypeFuncs(bandfacts: bandfacts),
                                 logLevel: .verbose)

        XCTAssertEqual(status.status,200)
    }
    
    func testGenerateSiteTwoSite() {

        
        let bandfacts = BandInfo (
        crawlTags: ["china" ,"elizabeth" ,"whipping" ,"one more" ,"riders" ,"light"],
        pathToContentDir: dirpath + "/Content",
        pathToOutputDir: dirpath + "/Resources/BigData",
        matchingURLPrefix:  "https://billdonner.com/halfdead" ,
        specialFolderPaths: ["/audiosessions","/favorites"],
        url: "http://abouthalfdead.com",
        name: "About Half Dead ",
        shortname: "ABHD")
        let status = generateBandSite(URL(string:"https://billdonner.github.io/LinkGrubber/linkgrubberexamples/two-site/")!,
                                      bandinfo:bandfacts,
                                 lgFuncs: FileTypeFuncs(bandfacts: bandfacts),
                                 logLevel: .verbose)

        XCTAssertEqual(status.status, 200)
    }
    

    static var allTests = [
        ("testExample", testExample),
        ("testGenerateSiteHD2019", testGenerateSiteHD2019) ,
        ("testGenerateSiteTwoSite", testGenerateSiteTwoSite)
    ]
}
