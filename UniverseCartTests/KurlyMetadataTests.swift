import Foundation
import Testing
@testable import UniverseCart

struct KurlyMetadataTests {
    private let sampleURL = URL(string: "https://kurlink.kurly.com/products/1000261454")!

    private let sampleHTML = """
    <html><head>
    <meta property="og:title" content="[조선호텔] 떡갈비 345g - 마켓컬리" />
    <meta property="og:image" content="https://img.kurly.com/test.jpg" />
    </head><body>
    <script id="__NEXT_DATA__" type="application/json">{"props":{"pageProps":{"product":{"discountedPrice":8700,"basePrice":9900}}}}</script>
    </body></html>
    """

    @Test func detectsKurlyMall() {
        #expect(MallDetector.detect(from: sampleURL) == .kurly)
    }

    @Test func parsesKurlyTitlePriceAndImage() {
        let result = OGMetadataExtractor.parseHTMLForTesting(sampleHTML, url: sampleURL)

        #expect(result.primaryIssue == nil)
        #expect(result.metadata.title == "[조선호텔] 떡갈비 345g")
        #expect(result.metadata.price == 8_700)
        #expect(result.metadata.imageURL == "https://img.kurly.com/test.jpg")
    }

    @Test func prefersDiscountedPriceOverBasePrice() {
        let html = """
        <html><body>
        <script id="__NEXT_DATA__" type="application/json">{"discountedPrice":4500,"basePrice":5900}</script>
        </body></html>
        """
        let result = OGMetadataExtractor.parseHTMLForTesting(html, url: sampleURL)
        #expect(result.metadata.price == 4_500)
    }
}
