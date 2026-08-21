import SwiftUI

struct ContentView: View {
    @StateObject private var scanner = ScannerEngine()
    @State private var selectedCountry = "全部地区"
    @State private var enableIPv6 = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("CLOUDFLARE SCANNER")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                        Text("网络环境: 自动识别中")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "bolt.horizontal.circle.fill")
                        .font(.title)
                        .foregroundColor(.cyan)
                }
                .padding()

                Button(action: {
                    Task {
                        let testList = ["104.16.1.1", "104.17.2.2", "162.158.1.1", "172.64.0.1"]
                        await scanner.startScan(ipList: testList)
                    }
                }) {
                    Text(scanner.isScanning ? "测速中..." : "启动高频 TLS 握手测速")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(scanner.isScanning ? Color.gray : Color.cyan)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
                .disabled(scanner.isScanning)
                .padding(.horizontal)

                List(scanner.results) { item in
                    HStack {
                        Text(item.ip)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(item.latency) ms")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(item.latency < 100 ? .green : .orange)
                    }
                    .listRowBackground(Color.transparent)
                }
                .listStyle(.plain)
            }
        }
    }
}
