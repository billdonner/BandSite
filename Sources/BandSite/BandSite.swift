import Foundation
import LinkGrubber
import Plot
import Publish
import HTMLExtractor
import CookieMonster

public struct BandSite {
    var text = "BandSite" // there is a test case that matches this
}
let letters = CharacterSet.letters
let digits = CharacterSet.decimalDigits


// extend the LgFuncs from Linkgrubber
public protocol FileTypeProts  {
    func isImageExtensionFunc(_ s:String) -> Bool
    func isAudioExtensionFunc(_ s:String) -> Bool
    func isMarkdownExtensionFunc(_ s:String) -> Bool
    func isNoteworthyExtensionFunc(_ s: String) -> Bool
    func isInterestingExtensionFunc (_ s:String) -> Bool
}

public typealias BandSiteProt = FileTypeProts&LgFuncProts



extension Transformer { // in LinkGrubber
    //MARK: - cleanup special folders for this site
    static func cleanOuputs(baseFolderPath:String,folderPaths:[String]) {
        do {
            // clear the output directory
            let fm = FileManager.default
            var counter = 0
            for folder in folderPaths{
                
                let dir = URL(fileURLWithPath:baseFolderPath+folder)
                
                let furls = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                for furl in furls {
                    try fm.removeItem(at: furl)
                    counter += 1
                }
            }
            print("[bandsite] Cleaned \(counter) files from ", baseFolderPath )
        }
        catch {print("[bandsite] Could not clean outputs \(error)")}
    }
}

open class BandInfo{
    public var artist : String
    public var crawlTags:[String]
    public var pathToContentDir : String
    public var pathToOutputDir: String
    public var matchingURLPrefix : String
    public var specialFolderPaths: [String]
    public var url : String
    public var name : String
    public var shortname: String
    
    public init(
        artist : String = "",
        crawlTags:[String]  = [],
        pathToContentDir : String = "",
        pathToOutputDir : String = "",
        matchingURLPrefix :String = "",
        specialFolderPaths :[String] = [],
        url : String = "",
        name : String = "",
        shortname : String = ""
    ){
        self.artist = artist
        self.crawlTags = crawlTags
        self.pathToContentDir = pathToContentDir
        self.pathToOutputDir = pathToOutputDir
        self.matchingURLPrefix = matchingURLPrefix
        self.specialFolderPaths = specialFolderPaths
        self.url = url
        self.name = name
        self.shortname = shortname 
        //
    }
}




func printUsage() {
    let processinfo = ProcessInfo()
    print(processinfo.processName)
    let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
    print("\(executableName)")
    print("usage:")
    print("\(executableName) s or m or l")
}

@discardableResult
public func generateBandSite(_ rootURL:URL, bandinfo:BandInfo ,lgFuncs:FileTypeProts&LgFuncProts, logLevel:LoggingLevel = .none) -> LinkGrubberStats {
    
    var audioCrawlStatus:LinkGrubberStats? = nil
    var audioCrawler : AudioCrawler  //let this get retained
    let start = Date() // start timing now
    
    func showCrawlStats(_ crawlResults:LinkGrubberStats,prcount:Int ) {
        // at this point we've plunked files into the designated directory
        let published_counts = crawlResults.count1 + prcount
        let elapsed = Date().timeIntervalSince(start) / Double(published_counts)
        print("[bandsite] published \(published_counts) pages,  \(String(format:"%5.2f",elapsed*1000)) ms per page")
    }
    
        let bletch = { fatalError("[bandsite] cant generate from \(rootURL)")}

        let rs = [RootStart(name: rootURL.deletingPathExtension().lastPathComponent,  url: rootURL)]
        
        print("[bandsite] crawling \(rootURL)")
        
        audioCrawler = AudioCrawler ( lgFuncs: lgFuncs,bandSiteParams: bandinfo)
        do {
            try audioCrawler.crawl(roots:rs, verbosity: logLevel) { status in
                audioCrawlStatus = status
                print("bandsiteruncrawler \(status)")
                switch     audioCrawlStatus?.status {
                case 200:  break
                default:  bletch()
                }
            }
        }
        catch {
            bletch()
        }
        // now stall until the crawl completes
        while (audioCrawlStatus==nil) { sleep(1);print("sleep...")}
        showCrawlStats(audioCrawlStatus!, prcount: 1)
        print("[bandsite] crawl complete \((audioCrawlStatus!.status == 200) ? "🤲🏻":"⛑")")
        return audioCrawlStatus!
} 


final class AudioCrawler {
    var lgFuncs: LgFuncProts
    var params: BandInfo
    
