import Foundation
import LinkGrubber

public struct BandSite {
    var text = "Hello, World!"
}

public func bandsite_command_main(bandfacts:AudioSiteSpec,rewriter:((String)->String)) {
    
    func printUsage() {
        let processinfo = ProcessInfo()
        print(processinfo.processName)
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
        print("\(executableName)")
        print("usage:")
        print("\(executableName) s or m or l")
        
    }
    // the main program starts right here really starts here
    
    do {
        let bletch = { print("[crawler] bad command \(CommandLine.arguments)"  )
            printUsage()
            return
        }
        guard CommandLine.arguments.count > 1 else  { bletch(); exit(0)  }
        let arg1 =  CommandLine.arguments[1].lowercased()
        let incoming = String(arg1.first ?? "X")
        let rooturl = rewriter(incoming)
        let rs = [RootStart(name: incoming, urlstr: rooturl)]
        Hd.setup(bandfacts)
        print("[crawler] executing \(rooturl)")
        let crawler = Hd.audioCrawler
        crawler(rs,  { status in
            switch status {
            case 200:   print("[crawler] it was a perfect crawl ")
            default:  bletch()
            }
        })
    }
} 
