import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedStories({bool force = false}) async {
  final fs = FirebaseFirestore.instance;
  final storiesRef = fs.collection("Stories");

  // Skip seeding nếu đã có data
  if (!force) {
    final snapshot = await storiesRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      print("Stories already exist → skipping seeding");
      return;
    }
  }

  final stories = [
    {
      "mainTitle": "From Part-time Barista to Full-stack Developer",
      "subTitle": "Alice Nguyen",
      "content":
          "Alice used to work part-time in a coffee shop. She decided to learn programming at night. After one year, she landed her first job as a junior developer. Today, she works remotely and earns around 2500 USD per month.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/barista_to_dev.jpg",
    },
    {
      "mainTitle": "Breaking into Data Science",
      "subTitle": "David Tran",
      "content":
          "David studied economics but always loved math. He took online courses in Python, statistics, and machine learning. Within 18 months, he switched careers and is now a data analyst at a tech startup.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/data_science.jpg",
    },
    {
      "mainTitle": "Freelancer Turned Entrepreneur",
      "subTitle": "Sophia Le",
      "content":
          "Sophia started freelancing as a graphic designer while still in university. With her strong portfolio, she co-founded a small design agency. Her team now works with clients across Asia.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/freelancer.jpg",
    },
    {
      "mainTitle": "Engineer Who Became a Teacher",
      "subTitle": "Minh Hoang",
      "content":
          "After 7 years as a mechanical engineer, Minh wanted to give back. He transitioned into teaching STEM subjects at a local college, inspiring the next generation of engineers.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/teacher.jpg",
    },
    {
      "mainTitle": "Turning a Hobby into a Career",
      "subTitle": "Linh Pham",
      "content":
          "Linh always loved photography. What started as a hobby became her full-time career. She now works as a professional photographer specializing in travel and lifestyle shoots.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/photography.jpg",
    },
    {
      "mainTitle": "From Accountant to Product Manager",
      "subTitle": "Khai Nguyen",
      "content":
          "Khai worked as an accountant for 5 years. He switched to tech by joining a startup as a business analyst, then grew into a product manager role. He now leads a team of 10.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/product_manager.jpg",
    },
    {
      "mainTitle": "The Nurse Who Became a Software Engineer",
      "subTitle": "Trang Do",
      "content":
          "Trang was a registered nurse. During the pandemic, she became fascinated with health-tech apps. She learned coding through bootcamps and is now a developer in a healthcare company.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/nurse_to_dev.jpg",
    },
    {
      "mainTitle": "Small Town to Silicon Valley",
      "subTitle": "Hung Vo",
      "content":
          "Hung grew up in a rural town. With dedication, he got a scholarship to study computer science abroad. Today, he works at a top tech company in Silicon Valley.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/silicon_valley.jpg",
    },
    {
      "mainTitle": "Career Restart After 40",
      "subTitle": "Mai Phan",
      "content":
          "Mai worked in administration for 20 years. At age 42, she retrained in UX/UI design. Now she enjoys a creative role at a digital agency, proving it’s never too late to start again.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/ux_ui.jpg",
    },
    {
      "mainTitle": "From Gamer to Game Developer",
      "subTitle": "Bao Tran",
      "content":
          "Bao loved gaming since childhood. He turned his passion into a career by studying computer graphics. He is now part of a game studio creating indie games.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/game_dev.jpg",
    },
    {
      "mainTitle": "Marketing Graduate Turned Digital Nomad",
      "subTitle": "Ha Nguyen",
      "content":
          "Ha started in a marketing agency but longed for freedom. She built skills in SEO and content strategy, now working fully remote while traveling across Southeast Asia.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/digital_nomad.jpg",
    },
    {
      "mainTitle": "From Factory Worker to Cloud Engineer",
      "subTitle": "Tuan Le",
      "content":
          "Tuan worked in a factory for years. Through self-study in cloud computing and certifications, he transitioned into IT. Today he earns 3x his previous salary as a cloud engineer.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/cloud_engineer.jpg",
    },
    {
      "mainTitle": "Lawyer Who Built a Startup",
      "subTitle": "Quyen Vo",
      "content":
          "Quyen practiced law for several years but always dreamed of entrepreneurship. She co-founded a legal-tech startup that helps people access affordable legal services online.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/legaltech.jpg",
    },
    {
      "mainTitle": "Switching from Sales to Cybersecurity",
      "subTitle": "An Tran",
      "content":
          "An worked in sales but got interested in cybersecurity after attending a workshop. Within two years, he became a security analyst at a multinational bank.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/cybersecurity.jpg",
    },
    {
      "mainTitle": "Teacher Who Became a Data Engineer",
      "subTitle": "Lan Pham",
      "content":
          "Lan taught mathematics for a decade. She transitioned into tech through data engineering bootcamps and now designs data pipelines for a fintech company.",
      "bannerUrl": "https://res.cloudinary.com/your-cloud/image/upload/v1/story_banners/data_engineer.jpg",
    },
  ];

  for (final story in stories) {
    await storiesRef.add({
      ...story,
      "userId": "Anonnymous",
      "status": "approved",
      "likesCount": 0,
      "commentsCount": 0,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  print("Seeded ${stories.length} stories successfully");
}
