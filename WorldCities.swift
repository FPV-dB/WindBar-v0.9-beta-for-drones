//
//  WorldCities.swift
//  WindBar
//
//  Medium World Dataset (~450 cities)
//  Alphabetically sorted
//

import Foundation

struct CountryData {
    let flag: String
    let cities: [String]
}

// MARK: - World Regions → Countries → Cities

let WorldCities: [String: [String: CountryData]] = [

    // -------------------------
    // 🌍 EUROPE
    // -------------------------
    "Europe": [

        "Austria": CountryData(flag: "🇦🇹", cities: [
            "Graz", "Innsbruck", "Linz", "Salzburg", "Vienna"
        ]),

        "Belgium": CountryData(flag: "🇧🇪", cities: [
            "Antwerp", "Brussels", "Ghent", "Liege"
        ]),

        "Czechia": CountryData(flag: "🇨🇿", cities: [
            "Brno", "Ostrava", "Plzeň", "Prague"
        ]),

        "Denmark": CountryData(flag: "🇩🇰", cities: [
            "Aalborg", "Aarhus", "Copenhagen", "Odense"
        ]),

        "Finland": CountryData(flag: "🇫🇮", cities: [
            "Espoo", "Helsinki", "Oulu", "Tampere"
        ]),

        "France": CountryData(flag: "🇫🇷", cities: [
            "Bordeaux", "Lille", "Lyon", "Marseille", "Nice", "Paris", "Toulouse", "Île-de-France (Paris Metro)"
        ]),

        "Germany": CountryData(flag: "🇩🇪", cities: [
            "Berlin", "Bremen", "Cologne", "Dortmund", "Dresden",
            "Frankfurt", "Hamburg", "Hannover", "Leipzig", "Munich", "Stuttgart",
            "Ruhr Area", "Rhineland"
        ]),

        "Greece": CountryData(flag: "🇬🇷", cities: [
            "Athens", "Heraklion", "Patras", "Thessaloniki"
        ]),

        "Hungary": CountryData(flag: "🇭🇺", cities: [
            "Budapest", "Debrecen", "Szeged"
        ]),

        "Ireland": CountryData(flag: "🇮🇪", cities: [
            "Cork", "Dublin", "Galway", "Limerick"
        ]),

        "Italy": CountryData(flag: "🇮🇹", cities: [
            "Bologna", "Florence", "Genoa", "Milan", "Naples", "Palermo", "Rome", "Turin", "Venice",
            "Milan Metro", "Rome Metro"
        ]),

        "Netherlands": CountryData(flag: "🇳🇱", cities: [
            "Amsterdam", "Eindhoven", "Rotterdam", "The Hague", "Utrecht", "Randstad"
        ]),

        "Norway": CountryData(flag: "🇳🇴", cities: [
            "Bergen", "Oslo", "Stavanger", "Trondheim"
        ]),

        "Poland": CountryData(flag: "🇵🇱", cities: [
            "Gdańsk", "Katowice", "Kraków", "Łódź", "Poznań", "Szczecin", "Warsaw", "Wrocław"
        ]),

        "Portugal": CountryData(flag: "🇵🇹", cities: [
            "Braga", "Faro", "Lisbon", "Porto", "Coimbra"
        ]),

        "Spain": CountryData(flag: "🇪🇸", cities: [
            "Alicante", "Barcelona", "Bilbao", "Madrid", "Malaga", "Seville", "Valencia", "Zaragoza",
            "Madrid Metro", "Barcelona Metro"
        ]),

        "Sweden": CountryData(flag: "🇸🇪", cities: [
            "Gothenburg", "Malmö", "Stockholm", "Uppsala"
        ]),

        "Switzerland": CountryData(flag: "🇨🇭", cities: [
            "Basel", "Bern", "Geneva", "Lausanne", "Zurich"
        ]),

        "United Kingdom": CountryData(flag: "🇬🇧", cities: [
            "Belfast", "Birmingham", "Bristol", "Cardiff", "Edinburgh",
            "Glasgow", "Leeds", "Liverpool", "London", "Manchester", "Newcastle",
            "Greater London"
        ])
    ],

    // -------------------------
    // 🌏 ASIA
    // -------------------------
    "Asia": [

        "China": CountryData(flag: "🇨🇳", cities: [
            "Beijing", "Chengdu", "Chongqing", "Guangzhou", "Hangzhou",
            "Nanjing", "Shanghai", "Shenzhen", "Tianjin", "Wuhan", "Xi’an",
            "Pearl River Delta", "Yangtze River Delta"
        ]),

        "India": CountryData(flag: "🇮🇳", cities: [
            "Ahmedabad", "Bangalore", "Chennai", "Delhi", "Hyderabad",
            "Jaipur", "Kolkata", "Mumbai", "Pune", "Surat",
            "NCR (Delhi)", "Mumbai Metro"
        ]),

        "Indonesia": CountryData(flag: "🇮🇩", cities: [
            "Bandung", "Jakarta", "Makassar", "Medan", "Surabaya",
            "Jakarta Metro"
        ]),

        "Japan": CountryData(flag: "🇯🇵", cities: [
            "Fukuoka", "Hiroshima", "Kobe", "Kyoto", "Nagoya",
            "Osaka", "Sapporo", "Sendai", "Tokyo", "Yokohama",
            "Greater Tokyo Area"
        ]),

        "Malaysia": CountryData(flag: "🇲🇾", cities: [
            "George Town", "Johor Bahru", "Kuala Lumpur", "Kuching"
        ]),

        "Philippines": CountryData(flag: "🇵🇭", cities: [
            "Cebu", "Davao", "Manila", "Quezon City"
        ]),

        "Singapore": CountryData(flag: "🇸🇬", cities: [
            "Singapore"
        ]),

        "South Korea": CountryData(flag: "🇰🇷", cities: [
            "Busan", "Daegu", "Daejeon", "Gwangju", "Incheon", "Seoul", "Ulsan",
            "Seoul Capital Area"
        ]),

        "Taiwan": CountryData(flag: "🇹🇼", cities: [
            "Hsinchu", "Kaohsiung", "Taichung", "Tainan", "Taipei"
        ]),

        "Thailand": CountryData(flag: "🇹🇭", cities: [
            "Bangkok", "Chiang Mai", "Pattaya",
            "Bangkok Metro"
        ])
    ],

    // -------------------------
    // 🌏 OCEANIA
    // -------------------------
    "Oceania": [

        "Australia": CountryData(flag: "🇦🇺", cities: [
            "Adelaide", "Brisbane", "Canberra", "Darwin", "Hobart",
            "Melbourne", "Perth", "Sydney",
            "Greater Sydney", "Greater Melbourne"
        ]),

        "New Zealand": CountryData(flag: "🇳🇿", cities: [
            "Auckland", "Christchurch", "Hamilton", "Wellington",
            "Auckland Metro"
        ])
    ],

    // -------------------------
    // 🌎 NORTH AMERICA
    // -------------------------
    "North America": [

        "Canada": CountryData(flag: "🇨🇦", cities: [
            "Calgary", "Edmonton", "Montreal", "Ottawa", "Toronto", "Vancouver",
            "Greater Toronto Area", "Greater Vancouver"
        ]),

        "Mexico": CountryData(flag: "🇲🇽", cities: [
            "Guadalajara", "Mexico City", "Monterrey", "Puebla", "Tijuana"
        ]),

        "United States": CountryData(flag: "🇺🇸", cities: [
            "Atlanta", "Boston", "Chicago", "Dallas", "Denver", "Detroit",
            "Houston", "Las Vegas", "Los Angeles", "Miami", "Minneapolis",
            "New York", "Philadelphia", "Phoenix", "San Diego",
            "San Francisco", "Seattle", "Washington D.C.",
            "New York Metro", "Los Angeles Metro", "Bay Area", "Dallas–Fort Worth", "Chicago Metro"
        ])
    ],

    // -------------------------
    // 🌎 SOUTH AMERICA
    // -------------------------
    "South America": [

        "Argentina": CountryData(flag: "🇦🇷", cities: [
            "Buenos Aires", "Córdoba", "Mendoza", "Rosario",
            "Buenos Aires Metro"
        ]),

        "Brazil": CountryData(flag: "🇧🇷", cities: [
            "Belo Horizonte", "Brasília", "Curitiba", "Fortaleza", "Porto Alegre",
            "Recife", "Rio de Janeiro", "Salvador", "São Paulo",
            "São Paulo Metro", "Rio Metro"
        ]),

        "Chile": CountryData(flag: "🇨🇱", cities: [
            "Antofagasta", "Concepción", "Santiago", "Valparaíso"
        ]),

        "Colombia": CountryData(flag: "🇨🇴", cities: [
            "Barranquilla", "Bogotá", "Cali", "Medellín"
        ]),

        "Peru": CountryData(flag: "🇵🇪", cities: [
            "Arequipa", "Cusco", "Lima", "Trujillo"
        ])
    ],

    // -------------------------
    // 🌍 AFRICA
    // -------------------------
    "Africa": [

        "Egypt": CountryData(flag: "🇪🇬", cities: [
            "Alexandria", "Cairo", "Giza", "Port Said",
            "Greater Cairo"
        ]),

        "Ethiopia": CountryData(flag: "🇪🇹", cities: [
            "Addis Ababa", "Dire Dawa"
        ]),

        "Ghana": CountryData(flag: "🇬🇭", cities: [
            "Accra", "Kumasi"
        ]),

        "Kenya": CountryData(flag: "🇰🇪", cities: [
            "Kisumu", "Mombasa", "Nairobi"
        ]),

        "Morocco": CountryData(flag: "🇲🇦", cities: [
            "Casablanca", "Fez", "Marrakesh", "Rabat"
        ]),

        "Nigeria": CountryData(flag: "🇳🇬", cities: [
            "Abuja", "Benin City", "Enugu", "Ibadan", "Kano", "Lagos", "Port Harcourt",
            "Lagos Metro"
        ]),

        "South Africa": CountryData(flag: "🇿🇦", cities: [
            "Cape Town", "Durban", "Johannesburg", "Pretoria",
            "Johannesburg Metro"
        ])
    ]
]
