# CTiOSAudit

Install using cocoapods

target 'YOUR_TARGET_NAME' do
pod 'CTiOSAudit'
end

Then run pod install

import CTiOSAudit module in AppDelegate file. Initialise the SDK and call start Audit method before autoIntegrate() method.

let ctAudit = CTAudit()

ctAudit.startAudit()

Run the app, a text file with audit results will be generated on the path mentioned in the logs
