# Subtext Documentation

Welcome to the Subtext documentation repository. This folder contains comprehensive research, technical specifications, and implementation plans for building Subtext - a privacy-first, on-device conversation coach for Gen Z daters.

## Document Index

### 📋 [01 - Product Vision](./01-product-vision.md)
**Core thesis, market opportunity, and strategic positioning**

Covers:
- Problem statement and user needs
- Core product philosophy (privacy-first, empowerment, safety)
- Target market analysis (Gen Z, 18-27)
- Jobs-to-be-done framework
- Competitive landscape overview
- Success metrics and KPIs
- Product roadmap vision (V1.0 → V3.0)

**Read this first** to understand the "why" behind Subtext.

---

### 🏗️ [02 - Technical Architecture](./02-technical-architecture.md)
**System design, data models, and implementation strategy**

Covers:
- High-level architecture (client-only, on-device)
- Platform requirements (iOS 26+ vs. iOS 17+)
- On-device AI architecture (Foundation Models + Core ML)
- Data models and storage security
- Business logic layer (parsers, safety, prompts)
- Performance optimization strategies
- API design and testing approach
- Deployment and monitoring

**Essential for engineers** building the app.

---

### 🤖 [03 - On-Device LLM Research](./03-on-device-llm-research.md)
**Model evaluation, benchmarks, and selection criteria**

Covers:
- Apple Foundation Models framework deep dive
- Core ML model options (Llama 3.1, Phi-3-Mini)
- Performance benchmarks (latency, memory, battery)
- Quality assessment for conversation tasks
- Optimization techniques
- Hybrid approach recommendation
- Model updates and maintenance

**Critical for ML/AI decisions** and understanding technical constraints.

---

### 🎯 [04 - Competitive Analysis](./04-competitive-analysis.md)
**Market landscape, competitors, and differentiation strategy**

Covers:
- Direct competitors (YourMove AI, Rizz AI, Teaser AI, ChatGPT)
- Adjacent competitors (dating apps, therapy apps, Reddit)
- Feature comparison matrix
- Competitive advantages (privacy, purpose-built, mobile-native)
- Positioning strategy and key messages
- Go-to-market strategy
- Competitive threats and mitigation
- Market sizing (TAM, SAM, SOM)

**Essential for product strategy** and marketing.

---

### 🚀 [05 - MVP Implementation Plan](./05-mvp-implementation-plan.md)
**8-week development roadmap and execution strategy**

Covers:
- MVP definition and scope
- Week-by-week implementation plan
- Technical implementation details
- User flows and UI/UX principles
- Success metrics and validation criteria
- Risk mitigation strategies
- Launch strategy (beta → public)
- Post-launch priorities

**Your execution playbook** for building the MVP.

---

## Quick Start Guide

### For Product Managers
1. Read: 01-Product Vision
2. Read: 04-Competitive Analysis
3. Skim: 05-MVP Implementation Plan

### For Engineers
1. Read: 02-Technical Architecture
2. Read: 03-On-Device LLM Research
3. Reference: 05-MVP Implementation Plan

### For Designers
1. Read: 01-Product Vision (understand users)
2. Reference: 05-MVP Implementation Plan (UI/UX section)
3. Skim: 02-Technical Architecture (understand constraints)

### For Founders/Investors
1. Read: 01-Product Vision (market opportunity)
2. Read: 04-Competitive Analysis (moat and positioning)
3. Skim: 05-MVP Implementation Plan (timeline and resources)

## Key Insights Summary

### The Opportunity
- **350M** dating app users globally
- **84%** of Gen Z want deeper connections but struggle with communication
- **61%** believe technology has harmed their conversation skills
- Gen Z already uses ChatGPT for dating advice (privacy nightmare)

### Our Approach
- **100% on-device**: Conversations never leave the iPhone
- **Purpose-built**: Optimized for dating, not generic AI
- **Safety-first**: Proactive red flag detection
- **Empowerment**: Coach, don't replace

### Technical Strategy
- **iOS 26+** with Apple Foundation Models (primary)
- **iOS 17+** with Core ML (future fallback)
- **8-week MVP** to validate product-market fit
- **Privacy by design**: No servers, no data collection

### Competitive Advantage
1. **Privacy**: On-device vs. cloud-based competitors
2. **Quality**: Purpose-built vs. generic AI
3. **Safety**: Red flag detection vs. none
4. **Mobile**: Native iOS vs. web tools

## Research Sources

This documentation is based on:

### Primary Research
- Apple WWDC 2025 Foundation Models announcement
- Apple ML Research papers (2024-2025)
- User behavior data from dating apps (Hinge, Tinder reports)
- Gen Z communication studies

### Industry Analysis
- Dating app market reports (Statista, 2025)
- AI coaching tools analysis (YourMove AI, Rizz AI)
- Privacy-first app trends
- On-device ML benchmarks

### Technical References
- Apple Developer Documentation (Foundation Models, Core ML)
- Academic papers on LLM optimization
- Open-source model comparisons (Llama, Phi-3)
- iOS performance benchmarks

## Document Maintenance

**These documents should be updated:**
- **Monthly**: Competitive landscape (new entrants, feature updates)
- **Quarterly**: Technical architecture (new Apple frameworks, model improvements)
- **Bi-annually**: Market sizing (as iOS 26 adoption grows)
- **As needed**: Based on user feedback and learnings

**Version History:**
- v1.0 (December 2025): Initial comprehensive documentation
- _Future updates will be tracked here_

## Contributing

When updating these documents:

1. **Maintain consistency**: Use similar structure and tone
2. **Date your changes**: Note when sections were updated
3. **Cite sources**: Link to research, articles, or data
4. **Cross-reference**: Link between documents when relevant
5. **Keep practical**: Focus on actionable insights

## Questions or Feedback?

These documents are living artifacts. If you have:
- **Questions** about any section
- **New research** to incorporate
- **Suggestions** for improvements
- **Findings** from user testing

Please create an issue or update the relevant document directly.

---

## Next Steps

**If you're building Subtext:**

1. ✅ **Review all 5 documents** to understand the full picture
2. 🎯 **Set up development environment** (Xcode, iOS 26 beta access)
3. 🏗️ **Follow the 8-week plan** in document 05
4. 📊 **Track metrics** defined in documents 01 and 05
5. 🔄 **Iterate based on learnings** and update docs accordingly

**The goal:** Launch a working MVP in 8 weeks that validates the core hypothesis:

> "Gen Z daters will use an on-device AI coach to improve their text conversations if it meaningfully helps them communicate better while keeping their conversations private."

Good luck building the future of private, empowering relationship technology! 🚀

---

*Last updated: December 2025*

