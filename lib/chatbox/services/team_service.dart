import '../models/team_member.dart';

class TeamService {
  static List<TeamMember> getTeamMembers() {
    return [
      TeamMember(
        name: "Hoàng Gia Huy",
        email: "huypg7645@gmail.com",
        avatarUrl:
            "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757582257/huy_zxzl6e.jpg",
      ),
      TeamMember(
        name: "Trần Nhật Linh",
        email: "nhatlinh3b122@gmail.com",
        avatarUrl:
            "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757582259/linh_mjmqyv.jpg",
      ),
      TeamMember(
        name: "Nguyễn Trần Hoàng Long",
        email: "hoanglongnguyen0510@gmail.com",
        avatarUrl:
            "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757582261/long_pbab33.jpg",
      ),
      TeamMember(
        name: "Nguyễn Anh Quân",
        email: "quan@gmail.com",
        avatarUrl:
            "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757582260/qu%C3%A2n_w8nrqr.jpg",
      ),
    ];
  }

  static Map<String, dynamic> getTeamInfo() {
    return {
      "members": getTeamMembers(),
      "office": {
        "address":
            "21Bis Hau Giang, Ward 4, Tan Binh, Ho Chi Minh City, Vietnam",
        "lat": 10.807730,
        "lng": 106.660864,
        "email": "team02aptech@gmail.com",
      },
    };
  }
}
