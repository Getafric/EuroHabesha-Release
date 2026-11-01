const Map<String, String> countryPhoneCodes = {
  'France': '+33',
  'Belgium': '+32',
  'UK': '+44',
  'Netherlands': '+31',
  'Portugal': '+351',
  'Spain': '+34',
  'Italy': '+39',
  'Switzerland': '+41',
  'Germany': '+49',
  'Austria': '+43',
  'Luxembourg': '+352',
  'Denmark': '+45',
  'Norway': '+47',
  'Sweden': '+46',
  'Finland': '+358',
  'Iceland': '+354',
  'Ireland': '+353',
  'Greece': '+30',
  'Poland': '+48',
  'Hungary': '+36',
  'Romania': '+40',
  'Bulgaria': '+359',
  'Albania': '+355',
  'Serbia': '+381',
  'Estonia': '+372',
  'Lithuania': '+370',
  'Malta': '+356',
  'Liechtenstein': '+423',
  'Monaco': '+377',
  'Ukraine': '+380',
  'Turkey': '+90',

  // Africa
  'Ethiopia': '+251',
  'Eritrea': '+291',
  'Kenya': '+254',
  'South Africa': '+27',
  'Morocco': '+212',

  // Middle East
  'Saudi Arabia': '+966',
  'Kuwait': '+965',
  'Qatar': '+974',
  'United Arab Emirates': '+971',

  // North America
  'United States': '+1',
  'Canada': '+1',

  // Oceania
  'Australia': '+61',
};

String? dialCodeForCountry(String country) {
  return countryPhoneCodes[country];
}
