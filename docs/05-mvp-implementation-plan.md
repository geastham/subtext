# MVP Implementation Plan

## MVP Definition

### Core Hypothesis to Validate

**"Gen Z daters will use an on-device AI coach to improve their text conversations if it meaningfully helps them communicate better while keeping their conversations private."**

### Must-Have Features for MVP

1. **Conversation Import** - Paste or share text conversations
2. **Intent Selection** - Choose what you want help with (5 core intents)
3. **AI Coaching** - Generate 3 reply options with rationales
4. **Safety Detection** - Flag red flags and unhealthy patterns
5. **Local Storage** - Save conversations privately
6. **Basic Settings** - Delete data, privacy controls

### Explicitly Out of Scope for MVP

- ❌ Keyboard extension (comes in V2)
- ❌ Style personalization / learning user's voice
- ❌ Voice note analysis
- ❌ Group chat support
- ❌ Advanced analytics / relationship insights
- ❌ Social features / community
- ❌ Monetization (focus on product-market fit)

## Development Timeline: 8 Weeks

### Week 1-2: Foundation & Architecture

**Goals:**
- Set up project structure
- Implement data models
- Basic UI shell

**Deliverables:**
- Xcode project with SwiftUI app
- Core Data / SwiftData models implemented
- Basic navigation (TabView, NavigationStack)
- Settings screen with privacy controls

**Team Requirements:**
- 1 iOS Engineer

**Tasks:**
```
[X] Create Xcode project (iOS 26+)
[X] Set up Core Data / SwiftData schema
[X] Implement ConversationThread model
[X] Implement Message model
[X] Implement CoachingSession model
[X] Create basic UI navigation structure
[X] Build settings screen
[X] Implement secure storage (encryption)
[X] Add delete all data functionality
```

**Validation:**
- Can create and persist conversations
- Can navigate between screens
- Data encryption works
- Delete functionality clears all data

### Week 3-4: Conversation Import & Parsing

**Goals:**
- Build conversation import flow
- Parse various text formats
- Label speakers accurately

**Deliverables:**
- Paste conversation screen
- Parser for common formats (iMessage, WhatsApp, manual)
- Speaker labeling UI
- Conversation detail view

**Tasks:**
```
[X] Build conversation import UI
[X] Implement text parser (detect format)
[X] Parse iMessage format
[X] Parse WhatsApp format
[X] Parse manual / plain text
[X] Build speaker labeling flow ("Who's who?")
[X] Create conversation thread view
[X] Display messages with proper speaker attribution
[X] Add edit/trim functionality
```

**Validation:**
- Can paste conversations from various sources
- Parser correctly identifies messages and speakers
- User can confirm/correct speaker labels
- Conversation displays correctly

### Week 5-6: AI Integration & Coaching

**Goals:**
- Integrate Foundation Models framework
- Implement core coaching logic
- Generate structured outputs

**Deliverables:**
- Foundation Models integration
- Intent selection UI
- Reply generation with 3 options
- Structured output parsing

**Tasks:**
```
[X] Set up Foundation Models framework
[X] Implement LLMClient abstraction
[X] Create prompt templates
[X] Define response schemas (Codable)
[X] Build intent selection screen
[X] Implement coaching request flow
[X] Generate structured coaching outputs
[X] Build coaching results UI (3 replies + rationales)
[X] Add regenerate functionality
[X] Implement streaming (if time permits)
```

**Validation:**
- Foundation Models generates responses
- Outputs are consistently structured (JSON)
- Replies are contextually appropriate
- Rationales explain why each reply works
- User can regenerate with tweaks

### Week 7: Safety & Polish

**Goals:**
- Implement safety detection
- Refine UI/UX
- Fix critical bugs

**Deliverables:**
- Red flag detection
- Safety recommendations
- Polished UI
- Bug fixes

**Tasks:**
```
[X] Implement hard safety rules (prohibited content)
[X] Add AI-based safety classification
[X] Create risk flag UI (warnings, recommendations)
[X] Add support resources (if high-risk detected)
[X] UI polish and refinements
[X] Add loading states and error handling
[X] Implement offline mode gracefully
[X] Performance optimization
[X] Fix critical bugs
```

