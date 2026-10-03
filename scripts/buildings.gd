extends RefCounted
## Bina kataloğu. Yeni bir bina eklemek için CATALOG ve ORDER'a bir satır eklemek yeterli.
## height: haritadaki kutunun karo genişliğine göre yüksekliği.

const CATALOG := {
	"house": {"name": "Ev", "price": 15, "color": "e07a5f", "height": 0.8},
	"park": {"name": "Park", "price": 25, "color": "81b29a", "height": 0.12},
	"cafe": {"name": "Kafe", "price": 30, "color": "f2cc8f", "height": 0.7},
	"library": {"name": "Kütüphane", "price": 60, "color": "5c6b9c", "height": 1.1},
	"school": {"name": "Okul", "price": 90, "color": "6d9dc5", "height": 1.3},
	"tower": {"name": "Saat Kulesi", "price": 150, "color": "9c6644", "height": 2.4},
}

## Mağazadaki sıra.
const ORDER: Array[String] = ["house", "park", "cafe", "library", "school", "tower"]


static func exists(id: String) -> bool:
	return CATALOG.has(id)


static func name_of(id: String) -> String:
	return CATALOG[id]["name"]


static func price(id: String) -> int:
	return CATALOG[id]["price"]


static func color(id: String) -> Color:
	return Color.html(CATALOG[id]["color"])


static func height(id: String) -> float:
	return CATALOG[id]["height"]
