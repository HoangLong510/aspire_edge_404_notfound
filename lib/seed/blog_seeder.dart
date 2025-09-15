import 'package:cloud_firestore/cloud_firestore.dart';

class BlogSeedResult {
  final int totalInserted;
  final int totalSkipped;
  final List<String> insertedTitles;
  const BlogSeedResult({
    required this.totalInserted,
    required this.totalSkipped,
    required this.insertedTitles,
  });

  @override
  String toString() =>
      'Inserted: $totalInserted, Skipped: $totalSkipped, Titles: ${insertedTitles.join(", ")}';
}

class _SeedBlog {
  final String title;
  final String content;
  final List<String> images;
  final String? video;
  const _SeedBlog({
    required this.title,
    required this.content,
    this.images = const [],
    this.video,
  });
}

List<_SeedBlog> _loadSeedBlogs() {
  return [
    _SeedBlog(
      title: 'Tech Salaries: Why Median Pay Is Trending Up This Year',
      content: '''
# Tech Salaries: Why Median Pay Is Trending Up This Year

Across software, data, and cloud roles, compensation bands have edged upward as companies compete for scarce mid–senior talent while simultaneously trimming non-core headcount. The result looks paradoxical: **layoffs in some teams** and **higher offers for high-impact roles**.

## What’s driving the increase
- **Skill scarcity** in AI/ML, platform engineering, and security.
- **Productivity leverage**: one senior engineer who can design, automate, and mentor often replaces multiple junior roles.
- **Cloud cost optimization**: firms pay more for talent that eliminates spend and accelerates migration.

## Roles seeing the strongest lift
- Staff/Principal Software Engineer (backend, platform, DevEx).
- Machine Learning Engineer / MLOps.
- Security Engineer (AppSec, CloudSec, Governance).
- Data Engineer with modern stack (dbt, Lakehouse, streaming).

## How to position yourself
1. Show **measurable business impact** (latency ↓, cost ↓, revenue ↑).
2. Prove **breadth** (infra + product sense) and **depth** (one craft you’re elite at).
3. Build **portfolio evidence**: design docs, RFCs, dashboards, and on-call stories.

### Sample compensation story to bring to an interview
- Reduced monthly cloud bill by 27% through right-sizing and autoscaling.
- Cut build times from 18m → 7m; developer throughput up 12%.
- Shipped feature that lifted conversion by 2.1 p.p. on 150k MAU cohort.

> Pay follows **impact + scarcity**. Grow both.
''',
      images: ['https://picsum.photos/id/1011/1200/675'],
      video: 'https://res.cloudinary.com/daxpkqhmd/video/upload/v1726300000/videos/tech_salaries.mp4',
    ),
    _SeedBlog(
      title: 'Hiring Freezes & Layoffs: Reading The Market Without Panic',
      content: '''
# Hiring Freezes & Layoffs: Reading The Market Without Panic

News feeds can feel chaotic—one company announces growth while another reduces headcount. What’s happening? Firms are **rotating capital** toward profitable lines and pausing experiments. This creates **choppy hiring** but not a total freeze.

## What you can control
- **Run a pipeline** like a salesperson: 20 targets, 5 intros, 3 loops in parallel.
- Build a **case-study resume**: problem → your plan → metrics → result.
- **Warm intros** beat cold applications 5:1. Ask for specific introductions.

## Signals to watch
- Job descriptions emphasizing **cost control** and **platform reliability**.
- Fewer “growth at all costs” words, more **unit economics** language.
- Priority for **revenue-adjacent** roles (sales engineering, analytics, PMM).

## If you’ve been affected
- Ship a **public portfolio** (GitHub, blogs, demo video).
- Write 2–3 **deep dives** on a system you improved.
- Practice **tight stories**: STAR but with numbers and graphs.

Resets are cyclical. Use the moment to **reposition** and come back stronger.
''',
      images: [
        'https://picsum.photos/id/1025/1200/675',
        'https://picsum.photos/id/1035/1200/675',
      ],
      video: 'https://res.cloudinary.com/daxpkqhmd/video/upload/v1726300000/videos/hiring_freezes.mp4',
    ),
    _SeedBlog(
      title: 'Healthcare Careers: Pay, Demand, and Upskilling Paths',
      content: '''
# Healthcare Careers: Pay, Demand, and Upskilling Paths

Healthcare demand keeps expanding with aging populations and chronic care needs. Pay has risen most where **specialization + shortage** intersect.

## Roles in demand
- Registered Nurse (critical care, OR)
- Medical Technologist (lab, diagnostics)
- Health Data Analyst / Informatics
- Allied Health (PT/OT/RT)

## Upskilling routes
- Stack **micro-credentials** (telehealth, informatics, coding for clinicians).
- Learn **data storytelling** with patient outcomes and quality metrics.
- Practice **interdisciplinary handoffs** (nurses ↔ pharmacists ↔ physicians).

## Sample 6-month plan
1. Earn a telehealth or informatics certificate.
2. Build a portfolio dashboard: readmission rates, LOS, cost per case.
3. Present a “quality improvement” case to your manager.

Patient outcomes first. Pay follows **shortage + measurable improvement**.
''',
      images: ['https://picsum.photos/id/1043/1200/675'],
      video: 'https://res.cloudinary.com/daxpkqhmd/video/upload/v1726300000/videos/healthcare_careers.mp4',
    ),
    _SeedBlog(
      title: 'Finance & Data: Comp Bands and What Moves Them',
      content: '''
# Finance & Data: Comp Bands and What Moves Them

As automation takes routine tasks, the premium is on **analysis that drives decisions**. FP&A, RevOps, and Data roles that tie to forecasting, pricing, and margin earn more.

## Core levers for higher pay
- Ownership of a **model that the business runs on** (forecast, pricing, capacity).
- Proven **variance analysis** with corrective actions.
- Ability to ship **self-serve insights** (dbt + warehouse + BI).

## Portfolio evidence
- Forecast accuracy within ±3% for 3 consecutive quarters.
- Pricing experiment improved gross margin by 1.4 p.p.
- Automated monthly close tasks → 18 hours saved per cycle.

Numbers talk. Make your work **queryable, reproducible, and visual**.
''',
      images: ['https://picsum.photos/id/1050/1200/675'],
    ),
    _SeedBlog(
      title: 'Design & Product: The Market Wants Outcomes, Not Dribbble',
      content: '''
# Design & Product: The Market Wants Outcomes, Not Dribbble

Beautiful pixels without business impact no longer win budgeting debates. Designers and PMs who tie work to **activation, retention, and revenue** lead comp bands.

## Show impact in your case studies
- Problem framing with baseline metrics.
- Options explored and why the chosen path won.
- **Before/after**: activation +3 p.p., time-to-first-value ↓ 25%.

## Skills to sharpen
- Product analytics (events, funnels, cohorts).
- Experiment design and causal thinking.
- Narrative memos and crisp decision docs.

Build **product stories** that stand up in a CFO meeting.
''',
      images: [
        'https://picsum.photos/id/1060/1200/675',
        'https://picsum.photos/id/1062/1200/675',
      ],
    ),
    _SeedBlog(
      title: 'Manufacturing & Supply Chain: Pay Premiums For Reliability',
      content: '''
# Manufacturing & Supply Chain: Pay Premiums For Reliability

Companies are re-architecting supply chains for resilience. Professionals who can **de-risk lead times** and **lift OEE** capture higher compensation.

## Where the bonuses show up
- S&OP excellence: forecast alignment across sales, ops, finance.
- OEE improvements via TPM and predictive maintenance.
- Supplier diversification and near-shoring programs.

## A reliability portfolio
- Before/after OEE charts with loss tree breakdown.
- Lead-time variance dropped from 21d → 12d through vendor SLAs.
- Pareto analysis of downtime and countermeasures.

Reliability is a **profit center** when you can prove it.
''',
      images: ['https://picsum.photos/id/1074/1200/675'],
    ),
    _SeedBlog(
      title: 'Salary Negotiation: A Playbook That Works In Any Market',
      content: '''
# Salary Negotiation: A Playbook That Works In Any Market

Comp is a **package** (base, bonus, equity, perks) and a **conversation**. The goal is alignment on value, not combat.

## Steps
1. **Research** bands from multiple sources and back-channel peers.
2. Prepare a **one-pager impact brief** (3 quantified wins).
3. Ask for **range clarity** early; anchor on total compensation.
4. Negotiate **trade-offs**: start date, signing bonus, level calibration.

## Talk tracks
- “Given my scope with cost savings and developer throughput gains, I’m targeting a total range of …”
- “If base is capped, we can close with a sign-on plus level calibration after 6 months based on KPIs.”

A confident, data-backed story earns respect—and better offers.
''',
      images: ['https://picsum.photos/id/1084/1200/675'],
    ),
    _SeedBlog(
      title: 'Career Switching Into Data: A 12-Week Intensive Plan',
      content: '''
# Career Switching Into Data: A 12-Week Intensive Plan

**Goal:** land interviews for analyst/BI roles by building a credible portfolio.

## Weeks 1–4: Foundations
- SQL daily drills; 30 classic analytics queries.
- Spreadsheets with pivot tables and vlookups.
- One project: cohort retention with a clear narrative.

## Weeks 5–8: Modeling + Visualization
- Data modeling with star/snowflake.
- dbt basics and version control.
- Dashboard: exec summary with KPIs and drill-downs.

## Weeks 9–12: Portfolio + Outreach
- Publish 3 case studies with datasets and code.
- 20 targeted applications + 10 warm intros.
- Mock interviews recorded and critiqued.

Consistency beats intensity. Ship something **every week**.
''',
      images: [
        'https://picsum.photos/id/109/1200/675',
        'https://picsum.photos/id/110/1200/675',
      ],
    ),
    _SeedBlog(
      title: 'AI Is Reshaping Job Descriptions—Here’s How To Benefit',
      content: '''
# AI Is Reshaping Job Descriptions—Here’s How To Benefit

AI copilots and automation change what teams expect from each role. The winners are professionals who **pair domain expertise with AI leverage**.

## Practical upgrades
- Treat LLMs as **junior assistants**: drafts, tests, boilerplate.
- Keep **human-in-the-loop** for judgment calls and safety.
- Build **tooling muscle**: prompt libraries, eval sets, red teaming.

## Evidence to capture
- Cycle time reduction with quality gates.
- Cost avoided through automation.
- New capabilities enabled (summaries, search, classification).

AI won’t replace you, but someone **augmented by AI** might.
''',
      images: ['https://picsum.photos/id/111/1200/675'],
    ),
    _SeedBlog(
      title: 'Fresh Graduates: Getting Your First Offer In A Noisy Market',
      content: '''
# Fresh Graduates: Getting Your First Offer In A Noisy Market

You don’t need ten internships. You need **three excellent proofs of work**.

## Your three proofs
1. A project that people can **use** (deployed app, BI dashboard, script).
2. A **deep dive** article with data and visuals.
3. A **team story** that shows collaboration and ownership.

## Process
- Batch applications weekly; avoid one-offs.
- Ask for **referrals** with a short, specific paragraph.
- Practice **pair sessions**: whiteboard or live SQL.

You’re not behind. You’re just **one credible proof** away.
''',
      images: ['https://picsum.photos/id/112/1200/675'],
    ),
    _SeedBlog(
      title:
          'Market Update: Pay Compression At Junior Levels, Premium At Senior',
      content: '''
# Market Update: Pay Compression At Junior Levels, Premium At Senior

Many orgs are leveling comp to control budgets. Entry bands compress, but **senior ICs and managers** who move needles command premiums.

## What to do if you’re junior
- **Compound fast**: ship weekly, seek hard feedback.
- Find a **senior mentor**; copy their thinking patterns.
- Volunteer for **messy problems** no one wants.

## What to do if you’re senior
- Tie every initiative to **CEO-level metrics**.
- Write **narratives** that help decisions happen.
- Multiply others: docs, templates, reusable playbooks.

The spread between average and top-quartile performers is widening. Be **obviously top-quartile**.
''',
      images: ['https://picsum.photos/id/113/1200/675'],
    ),
    _SeedBlog(
      title: 'Remote, Hybrid, On-Site: Comp Trade-offs You Should Know',
      content: '''
# Remote, Hybrid, On-Site: Comp Trade-offs You Should Know

Comp packages increasingly reflect location policy and expected presence.

## Patterns
- **On-site**: higher collaboration, sometimes higher bonus multipliers.
- **Hybrid**: balanced, with clear anchor days and team rituals.
- **Remote**: flexibility premium, sometimes adjusted base by location.

## How to decide
- Map **energy cost** of commuting vs. team velocity gained.
- Ask for **tools and stipends** to make either setup great.
- Optimize for **manager quality** over policy labels.

Presence matters—but **management quality** matters more.
''',
      images: ['https://picsum.photos/id/114/1200/675'],
    ),
  ];
}

