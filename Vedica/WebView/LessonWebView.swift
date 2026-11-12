import SwiftUI
import WebKit

/// Reusable host for a bundled lesson page. Pages open with `?native=1`, which tells them they run inside the app.
/// Messages arrive through `WKScriptMessageHandler` as: "exit", "continue" (the lesson's own Continue button),
/// "done" (a stand-alone page finished), or "resume:{...}".
struct LessonWebView: UIViewRepresentable {
    let lessonID: String
    let narrate: Bool
    /// Step to open at; 0 means the lesson's own saved place (or its Start card).
    let startStep: Int
    /// Text for the lesson's own Continue button.
    let continueLabel: String
    let onMessage: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onMessage: onMessage) }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        let uc = WKUserContentController()
        uc.add(context.coordinator, name: "vedica")
        uc.addUserScript(WKUserScript(source: early, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        uc.addUserScript(WKUserScript(source: bridge, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        cfg.userContentController = uc

        let wv = WKWebView(frame: .zero, configuration: cfg)
        context.coordinator.webView = wv
        wv.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.backgroundColor = .clear
        wv.scrollView.isScrollEnabled = false
        wv.scrollView.bounces = false
        wv.scrollView.contentInsetAdjustmentBehavior = .never
        wv.navigationDelegate = context.coordinator
        if let root = Bundle.main.url(forResource: "Lessons", withExtension: nil) {
            let page = Catalog.page(lessonID)
            let file = root.appendingPathComponent(page.file)
            var comps = URLComponents(url: file, resolvingAgainstBaseURL: false)
            let label = continueLabel.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            comps?.percentEncodedQuery = ["native=1", page.query, "label=\(label)"].filter { !$0.isEmpty }.joined(separator: "&")
            wv.loadFileURL(comps?.url ?? file, allowingReadAccessTo: root)
        }
        return wv
    }

    func updateUIView(_ wv: WKWebView, context: Context) {}

    static func dismantleUIView(_ wv: WKWebView, coordinator: Coordinator) {
        wv.configuration.userContentController.removeScriptMessageHandler(forName: "vedica")
        wv.evaluateJavaScript(Coordinator.stopJS)
    }

    /// Before the page runs: Profile's narration setting, the requested step, and forwarding of the lesson's saved place.
    private var early: String {
        var js = "try{localStorage.setItem('vedica-narration',JSON.stringify({lang:'en',audio:\(narrate)}))}catch(e){};"
        // The app's saved step decides where the page opens (0 = its Start card), so a page never resumes from a stale place.
        js += "window.__vdLesson='\(lessonID)';try{var r=JSON.parse(localStorage.getItem('vedica-resume')||'{}');if(\(startStep)>0)r['\(lessonID)']=\(startStep);else delete r['\(lessonID)'];localStorage.setItem('vedica-resume',JSON.stringify(r))}catch(e){};"
        js += """
        // React ships inside the app, so a lesson opens without downloading it first.
        window.__resources=Object.assign(window.__resources||{},{
          'https://unpkg.com/react@18.3.1/umd/react.production.min.js':'vendor/react.production.min.js',
          'https://unpkg.com/react-dom@18.3.1/umd/react-dom.production.min.js':'vendor/react-dom.production.min.js'});
        (function(){
          // One male voice for every line of every lesson. iOS loads its voice list late, so a line spoken
          // before the list is ready waits for it instead of playing in the default (female) voice.
          var ss=window.speechSynthesis;if(!ss||!window.SpeechSynthesisUtterance)return;
          var names=['Daniel','Aaron','Arthur','Rishi','Gordon','Oliver','Tom','Alex','Fred'],male=null;
          var pick=function(){if(male)return male;var vs=ss.getVoices().filter(function(v){return /^en/i.test(v.lang)});
            for(var i=0;i<names.length;i++){for(var j=0;j<vs.length;j++){if(vs[j].name.split(' ')[0]===names[i]){male=vs[j];return male}}}
            return null;};
          var speak=ss.speak.bind(ss),hardCancel=ss.cancel.bind(ss),waiting=null,cur=null,next=null,soft=null;
          // "Your turn" is spoken once per lesson; after that the voice goes straight to the instruction.
          var saidTurn=false;
          var trim=function(t){var r=/^\\s*your turn\\b[.:!,]*\\s*/i;if(!r.test(t))return t;if(!saidTurn){saidTurn=true;return t;}return t.replace(r,'');};
          var send=function(u){var v=pick();
            // Never keep the lesson's own choice: with no male voice found, British English is Daniel on iPhone and iPad.
            if(v){u.voice=v;u.lang=v.lang;}else{u.voice=null;u.lang='en-GB';}
            u.text=String(u.text).replace(/[+]/g,' plus ').replace(/\\u2212/g,' minus ');
            cur=u;var done=function(){if(cur!==u)return;cur=null;if(next){var n=next;next=null;send(n);}};
            u.addEventListener('end',done);u.addEventListener('error',done);
            speak(u);};
          var start=function(u){
            // The current screen always wins: a new line (Next, Back, a new step) stops the old one at once.
            // (iOS can drop a line spoken in the same moment as a cancel, so the new one follows a beat later.)
            if(cur){cur=null;next=null;hardCancel();waiting=u;setTimeout(function(){if(waiting===u){waiting=null;start(u);}},90);return;}
            if(pick()){send(u);return;}
            waiting=u;var t0=Date.now();
            (function wait(){if(waiting!==u)return;if(pick()||Date.now()-t0>2500){waiting=null;send(u);}else setTimeout(wait,60);})();};
          // Lessons call cancel() right before each new line; that is treated as a restart, not a stop.
          ss.speak=function(u){if(soft){clearTimeout(soft);soft=null;}u.text=trim(String(u.text));if(!u.text.trim())return;start(u);};
          ss.cancel=function(){waiting=null;next=null;clearTimeout(soft);soft=setTimeout(function(){soft=null;cur=null;hardCancel();},250);};
          // A real stop (closing the lesson, leaving the app): silence straight away.
          // Lessons ask this before moving on by themselves, so a line is never cut off by the screen changing.
          window.__vdBusy=function(){return !!(cur||waiting);};
          window.__vdStop=function(){clearTimeout(soft);soft=null;waiting=null;next=null;cur=null;hardCancel();};
          if(ss.addEventListener)ss.addEventListener('voiceschanged',pick);pick();
          // Leaving the app or hiding the page stops the voice.
          document.addEventListener('visibilitychange',function(){if(document.hidden)__vdStop();});
          addEventListener('pagehide',function(){__vdStop();});
        })();
        (function(){var set=Storage.prototype.setItem;Storage.prototype.setItem=function(k,v){set.call(this,k,v);
        if(k==='vedica-resume'){try{webkit.messageHandlers.vedica.postMessage('resume:'+v)}catch(e){}}}})();
        """
        return js
    }

    /// Forwards close and finish from the pages, and stops iOS dropping quick keypad taps.
    private var bridge: String {
        """
        (function(){
          var P=function(t){try{webkit.messageHandlers.vedica.postMessage(t)}catch(e){}};
          var s=document.createElement('style');s.textContent='*{touch-action:manipulation}html,body{background:#fffefa!important}'+
            '[data-screen-label="Lesson"],#cv{position:fixed!important;left:0!important;top:0!important;margin:0!important;width:var(--W)!important;height:var(--H)!important;'+
            'transform:scale(var(--k))!important;transform-origin:0 0!important;border-radius:0!important}'+
            ':has(>[data-screen-label="Lesson"]){transform:none!important;padding:0!important;box-shadow:none!important}'+
            '.rail-below [data-rail]{left:0!important;right:0!important;width:auto!important;top:var(--railTop)!important;translate:none!important;flex-direction:row!important;'+
            'flex-wrap:wrap!important;justify-content:center!important;align-items:center!important;gap:10px!important}'+
            '.rail-below [data-rail]>*{flex:0 0 auto!important;width:auto!important;align-self:auto!important}'+
            '.rail-below [data-rail]>:first-child{flex-basis:100%!important;text-align:center}'+
            '.rail-below [data-rail] #rail{flex-direction:row!important;flex-wrap:wrap!important;justify-content:center!important;width:100%!important}'+
            '.rail-col [data-rail] #rail{flex-direction:column!important;align-items:center!important}'+
            '.rail-col [data-rail]{flex-direction:column!important;flex-wrap:nowrap!important}'+
            '.rail-col [data-rail]>:first-child{flex-basis:auto!important}'+
            '.rail-below [data-stage]{transform:none!important}'+
            '[data-screen-label="Lesson"]>div:has(>svg[width="66"]),#cv>#hand{margin-left:var(--hdx,0px)!important;margin-top:var(--hdy,0px)!important}'+
            '.vd-hand-off [data-screen-label="Lesson"] div:has(>svg[width="66"]),.vd-hand-off #hand{visibility:hidden!important}';document.documentElement.appendChild(s);
          document.documentElement.style.webkitUserSelect='none';
          document.documentElement.style.webkitTouchCallout='none';
          // Lessons are drawn on a 1024 x 768 canvas. Here the canvas grows to the window's shape: the header and
          // bottom bar stay on the edges and the animation sits in the middle, in portrait and in any window.
          // Portrait uses a narrower canvas (the lessons' side margins are unused there), so lessons draw larger.
          window.__vdPW=820;
          var fit=function(){
            var vw=innerWidth,vh=innerHeight,W=Math.max(vh>vw?__vdPW:1024,768*vw/vh),H=Math.max(768,W*vh/vw),r=document.documentElement.style;
            r.setProperty('--W',W+'px');r.setProperty('--H',H+'px');r.setProperty('--k',vw/W);
            var c=document.querySelector('[data-screen-label="Lesson"],#cv');if(!c)return;
            var dx=(W-1024)/2,dy=(H-768)/2;
            // Tall screens have room below the animation, so the steps sit there instead of over it.
            document.documentElement.classList.toggle('rail-below',H>=1000);
            // With enough height they stack one per line; a shorter window keeps them wrapped in rows.
            document.documentElement.classList.toggle('rail-col',H>=1250);
            r.setProperty('--railTop',(dy+650)+'px');
            r.setProperty('--hdx',dx+'px');r.setProperty('--hdy',dy+'px');
            Array.prototype.forEach.call(c.children,function(e){
              var st=e.style,cs=getComputedStyle(e);
              // The pointing hand is never written to here (on iOS that drops the lesson's own styling);
              // a stylesheet rule moves it using --hdx and --hdy instead.
              if(e.querySelector&&e.querySelector(':scope>svg[width="66"]'))return;
              if(cs.position!=='absolute'){if(cs.position==='static'&&e.tagName==='DIV')st.translate=dx+'px '+dy+'px';return;}
              if(e.offsetWidth>=W-1&&e.offsetHeight>=H-1&&cs.pointerEvents==='none'){e.dataset.stage=1;st.translate=dx+'px '+dy+'px';return;}
              if(e.dataset.rail===undefined&&(e.querySelector('#rail')||(st.right!==''&&(parseFloat(st.top)||0)>100&&cs.pointerEvents==='none'&&cs.flexDirection==='column')))e.dataset.rail=1;
              // The steps list never shifts sideways: below the animation it is centred, beside it it keeps its edge.
              if(e.dataset.rail!==undefined&&!document.documentElement.classList.contains('rail-below')){st.translate='0px '+dy+'px';return;}
              var hasL=st.left!==''&&st.left!=='auto',hasR=st.right!==''&&st.right!=='auto',hasB=st.bottom!==''&&st.bottom!=='auto'&&!st.top;
              var top=parseFloat(st.top)||0,full=e.offsetWidth>=W-1&&e.offsetHeight>=H-1;
              if(hasB||full||(top<=100&&st.top!==''&&(hasR||st.left.indexOf('%')>0))){st.translate='';return;}
              st.translate=((hasL&&hasR)||hasR||st.left.indexOf('%')>0?0:dx)+'px '+dy+'px';
            });
          };
          // The hand rests just off the 1024 x 768 area, which is now on screen, so hide it while it rests there.
          var hand=function(){
            var vw=innerWidth,vh=innerHeight,W=Math.max(vh>vw?__vdPW:1024,768*vw/vh),H=Math.max(768,W*vh/vw),k=vw/W,x0=(W-1024)/2*k,y0=(H-768)/2*k;
            var off=false;
            Array.prototype.forEach.call(document.querySelectorAll('svg[width="66"]'),function(v){
              var r=v.getBoundingClientRect();
              if(r.right<x0+8||r.left>x0+1024*k-8||r.bottom<y0+8||r.top>y0+768*k-8)off=true;
            });
            document.documentElement.classList.toggle('vd-hand-off',off);
          };
          fit();addEventListener('resize',fit);setInterval(function(){fit();hand()},120);
          var x=document.getElementById('x');
          if(x){x.addEventListener('click',function(e){e.stopImmediatePropagation();try{__vdStop()}catch(_){};P('exit')},true);}
          var dn=document.getElementById('dn');
          if(dn){new MutationObserver(function(){if(getComputedStyle(dn).display!=='none'&&!dn._s){dn._s=1;P('done')}}).observe(dn,{attributes:true});}
        })();
        """
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        let onMessage: (String) -> Void
        weak var webView: WKWebView?
        private var observers: [NSObjectProtocol] = []

        init(onMessage: @escaping (String) -> Void) {
            self.onMessage = onMessage
            super.init()
            // Leaving the app stops the narration straight away.
            for name in [UIApplication.willResignActiveNotification, UIApplication.didEnterBackgroundNotification] {
                observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    self?.webView?.evaluateJavaScript(Self.stopJS)
                })
            }
        }

        deinit { observers.forEach(NotificationCenter.default.removeObserver) }

        /// Stops narration at once, including any line waiting to play.
        static let stopJS = "try{window.__vdStop?__vdStop():speechSynthesis.cancel()}catch(e){}"


        /// Gives the page keyboard focus so a hardware keyboard can answer lesson questions.
        func webView(_ wv: WKWebView, didFinish navigation: WKNavigation!) {
            wv.becomeFirstResponder()
            wv.evaluateJavaScript("window.focus()")
        }
        func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
            if let s = m.body as? String { DispatchQueue.main.async { self.onMessage(s) } }
        }
    }
}