    public func crawl( roots:[RootStart],
                       verbosity: LoggingLevel,
                       finally:@escaping ReturnsGrubberStats) throws {
        
        
        // first lets have a  cleansing
        Transformer.cleanOuputs(baseFolderPath:params.pathToContentDir,folderPaths: params.specialFolderPaths)
        try  LinkGrubber().grub (roots:roots,
                                 opath:params.pathToOutputDir + "/bigdata",
                                 logLevel: verbosity,
                                 lgFuncs:lgFuncs)
        {  crawlResults  in
            //// print("BANDSITE - crawl is done")
            finally(crawlResults)
        }
        
    }
    public  init( lgFuncs:LgFuncProts, bandSiteParams params:  BandInfo ) {
        
        self.lgFuncs = lgFuncs
        self.params = params
    }//init
    
}//audiocrawler
open  class AudioHTMLSupport {
    let bandinfo: BandInfo
    let lgFuncs: FileTypeProts
    public init(bandinfo: BandInfo,lgFuncs:FileTypeProts)
    {
        self.bandinfo = bandinfo
        self.lgFuncs = lgFuncs
    }
    func topdiv(cookie:String,links:[Fav],lgFuncs:FileTypeProts)-> Node<HTML.BodyContext>  {
        let immd = AudioHTMLSupport.ImagesAndMarkdown.generateImagesAndMarkdownFromRemoteDirectoryAssets(links:links,lgFuncs:lgFuncs)
        
        return Node.div ( .div(
            .img(.src("\(immd.images[0])"), .class("img300"),
                 .alt("\(immd.markdown.prefix(50))")),
            .h4 ( .i ("\(cookie)")),
            .p("\(immd.markdown)"))
        )
    }
    struct BannerAndTags {
        let banner: String
        let tags:[String]
    }
    struct ImagesAndMarkdown {
        let images: [String]
        let markdown: String
        
        static func generateImagesAndMarkdownFromRemoteDirectoryAssets(links:[Fav],lgFuncs:FileTypeProts) -> ImagesAndMarkdown {
            var images: [String] = []
            var pmdbuf = "\n"
            for(_,alink) in links.enumerated() {
                let pext = (alink.url.components(separatedBy: ".").last ?? "fail").lowercased()
                if (pext=="md") {
                    // copy the bytes inline from remote md file
                    if let surl = URL(string:alink.url) {
                        do {
                            pmdbuf +=   try String(contentsOf: surl) + "\n\n\n"
                        }
                        catch {
                            print("[bandsite] Couldnt read bytes from \(alink.url) \(error)")
                        }
                    }
                } else
                    if lgFuncs.isImageExtensionFunc(pext) {
                        // if its an image just accumulate them in a gallery
                        images.append(alink.url)
                }
            }
            if images.count == 0  {
                images.append( "/images/abhdlogo300.png")
            }
            return ImagesAndMarkdown(images:images,markdown:pmdbuf)
        }
    }
    
    private func buildAudioBlock(idx:Int,alink:Fav)->String {
        let pext = (alink.url.components(separatedBy: ".").last ?? "fail").lowercased()
        if lgFuncs.isAudioExtensionFunc(pext){
            let div = Node.div(
                .h2("\(String(format:"%02d",idx+1))    \(alink.name)"),
                .figure(
                    .figcaption(.text(alink.comment)),
                    .audio(.controls(true), .source(.src(alink.url), .type((pext == "mp3") ? .mp3:.wav))))
            )
            return  div.render()
        }
        else {
            return    ""
        }
    }
    private func generateAudioHTMLFromRemoteDirectoryAssets(links:[Fav]) -> String {
        var outbuf = ""
        for(idx,alink) in links.enumerated() {
            outbuf += buildAudioBlock(idx: idx,alink: alink)
        }
        return outbuf
    }
    
    
    
    private func generateAudioTopMdHTML(title:String,u sourceurl:URL, venue:String,playdate:String,tags:[String] ,links:[Fav])->String {
        
        let immd = ImagesAndMarkdown.generateImagesAndMarkdownFromRemoteDirectoryAssets(links:links,lgFuncs:lgFuncs)
        
        let cookie = CookieMonster.get_fortune_cookie()
        
        // it seems essential to put the title in here instead of inside the plot Node above
        func   markdownmetadata(stuff:String)-> String {
            let ellipsis = stuff.count>500 ? "..." : ""
            return """
            ---
            sourceurl: \(sourceurl.absoluteString)
            venue: \(venue)
            description: \(cookie) \(stuff.prefix(500))\(ellipsis)
            tags: \(tags.joined(separator: ","))
            ---
            
            # \(title)
            
            
            """
        }
        
        // func topdiv(cookie:String,links:[Fav],lgFuncs:LgFuncs)-> Node<HTML.BodyContext>
        return markdownmetadata(stuff: immd.markdown) + "\(topdiv(cookie:cookie,links:links,lgFuncs:lgFuncs).render())"
    }
    
