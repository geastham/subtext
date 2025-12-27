# Post-Launch Roadmap

**Timeline:** Weeks 9-24 (6 months post-MVP)  
**Status:** 📅 Future Planning

## Overview

This document outlines the post-MVP roadmap for Subtext, covering feature enhancements, scaling, and business model development over the 6 months following initial launch.

## Launch Strategy

### Beta Phase (Weeks 9-12)

**Goals:**
- Validate product-market fit with 100-500 users
- Identify critical issues
- Collect qualitative feedback
- Iterate rapidly

**Activities:**
- **Week 9:** Internal beta (25 testers)
- **Week 10:** Expand to 100 testers (friends of friends)
- **Week 11:** Product Hunt beta list (target 250 users)
- **Week 12:** Analyze data, fix critical bugs, prepare for public launch

**Success Metrics:**
- 4.0+ / 5.0 satisfaction score
- 50%+ D7 retention
- <5 critical bugs
- Clear value proposition resonance

### Public Launch (Week 13)

**Timing:** iOS 26 general availability (September 2025)

**Launch Channels:**
1. **Product Hunt**
   - Target: #1 Product of the Day
   - Prepare: Demo video, founder story, user testimonials
   
2. **Tech Press**
   - TechCrunch, The Verge pitch: "First truly private AI dating coach"
   - Hacker News: Technical deep dive on on-device AI
   
3. **Social Media**
   - Twitter/X: Developer and privacy communities
   - Reddit: r/privacy, r/dating_advice, r/ios
   - TikTok: Short demos of the app in action

4. **Content Marketing**
   - Launch blog post (technical + vision)
   - Founder story (why privacy matters)
   - User testimonials from beta

**Press Angle:**
- "First truly private dating coach built on Apple Intelligence"
- "Gen Z is terrified of AI seeing their conversations - here's the solution"
- "On-device AI is changing how we think about privacy in intimate apps"

**Launch Week Goals:**
- 1,000+ downloads
- Feature on Product Hunt homepage
- Press coverage in 2+ major outlets
- 4.5+ App Store rating

## Immediate Post-Launch (Weeks 13-16)

### Priority 1: Stability & Performance

**Focus:** Ensure core experience is rock-solid

- [ ] Monitor crash reports daily
- [ ] Fix critical bugs within 24 hours
- [ ] Optimize performance based on real-world data
- [ ] Address top user complaints

**Targets:**
- Crash rate <0.1%
- <10 critical bug reports per week
- Performance within targets (measured)

### Priority 2: Onboarding Improvements

**Problem:** Activation rate may be lower than target

**Improvements:**
- [ ] Add interactive tutorial on first launch
- [ ] Improve empty state messaging
- [ ] Simplify speaker labeling flow
- [ ] Add sample conversation for demo

**Target:**
- Increase activation rate from 70% to 80%

### Priority 3: Quality Iterations

**Focus:** Make coaching suggestions better

- [ ] Collect user ratings on every reply
- [ ] A/B test different prompt variations
- [ ] Fine-tune safety detection based on feedback
- [ ] Iterate on intent descriptions

**Target:**
- 4.5+ / 5.0 average reply quality

## Feature Roadmap

### V1.1 - Quick Wins (Weeks 17-20)

**Theme:** Polish and convenience

1. **Share Sheet Import** (High Impact)
   - Import directly from Messages, WhatsApp
   - Eliminates copy-paste friction
   - Expected: +20% activation rate

2. **Conversation Search** (Medium Impact)
   - Search by participant name or message content
   - Better for power users with many conversations
   
3. **Reply History** (Medium Impact)
   - See which replies you've used before
   - Learn from past conversations
   
4. **More Intent Options** (High Impact)
   - "Ask Them Out" intent
   - "Define the Relationship" intent
   - "Apologize" intent

5. **Tone Presets** (Low Impact)
   - Save favorite tone combinations
   - Quick access to preferred styles

**Estimated Effort:** 4 weeks (1 engineer)

### V1.2 - Personalization (Weeks 21-28)

**Theme:** Learn user's voice and style

1. **Style Learning** (High Impact)
   - Analyze user's actual messages
   - Adapt suggestions to their natural voice
   - Make coaching feel more authentic

2. **Favorite Replies** (Low Impact)
   - Star replies you loved
   - Build personal collection

3. **Custom Intents** (Medium Impact)
   - Let users create their own intent categories
   - More flexible coaching

4. **Conversation Insights** (Medium Impact)
   - Patterns in your conversations
   - Communication style analysis
   - Relationship health indicators

**Estimated Effort:** 6 weeks (1-2 engineers)

### V1.3 - Safety Enhancements (Weeks 29-32)

**Theme:** Better protection and resources

