# Subtext MVP - Multi-Phase Implementation Plan

## Executive Summary

This document outlines a **5-phase implementation plan** to build and launch the Subtext MVP over **8 weeks**. Each phase is designed to deliver working functionality that can be tested and validated incrementally, reducing risk and enabling rapid iteration.

## Core Hypothesis

**"Gen Z daters will use an on-device AI coach to improve their text conversations if it meaningfully helps them communicate better while keeping their conversations private."**

## Must-Have Features for MVP

1. ✅ **Conversation Import** - Paste or share text conversations
2. ✅ **Intent Selection** - Choose what you want help with (5 core intents)
3. ✅ **AI Coaching** - Generate 3 reply options with rationales
4. ✅ **Safety Detection** - Flag red flags and unhealthy patterns
5. ✅ **Local Storage** - Save conversations privately
6. ✅ **Basic Settings** - Delete data, privacy controls

## Phase Overview

| Phase | Duration | Focus | Key Deliverables |
|-------|----------|-------|------------------|
| **Phase 1** | Week 1-2 | Foundation & Data Layer | Project setup, data models, secure storage |
| **Phase 2** | Week 3-4 | Conversation Management | Import, parse, display conversations |
| **Phase 3** | Week 5-6 | AI Integration | Foundation Models, coaching, intents |
| **Phase 4** | Week 7 | Safety & Polish | Risk detection, UX refinement |
| **Phase 5** | Week 8 | Testing & Launch | QA, App Store prep, TestFlight |

## Success Criteria

### Activation Metrics
- **Target:** 70% of users complete first coaching session
- **Measure:** Drop-off points, time to first generation

### Quality Metrics
- **Target:** 4.0+ / 5.0 average rating on reply quality
- **Measure:** User ratings, edit distance, qualitative feedback

### Safety Metrics
- **Target:** >85% precision on risk flag detection
- **Measure:** False positive/negative rates, manual review

### Engagement Metrics
- **Target:** 50% D7, 30% D30 retention
- **Measure:** DAU/WAU, sessions per user, return time

### Privacy Trust Metrics
- **Target:** 90%+ users stay in "on-device only" mode
- **Measure:** Settings visits, user reviews

## Risk Mitigation Strategy

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Foundation Models unavailable | Low | High | Core ML backup (Phi-3-Mini) |
| Quality insufficient | Medium | High | Extensive testing, prompt iteration |
| Performance too slow | Low | Medium | Device testing, optimization |
| Safety detection fails | Medium | High | Conservative flagging, manual review |
| Privacy not valued | Low | Medium | A/B test messaging, user research |

## Team Requirements

### MVP Team (Minimum)
- **1 iOS Engineer**: Full-stack iOS development
- **1 Designer**: UI/UX (part-time or founder)
- **1 Product Manager**: Strategy, user research (founder)

### Nice to Have
- **ML Engineer**: Prompt optimization, Core ML backup
- **Community Manager**: Beta support, feedback

## Budget Estimate

| Item | Cost |
|------|------|
| Development (8 weeks) | $80K (if outsourced) |
| Design (4 weeks, part-time) | $20K |
| Apple Developer Account | $99/year |
| Testing Devices | $2K |
| **Total** | ~$102K |

*Note: Significantly reduced if founder-built*

## Timeline at a Glance

```
Week 1-2: Phase 1 - Foundation & Data Layer
├── Project setup (SwiftUI, SwiftData)
├── Core data models
├── Secure storage
└── Basic navigation

Week 3-4: Phase 2 - Conversation Management
├── Import UI
├── Text parsing (iMessage, WhatsApp)
├── Speaker labeling
└── Conversation display

Week 5-6: Phase 3 - AI Integration
├── Foundation Models setup
├── Prompt engineering
├── Intent selection
└── Coaching results UI

Week 7: Phase 4 - Safety & Polish
├── Risk detection
├── UI/UX refinement
├── Error handling
└── Performance optimization

Week 8: Phase 5 - Testing & Launch
├── Unit & integration tests
├── App Store assets
├── TestFlight setup
└── Beta launch (25 users)
```

## Next Steps

1. Review [Phase 1: Foundation & Data Layer](./01-phase-1-foundation.md)
2. Set up development environment
3. Create Xcode project
4. Begin implementation

## Documents in This Series

- **[Phase 1: Foundation & Data Layer](./01-phase-1-foundation.md)** - Weeks 1-2
- **[Phase 2: Conversation Management](./02-phase-2-conversations.md)** - Weeks 3-4
- **[Phase 3: AI Integration](./03-phase-3-ai-integration.md)** - Weeks 5-6
- **[Phase 4: Safety & Polish](./04-phase-4-safety-polish.md)** - Week 7
- **[Phase 5: Testing & Launch](./05-phase-5-testing-launch.md)** - Week 8
- **[Post-Launch Roadmap](./06-post-launch-roadmap.md)** - Weeks 9+

---

*This plan should be treated as a living document. Expect to iterate based on learnings from development and user feedback.*

