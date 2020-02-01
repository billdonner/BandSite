import Foundation
import LinkGrubber
import Kanna 
import Plot
import Publish 

public struct BandSite {
    var text = "BandSite" // there is a test case that matches this
}

extension Array where Element == String  {
func includes(_ f:Element)->Bool {
    self.firstIndex(of: f) != nil
    }
}


// these functions must be supplied by the caller of LinkGrubber.grub()
func scraperReturnsNothing (_  lgFuncs:LgFuncs,url: URL, s: String ) throws -> ScrapeAndAbsorbBlock {
    print("[LinkGrubber] scraping \(url)")
    return ScrapeAndAbsorbBlock(title: "scraperReturnsNothing",links: [])
}

//  we'll use kanna

func kannaScrapeAndAbsorb (lgFuncs:LgFuncs,theURL:URL, html:String ) throws -> ScrapeAndAbsorbBlock {
    func absorbLink(href:String? , txt:String? ,relativeTo: URL?, tag: String, links: inout [LinkElement]) {
        if let lk = href, //link["href"] ,
            let url = URL(string:lk,relativeTo:relativeTo) ,
            let linktype = processExtension(lgFuncs: lgFuncs, url:url, relativeTo: relativeTo) {
            
            // strip exension if any off the title
            let parts = (txt ?? "fail").components(separatedBy: ".")
            if let ext  = parts.last,  let front = parts.first , ext.count > 0
            {
                let subparts = front.components(separatedBy: "-")
                if let titl = subparts.last {
                    let titw =  titl.trimmingCharacters(in: .whitespacesAndNewlines)
                    links.append(LinkElement(title:titw,href:url.absoluteString,linktype:linktype, relativeTo: relativeTo))
                }
            } else {
                // this is what happens upstream
                if  let txt  = txt  {
                    links.append(LinkElement(title:txt,href:url.absoluteString,linktype:linktype, relativeTo: relativeTo))
                }
            }
        }
    }// end of absorbLink
    let doc = try  Kanna.HTML(html: html, encoding: .utf8)
    let title = doc.title ?? "<untitled>"
    var absorbedlinks:[LinkElement] = []
    for link in doc.xpath("//a") {
        absorbLink(href:link["href"],
                   txt:link.text,
                   relativeTo:theURL,
                   tag: "media",links:&absorbedlinks )
    }
    return ScrapeAndAbsorbBlock(title:  title, links:absorbedlinks)
}

public struct LgFuncs: LgFuncProts {
    
    public init () {} // needed to allow instantiation from "main"
    
    public func scrapeAndAbsorbFunc ( theURL:URL, html:String ) throws -> ScrapeAndAbsorbBlock {
        try  kannaScrapeAndAbsorb ( lgFuncs: self,theURL:theURL, html:html )
    }
    public func pageMakerFunc(_ props:CustomPageProps,  _ links: [Fav] ) throws -> () {
       // print ("MAKING PAGE with props \(props) linkscount: \(links)")
    }
    public func matchingFunc(_ u: URL) -> Bool {
        return  true//u.absoluteString.hasPrefix("https://billdonner.github.io/LinkGrubber/")
    }
    public func isImageExtensionFunc (_ s:String) -> Bool {
        ["jpg","jpeg","png"].includes(s)
    }
    public   func isAudioExtensionFunc(_ s:String) -> Bool {
        ["mp3","mpeg","wav"].includes(s)
    }
   public    func isMarkdownExtensionFunc(_ s:String) -> Bool{
        ["md", "markdown", "txt", "text"].includes(s)
    }
    
    public func isNoteworthyExtensionFunc(_ s: String) -> Bool {
        isImageExtensionFunc(s) || isMarkdownExtensionFunc(s)
    }
    public func isInterestingExtensionFunc (_ s:String) -> Bool {
        isImageExtensionFunc(s) || isAudioExtensionFunc(s)
    }
}

let letters = CharacterSet.letters
let digits = CharacterSet.decimalDigits


fileprivate extension SortOrder {
    func makeASorter<T, V: Comparable>(
        forKeyPath keyPath: KeyPath<T, V>
    ) -> (T, T) -> Bool {
        switch self {
        case .ascending:
            return {
                $0[keyPath: keyPath] < $1[keyPath: keyPath]
            }
        case .descending:
            return {
                $0[keyPath: keyPath] > $1[keyPath: keyPath]
            }
        }
    }
}
extension PublishingContext  {
    /// Return someitems within this website, sorted by a given key path.
    ///  - parameter max: Max Number of items to return
    /// - parameter sortingKeyPath: The key path to sort the items by.
    /// - parameter order: The order to use when sorting the items.
    
    
   public func someItems<T: Comparable>(max:Int,
                                  sortedBy sortingKeyPath: KeyPath<Item<Site>, T>,
                                  order: SortOrder = .ascending
    ) -> [Item<Site>] {
        let items = sections.flatMap { $0.items }
        let x = items.sorted(
            by: order.makeASorter(forKeyPath: sortingKeyPath))
        return x.dropLast((x.count-max)>0 ? x.count-max : 0)
    }
}


extension Transformer { 
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
    public var venueShort : String
    public var venueLong : String
    public var crawlTags:[String]
    public var pathToContentDir : String
    public var pathToOutputDir: String
    public var matchingURLPrefix : String
    public var specialFolderPaths: [String]
    public var language : Language
    public var url : String
    public var name : String
    public var shortname: String
    public var resourcePaths:Set<Path>
    public var description : String
    public var imagePath : Path?
    public var favicon: Favicon?
    
