# AX API and native evidence
2026-11-11 Chrome native UI, public W3C PDF: https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf
Focused element remains extension AXWebArea chrome-extension://mhjfbmdgcfjbbpaeojofohoefgiehjai/index.html, with toolbar controls and nested AXWebArea -> PDF document group -> page group -> static text. Doubleclick public text selected exactly Dummy; focused extensionwebarea remains. This establishes nested PDF accessibility, not candidate app read or physicalForceClick success.
Apple parameterized API: https://developer.apple.com/documentation/applicationservices/1461203-axuielementcopyparameterizedattr
Selected range substring: https://developer.apple.com/documentation/applicationservices/kaxstringforrangeparameterizedattribute
Chromium source selection/visible caret and markers: https://chromium.googlesource.com/chromium/src/+/1932b1654790288639eb22a0cfcc738774469f8b/content/browser/accessibility/browser_accessibility_cocoa.mm
