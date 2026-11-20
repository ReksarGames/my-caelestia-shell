// Run with: node tests/test_weather_location.js
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const source = fs.readFileSync(path.join(__dirname, "../services/Weather.qml"), "utf8");
const functions = [...source.matchAll(/^    function \w+\([^]*?^    }/gm)]
    .map(([body]) => body.replace(/^    function [^\n]+/, signature => signature.replace(/:\s*\w+/g, "")))
    .join("\n");
const onChange = source.match(/        function onWeatherLocationChanged\(\): void \{([^]*?)^        }/m)[1];

function weather(location = "Київ") {
    const requests = [];
    const context = vm.createContext({
        GlobalConfig: { services: { weatherLocation: location } },
        Requests: { get: (url, success, error) => requests.push({ url, success, error }) },
        Qt: { locale: () => ({ name: "en_US" }) },
        Tr: { tr: text => text, trCtx: text => text },
        console: { warn() {} }, lc: {},
        timer: { elapsed: () => 0, restart() {} },
        cityLookupTimer: { restart() {} },
        loc: "", city: "", locationError: "", cc: undefined,
        forecast: [], hourlyForecast: [], pendingCoords: "",
        ipApiRequestPending: false, ipApiBlockedUntil: 0,
        cachedCities: new Map(), citiesLoaded: true, CUtils: { version: "test" },
        requests
    });
    vm.runInContext(functions, context);
    context.root = context;
    context.changeLocation = value => {
        context.GlobalConfig.services.weatherLocation = value;
        vm.runInContext(onChange, context);
    };
    return context;
}

const w = weather();
w.reload();
assert.ok(w.requests[0].url.includes(`name=${encodeURIComponent("Київ")}`));
w.requests.shift().success(JSON.stringify({ results: [{ name: "Kyiv", latitude: 50.45, longitude: 30.52 }] }));
assert.equal(w.city, "Kyiv");
assert.equal(w.loc, "50.45,30.52");

w.changeLocation("Stockholm");
assert.equal(w.loc, "");
assert.equal(w.city, "");
const oldRequest = w.requests.shift();
w.changeLocation("Paris");
oldRequest.success('{"results":[{"name":"Stockholm","latitude":59.3,"longitude":18.1}]}');
oldRequest.error("offline");
assert.equal(w.loc, "");
assert.equal(w.locationError, "");
w.requests.shift().success('{"results":[{"name":"Paris","latitude":48.85,"longitude":2.35}]}');
assert.equal(w.city, "Paris");

for (const response of ['{}', 'null', '{"results":[]}', '{"results":[{"latitude":"invalid","longitude":2}]}', 'not json']) {
    w.changeLocation("unknown city");
    w.requests.shift().success(response);
    assert.ok(w.locationError);
    assert.equal(w.loc, "");
    assert.equal(w.requests.length, 0, "failed lookup must not retry in a loop");
}
w.reload();
w.requests.shift().error("offline");
assert.ok(w.locationError.includes("Try again"));

w.cc = { tempC: 20 };
w.forecast = [1];
w.hourlyForecast = [2];
w.changeLocation("");
assert.equal(w.cc, undefined);
assert.equal(w.forecast.length, 0);
assert.equal(w.hourlyForecast.length, 0);
assert.equal(w.locationError, "");
assert.ok(w.requests[0].url.startsWith("http://ip-api.com/"), "clearing the city must immediately detect location");
const ipRequest = w.requests.shift();
w.changeLocation("Kyiv");
ipRequest.success('{"status":"success","city":"VPN city","lat":1,"lon":2}', {});
assert.equal(w.city, "");

const f = weather("59.3,18.1");
f.reload();
assert.equal(f.loc, "59.3,18.1", "existing coordinate configuration must still work");
assert.equal(f.requests.length, 0, "reverse lookup is delayed while choosing a map location");
f.fetchCityFromCoords(f.loc);
const reverseRequest = f.requests.shift();
f.changeLocation("Kyiv");
reverseRequest.success('{"features":[{"properties":{"geocoding":{"type":"city","name":"Old city"}}}]}');
reverseRequest.error("offline");
assert.equal(f.city, "");

const forecast = weather();
forecast.loc = "1,2";
forecast.fetchWeatherData();
const forecastRequest = forecast.requests.shift();
forecast.changeLocation("Paris");
forecastRequest.success("not json: stale weather must be ignored before parsing");
assert.equal(forecast.cc, undefined);

console.log("PASS: manual city, Unicode, reset to IP, lookup failures, coordinates and stale responses");