1. **Risk Scoring** (High Impact)
   - Conversation-level risk assessment
   - Track patterns over time
   - Early warning system

2. **Education Resources** (Medium Impact)
   - In-app articles on healthy relationships
   - Communication tips and guides
   - Vetted external resources

3. **Export for Therapists** (Low Impact)
   - Secure export for therapy sessions
   - Privacy-preserving anonymization

4. **Community Support** (Low Impact)
   - Anonymous peer support forum
   - Moderated by professionals

**Estimated Effort:** 4 weeks (1 engineer + 1 content specialist)

### V1.5 - Advanced Features (Weeks 33-40)

**Theme:** Power user features

1. **Voice Note Analysis** (High Impact)
   - Transcribe and analyze voice messages
   - Coaching for verbal communication

2. **Group Chat Support** (Medium Impact)
   - Navigate group dynamics
   - Specialized intents for groups

3. **Relationship Timeline** (Low Impact)
   - Track relationship progression
   - Milestone markers
   - Conversation archive

4. **Advanced Analytics** (Low Impact)
   - Communication patterns over time
   - Sentiment analysis
   - Compatibility insights

**Estimated Effort:** 6 weeks (2 engineers)

## Platform Expansion

### iOS 17+ Support (V1.6)

**Rationale:** Expand addressable market

**Approach:**
- Implement Core ML fallback (Phi-3-Mini)
- Trade-off: Slightly lower quality, but broader reach
- A/B test quality difference

**Target:** +200% TAM (Total Addressable Market)

**Estimated Effort:** 6 weeks (1 ML engineer)

### Keyboard Extension (V2.0)

**Rationale:** Ultimate convenience - coaching without leaving Messages

**Features:**
- Mini coaching interface in keyboard
- Quick reply suggestions
- One-tap coaching

**Challenges:**
- Technical complexity (keyboard extensions are hard)
- Limited on-device model in keyboard context
- May need simplified prompts

**Target:** +50% daily active usage

**Estimated Effort:** 8 weeks (2 engineers)

### iPad & Mac Support (V2.1)

**Rationale:** Multi-device experience

**Features:**
- Sync via iCloud (encrypted)
- Optimized layouts for larger screens
- Mac menubar widget

**Target:** +30% user base

**Estimated Effort:** 4 weeks (1 engineer)

## Business Model Development

### Free vs. Premium

**MVP Launch:** 100% free
- Focus on product-market fit
- No monetization friction
- Build user base

### V1.5: Premium Tier Introduction (Month 6)

**Free Tier:**
- Unlimited conversations
- 10 coaching sessions per week
- 5 core intents
- Basic safety detection

**Premium Tier ($4.99/month or $49.99/year):**
- Unlimited coaching sessions
- All intents (including advanced)
- Style personalization
- Priority support
- Export features
- Advanced analytics

**Target:** 10% conversion rate to premium

**Revenue Goal (Month 12):**
- 10,000 DAU × 30% active premium = 3,000 premium users
- 3,000 × $4.99 = $14,970/month = ~$180K/year

### Alternative Monetization

**Option 1: Freemium with Limits**
- 5 coaching sessions/week free
- Unlimited for $2.99/month

**Option 2: Pay-Per-Use**
- First 10 sessions free
- $0.49 per coaching session after
- Credits bundle discounts

**Option 3: Coaching as a Service**
- B2B licensing to dating apps
- White-label coaching API
- Higher margins, different market

## Growth Strategy

### Organic Growth (Months 1-6)

**Channels:**
1. **Word of Mouth**
   - Referral program (coming V1.2)
   - Viral mechanics (share favorite replies?)
   
2. **App Store SEO**
   - Optimize for keywords
   - Build rating/review base
   - Featured app pitches
   
3. **Content Marketing**
   - Blog posts on dating/communication
   - Guest posts on larger platforms
   - YouTube demos and tutorials

4. **Community Building**
   - Discord server for users
   - Weekly tips newsletter
   - User-generated content

### Paid Acquisition (Month 7+)

**Channels:**
1. **Instagram/TikTok Ads**
   - Target: Gen Z daters
   - Creative: Privacy-focused, relatable scenarios
   - Budget: $5K/month test

2. **Reddit/Twitter Ads**
   - Target: Privacy-conscious users
   - Creative: Technical deep-dives
   - Budget: $2K/month

3. **Influencer Partnerships**
   - Dating coaches, therapists
   - Privacy advocates
   - Micro-influencers in dating space

**Target CAC (Customer Acquisition Cost):** <$5
**Target LTV (Lifetime Value):** >$25

## Partnerships

### Dating Apps
- Tinder, Hinge, Bumble integrations
- In-app coaching features
- Revenue share model

### Therapists/Coaches
- Professional tools tier
- Client progress tracking
- Educational resources