    // this variation uses venu and playdate to form a title
    public  func audioListPageMakerFunc(
        props:CustomPageProps,
        links:[Fav] ) throws {
        
        struct Shredded {
            let letters: String
            let digits:String
        }
        func yymmddFromDigits(digits:String)->String{
            let month = digits.prefix(2)
            let year = digits.suffix(2)
            let start = digits.index(digits.startIndex, offsetBy: 2)
            let end = digits.index(digits.endIndex, offsetBy: -2)
            let day = digits[start..<end]
            return String(year+month+day)
        }
        func pickapart(_ phrase:String) -> Shredded {
            
            var letterCount = 0
            var digitCount = 0
            var lets:String = ""
            var digs:String = ""
            
            for uni in phrase.unicodeScalars  {
                if letters.contains(uni) {
                    letterCount += 1
                    lets += String(uni)
                } else if digits.contains(uni) {
                    digitCount += 1
                    digs += String(uni)
                }
            }
            return Shredded(letters:lets, digits:digs)
        }
        func checkForBonusTags(name:String?)->String? {
            if let songName = name {
                let shorter = songName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                for tuneTag in  bandinfo.crawlTags {
                    if shorter.hasPrefix(tuneTag) {
                        return tuneTag
                    }
                }
            }
            return nil
        }
        
        func makeAndWriteMdFile(_ title:String, stuff:String,spec:String) throws {
            let markdownData: Data? = stuff.data(using: .utf8)
            try markdownData!.write(to:URL(fileURLWithPath:  spec,isDirectory: false))
        }
        
        var moretags:Set<String>=[]
        
        // starts here
        let fund = props.urlstr.components(separatedBy: ".").last ?? "fail"
        let shredded = pickapart(fund)
        let playdate = shredded.digits
        let venue = shredded.letters
        let ve =  venue == "" ? "<no venue>" : venue
        guard playdate != "" else {return}
        
        for link in links {
            if  let bonustag = checkForBonusTags(name: link.name )  {
                moretags.insert(bonustag)
            }
        }
        if links.count == 0 { print("[bandsite] no links for \(props.title) - check your music tree") }
        else {
            
            let x=makeBannerAndTags(aurl:props.urlstr , mode: props.isInternalPage)
            
            var spec: String
            switch  props.isInternalPage {
            case  false :
                spec =  "\(bandinfo.pathToContentDir)/audiosessions/\(ve)\(playdate).md"
            case true  :
                spec =  "\(bandinfo.pathToContentDir)/favorites/\(props.title).md"
            }
            guard let u = URL(string:props.urlstr) else { return }
            let stuff =  generateAudioMarkdownPage(x.banner,
                                                   u:u,
                                                   venue: venue ,
                                                   playdate:playdate,
                                                   tags:Array(moretags) + x.tags  + props.tags ,
                                                   links:links,
                                                   mode:props.isInternalPage)
            try makeAndWriteMdFile(props.title,  stuff: stuff, spec: spec)
        }
    }
    private func generateAudioMarkdownPage(_ title:String,u:URL,venue:String ,playdate:String,tags:[String]=[],links:[Fav]=[],
                                           mode:Bool )->String {
        var newtags = tags
        switch mode {
        case true:
            break
        case false :
            newtags.append("favorite")
        }
        
        return  generateAudioTopMdHTML(title:title,u:u,venue:venue,playdate:playdate,tags:newtags,links:links)
            + "\n\n\n\n"
            + generateAudioHTMLFromRemoteDirectoryAssets(links: links)
    }
    
    /// make some tags  and banner from the alburm name
    private func makeBannerAndTags(aurl:String,mode:Bool)->BannerAndTags {
        guard let u = URL(string:aurl) else { fatalError() }
        // take only the top two parts and use them as
        
        let parts = u.path.components(separatedBy: "/")
        var tags = [parts[1],parts[2]]
        // lets analyze parts3, if it is multispaced then lets call it a gig
        let subparts3 = parts[3].components(separatedBy: " ")
        var performanceKind = ""
        if (subparts3.count > 1) {
            performanceKind = "live"
            tags.append(subparts3[1])
        }
        else  {
            performanceKind = "rehearsal"
        }
        
        var banner:String
        switch mode {
        case true:
            // if publish is generating, then use this
            tags.append( performanceKind )
            banner = parts[2] + " \(performanceKind) " + parts[3]
            
        case false:
            
            banner =  parts[3]
        }
        
        return BannerAndTags(banner: banner , tags: tags )
    }
    
}// struct audio

