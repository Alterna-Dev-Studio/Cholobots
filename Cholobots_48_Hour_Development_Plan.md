CHOLOBOTS

**48-HOUR DEVELOPMENT ROADMAP | October 30–December 18, 2026**

Working plan • Version 1 • Prepared for scheduling, testing, and collaboration

# Purpose and definition of success

Build on Cholobots as an operational accessibility aid for Handley Man while creating a credible first-use experience for other businesses and a pilot-ready quarterly guild quest for SACA in January 2027. The immediate business priority is dependable task guidance that reduces reliance on manual prompts to Daniel.

# Development budget

| Date / window                       | Hours | Focus                                            |
| ----------------------------------- | ----- | ------------------------------------------------ |
| Fri, Oct 30 — school Trunk or Treat | 2     | Inventory and audit setup                        |
| Fri, Nov 6                          | 7     | Truth current command and data flows             |
| Fri, Nov 13                         | 7     | Fix critical flows; prototype easier interaction |
| Fri, Nov 20                         | 7     | Conversational UX and wearable proof of concept  |
| Nov 21–28 — Missouri trip           | 4     | Lightweight wearable testing / review            |
| Fri, Dec 4                          | 7     | Multi-company profiles, security, onboarding     |
| Fri, Dec 11                         | 7     | Website-to-Discord handoff; quest design         |
| Fri, Dec 18                         | 7     | End-to-end pilot tests; January preparation      |
| TOTAL                               | 48    | Planning capacity, not a delivery guarantee      |

Normal Friday pattern: 9:00 AM–2:00 PM (5 hours) plus two hours after 4:00 PM. Travel and school-event weeks have reduced allocations. The Mexico trip from Christmas through January 8 is excluded from planned development.

# Five objectives and provisional hour allocations

| Objective                                     | Hours | Primary outcome                                                      |
| --------------------------------------------- | ----- | -------------------------------------------------------------------- |
| 1\. Truth current command flows               | 12    | Working data paths and identified/fixed critical defects             |
| 2\. Friendlier bot interactions               | 10    | At least one useful workflow without memorized commands              |
| 3\. Wearable technology MVP                   | 6     | Actionable prompt delivered to a wearable; test feedback             |
| 4\. Multi-company readiness + full onboarding | 12    | QR → website → Discord → first useful bot action, with isolated data |
| 5\. Quarterly quest experience                | 8     | Pilot-ready challenge, progress review, KPIs, arcade event concept   |

## 1 | Audit current functionality (12 hours)

- Verify !mtoday tasks sync correctly with project lists and Daniel's task view; check that task time records are actually captured.
- Test !mbraindump organization, !mwakeup, pings, leads/customer note capture, and Oven project closeout.
- Remove !queso; document broken behavior, reproducible steps, and acceptance checks.
- Inspect financial engine and !crudoproject interactions insofar as they affect the immediate daily workflow.

## 2 | Friendlier interactions (10 hours)

- Evaluate Angel Escobedo's listener / conversational approach against existing commands.
- Prototype one end-to-end natural-language workflow with context, sensible follow-up questions, and confirmation before consequential changes.
- Focus usability testing on task initiation, lead entry, and not requiring Daniel or a first-time user to remember commands.

## 3 | Wearable MVP (6 hours)

- Choose the smallest device-to-notification path; test sending a timely, actionable task prompt to a smartwatch or wearable companion.
- Test whether notification → orientation → actionable response helps Daniel, rather than counting pings alone.
- Treat full sensor integration, autonomous prioritization, and advanced wearables as later work.

## 4 | Multi-company readiness and website onboarding (12 hours)

- QR code opens cholobots.com; website bot explains the concept, learns a visitor's goals, and invites them to the Homie Guild in Discord.
- Guide the new member from website to Discord, connect identity/profile and company or individual context, and offer a first quest or useful bot task.
- Use separate organization/user profiles, role permissions, and secure data isolation; test with fictitious records before allowing real external-company information.
- Review Wolfy / Andrew Sneed's security notes before inviting external users; test the entire journey without founder hand-holding.
- Keep the current !cholobots.com entry-point concept for evaluation, but avoid making a rigid command the only onboarding route.

## 5 | Quarterly quest experience (8 hours)

- Design one complete quarterly guild quest: participant goal, baseline, milestones, measurable KPIs/income progress, check-ins, and outcome review.
- Design how members interact with other humans and bots, and how guild accountability and competition work.
- Prepare a January SACA visioning introduction, with quarterly arcade-night reviews envisioned at Inov8 Space.
- Permit manual facilitation in the first pilot; defer a full leaderboard/tournament platform.

# Acceptance tests by December 18

- ☐ Existing priority workflows are tested; critical command/data problems are corrected or clearly logged with reproduction steps.
- ☐ Daniel can view tasks from shared !mtoday/project data; the prompting flow is demonstrably more actionable, though independent task initiation remains a test hypothesis.
- ☐ One natural-language interaction successfully triggers an existing Cholobots function.
- ☐ A wearable receives one relevant actionable notification in a controlled test.
- ☐ A newcomer can scan a QR code, learn about Cholobots, enter Discord, establish a test profile, and complete a useful action without assistance.
- ☐ Test-company information cannot be viewed by another company; no real cross-company rollout precedes security review.
- ☐ A complete quarterly quest can be piloted with SACA in January even if supporting automation is incomplete.

# Operating principles and dependencies

- Protect Handley Man revenue work, caregiving, family commitments, exercise, and the Missouri/Mexico trips; do not assume development expands into every spare hour.
- Use the 48 hours as an allocation cap, not a promise that every feature will be production-ready. If work runs long, stabilize core data and task guidance first.
- Separate founder work (workflow specification and acceptance tests) from collaborator work (architecture, listener integration, security, and testing).
- Agree on ownership, licensing, access, and contributions before bringing Growth Garage or other developers into production code.
- Keep Hermes as a possible tool to test, not an assumed architectural dependency.

# Later backlog — not committed within these 48 hours

Advanced financial-engine income-generating suggestions; handwriting/doodle/calendar capture; sophisticated adaptive task prompting; automated company onboarding at scale; complete guild tournament system; NeuroSpicy bimonthly life-skills game platform; Circular SA virtual swap item claiming and event workflows. These remain in the product vision, but are not part of the December delivery commitment.