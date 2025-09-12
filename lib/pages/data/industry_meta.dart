import 'package:flutter/material.dart';
/// Data meta cho từng ngành
final Map<String, Map<String, Object>> industryMeta = {
  "tech": {
    "title": "Information Technology",
    "color": Colors.blue,
    "banner":
    "https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=1600&auto=format&fit=crop",
    "stats": [
      "+18% nhu cầu nhân sự năm nay",
      "Lương TB: \$65k–\$120k",
      "Việc làm từ xa: 42%",
      "Top mảng: AI, Cloud, Mobile, Data",
    ],
    "skills": [
      "Python",
      "Cloud (AWS/GCP/Azure)",
      "SQL",
      "Docker/K8s",
      "System Design",
    ],
    "roles": [
      "Backend Developer",
      "Mobile Developer",
      "Data Engineer",
      "DevOps"
    ],
    "lottieStats":
    "assets/lottie/tech.json",
    "lottieSkills":
    "assets/lottie/skillstech.json",
    "lottieRoles":
    "https://assets1.lottiefiles.com/packages/lf20_oojuetow.json",
  },
  "healthcare": {
    "title": "Healthcare",
    "color": Colors.teal,
    "banner":
    "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?q=80&w=1600&auto=format&fit=crop",
    "stats": [
      "+12% nhu cầu nhân sự",
      "Lương TB: \$45k–\$90k",
      "Ổn định & phúc lợi tốt",
    ],
    "skills": ["Patient Care", "Clinical", "EMR", "Communication"],
    "roles": ["Nurse", "Resident Doctor", "Pharmacist"],
    "lottieStats":
    "https://assets6.lottiefiles.com/packages/lf20_w51pcehl.json",
    "lottieSkills":
    "assets/lottie/skillsdoctor.json",
    "lottieRoles":
    "assets/lottie/doctorrole.json",
  },
  "art": {
    "title": "Art",
    "color": Colors.purple,
    "banner":
    "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=1600&auto=format&fit=crop",
    "stats": ["Tăng 8% mảng digital", "Freelance chiếm 60%"],
    "skills": ["Illustration", "Branding", "Motion", "UI/UX"],
    "roles": ["Graphic Designer", "Illustrator", "Animator"],
    "lottieStats":
    "assets/lottie/art.json",
    "lottieSkills":
    "assets/lottie/skillsart.json",
    "lottieRoles":
    "assets/lottie/artrole.json",
  },
  "science": {
    "title": "Science",
    "color": Colors.indigo,
    "banner":
    "https://bvtb.org.vn/wp-content/uploads/2024/03/hinh-anh-de-tai-nghien-cuu-khoa-hoc-0-1-350x220.jpg",
    "stats": ["+10% R&D", "Liên ngành mạnh", "Yêu cầu kỹ năng phân tích"],
    "skills": ["Research", "Data Analysis", "Lab", "Statistics"],
    "roles": ["Researcher", "Bioinformatician", "Data Scientist"],
    "lottieStats":
    "assets/lottie/science.json",
    "lottieSkills":
    "assets/lottie/skillscience.json",
    "lottieRoles":
    "https://assets1.lottiefiles.com/packages/lf20_yr6zz3wv.json",
  },
};
