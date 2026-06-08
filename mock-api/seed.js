const { faker } = require("@faker-js/faker");
const fs = require("fs");

const BASE_LAT = 42.98;
const BASE_LNG = -81.24;
const EVENT_COUNT = 40;

const venues = [
  "Aeolian Hall",
  "Budweiser Gardens",
  "Grand Theatre",
  "Museum London",
  "Covent Garden Market",
  "Victoria Park",
  "Centennial Hall",
  "London Music Hall",
  "The Rum Runners",
  "Call The Office",
  "Western Fair District",
  "Fanshawe Pioneer Village",
  "Banting House",
  "Eldon House",
  "London Public Library",
];

function generateEvent(index) {
  const id = String(index + 1);
  const lat = BASE_LAT + (Math.random() - 0.5) * 0.1;
  const lng = BASE_LNG + (Math.random() - 0.5) * 0.1;
  const daysFromNow = Math.floor(Math.random() * 60);
  const startTime = new Date(
    Date.now() + daysFromNow * 24 * 60 * 60 * 1000
  ).toISOString();

  return {
    id,
    title: faker.music.songName() + " at " + faker.company.name(),
    description: faker.lorem.sentences(2),
    venueName: venues[index % venues.length],
    latitude: parseFloat(lat.toFixed(6)),
    longitude: parseFloat(lng.toFixed(6)),
    startTime,
    imageUrl: `https://picsum.photos/seed/${id}/600/400`,
  };
}

const events = Array.from({ length: EVENT_COUNT }, (_, i) => generateEvent(i));
const db = { events };

fs.writeFileSync("db.json", JSON.stringify(db, null, 2));
console.log(`Generated ${EVENT_COUNT} events in db.json`);
