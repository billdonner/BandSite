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
                                 lgFuncs: FileTypeFuncs(bandfacts: bandfacts),
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
                                 lgFuncs: FileTypeFuncs(bandfacts: bandfacts),
                                 logLevel: .verbose)

        XCTAssertEqual(status, 200)
    }
    

    static var allTests = [
        ("testExample", testExample),
        ("testGenerateSiteHD2019", testGenerateSiteHD2019) ,
        ("testGenerateSiteTwoSite", testGenerateSiteTwoSite)
    ]
}