### Privacy Organizations
- EFF, Privacy International partnerships
- Thought leadership
- Joint advocacy campaigns

## Decision Points

### At 100 Users (Week 10)
**Question:** Is retention >40% D7?
- ✅ Yes → Continue to public launch
- ❌ No → Iterate on core value, delay launch

**Question:** Is quality rated >4.0/5?
- ✅ Yes → Continue
- ❌ No → Improve AI prompts, delay launch

### At 1,000 Users (Week 16)
**Question:** Is growth organic or paid?
- Organic → Strong PMF signal, scale up
- Paid → Weak virality, focus on retention

**Question:** What are top feature requests?
- Prioritize V1.1 roadmap accordingly

**Question:** Is iOS 26+ requirement too limiting?
- Yes → Accelerate Core ML support (V1.6)
- No → Continue with current strategy

### At 10,000 Users (Week 28)
**Question:** Is monetization needed?
- Yes → Introduce premium tier (V1.5)
- No → Continue building user base

**Question:** Are users willing to pay?
- Survey 1,000 users on pricing
- Test different tiers and pricing

**Question:** What's the right business model?
- Data guides decision (usage patterns, demographics)

## Success Metrics by Milestone

### 100 Users (Week 10)
- 50% D7 retention
- 4.0+ / 5.0 satisfaction
- <5 critical bugs
- 70%+ activation rate

### 1,000 Users (Week 16)
- 45% D7, 25% D30 retention
- 4.2+ / 5.0 satisfaction
- 20%+ organic growth w/w
- 75%+ activation rate

### 10,000 Users (Week 28)
- 40% D7, 30% D30 retention
- 4.5+ / 5.0 satisfaction
- 4.5+ App Store rating
- 10%+ premium conversion (if launched)

### 100,000 Users (Month 18)
- 35% D7, 25% D30 retention
- 4.5+ / 5.0 satisfaction
- $50K+ MRR (if monetized)
- Sustainable growth (15%+ m/m)

## Team Scaling

### Current (MVP): 1-3 people
- 1 iOS Engineer (founder or hire)
- 1 Designer (founder or part-time)
- 1 PM/Founder

### At 1,000 Users: +1-2 people
- +1 iOS Engineer (features + support)
- +1 Community Manager (part-time)

### At 10,000 Users: +2-3 people
- +1 ML Engineer (personalization, Core ML)
- +1 Content/Marketing (growth)
- +1 Support (full-time)

### At 100,000 Users: +5-10 people
- iOS team of 3-4
- Backend team of 2 (if needed)
- Growth team of 2-3
- Operations/Support of 2-3

## Budget Projection

### Months 1-6 (MVP + V1.1)
- Salaries: $60K (part-time team)
- Infrastructure: $500 (Apple Developer, domains, etc.)
- Marketing: $2K (launch campaigns)
- **Total:** ~$62K

### Months 7-12 (V1.2-1.5 + Growth)
- Salaries: $120K (full-time team)
- Infrastructure: $2K (servers if needed, tools)
- Marketing: $30K (paid acquisition)
- **Total:** ~$152K

### Months 13-18 (Scale)
- Salaries: $200K (expanded team)
- Infrastructure: $5K
- Marketing: $60K
- **Total:** ~$265K

**Cumulative 18-Month Budget:** ~$480K

## Risks & Contingencies

### Risk: Market Doesn't Materialize
**Mitigation:**
- Pivot to adjacent markets (therapy, professional communication)
- B2B licensing model
- Open source core, monetize premium features

### Risk: Apple Restrictions
**Mitigation:**
- Lobby through developer channels
- Public advocacy campaign
- Prepare non-AI fallbacks

### Risk: Competition Emerges
**Mitigation:**
- Move fast, build moat via quality and privacy
- Strong brand around privacy
- Community and network effects

### Risk: Monetization Fails
**Mitigation:**
- Test multiple pricing models
- User research on willingness to pay
- Alternative revenue streams (B2B, partnerships)

## Long-Term Vision (2+ years)

### Product Evolution
- AI that truly understands you
- Proactive coaching (before you even ask)
- Real-time conversation analysis
- Multi-modal (text, voice, video)

### Market Expansion
- Beyond dating: professional communication
- Team collaboration coaching
- Conflict resolution for families
- Therapeutic applications

### Platform Play
- Open coaching API
- Third-party intent marketplace
- White-label solutions for enterprises

### Impact Goals
- 1M+ users
- 100K+ healthier relationships
- Industry-leading privacy standards
- Acquired or IPO ($100M+ valuation)

---

**This roadmap is a living document.** Expect significant changes based on user feedback, market dynamics, and team learnings.

**Key Principle:** Stay nimble, listen to users, and always prioritize privacy and user well-being over growth.