**Validation:**
- Safety detection works accurately (>85% precision)
- Risk flags display appropriately
- UI feels polished and professional
- App handles errors gracefully
- Performance is acceptable (<3s first token)

### Week 8: Testing & Launch Prep

**Goals:**
- Comprehensive testing
- App Store preparation
- Beta release

**Deliverables:**
- Test coverage (unit, integration, UI)
- App Store listing
- TestFlight beta

**Tasks:**
```
[X] Write unit tests (parsers, models, safety)
[X] Write integration tests (end-to-end flows)
[X] UI tests (critical paths)
[X] Performance testing (latency, memory, battery)
[X] Security audit (data protection, encryption)
[X] Create app icons and marketing assets
[X] Write App Store description
[X] Create screenshots
[X] Set up TestFlight
[X] Internal testing (team + friends, 25 users)
[X] Fix showstopper bugs
```

**Validation:**
- Test coverage >70% for critical code
- No critical bugs
- Performance meets targets
- Privacy Nutrition Label is accurate
- Ready for beta users

## Technical Implementation Details

### Project Structure

```
Subtext/
├── SubtextApp.swift              # App entry point
├── Models/
│   ├── ConversationThread.swift
│   ├── Message.swift
│   ├── CoachingSession.swift
│   └── Intent.swift
├── Services/
│   ├── LLMClient.swift           # AI abstraction
│   ├── ConversationParser.swift
│   ├── SafetyClassifier.swift
│   ├── DataStore.swift           # Core Data wrapper
│   └── PromptTemplates.swift
├── Views/
│   ├── ConversationList.swift
│   ├── ConversationImport.swift
│   ├── ConversationDetail.swift
│   ├── IntentSelection.swift
│   ├── CoachingResults.swift
│   ├── Settings.swift
│   └── Components/
│       ├── MessageBubble.swift
│       ├── ReplyCard.swift
│       └── RiskFlagBanner.swift
├── ViewModels/
│   ├── ConversationViewModel.swift
│   ├── CoachingViewModel.swift
│   └── SettingsViewModel.swift
└── Tests/
    ├── ParserTests.swift
    ├── SafetyTests.swift
    ├── ModelTests.swift
    └── UITests/
```

### Key Technical Decisions

**1. SwiftUI vs. UIKit**
- **Decision**: SwiftUI only
- **Rationale**: Modern, declarative, less code, better for MVP speed
- **Trade-off**: iOS 26+ requirement (acceptable for target market)

**2. Core Data vs. SwiftData**
- **Decision**: SwiftData (if stable), otherwise Core Data
- **Rationale**: SwiftData is more modern and SwiftUI-friendly
- **Fallback**: Core Data is battle-tested if SwiftData has issues

**3. Foundation Models vs. Core ML**
- **Decision**: Foundation Models only for MVP
- **Rationale**: Fastest time to market, best quality
- **Future**: Add Core ML fallback in V1.5

**4. Prompt Engineering Approach**
- **Decision**: Structured prompts with JSON schema enforcement
- **Rationale**: Reliable parsing, consistent UI rendering
- **Implementation**: Use Foundation Models' guided generation

**5. Testing Strategy**
- **Decision**: Focus on critical path and safety testing
- **Rationale**: Limited time, need to ensure safety and core flow work
- **Coverage Target**: 70%+ for business logic, 100% for safety

## User Flows

### Flow 1: First-Time User Onboarding

```
1. Launch app
2. Welcome screen
   - "Your private conversation coach"
   - "100% on-device. Your conversations never leave your iPhone."
   - [Get Started]
3. Permission screen (optional)
   - Explain what data is stored (locally)
   - [Continue]
4. Import first conversation
   - [Paste Conversation] or [Manual Entry]
```

### Flow 2: Paste & Get Coaching

```
1. From conversation list, tap [+]
2. Paste conversation text
3. System detects format, parses messages
4. "Who's who?" speaker labeling
   - Auto-inferred (can edit)
   - [Me] [Them] labels
5. Tap [Get Coaching]
6. Select intent: [Reply] [Interpret] [Boundary] [Flirt] [Conflict]
7. (Optional) Adjust tone sliders
8. [Generate]
9. View coaching results:
   - Summary of situation
   - 3 reply options with rationales
   - Any risk flags (if detected)
   - Follow-up questions
10. [Use This Reply] → copy to clipboard
    Or [Regenerate] with tweaks
```

