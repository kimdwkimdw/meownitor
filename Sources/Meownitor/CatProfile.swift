import Foundation

struct CatProfile: Equatable {
  static let defaultsKey = "selectedCat"

  let id: String
  let nameKo: String
  let nameEn: String
  let breedKo: String
  let breedEn: String

  static let all = [
    CatProfile(
      id: "elsa", nameKo: "엘사", nameEn: "Elsa", breedKo: "하얀 집고양이", breedEn: "White Domestic Cat"),
    CatProfile(
      id: "K01", nameKo: "호두", nameEn: "Hodu", breedKo: "코리안 숏헤어 · 고등어",
      breedEn: "Korean Shorthair · Brown Tabby"),
    CatProfile(
      id: "K02", nameKo: "치즈", nameEn: "Cheese", breedKo: "코리안 숏헤어 · 치즈",
      breedEn: "Korean Shorthair · Orange Tabby"),
    CatProfile(
      id: "K03", nameKo: "모찌", nameEn: "Mochi", breedKo: "코리안 숏헤어 · 삼색",
      breedEn: "Korean Shorthair · Calico"),
    CatProfile(
      id: "K04", nameKo: "콩이", nameEn: "Kongi", breedKo: "코리안 숏헤어 · 턱시도",
      breedEn: "Korean Shorthair · Tuxedo"),
    CatProfile(
      id: "K05", nameKo: "두부", nameEn: "Dubu", breedKo: "코리안 숏헤어 · 젖소",
      breedEn: "Korean Shorthair · Black and White"),
    CatProfile(
      id: "K06", nameKo: "구름", nameEn: "Gureum", breedKo: "러시안 블루", breedEn: "Russian Blue"),
    CatProfile(id: "K07", nameKo: "설기", nameEn: "Seolgi", breedKo: "페르시안", breedEn: "Persian"),
    CatProfile(
      id: "K08", nameKo: "만두", nameEn: "Mandu", breedKo: "스코티시 폴드", breedEn: "Scottish Fold"),
    CatProfile(id: "K09", nameKo: "보리", nameEn: "Bori", breedKo: "샴", breedEn: "Siamese"),
    CatProfile(
      id: "K10", nameKo: "솜이", nameEn: "Somi", breedKo: "터키시 앙고라", breedEn: "Turkish Angora"),
    CatProfile(
      id: "U01", nameKo: "올리버", nameEn: "Oliver", breedKo: "아메리칸 숏헤어", breedEn: "American Shorthair"
    ),
    CatProfile(
      id: "U02", nameKo: "마일로", nameEn: "Milo", breedKo: "도메스틱 숏헤어", breedEn: "Domestic Shorthair"),
    CatProfile(
      id: "U03", nameKo: "메이플", nameEn: "Maple", breedKo: "도메스틱 롱헤어", breedEn: "Domestic Longhair"),
    CatProfile(id: "U04", nameKo: "코코", nameEn: "Coco", breedKo: "샴", breedEn: "Siamese"),
    CatProfile(id: "U05", nameKo: "레오", nameEn: "Leo", breedKo: "메인쿤", breedEn: "Maine Coon"),
    CatProfile(id: "U06", nameKo: "벨라", nameEn: "Bella", breedKo: "랙돌", breedEn: "Ragdoll"),
    CatProfile(
      id: "U07", nameKo: "스모키", nameEn: "Smokey", breedKo: "러시안 블루", breedEn: "Russian Blue"),
    CatProfile(id: "U08", nameKo: "오닉스", nameEn: "Onyx", breedKo: "봄베이", breedEn: "Bombay"),
    CatProfile(id: "U09", nameKo: "써니", nameEn: "Sunny", breedKo: "벵갈", breedEn: "Bengal"),
    CatProfile(id: "U10", nameKo: "데이지", nameEn: "Daisy", breedKo: "페르시안", breedEn: "Persian"),
  ]

  static var selected: CatProfile {
    get {
      let id = UserDefaults.standard.string(forKey: defaultsKey) ?? "elsa"
      guard let cat = all.first(where: { $0.id == id }), CatPackStore.shared.isInstalled(cat)
      else {
        return all[0]
      }
      return cat
    }
    set {
      UserDefaults.standard.set(newValue.id, forKey: defaultsKey)
    }
  }

  func pickerTitle(in language: AppLanguage) -> String {
    language.text("\(nameKo) · \(breedKo)", "\(nameEn) · \(breedEn)")
  }

  var assetExtension: String {
    "webp"
  }

  var assetSubdirectory: String {
    id == "elsa" ? "ElsaHD" : "Cats/\(id)"
  }

  var localAssetDirectory: String {
    id == "elsa" ? "Resources/ElsaHD/runtime" : "Resources/Cats/\(id)/strips"
  }
}
