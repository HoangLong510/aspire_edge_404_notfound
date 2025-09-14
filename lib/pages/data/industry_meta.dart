import 'package:flutter/material.dart';

final Map<String, Map<String, Object>> industryMeta = {
  "tech": {
    "title": "Information Technology",
    "color": Colors.blue,
    "banner":
    "https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=1600&auto=format&fit=crop",
    "stats": [
      "+18% workforce demand this year",
      "Average salary: \$65k–\$120k",
      "Remote jobs: 42%",
      "Top fields: AI, Cloud, Mobile, Data",
    ],
    "skills": [
      "Python",
      "Cloud (AWS/GCP/Azure)",
      "SQL",
      "Docker/Kubernetes",
      "System Design",
    ],
    "roles": [
      "Backend Developer",
      "Mobile Developer",
      "Data Engineer",
      "DevOps Engineer"
    ],
    "lottieStats": "assets/lottie/tech.json",
    "lottieSkills": "assets/lottie/skillstech.json",
    "lottieRoles": "https://assets1.lottiefiles.com/packages/lf20_oojuetow.json",
  },
  "healthcare": {
    "title": "Healthcare",
    "color": Colors.teal,
    "banner":
    "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?q=80&w=1600&auto=format&fit=crop",
    "stats": [
      "+12% workforce demand",
      "Average salary: \$45k–\$90k",
      "Stable with good benefits",
    ],
    "skills": ["Patient Care", "Clinical Knowledge", "EMR", "Communication"],
    "roles": ["Nurse", "Resident Doctor", "Pharmacist"],
    "lottieStats": "https://assets6.lottiefiles.com/packages/lf20_w51pcehl.json",
    "lottieSkills": "assets/lottie/skillsdoctor.json",
    "lottieRoles": "assets/lottie/doctorrole.json",
  },
  "art": {
    "title": "Art",
    "color": Colors.purple,
    "banner":
    "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=1600&auto=format&fit=crop",
    "stats": [
      "+8% growth in digital arts",
      "Freelancers account for 60%",
    ],
    "skills": ["Illustration", "Branding", "Motion Graphics", "UI/UX Design"],
    "roles": ["Graphic Designer", "Illustrator", "Animator"],
    "lottieStats": "assets/lottie/art.json",
    "lottieSkills": "assets/lottie/skillsart.json",
    "lottieRoles": "assets/lottie/artrole.json",
  },
  "science": {
    "title": "Science",
    "color": Colors.indigo,
    "banner":
    "https://bvtb.org.vn/wp-content/uploads/2024/03/hinh-anh-de-tai-nghien-cuu-khoa-hoc-0-1-350x220.jpg",
    "stats": [
      "+10% R&D growth",
      "Strong interdisciplinary demand",
      "High requirement for analytical skills",
    ],
    "skills": ["Research", "Data Analysis", "Laboratory Work", "Statistics"],
    "roles": ["Researcher", "Bioinformatician", "Data Scientist"],
    "lottieStats": "assets/lottie/science.json",
    "lottieSkills": "assets/lottie/skillscience.json",
    "lottieRoles": "https://assets1.lottiefiles.com/packages/lf20_yr6zz3wv.json",
  },
};