### Flow 3: Safety Detection (Unhealthy Pattern)

```
1-7. (same as Flow 2)
8. Coaching results show:
   - ⚠️ Risk Flag: "Possible manipulation detected"
   - Evidence: [specific messages highlighted]
   - Recommendation: "Consider setting a boundary"
   - Suggested replies focus on boundaries and safety
   - [Learn More] → resources on healthy communication
```

## UI/UX Design Principles

### Visual Design

**Style:**
- Clean, modern, iOS-native
- Inspired by Apple's design language
- Calm colors (reduce anxiety)
- Clear typography (SF Pro)

**Color Palette:**
- Primary: Blue (trustworthy, calm)
- Accent: Purple (creative, friendly)
- Safety: Yellow/Orange (caution)
- Danger: Red (high-risk flags)

### Interaction Design

**Principles:**
1. **Zero friction**: Minimal taps to coaching
2. **Progressive disclosure**: Show basics, reveal details on tap
3. **Non-judgmental tone**: Supportive, never preachy
4. **Fast feedback**: Loading states, streaming if possible
5. **Forgiving**: Easy to undo, regenerate, edit

**Key Interactions:**
- Swipe to delete conversations
- Long-press on message to highlight context
- Tap reply card to expand rationale
- Pull-to-refresh to regenerate

### Copy & Tone

**Voice:**
- Warm but not overly casual
- Supportive, not parental
- Empowering, not prescriptive
- Honest about limitations

**Example Copy:**
- ✅ "Here are three ways you could respond"
- ❌ "You should say this"
- ✅ "I noticed some concerning patterns"
- ❌ "This person is toxic"
- ✅ "I'm here to help you communicate better"
- ❌ "I'll make you a master conversationalist"

## Success Metrics for MVP

### Activation Metrics

**Target:** 70% of users complete first coaching session

**Measure:**
- % who paste/import conversation
- % who select intent and generate
- Time to first generation
- Drop-off points in flow

### Quality Metrics

**Target:** 4.0+ / 5.0 average rating on reply quality

**Measure:**
- Thumbs up/down on replies
- % of replies that get edited before use
- Edit distance (less = better quality)
- Qualitative feedback

### Safety Metrics

**Target:** >85% precision on risk flag detection

