
struct Claim: Identifiable {
  let key: String
  let value: String
  var id: String {key}
}