Map<String, dynamic> _buildDoc({
  required _SeedBlog seed,
  required String authorId,
  required DateTime createdAt,
}) {
  return {
    'Title': seed.title,
    'ContentMarkdown': seed.content,
    'ImageUrls': seed.images,
    'VideoUrl': seed.video,
    'AuthorId': authorId,
    'CreatedAt': Timestamp.fromDate(createdAt),
    'UpdatedAt': Timestamp.fromDate(createdAt),
    'Views': 0,
  };
}

Future<BlogSeedResult> seedBlogs({
  bool force = false,
  String authorId = 'seed',
}) async {
  final col = FirebaseFirestore.instance.collection('Blogs');
  final existingSnap = await col.get();
  final existingTitles = existingSnap.docs
      .map((d) => (d.data()['Title'] ?? '').toString().trim())
      .toSet();

  final seeds = _loadSeedBlogs();
  final inserted = <String>[];
  int skipped = 0;

  var batch = FirebaseFirestore.instance.batch();
  int inBatch = 0;
  final now = DateTime.now();

  for (int i = 0; i < seeds.length; i++) {
    final s = seeds[i];
    final title = s.title.trim();
    final duplicated = existingTitles.contains(title);

    if (!force && duplicated) {
      skipped++;
      continue;
    }

    final createdAt = now.subtract(Duration(days: seeds.length - i));
    final docRef = col.doc();
    batch.set(
      docRef,
      _buildDoc(seed: s, authorId: authorId, createdAt: createdAt),
    );
    inserted.add(title);
    inBatch++;

    if (inBatch >= 450) {
      await batch.commit();
      batch = FirebaseFirestore.instance.batch();
      inBatch = 0;
    }
  }

  if (inBatch > 0) {
    await batch.commit();
  }

  return BlogSeedResult(
    totalInserted: inserted.length,
    totalSkipped: skipped,
    insertedTitles: inserted,
  );
}