/// The lesson screen: native controller, HTML animation.
struct LessonScreen: View {
    @Environment(AppNavigator.self) private var nav
    let id: String
    let start: Int
    let review: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var finished = false

    private var buttonTitle: String {
        if review { return "Back to results" }
        switch Catalog.after(id) {
        case .practice: return "Continue to practice"
        case .quiz: return "Start quiz"
        case .list: return Catalog.tier(of: id) == .inter ? "Back to Intermediate" : "Back to lessons"
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Theme.canvas.ignoresSafeArea()
            LessonWebView(lessonID: id, narrate: nav.store.s.narrationOn, startStep: start, continueLabel: buttonTitle, onMessage: handle)
                .ignoresSafeArea()
            if finished {
                PrimaryPill(title: buttonTitle) {
                    advance()
                }
                .padding(.trailing, pt(36)).padding(.bottom, pt(30))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: finished)
        .statusBarHidden()
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            if scenePhase == .active { nav.store.addActivity(5) }
        }
    }

    private func advance() {
        if review { nav.show(.results, forward: false) } else { nav.lessonFinished(id) }
    }

    private func handle(_ msg: String) {
        if msg == "exit" {
            if review { nav.show(.results, forward: false) } else { nav.lessonExit(id) }
        } else if msg == "continue" {
            advance()
        } else if msg == "done" && Catalog.page(id).file.hasPrefix("lessons/") {
            finished = true
        } else if msg.hasPrefix("resume:"), let d = msg.dropFirst(7).data(using: .utf8),
                  let r = try? JSONDecoder().decode([String: Int].self, from: d), let step = r[id] {
            nav.store.s.resume[id] = step
        }
    }
}