**Measure:**
- False positive rate (flags that shouldn't exist)
- False negative rate (missed red flags)
- User feedback on flag accuracy
- Manual review of flagged conversations

### Engagement Metrics

**Target:** 50% D7, 30% D30 retention

**Measure:**
- Daily / weekly active users
- Sessions per user per week
- Conversations coached per user
- Return time between sessions

### Privacy Trust Metrics

**Target:** 90%+ users stay in "on-device only" mode

**Measure:**
- % in on-device mode
- Settings screen visits
- User reviews mentioning privacy
- Churn reasons (if privacy concerns)

## Risk Mitigation

### Risk 1: Foundation Models Not Available

**Likelihood:** Low (Apple announced at WWDC 2025)

**Mitigation:**
- Have Core ML backup plan (Phi-3-Mini)
- Prototype with beta access early
- Stay in touch with Apple Developer Relations

### Risk 2: Quality Not Good Enough

**Likelihood:** Medium (model might not handle nuance)

**Mitigation:**
- Test extensively with real conversations
- Iterate on prompts
- Collect user feedback aggressively
- Be ready to add Core ML if needed

### Risk 3: Performance Too Slow

**Likelihood:** Low (Apple claims good performance)

**Mitigation:**
- Performance testing on target devices
- Optimize context windows
- Progressive enhancement (fast then deep)
- User testing for perceived speed

### Risk 4: Safety Detection Fails

**Likelihood:** Medium (hard problem)

**Mitigation:**
- Conservative flagging (prefer false positives)
- Manual review of edge cases
- Iterate based on user feedback
- Provide resources even on uncertain flags

### Risk 5: Market Doesn't Care About Privacy

**Likelihood:** Low (Gen Z cares, data shows)

**Mitigation:**
- A/B test messaging (privacy vs. quality)
- User research on privacy value
- Have quality as secondary value prop
- Be ready to pivot positioning

## Launch Strategy

### Beta Phase (Weeks 9-12)

**Goals:**
- Validate product-market fit
- Identify critical bugs
- Collect usage data
- Refine messaging

**Approach:**
- Start with 25 close friends/family
- Expand to 100 users via Product Hunt beta list
- Active feedback collection (in-app + Discord)
- Weekly iterations

**Success Criteria:**
- 4.0+ / 5.0 satisfaction
- 50%+ D7 retention
- <5 critical bugs
- Clear value prop resonance

### Public Launch (Week 13+)

**Timing:**
- iOS 26 general availability (September 2025)
- Coordinate with Apple Intelligence hype

**Channels:**
- Product Hunt (aim for #1 product of the day)
- TechCrunch / The Verge pitch
- Hacker News (technical deep dive post)
- Reddit (r/privacy, r/dating_advice, r/ios)
- Twitter/X (developer community)

**Content:**
- Launch blog post (technical depth + vision)
- Demo video (30-60 seconds)
- Founder story (why privacy matters)
- User testimonials (from beta)

**Press Angle:**
- "First truly private dating coach"
- "Built for Apple Intelligence"
- "Gen Z is afraid of AI seeing their conversations"

## Post-Launch (Weeks 13-24)

### Immediate Priorities
1. **Bug fixes** (based on user reports)
2. **Performance optimization** (if needed)
3. **Onboarding improvements** (reduce drop-off)
4. **Quality iterations** (improve prompts)

### Feature Backlog (V1.1-1.5)
1. Share sheet import (from Messages, WhatsApp)
2. Conversation search
3. Style personalization (learn user's voice)
4. Advanced safety (risk scoring, resources)
5. More intents (e.g., "Ask them out", "Define the relationship")
6. Tone presets (casual, professional, flirty)
7. iOS 17+ support with Core ML

### Metrics to Monitor
- Week-over-week growth
- Retention curves (D1, D7, D30, D90)
- Feature adoption
- Crash rate
- App Store rating
- User feedback themes

### Decision Points

**At 100 users:**
- Is retention >40% D7? (If no: iterate on core value)
- Is quality rated >4.0/5? (If no: improve AI)
- Are users returning weekly? (If no: add habit loops)

**At 1,000 users:**
- Is growth organic or paid? (Organic = PMF signal)
- What are top feature requests? (Prioritize)
- Is iOS 26+ requirement too limiting? (Decide on Core ML)

**At 10,000 users:**
- Is monetization needed? (Consider premium tier)
- Are users willing to pay? (Survey)
- What's the right business model? (Test options)

## Team & Resources

### MVP Team (Minimum)
- **1 iOS Engineer**: Core development
- **1 Designer**: UI/UX (part-time)
- **1 Product Manager** / Founder: Strategy, user research

### Nice to Have
- **ML Engineer**: Prompt optimization, Core ML fallback
- **Community Manager**: Beta user support, feedback collection

### Budget Estimate
- **Development**: 8 weeks × $10K/week = $80K (if outsourced)
- **Design**: 4 weeks × $5K/week = $20K (part-time)
- **Apple Developer**: $99/year
- **Testing devices**: $2K (iPhone 15 Pro, iPhone 15)
- **Total**: ~$102K (or sweat equity if founder-built)

## Conclusion

This MVP can be built in **8 weeks with a small team**, validating the core hypothesis:

**"Gen Z daters will use private AI coaching to improve their text conversations."**

Success requires:
1. **Speed**: Launch before competitors
2. **Quality**: Coaching must genuinely help
3. **Privacy**: Deliver on "on-device only" promise
4. **Safety**: Protect users from bad advice
5. **Iteration**: Rapid learning from users

If the MVP validates product-market fit, the path forward includes:
- Expanding device support (Core ML)
- Adding advanced features (keyboard, personalization)
- Scaling user acquisition
- Building sustainable business model

---

*This plan should be treated as a living document. Expect to iterate based on learnings from development and user feedback.*

