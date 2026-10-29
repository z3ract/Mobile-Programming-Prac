import '../models/weather_model.dart';

class DummyWeatherData {
  static WeatherModel getPrimaryWeather() {
    return WeatherModel(
      cityName: 'Jakarta Pusat',
      regionName: 'DKI Jakarta',
      country: 'Indonesia',
      latitude: -6.1754,
      longitude: 106.8272,
      tempC: '29',
      tempMaxC: '33',
      tempMinC: '24',
      feelsLikeC: '32',
      humidity: '72',
      weatherDesc: 'Cerah Berawan',
      windSpeedKm: '14',
      windDirection: 'Barat Laut (315°)',
      uvIndex: 7,
      aqi: 45,
      aqiStatus: 'Baik / Sedang',
      sunrise: '05:41 WIB',
      sunset: '17:54 WIB',
      dewPoint: '23°C',
      pressureMb: '1011 hPa',
      isGpsSource: true,
      hourly: [
        HourlyForecast(time: 'Sekarang', tempC: '29', condition: 'Cerah Berawan', iconCode: 'partly_cloudy'),
        HourlyForecast(time: '14:00', tempC: '31', condition: 'Cerah', iconCode: 'sunny'),
        HourlyForecast(time: '15:00', tempC: '32', condition: 'Cerah Berawan', iconCode: 'partly_cloudy'),
        HourlyForecast(time: '16:00', tempC: '30', condition: 'Hujan Ringan', iconCode: 'rain'),
        HourlyForecast(time: '17:00', tempC: '28', condition: 'Hujan Petir', iconCode: 'thunder'),
        HourlyForecast(time: '18:00', tempC: '27', condition: 'Berawan Tebal', iconCode: 'cloudy'),
        HourlyForecast(time: '19:00', tempC: '26', condition: 'Mendung', iconCode: 'cloudy'),
        HourlyForecast(time: '20:00', tempC: '26', condition: 'Cerah Berawan', iconCode: 'partly_cloudy'),
        HourlyForecast(time: '21:00', tempC: '25', condition: 'Cerah', iconCode: 'night_clear'),
      ],
      daily: [
        DailyForecast(day: 'Hari ini', condition: 'Cerah Berawan', minTemp: 24, maxTemp: 32, currentTemp: 29),
        DailyForecast(day: 'Jum, 30 Okt', condition: 'Hujan Ringan', minTemp: 24, maxTemp: 31, currentTemp: null),
        DailyForecast(day: 'Sab, 31 Okt', condition: 'Hujan Petir', minTemp: 23, maxTemp: 30, currentTemp: null),
        DailyForecast(day: 'Min, 1 Nov', condition: 'Berawan', minTemp: 24, maxTemp: 32, currentTemp: null),
        DailyForecast(day: 'Sen, 2 Nov', condition: 'Cerah', minTemp: 25, maxTemp: 33, currentTemp: null),
        DailyForecast(day: 'Sel, 3 Nov', condition: 'Cerah Berawan', minTemp: 25, maxTemp: 33, currentTemp: null),
        DailyForecast(day: 'Rab, 4 Nov', condition: 'Hujan Sedang', minTemp: 23, maxTemp: 29, currentTemp: null),
      ],
    );
  }
}