    public init(
        artist : String = "",
        venueShort : String = "",
        venueLong : String  = "",
        crawlTags:[String]  = [],
        pathToContentDir : String = "",
        pathToOutputDir : String = "",
        matchingURLPrefix :String = "",
        specialFolderPaths :[String] = [],
        language : Language = .english,
        url : String = "",
        name : String = "",
        shortname : String = "",
        description : String = "",
        resourcePaths: Set<Path> = [],
        imagePath : Path? = nil,
        favicon:Favicon? = nil
    ){
        self.artist = artist
        self.venueShort = venueShort
        self.venueLong = venueLong
        self.crawlTags = crawlTags
        self.pathToContentDir = pathToContentDir
        self.pathToOutputDir = pathToOutputDir
        self.matchingURLPrefix = matchingURLPrefix
        self.specialFolderPaths = specialFolderPaths
        self.language = language
        self.url = url
        self.name = name
        self.shortname = shortname
        self.resourcePaths = resourcePaths
        self.description = description
        self.imagePath = imagePath
        self.favicon = favicon
        //
    }
}


@discardableResult
public func generateBandSite(bandinfo:BandInfo ,rewriter:((String)->URL),lgFuncs:LgFuncs, logLevel:LoggingLevel = .none) -> Int {
func showCrawlStats(_ crawlResults:LinkGrubberStats,prcount:Int ) {
    // at this point we've plunked files into the designated directory
    let start = Date()
    let published_counts = crawlResults.count1 + prcount
    let elapsed = Date().timeIntervalSince(start) / Double(published_counts)
    print("[bandsite] published \(published_counts) pages,  \(String(format:"%5.2f",elapsed*1000)) ms per page")
}
    
    func printUsage() {
        let processinfo = ProcessInfo()
        print(processinfo.processName)
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
        print("\(executableName)")
        print("usage:")
        print("\(executableName) s or m or l")
    }
    
    
    func bandSiteRunCrawler (_ roots:[RootStart],lgFuncs:LgFuncs,finally:@escaping (Int)->()) {
        
        let pmf = AudioHTMLSupport(bandinfo: bandinfo,
                                   lgFuncs: lgFuncs ).audioListPageMakerFunc
        
        let _ = AudioCrawler(roots:roots,
                             verbosity: logLevel,
                             lgFuncs: lgFuncs,
                             pageMaker: pmf,
                           //  prepublishCount: bandinfo.allFavorites.count ,
                             //
        bandSiteParams: bandinfo) { status in // just runs
            finally(status)
        }
    }
    
    
    // the main generateBandSite starts right here really starts here
    var command_status =  0
    
    do {
        let bletch = { print("[bandsite] bad command \(CommandLine.arguments)"  )
            printUsage()
            return
        }
        guard CommandLine.arguments.count > 1 else  { bletch(); exit(0)  }
        let arg1 =  CommandLine.arguments[1].lowercased()
        let incoming = String(arg1.first ?? "X")
        let rooturl = rewriter(incoming)
        let rs = [RootStart(name: incoming, url: rooturl)]
    
        print("[bandsite] crawling \(rooturl)")
        let crawler = bandSiteRunCrawler
        
        var done = false
        crawler(rs, lgFuncs, { status in
            command_status = status
            switch     command_status {
            case 200:
                break
            default:  bletch(); exit(0) 
            }
            done=true
        })
        while (done==false) { sleep(1);}
        print("[bandsite] crawl complete \((command_status == 200) ? "🤲🏻":"⛑")")

        return command_status
    }
} 

extension Node where Context: HTML.BodyContext {
    /// Add a `<figure>` HTML element within the current context.
    /// - parameter nodes: The element's attributes and child elements.
    static func figure(_ nodes: Node<HTML.BodyContext>...) -> Node {
        .element(named: "figure", nodes: nodes)
    }
    /// Add a `<figcaption>` HTML element within the current context.
    /// - parameter nodes: The element's attributes and child elements.
    static func figcaption(_ nodes: Node<HTML.BodyContext>...) -> Node {
        .element(named: "figcaption", nodes: nodes)
    }
}
final class AudioCrawler {
    
    var lgFuncs: LgFuncs
    
    public  init( roots:[RootStart],
                  verbosity: LoggingLevel,
                  lgFuncs:LgFuncs,
                  pageMaker pmf: @escaping PageMakerFunc,
                 // prepublishCount: Int,
                  bandSiteParams params:  BandInfo,
                  finally:@escaping (Int) -> ()) {
      
        self.lgFuncs = lgFuncs

        do {

// first lets have a  cleansing
            Transformer.cleanOuputs(baseFolderPath:params.pathToContentDir,folderPaths: params.specialFolderPaths)

// now grub and make more files
            try  LinkGrubber()
                .grub (roots:roots,
                       opath:params.pathToOutputDir + "/bigdata",
                       logLevel: verbosity,
                       lgFuncs:lgFuncs)
                {  crawlResults  in
                   //// print("BANDSITE - crawl is done")
                    finally(200)
            }
        }
        catch {
            print("[bandsite] encountered error \(error)")
            finally(404)
        }
    }//init
    
}//audiocrawler
final class AudioHTMLSupport {
    let bandinfo: BandInfo
    let lgFuncs: LgFuncs
 init(bandinfo: BandInfo,lgFuncs:LgFuncs)
    {
        self.bandinfo = bandinfo
        self.lgFuncs = lgFuncs
    }
    func topdiv(cookie:String,links:[Fav],lgFuncs:LgFuncs)-> Node<HTML.BodyContext>  {
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
        
        static func generateImagesAndMarkdownFromRemoteDirectoryAssets(links:[Fav],lgFuncs:LgFuncs) -> ImagesAndMarkdown {
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
        
        let cookie = Fortunes.get_fortune_cookie()
        
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
        let ve =  venue == "" ? bandinfo.venueShort : venue
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

